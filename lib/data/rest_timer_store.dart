import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_storage.dart';

/// The small, local-only rest timer snapshot that lets a running countdown
/// survive a process death in the middle of a workout.
///
/// It is deliberately separate from the training document: this is ephemeral
/// UI state, never exported, and a corrupt file simply means "no timer".
class PersistedRestTimer {
  const PersistedRestTimer({required this.endsAt, required this.duration});

  final DateTime endsAt;
  final Duration duration;

  Map<String, Object?> toJson() => <String, Object?>{
    'endsAt': endsAt.toUtc().toIso8601String(),
    'durationSeconds': duration.inSeconds,
  };

  static PersistedRestTimer? fromJson(Map<String, Object?> json) {
    final Object? endsAtValue = json['endsAt'];
    final Object? durationValue = json['durationSeconds'];
    if (endsAtValue is! String || durationValue is! int) {
      return null;
    }
    final DateTime? endsAt = DateTime.tryParse(endsAtValue);
    if (endsAt == null || durationValue <= 0) {
      return null;
    }
    return PersistedRestTimer(
      endsAt: endsAt.toUtc(),
      duration: Duration(seconds: durationValue),
    );
  }
}

abstract interface class RestTimerStore {
  Future<PersistedRestTimer?> load();

  Future<void> save(PersistedRestTimer timer);

  Future<void> clear();
}

/// Atomic best-effort persistence for the in-app rest countdown.
class JsonRestTimerStore implements RestTimerStore {
  JsonRestTimerStore(this._file);

  final Future<File> _file;
  Future<void> _writeChain = Future<void>.value();

  Future<void> _enqueue(Future<void> Function() body) {
    final Completer<void> completer = Completer<void>();
    _writeChain = _writeChain.then((_) async {
      try {
        await body();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  @override
  Future<PersistedRestTimer?> load() async {
    try {
      final File file = await _file;
      if (!await file.exists()) {
        return null;
      }
      final Object? decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return null;
      }
      return PersistedRestTimer.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(PersistedRestTimer timer) {
    return _enqueue(() async {
      try {
        final File file = await _file;
        await file.parent.create(recursive: true);
        final File temporary = File('${file.path}.tmp');
        await temporary.writeAsString(jsonEncode(timer.toJson()), flush: true);
        await temporary.rename(file.path);
      } catch (_) {
        // The countdown is still correct in memory; a failed write only means
        // it cannot be restored after a process death.
      }
    });
  }

  @override
  Future<void> clear() {
    return _enqueue(() async {
      try {
        final File file = await _file;
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // A stale marker is discarded on the next read when it is in the past.
      }
    });
  }
}

final Provider<Future<File>> restTimerFileProvider = Provider<Future<File>>(
  (Ref ref) => appSupportFile(ref, 'rest_timer.json'),
);

final Provider<RestTimerStore> restTimerStoreProvider =
    Provider<RestTimerStore>((Ref ref) {
      return JsonRestTimerStore(ref.watch(restTimerFileProvider));
    });
