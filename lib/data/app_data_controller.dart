import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:lift_core/lift_core.dart' as core show reorderPlanItems;
import 'package:uuid/uuid.dart';

import 'app_data_store.dart';
import 'photo_storage.dart';

/// Store shared by the exercise and program features.
final Provider<AppDataStore> appDataStoreProvider = Provider<AppDataStore>((
  Ref ref,
) {
  return JsonAppDataStore(ref.watch(appDataFileProvider));
});

/// Authoritative in-memory copy of the persisted document.
///
/// Corrupt or newer-version data is not transient, so failed loads are not
/// retried; the screen offers an explicit retry instead.
final AsyncNotifierProvider<AppDataController, AppData>
appDataControllerProvider = AsyncNotifierProvider<AppDataController, AppData>(
  AppDataController.new,
  retry: (int retryCount, Object error) => null,
);

/// Mutates the loaded document and writes it through the store.
///
/// Mutations are serialized: each operation reads the latest state, applies one
/// transformation, and only then allows the next operation to run. A failed
/// write restores the previous in-memory snapshot and surfaces the error.
class AppDataController extends AsyncNotifier<AppData> {
  static const Uuid _uuid = Uuid();
  Future<void> _mutationChain = Future<void>.value();

  @override
  Future<AppData> build() => ref.watch(appDataStoreProvider).load();

