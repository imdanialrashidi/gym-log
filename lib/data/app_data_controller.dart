import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:lift_core/lift_core.dart' as edits;
import 'package:uuid/uuid.dart';

import 'app_data_store.dart';
import 'photo_storage.dart';

/// Store shared by the exercise and program features.
final Provider<AppDataStore> appDataStoreProvider = Provider<AppDataStore>((
  Ref ref,
) {
  return JsonAppDataStore(ref.watch(appDataFileProvider));
});

/// A document load that `main` started before `runApp`.
///
/// The first controller build consumes the future once; an explicit retry
/// after a failed load must read the file again instead of replaying the same
/// failure.
class AppDataPreloader {
  AppDataPreloader(this._pending);

  Future<AppData>? _pending;

  Future<AppData>? take() {
    final Future<AppData>? pending = _pending;
    _pending = null;
    return pending;
  }
}

/// Overridden by `main` with the load that overlaps engine startup. Null in
/// tests and in any embedding that does not preload.
final Provider<AppDataPreloader?> appDataPreloaderProvider =
    Provider<AppDataPreloader?>((Ref ref) => null);

/// Authoritative in-memory copy of the persisted document.
///
/// Corrupt or newer-version data is not transient, so failed loads are not
/// retried; the screen offers an explicit retry instead.
final AsyncNotifierProvider<AppDataController, AppData>
appDataControllerProvider = AsyncNotifierProvider<AppDataController, AppData>(
  AppDataController.new,
  retry: (int retryCount, Object error) => null,
);

/// Pre-Replace data snapshots, newest first. Invalidated after every write
/// that adds a snapshot so Settings shows the new recovery point immediately.
final FutureProvider<List<DataSnapshotInfo>> dataSnapshotsProvider =
    FutureProvider<List<DataSnapshotInfo>>(
      (Ref ref) => ref.watch(appDataStoreProvider).listSnapshots(),
    );

/// Commits document edits and persists them.
///
/// The edits themselves are pure functions in `lift_core`; this controller owns
/// only the ordering that makes them safe: one writer at a time, snapshot
/// before Replace, durable write before publishing, and rollback on failure.
/// A failed write restores the previous in-memory snapshot and surfaces the
/// error.
class AppDataController extends AsyncNotifier<AppData> {
  static const Uuid _uuid = Uuid();
  Future<void> _mutationChain = Future<void>.value();

  String _newId() => _uuid.v4();

  DateTime _now() => DateTime.now().toUtc();

  @override
  Future<AppData> build() {
    final AppDataPreloader? preloader = ref.watch(appDataPreloaderProvider);
    final Future<AppData>? preloaded = preloader?.take();
    if (preloaded != null) {
      return preloaded;
    }
    return ref.watch(appDataStoreProvider).load();
  }

