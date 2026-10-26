import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';

import 'app_storage.dart';

/// The in-app reminder interval (`SET-004`).
const Duration exportReminderInterval = Duration(days: 30);

/// How long “Later” hides the reminder.
const Duration exportReminderSnooze = Duration(days: 30);

const Object _absent = Object();

/// Reminder metadata is local-only. It is never included in an export because
/// it describes this device, not training data.
class ExportReminderState {
  const ExportReminderState({
    this.lastExportedAt,
    this.snoozedUntil,
    this.dismissedForBaseline,
  });

  final DateTime? lastExportedAt;
  final DateTime? snoozedUntil;

  /// Dismissal applies to one baseline (last export, or the oldest record when
  /// no export exists). A later export changes the baseline.
  final DateTime? dismissedForBaseline;

  ExportReminderState copyWith({
    Object? lastExportedAt = _absent,
    Object? snoozedUntil = _absent,
    Object? dismissedForBaseline = _absent,
  }) {
    return ExportReminderState(
      lastExportedAt: identical(lastExportedAt, _absent)
          ? this.lastExportedAt
          : lastExportedAt as DateTime?,
      snoozedUntil: identical(snoozedUntil, _absent)
          ? this.snoozedUntil
          : snoozedUntil as DateTime?,
      dismissedForBaseline: identical(dismissedForBaseline, _absent)
          ? this.dismissedForBaseline
          : dismissedForBaseline as DateTime?,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'lastExportedAt': lastExportedAt?.toUtc().toIso8601String(),
    'snoozedUntil': snoozedUntil?.toUtc().toIso8601String(),
    'dismissedForBaseline': dismissedForBaseline?.toUtc().toIso8601String(),
  };

  factory ExportReminderState.fromJson(Map<String, Object?> json) {
    DateTime? read(String key) {
      final Object? value = json[key];
      if (value == null) {
        return null;
      }
      if (value is! String) {
        throw FormatException('"$key" must be a string or null');
      }
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed == null) {
        throw FormatException('"$key" must be an ISO-8601 timestamp');
      }
      return parsed.toUtc();
    }

    return ExportReminderState(
      lastExportedAt: read('lastExportedAt'),
      snoozedUntil: read('snoozedUntil'),
      dismissedForBaseline: read('dismissedForBaseline'),
    );
  }
}

/// Local persistence for the reminder. Overridden in tests.
abstract interface class ExportReminderStore {
  Future<ExportReminderState> load();

  Future<void> save(ExportReminderState state);
}

class JsonExportReminderStore implements ExportReminderStore {
  JsonExportReminderStore(this._file);

  final Future<File> _file;

  @override
  Future<ExportReminderState> load() async {
    final File file = await _file;
    if (!await file.exists()) {
      return const ExportReminderState();
    }
    try {
      final Object? decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return const ExportReminderState();
      }
      return ExportReminderState.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      // Reminder metadata is non-critical. A corrupt file must never block
      // app start or an export; the next save rewrites it.
      return const ExportReminderState();
    }
  }

  @override
  Future<void> save(ExportReminderState state) async {
    final File file = await _file;
    await file.parent.create(recursive: true);
    final File temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(state.toJson()), flush: true);
    await temporary.rename(file.path);
  }
}

final Provider<Future<File>> exportReminderFileProvider =
    Provider<Future<File>>(
      (Ref ref) => appSupportFile(ref, 'gym_log_reminder.json'),
    );

final Provider<ExportReminderStore> exportReminderStoreProvider =
    Provider<ExportReminderStore>((Ref ref) {
      return JsonExportReminderStore(ref.watch(exportReminderFileProvider));
    });

/// Whether training data exists at all. Settings-only data does not count.
bool hasTrainingData(AppData data) {
  return data.exercises.isNotEmpty ||
      data.programs.isNotEmpty ||
      data.sessions.isNotEmpty;
}

/// Earliest timestamp created by the user, used as the no-export baseline.
DateTime? earliestDataTimestamp(AppData data) {
  DateTime? earliest;
  void consider(DateTime value) {
    if (earliest == null || value.isBefore(earliest!)) {
      earliest = value;
    }
  }

  for (final Exercise exercise in data.exercises) {
    consider(exercise.createdAt);
  }
  for (final Program program in data.programs) {
    consider(program.createdAt);
  }
  for (final Session session in data.sessions) {
    consider(session.startedAt);
  }
  return earliest;
}

/// Pure `SET-004` policy shared by the banner and tests.
///
/// The banner appears after 30 full days without an export, only when training
/// data exists, is suppressed while snoozed, and stays dismissed for the
/// current baseline. Clock skew into the future never triggers it.
bool shouldShowExportReminder({
  required AppData data,
  required ExportReminderState state,
  required DateTime now,
}) {
  if (!hasTrainingData(data)) {
    return false;
  }
  final DateTime? baseline =
      state.lastExportedAt ?? earliestDataTimestamp(data);
  if (baseline == null) {
    return false;
  }
  if (now.difference(baseline) < exportReminderInterval) {
    return false;
  }
  final DateTime? snoozedUntil = state.snoozedUntil;
  if (snoozedUntil != null && now.isBefore(snoozedUntil)) {
    return false;
  }
  final DateTime? dismissedForBaseline = state.dismissedForBaseline;
  if (dismissedForBaseline != null &&
      dismissedForBaseline.isAtSameMomentAs(baseline)) {
    return false;
  }
  return true;
}

final AsyncNotifierProvider<ExportReminderController, ExportReminderState>
exportReminderControllerProvider =
    AsyncNotifierProvider<ExportReminderController, ExportReminderState>(
      ExportReminderController.new,
      retry: (int retryCount, Object error) => null,
    );

/// Owns local reminder metadata. A failed save restores the prior in-memory
/// state so the banner does not claim a snooze that was not persisted.
class ExportReminderController extends AsyncNotifier<ExportReminderState> {
  Future<void> _chain = Future<void>.value();
  final Completer<ExportReminderState> _ready =
      Completer<ExportReminderState>();

  @override
  Future<ExportReminderState> build() async {
    try {
      final ExportReminderState loaded = await ref
          .watch(exportReminderStoreProvider)
          .load();
      if (!_ready.isCompleted) {
        _ready.complete(loaded);
      }
      return loaded;
    } catch (_) {
      const ExportReminderState fallback = ExportReminderState();
      if (!_ready.isCompleted) {
        _ready.complete(fallback);
      }
      return fallback;
    }
  }

  Future<void> _update(
    ExportReminderState Function(ExportReminderState current) update,
  ) {
    final Completer<void> completer = Completer<void>();
    _chain = _chain.then((_) async {
      ExportReminderState? previous;
      try {
        final ExportReminderState current = state.value ?? await _ready.future;
        previous = current;
        final ExportReminderState next = update(current);
        state = AsyncData<ExportReminderState>(next);
        await ref.read(exportReminderStoreProvider).save(next);
        completer.complete();
      } catch (error, stackTrace) {
        if (previous != null) {
          state = AsyncData<ExportReminderState>(previous);
        }
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> markExported(DateTime exportedAt) {
    return _update(
      (ExportReminderState current) =>
          ExportReminderState(lastExportedAt: exportedAt.toUtc()),
    );
  }

  Future<void> snooze(DateTime now) {
    return _update(
      (ExportReminderState current) =>
          current.copyWith(snoozedUntil: now.toUtc().add(exportReminderSnooze)),
    );
  }

  Future<void> dismiss(DateTime baseline) {
    return _update(
      (ExportReminderState current) =>
          current.copyWith(dismissedForBaseline: baseline.toUtc()),
    );
  }
}