  Future<void> _mutate(
    AppData Function(AppData current) update, {
    bool snapshotFirst = false,
  }) {
    final Completer<void> completer = Completer<void>();
    _mutationChain = _mutationChain.then((_) async {
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
        completer.complete();
      } catch (error, stackTrace) {
        if (previous != null) {
          state = AsyncData<AppData>(previous);
        }
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
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

  Future<Exercise> createExercise({
    required String name,
    String? searchTerm,
    MuscleGroup? muscleGroup,
    int? defaultRepMin,
    int? defaultRepMax,
    int incrementGrams = defaultKilogramIncrementGrams,
  }) async {
    final Exercise exercise = Exercise(
      id: _uuid.v4(),
      name: name,
      searchTerm: searchTerm,
      muscleGroup: muscleGroup,
      defaultRepMin: defaultRepMin,
      defaultRepMax: defaultRepMax,
      incrementGrams: incrementGrams,
      createdAt: DateTime.now().toUtc(),
    );
    await _mutate(
      (AppData data) =>
          data.copyWith(exercises: <Exercise>[...data.exercises, exercise]),
    );
    return exercise;
  }

  Future<Exercise> updateExercise(Exercise exercise) async {
    await _mutate(
      (AppData data) => data.copyWith(
        exercises: <Exercise>[
          for (final Exercise existing in data.exercises)
            if (existing.id == exercise.id) exercise else existing,
        ],
      ),
    );
    return exercise;
  }

  Future<void> setExerciseArchived(
    String exerciseId, {
    required bool archived,
  }) {
    return _mutate(
      (AppData data) => data.copyWith(
        exercises: <Exercise>[
          for (final Exercise exercise in data.exercises)
            if (exercise.id == exerciseId)
              exercise.copyWith(
                archivedAt: archived ? DateTime.now().toUtc() : null,
              )
            else
              exercise,
        ],
      ),
    );
  }

  Future<Program> createProgram(String name) async {
    final Program program = Program(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now().toUtc(),
    );
    await _mutate(
      (AppData data) =>
          data.copyWith(programs: <Program>[...data.programs, program]),
    );
    return program;
  }

  Future<void> renameProgram(String programId, String name) {
    return _mutate(
      (AppData data) => data.copyWith(
        programs: <Program>[
          for (final Program program in data.programs)
            if (program.id == programId)
              program.copyWith(name: name)
            else
              program,
        ],
      ),
    );
  }

  Future<void> deleteProgram(String programId) {
    return _mutate(
      (AppData data) => data.copyWith(
        programs: <Program>[
          for (final Program program in data.programs)
            if (program.id != programId) program,
        ],
      ),
    );
  }

  Future<ProgramDay> addDay(String programId, String name) async {
    late ProgramDay day;
    await _mutate((AppData data) {
      final Program? program = data.programById(programId);
      if (program == null) {
        throw StateError('Program $programId does not exist');
      }
      day = ProgramDay(
        id: _uuid.v4(),
        name: name,
        sortOrder: program.days.isEmpty ? 0 : program.days.last.sortOrder + 1,
      );
      return data.copyWith(
        programs: <Program>[
          for (final Program existing in data.programs)
            if (existing.id == programId)
              existing.copyWith(days: <ProgramDay>[...existing.days, day])
            else
              existing,
        ],
      );
    });
    return day;
  }

  Future<void> renameDay(String programId, String dayId, String name) {
    return _mutate(
      (AppData data) => data.copyWith(
        programs: <Program>[
          for (final Program program in data.programs)
            if (program.id == programId)
              program.copyWith(
                days: <ProgramDay>[
                  for (final ProgramDay day in program.days)
                    if (day.id == dayId) day.copyWith(name: name) else day,
                ],
              )
            else
              program,
        ],
      ),
    );
  }

  Future<void> deleteDay(String programId, String dayId) {
    return _mutate(
      (AppData data) => data.copyWith(
        programs: <Program>[
          for (final Program program in data.programs)
            if (program.id == programId)
              program.copyWith(
                days: <ProgramDay>[
                  for (final ProgramDay day in program.days)
                    if (day.id != dayId) day,
                ],
              )
            else
              program,
        ],
      ),
    );
  }

  Future<void> reorderDays(String programId, int oldIndex, int newIndex) {
    return _mutate(
      (AppData data) => data.copyWith(
        programs: <Program>[
          for (final Program program in data.programs)
            if (program.id == programId)
              program.copyWith(
                days: reorderProgramDays(program.days, oldIndex, newIndex),
              )
            else
              program,
        ],
      ),
    );
  }

  Future<PlanItem> addPlanItem({
    required String dayId,
    required String exerciseId,
    required int targetSets,
    required int repMin,
    required int repMax,
  }) async {
    late PlanItem item;
    await _mutate((AppData data) {
      final ProgramDay? day = data.dayById(dayId);
      if (day == null) {
        throw StateError('Day $dayId does not exist');
      }
      item = PlanItem(
        id: _uuid.v4(),
        exerciseId: exerciseId,
        targetSets: targetSets,
        repMin: repMin,
        repMax: repMax,
        sortOrder: day.items.isEmpty ? 0 : day.items.last.sortOrder + 1,
      );
      return _replaceDay(
        data,
        dayId,
        (ProgramDay existing) =>
            existing.copyWith(items: <PlanItem>[...existing.items, item]),
      );
    });
    return item;
  }

  Future<PlanItem> updatePlanItem(PlanItem item) async {
    await _mutate(
      (AppData data) => _replaceDay(
        data,
        _dayIdForItem(data, item.id),
        (ProgramDay day) => day.copyWith(
          items: <PlanItem>[
            for (final PlanItem existing in day.items)
              if (existing.id == item.id) item else existing,
          ],
        ),
      ),
    );
    return item;
  }

  Future<void> deletePlanItem(String dayId, String itemId) {
    return _mutate(
      (AppData data) => _replaceDay(
        data,
        dayId,
        (ProgramDay day) => day.copyWith(
          items: <PlanItem>[
            for (final PlanItem item in day.items)
              if (item.id != itemId) item,
          ],
        ),
      ),
    );
  }

  Future<void> reorderPlanItems(String dayId, int oldIndex, int newIndex) {
    return _mutate(
      (AppData data) => _replaceDay(
        data,
        dayId,
        (ProgramDay day) => day.copyWith(
          items: core.reorderPlanItems(day.items, oldIndex, newIndex),
        ),
      ),
    );
  }

  Future<void> setWeightUnit(WeightUnit unit) {
    return _mutate(
      (AppData data) =>
          data.copyWith(settings: data.settings.copyWith(weightUnit: unit)),
    );
  }

  /// Sets the explicit digit style (`SET-002`); display only.
  Future<void> setDigitStyle(DigitStyle style) {
    return _mutate(
      (AppData data) =>
          data.copyWith(settings: data.settings.copyWith(digitStyle: style)),
    );
  }

  /// Sets the default increment for new exercises (`EXR-007`).
  Future<void> setDefaultIncrementGrams(int grams) {
    if (grams <= 0 || grams > maximumSetWeightGrams) {
      throw ArgumentError.value(grams, 'grams');
    }
    return _mutate(
      (AppData data) => data.copyWith(
        settings: data.settings.copyWith(defaultIncrementGrams: grams),
      ),
    );
  }

  Future<void> setRestTimerEnabled(bool enabled) {
    return _mutate(
      (AppData data) => data.copyWith(
        settings: data.settings.copyWith(restTimerEnabled: enabled),
      ),
    );
  }

  Future<void> setRestTimerDurationSeconds(int seconds) {
    if (!isValidRestTimerDuration(seconds)) {
      throw ArgumentError.value(seconds, 'seconds');
    }
    return _mutate(
      (AppData data) => data.copyWith(
        settings: data.settings.copyWith(restTimerDurationSeconds: seconds),
      ),
    );
  }

  /// Starts an empty session or snapshots [programDayId]'s planned exercises.
  ///
  /// The session is written before it is shown so a process death immediately
  /// after starting still recovers it (`LOG-009`, `PLAN-004`).
  Future<Session> startSession({String? programDayId}) async {
    late Session session;
    await _mutate((AppData data) {
      if (data.activeSession != null) {
        throw StateError('An active session already exists');
      }
      final List<SessionExercise> exercises = <SessionExercise>[];
      if (programDayId != null) {
        final ProgramDay? day = data.dayById(programDayId);
        if (day == null) {
          throw StateError('Day $programDayId does not exist');
        }
        for (final PlanItem item in day.items) {
          exercises.add(
            SessionExercise(
              id: _uuid.v4(),
              exerciseId: item.exerciseId,
              sortOrder: exercises.length,
              targetSets: item.targetSets,
              repMin: item.repMin,
              repMax: item.repMax,
            ),
          );
        }
      }
      session = Session(
        id: _uuid.v4(),
        startedAt: DateTime.now().toUtc(),
        programDayId: programDayId,
        exercises: exercises,
      );
      return data.copyWith(sessions: <Session>[...data.sessions, session]);
    });
    return session;
  }

  /// Adds an exercise to the active session (`PLAN-004`).
  ///
  /// The rep range comes from the exercise defaults; target sets stay null so
  /// the user logs as many sets as they choose.
  Future<SessionExercise> addExerciseToSession({
    required String sessionId,
    required String exerciseId,
  }) async {
    late SessionExercise sessionExercise;
    await _mutate((AppData data) {
      final Session? session = data.sessionById(sessionId);
      if (session == null) {
        throw StateError('Session $sessionId does not exist');
      }
      if (!session.isActive) {
        throw StateError('Session $sessionId is finished');
      }
      final Exercise? exercise = data.exerciseById(exerciseId);
      if (exercise == null) {
        throw StateError('Exercise $exerciseId does not exist');
      }
      sessionExercise = SessionExercise(
        id: _uuid.v4(),
        exerciseId: exerciseId,
        sortOrder: session.exercises.length,
        repMin: exercise.defaultRepMin,
        repMax: exercise.defaultRepMax,
      );
      return data.copyWith(
        sessions: <Session>[
          for (final Session existing in data.sessions)
            if (existing.id == sessionId)
              existing.copyWith(
                exercises: <SessionExercise>[
                  ...existing.exercises,
                  sessionExercise,
                ],
              )
            else
              existing,
        ],
      );
    });
    return sessionExercise;
  }

  /// Commits one set immediately (`LOG-001`, `NFR-REL-001`).
  Future<SetLog> logSet({
    required String sessionId,
    required String sessionExerciseId,
    required int setIndex,
    required int weightGrams,
    required int reps,
    int? rir,
    bool isWarmup = false,
  }) async {
    late SetLog logged;
    await _mutate((AppData data) {
      final Session? session = data.sessionById(sessionId);
      if (session == null) {
        throw StateError('Session $sessionId does not exist');
      }
      if (!session.isActive) {
        throw StateError('Session $sessionId is finished');
      }
      final SessionExercise? sessionExercise = session.exerciseById(
        sessionExerciseId,
      );
      if (sessionExercise == null) {
        throw StateError('Session exercise $sessionExerciseId does not exist');
      }
      if (sessionExercise.sets.any((SetLog set) => set.setIndex == setIndex)) {
        throw StateError('Set index $setIndex is already logged');
      }
      logged = SetLog(
        id: _uuid.v4(),
        setIndex: setIndex,
        weightGrams: weightGrams,
        reps: reps,
        rir: rir,
        isWarmup: isWarmup,
        loggedAt: DateTime.now().toUtc(),
      );
      return data.copyWith(
        sessions: <Session>[
          for (final Session existing in data.sessions)
            if (existing.id == sessionId)
              existing.copyWith(
                exercises: <SessionExercise>[
                  for (final SessionExercise exercise in existing.exercises)
                    if (exercise.id == sessionExerciseId)
                      exercise.copyWith(
                        sets: <SetLog>[...exercise.sets, logged],
                      )
                    else
                      exercise,
                ],
              )
            else
              existing,
        ],
      );
    });
    return logged;
  }

  /// Replaces one logged set in an active or finished session (`LOG-006`).
  ///
  /// The set keeps its id, row position, and original timestamp; callers edit
  /// the values only.
  Future<SetLog> updateSet({
    required String sessionId,
    required String sessionExerciseId,
    required SetLog set,
  }) async {
    await _mutate((AppData data) {
      final Session session = _requireSession(data, sessionId);
      final SessionExercise exercise = _requireSessionExercise(
        session,
        sessionExerciseId,
      );
      if (!exercise.sets.any((SetLog existing) => existing.id == set.id)) {
        throw StateError('Set ${set.id} does not exist');
      }
      return _replaceSessionExercise(
        data,
        sessionId,
        sessionExerciseId,
        (SessionExercise existing) => existing.copyWith(
          sets: <SetLog>[
            for (final SetLog current in existing.sets)
              if (current.id == set.id) set else current,
          ],
        ),
      );
    });
    return set;
  }

  /// Removes one set and returns the removed value for Undo (`LOG-006`).
  Future<SetLog> deleteSet({
    required String sessionId,
    required String sessionExerciseId,
    required String setId,
  }) async {
    late SetLog removed;
    await _mutate((AppData data) {
      final Session session = _requireSession(data, sessionId);
      final SessionExercise exercise = _requireSessionExercise(
        session,
        sessionExerciseId,
      );
      final int index = exercise.sets.indexWhere(
        (SetLog set) => set.id == setId,
      );
      if (index < 0) {
        throw StateError('Set $setId does not exist');
      }
      removed = exercise.sets[index];
      return _replaceSessionExercise(
        data,
        sessionId,
        sessionExerciseId,
        (SessionExercise existing) => existing.copyWith(
          sets: <SetLog>[
            for (final SetLog set in existing.sets)
              if (set.id != setId) set,
          ],
        ),
      );
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
      (AppData data) => _replaceSessionExercise(
        data,
        sessionId,
        sessionExerciseId,
        (SessionExercise existing) =>
            existing.copyWith(sets: <SetLog>[...existing.sets, set]),
      ),
    );
  }

  /// Deletes a session, everything nested in it, and its private photo files.
  Future<Session> deleteSession(String sessionId) async {
    late Session removed;
    await _mutate((AppData data) {
      final Session session = _requireSession(data, sessionId);
      removed = session;
      return data.copyWith(
        sessions: <Session>[
          for (final Session existing in data.sessions)
            if (existing.id != sessionId) existing,
        ],
      );
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
      (AppData data) => _replaceSession(
        data,
        sessionId,
        (Session s) => s.copyWith(note: note),
      ),
    );
  }

  /// Sets or clears one exercise's note inside a session (`LOG-007`).
  Future<void> setSessionExerciseNote({
    required String sessionId,
    required String sessionExerciseId,
    required String? note,
  }) {
    return _mutate(
      (AppData data) => _replaceSessionExercise(
        data,
        sessionId,
        sessionExerciseId,
        (SessionExercise exercise) => exercise.copyWith(note: note),
      ),
    );
  }

  /// Ends the active session. Logged sets stay in history.
  Future<Session> finishSession(String sessionId) async {
    late Session finished;
    await _mutate((AppData data) {
      final Session? session = data.sessionById(sessionId);
      if (session == null) {
        throw StateError('Session $sessionId does not exist');
      }
      if (!session.isActive) {
        throw StateError('Session $sessionId is already finished');
      }
      final DateTime now = DateTime.now().toUtc();
      finished = session.copyWith(
        endedAt: now.isBefore(session.startedAt) ? session.startedAt : now,
      );
      return data.copyWith(
        sessions: <Session>[
          for (final Session existing in data.sessions)
            if (existing.id == sessionId) finished else existing,
        ],
      );
    });
    return finished;
  }

  String _dayIdForItem(AppData data, String itemId) {
    for (final Program program in data.programs) {
      for (final ProgramDay day in program.days) {
        if (day.items.any((PlanItem item) => item.id == itemId)) {
          return day.id;
        }
      }
    }
    throw StateError('Plan item $itemId does not exist');
  }

  Session _requireSession(AppData data, String sessionId) {
    final Session? session = data.sessionById(sessionId);
    if (session == null) {
      throw StateError('Session $sessionId does not exist');
    }
    return session;
  }

  SessionExercise _requireSessionExercise(
    Session session,
    String sessionExerciseId,
  ) {
    final SessionExercise? exercise = session.exerciseById(sessionExerciseId);
    if (exercise == null) {
      throw StateError('Session exercise $sessionExerciseId does not exist');
    }
    return exercise;
  }

  AppData _replaceSession(
    AppData data,
    String sessionId,
    Session Function(Session session) update,
  ) {
    _requireSession(data, sessionId);
    return data.copyWith(
      sessions: <Session>[
        for (final Session session in data.sessions)
          if (session.id == sessionId) update(session) else session,
      ],
    );
  }

  AppData _replaceSessionExercise(
    AppData data,
    String sessionId,
    String sessionExerciseId,
    SessionExercise Function(SessionExercise exercise) update,
  ) {
    final Session session = _requireSession(data, sessionId);
    _requireSessionExercise(session, sessionExerciseId);
    return _replaceSession(
      data,
      sessionId,
      (Session existing) => existing.copyWith(
        exercises: <SessionExercise>[
          for (final SessionExercise exercise in existing.exercises)
            if (exercise.id == sessionExerciseId)
              update(exercise)
            else
              exercise,
        ],
      ),
    );
  }

  AppData _replaceDay(
    AppData data,
    String dayId,
    ProgramDay Function(ProgramDay day) update,
  ) {
    return data.copyWith(
      programs: <Program>[
        for (final Program program in data.programs)
          program.copyWith(
            days: <ProgramDay>[
              for (final ProgramDay day in program.days)
                if (day.id == dayId) update(day) else day,
            ],
          ),
      ],
    );
  }
}