  /// Runs [body] after every previously queued write, completing this caller
  /// only when the body finishes. Bodies own their rollback.
  Future<void> _serialized(Future<void> Function() body) {
    final Completer<void> completer = Completer<void>();
    _mutationChain = _mutationChain.then((_) async {
      try {
        await body();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _mutate(
    AppData Function(AppData current) update, {
    bool snapshotFirst = false,
  }) {
    return _serialized(() async {
      AppData? previous;
      try {
        previous = state.requireValue;
        final AppData next = update(previous);
        final AppDataStore store = ref.read(appDataStoreProvider);
        if (snapshotFirst) {
          await store.snapshot();
        }
        // Publish only after the write is durable. Photo pruning and other
        // observers must never act on a state that a failed save rolls back.
        await store.save(next);
        state = AsyncData<AppData>(next);
      } catch (error) {
        if (previous != null) {
          state = AsyncData<AppData>(previous);
        }
        rethrow;
      }
    });
  }

  /// Applies a validated import through the serialized mutation chain.
  ///
  /// Replace snapshots first. Merge is additive and re-plans against the
  /// current state; if the brought counts no longer match the preview, nothing
  /// is written and the caller can ask the user to review again.
  Future<void> applyImport(ImportPreview preview) async {
    if (preview.mode == ImportMode.replace) {
      await _mutate((AppData _) => preview.data, snapshotFirst: true);
    } else {
      await _mutate((AppData current) {
        final MergeResult result = mergeAppData(current, preview.document.data);
        if (result.summary != preview.summary) {
          throw const ImportPreviewMismatch();
        }
        return result.data;
      });
    }
    // Replace can remove sessions/exercises; Merge can add them. Prune private
    // photo files against the new identity set so no orphan survives.
    await _prunePhotos(state.requireValue);
  }

  Future<void> _prunePhotos(AppData data) async {
    try {
      await ref
          .read(photoStorageProvider)
          .pruneAndLoad(
            exerciseIds: <String>{
              for (final Exercise exercise in data.exercises) exercise.id,
            },
            sessionIds: <String>{
              for (final Session session in data.sessions) session.id,
            },
          );
    } catch (_) {
      // The startup prune retries on the next app start; import/delete itself
      // must not fail because cleanup is temporarily unavailable.
    }
  }

  /// Replaces an unreadable on-device document with a validated backup.
  ///
  /// The existing bytes are snapshotted before the write, so the unreadable
  /// file survives; only Replace is meaningful when no document could be
  /// loaded. State is published only after the write succeeds.
  Future<void> restoreFromBackup(ImportPreview preview) {
    if (preview.mode != ImportMode.replace) {
      throw ArgumentError.value(preview.mode, 'preview.mode');
    }
    return _serialized(() async {
      if (state.hasValue) {
        throw StateError('A document is already loaded');
      }
      final AppDataStore store = ref.read(appDataStoreProvider);
      await store.snapshot();
      await store.save(preview.data);
      state = AsyncData<AppData>(preview.data);
    }).then((_) => _prunePhotos(preview.data));
  }

  /// Restores one pre-Replace data snapshot over the current document.
  ///
  /// The snapshot is fully parsed before the mutation chain starts, so a
  /// corrupt file writes nothing. The current document is snapshotted first,
  /// making the restore itself reversible. Photos are not part of either file.
  Future<void> restoreSnapshot(String fileName) async {
    final AppData restored = await ref
        .read(appDataStoreProvider)
        .loadSnapshot(fileName);
    await _mutate((AppData _) => restored, snapshotFirst: true);
    await _prunePhotos(state.requireValue);
  }

  Future<Exercise> createExercise({
    required String name,
    String? searchTerm,
    MuscleGroup? muscleGroup,
    int? defaultRepMin,
    int? defaultRepMax,
    int incrementGrams = defaultKilogramIncrementGrams,
  }) async {
    late Exercise created;
    await _mutate((AppData data) {
      final result = edits.createExercise(
        data,
        id: _newId(),
        name: name,
        createdAt: _now(),
        searchTerm: searchTerm,
        muscleGroup: muscleGroup,
        defaultRepMin: defaultRepMin,
        defaultRepMax: defaultRepMax,
        incrementGrams: incrementGrams,
      );
      created = result.exercise;
      return result.data;
    });
    return created;
  }

  Future<Exercise> updateExercise(Exercise exercise) async {
    await _mutate((AppData data) => edits.updateExercise(data, exercise));
    return exercise;
  }

  Future<void> setExerciseArchived(
    String exerciseId, {
    required bool archived,
  }) {
    return _mutate(
      (AppData data) => edits.setExerciseArchived(
        data,
        exerciseId,
        archived: archived,
        changedAt: _now(),
      ),
    );
  }

  Future<Program> createProgram(String name) async {
    late Program created;
    await _mutate((AppData data) {
      final result = edits.createProgram(
        data,
        id: _newId(),
        name: name,
        createdAt: _now(),
      );
      created = result.program;
      return result.data;
    });
    return created;
  }

  Future<void> renameProgram(String programId, String name) {
    return _mutate(
      (AppData data) => edits.renameProgram(data, programId, name),
    );
  }

  Future<void> deleteProgram(String programId) {
    return _mutate((AppData data) => edits.deleteProgram(data, programId));
  }

  Future<ProgramDay> addDay(String programId, String name) async {
    late ProgramDay created;
    await _mutate((AppData data) {
      final result = edits.addDay(
        data,
        id: _newId(),
        programId: programId,
        name: name,
      );
      created = result.day;
      return result.data;
    });
    return created;
  }

  Future<void> renameDay(String programId, String dayId, String name) {
    return _mutate(
      (AppData data) => edits.renameDay(data, programId, dayId, name),
    );
  }

  Future<void> deleteDay(String programId, String dayId) {
    return _mutate((AppData data) => edits.deleteDay(data, programId, dayId));
  }

  Future<void> reorderDays(String programId, int oldIndex, int newIndex) {
    return _mutate(
      (AppData data) => edits.reorderDays(data, programId, oldIndex, newIndex),
    );
  }

  Future<PlanItem> addPlanItem({
    required String dayId,
    required String exerciseId,
    required int targetSets,
    required int repMin,
    required int repMax,
  }) async {
    late PlanItem created;
    await _mutate((AppData data) {
      final result = edits.addPlanItem(
        data,
        id: _newId(),
        dayId: dayId,
        exerciseId: exerciseId,
        targetSets: targetSets,
        repMin: repMin,
        repMax: repMax,
      );
      created = result.item;
      return result.data;
    });
    return created;
  }

  Future<PlanItem> updatePlanItem(PlanItem item) async {
    await _mutate((AppData data) => edits.updatePlanItem(data, item));
    return item;
  }

  Future<void> deletePlanItem(String dayId, String itemId) {
    return _mutate((AppData data) => edits.deletePlanItem(data, dayId, itemId));
  }

  Future<void> reorderPlanItems(String dayId, int oldIndex, int newIndex) {
    return _mutate(
      (AppData data) =>
          edits.reorderItemsInDay(data, dayId, oldIndex, newIndex),
    );
  }

  Future<void> setWeightUnit(WeightUnit unit) {
    return _mutate((AppData data) => edits.setWeightUnit(data, unit));
  }

  /// Sets the explicit digit style (`SET-002`); display only.
  Future<void> setDigitStyle(DigitStyle style) {
    return _mutate((AppData data) => edits.setDigitStyle(data, style));
  }

  /// Sets the default increment for new exercises (`EXR-007`).
  Future<void> setDefaultIncrementGrams(int grams) {
    return _mutate(
      (AppData data) => edits.setDefaultIncrementGrams(data, grams),
    );
  }

  Future<void> setRestTimerEnabled(bool enabled) {
    return _mutate((AppData data) => edits.setRestTimerEnabled(data, enabled));
  }

  /// Applies a relative rest-duration change through the serialized mutation
  /// chain, so two quick taps each see the previous result. Values clamp to
  /// the supported bounds.
  Future<void> adjustRestTimerDurationSeconds(int delta) {
    return _mutate(
      (AppData data) => edits.adjustRestTimerDurationSeconds(data, delta),
    );
  }

  Future<void> setRestTimerDurationSeconds(int seconds) {
    return _mutate(
      (AppData data) => edits.setRestTimerDurationSeconds(data, seconds),
    );
  }

  /// Enables or updates the optional weekly goal (`GOAL-001`).
  Future<void> setWeeklyGoals({int? sessionGoal, int? setGoal}) {
    return _mutate(
      (AppData data) => edits.setWeeklyGoals(
        data,
        sessionGoal: sessionGoal,
        setGoal: setGoal,
      ),
    );
  }

  /// Removes both weekly goals.
  Future<void> clearWeeklyGoals() {
    return _mutate(edits.clearWeeklyGoals);
  }

  /// Records one body-weight check-in (`BODY-001`).
  ///
  /// The weight is canonical grams; the display unit only affects the input
  /// and labels in the UI.
  Future<BodyWeightEntry> logBodyWeight({
    required int weightGrams,
    DateTime? recordedAt,
    String? replaceId,
  }) async {
    late BodyWeightEntry entry;
    await _mutate((AppData data) {
      if (replaceId == null) {
        final result = edits.addBodyWeightEntry(
          data,
          id: _newId(),
          weightGrams: weightGrams,
          recordedAt: recordedAt ?? _now(),
        );
        entry = result.entry;
        return result.data;
      }
      final result = edits.replaceBodyWeightEntry(
        data,
        id: replaceId,
        weightGrams: weightGrams,
        recordedAt: recordedAt ?? _now(),
      );
      entry = result.entry;
      return result.data;
    });
    return entry;
  }

  /// Removes one check-in and returns it for Undo.
  Future<BodyWeightEntry> deleteBodyWeight(String id) async {
    late BodyWeightEntry removed;
    await _mutate((AppData data) {
      final result = edits.deleteBodyWeightEntry(data, id);
      removed = result.entry;
      return result.data;
    });
    return removed;
  }

  /// Restores a check-in removed by [deleteBodyWeight] without changing it.
  Future<void> restoreBodyWeight(BodyWeightEntry entry) {
    return _mutate(
      (AppData data) => data.copyWith(
        bodyWeights: <BodyWeightEntry>[...data.bodyWeights, entry],
      ),
    );
  }

  /// Starts an empty session or snapshots [programDayId]'s planned exercises.
  ///
  /// The session is written before it is shown so a process death immediately
  /// after starting still recovers it (`LOG-009`, `PLAN-004`).
  Future<Session> startSession({String? programDayId}) async {
    late Session started;
    await _mutate((AppData data) {
      final result = edits.startSession(
        data,
        id: _newId(),
        startedAt: _now(),
        nextExerciseId: _newId,
        programDayId: programDayId,
      );
      started = result.session;
      return result.data;
    });
    return started;
  }

  /// Adds an exercise to the active session (`PLAN-004`).
  ///
  /// The rep range comes from the exercise defaults; target sets stay null so
  /// the user logs as many sets as they choose.
  Future<SessionExercise> addExerciseToSession({
    required String sessionId,
    required String exerciseId,
  }) async {
    late SessionExercise created;
    await _mutate((AppData data) {
      final result = edits.addExerciseToSession(
        data,
        id: _newId(),
        sessionId: sessionId,
        exerciseId: exerciseId,
      );
      created = result.sessionExercise;
      return result.data;
    });
    return created;
  }

  /// Commits one set immediately (`LOG-001`, `NFR-REL-001`) and returns the set
  /// with the records it earned. The records are derived inside the same commit
  /// from the document that already contains the set.
  Future<LoggedSet> logSet({
    required String sessionId,
    required String sessionExerciseId,
    required int setIndex,
    required SetEntry entry,
  }) async {
    late LoggedSet logged;
    await _mutate((AppData data) {
      final result = edits.logSet(
        data,
        id: _newId(),
        sessionId: sessionId,
        sessionExerciseId: sessionExerciseId,
        setIndex: setIndex,
        entry: entry,
        loggedAt: _now(),
      );
      logged = result.loggedSet;
      return result.data;
    });
    return logged;
  }

  /// Replaces one logged set's values in an active or finished session
  /// (`LOG-006`). The set keeps its id, row position, and original timestamp.
  Future<void> updateSet({
    required String sessionId,
    required String sessionExerciseId,
    required String setId,
    required SetEntry entry,
  }) {
    return _mutate(
      (AppData data) => edits.updateSet(
        data,
        sessionId: sessionId,
        sessionExerciseId: sessionExerciseId,
        setId: setId,
        entry: entry,
      ),
    );
  }

  /// Removes one set and returns the removed value for Undo (`LOG-006`).
  Future<SetLog> deleteSet({
    required String sessionId,
    required String sessionExerciseId,
    required String setId,
  }) async {
    late SetLog removed;
    await _mutate((AppData data) {
      final result = edits.deleteSet(
        data,
        sessionId: sessionId,
        sessionExerciseId: sessionExerciseId,
        setId: setId,
      );
      removed = result.set;
      return result.data;
    });
    return removed;
  }

  /// Restores a set removed by [deleteSet] without changing its data.
  Future<void> restoreSet({
    required String sessionId,
    required String sessionExerciseId,
    required SetLog set,
  }) {
    return _mutate(
      (AppData data) => edits.restoreSet(
        data,
        sessionId: sessionId,
        sessionExerciseId: sessionExerciseId,
        set: set,
      ),
    );
  }

  /// Deletes a session, everything nested in it, and its private photo files.
  Future<Session> deleteSession(String sessionId) async {
    late Session removed;
    await _mutate((AppData data) {
      final result = edits.deleteSession(data, sessionId: sessionId);
      removed = result.session;
      return result.data;
    });
    try {
      await ref.read(photoStorageProvider).removeSession(sessionId);
    } catch (_) {
      // The data deletion is authoritative. A failed file delete is retried by
      // the startup photo prune on the next app start.
    }
    return removed;
  }

  /// Sets or clears the session note (`LOG-007`).
  Future<void> setSessionNote(String sessionId, String? note) {
    return _mutate(
      (AppData data) => edits.setSessionNote(data, sessionId, note),
    );
  }

  /// Sets or clears one exercise's note inside a session (`LOG-007`).
  Future<void> setSessionExerciseNote({
    required String sessionId,
    required String sessionExerciseId,
    required String? note,
  }) {
    return _mutate(
      (AppData data) => edits.setSessionExerciseNote(
        data,
        sessionId: sessionId,
        sessionExerciseId: sessionExerciseId,
        note: note,
      ),
    );
  }

  /// Ends the active session. Logged sets stay in history.
  Future<Session> finishSession(String sessionId) async {
    late Session finished;
    await _mutate((AppData data) {
      final result = edits.finishSession(
        data,
        sessionId: sessionId,
        endedAt: _now(),
      );
      finished = result.session;
      return result.data;
    });
    return finished;
  }
}
