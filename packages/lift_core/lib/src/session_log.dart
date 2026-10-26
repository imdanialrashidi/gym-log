import 'app_data.dart';
import 'exercise.dart';
import 'personal_records.dart';
import 'program.dart';
import 'session.dart';
import 'set_entry.dart';

/// Creates a new entity id inside an edit. Tests pass a counter; the app passes
/// UUIDs.
typedef IdFactory = String Function();

/// A committed set together with the personal records it earned.
///
/// The record set is derived from the document that already contains the set,
/// so a caller never has to re-read the document to render badges (`INT-003`).
class LoggedSet {
  const LoggedSet({
    required this.set,
    this.personalRecords = const <PersonalRecordType>{},
  });

  final SetLog set;
  final Set<PersonalRecordType> personalRecords;
}

/// Starts an empty session, or snapshots [programDayId]'s planned exercises.
({AppData data, Session session}) startSession(
  AppData data, {
  required String id,
  required DateTime startedAt,
  required IdFactory nextExerciseId,
  String? programDayId,
}) {
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
          id: nextExerciseId(),
          exerciseId: item.exerciseId,
          sortOrder: exercises.length,
          targetSets: item.targetSets,
          repMin: item.repMin,
          repMax: item.repMax,
        ),
      );
    }
  }
  final Session session = Session(
    id: id,
    startedAt: startedAt,
    programDayId: programDayId,
    exercises: exercises,
  );
  return (
    data: data.copyWith(sessions: <Session>[...data.sessions, session]),
    session: session,
  );
}

/// Adds an exercise to the active session with the exercise's default targets.
({AppData data, SessionExercise sessionExercise}) addExerciseToSession(
  AppData data, {
  required String id,
  required String sessionId,
  required String exerciseId,
}) {
  final Session session = _requireSession(data, sessionId);
  if (!session.isActive) {
    throw StateError('Session $sessionId is finished');
  }
  final Exercise? exercise = data.exerciseById(exerciseId);
  if (exercise == null) {
    throw StateError('Exercise $exerciseId does not exist');
  }
  final SessionExercise sessionExercise = SessionExercise(
    id: id,
    exerciseId: exerciseId,
    sortOrder: session.exercises.length,
    repMin: exercise.defaultRepMin,
    repMax: exercise.defaultRepMax,
  );
  return (
    data: _replaceSession(
      data,
      sessionId,
      (Session existing) => existing.copyWith(
        exercises: <SessionExercise>[...existing.exercises, sessionExercise],
      ),
    ),
    sessionExercise: sessionExercise,
  );
}

/// Commits one set immediately and derives its PR badges from the new document
/// (`LOG-001`, `INT-003`).
({AppData data, LoggedSet loggedSet}) logSet(
  AppData data, {
  required String id,
  required String sessionId,
  required String sessionExerciseId,
  required int setIndex,
  required SetEntry entry,
  required DateTime loggedAt,
}) {
  final Session session = _requireSession(data, sessionId);
  if (!session.isActive) {
    throw StateError('Session $sessionId is finished');
  }
  final SessionExercise sessionExercise = _requireSessionExercise(
    session,
    sessionExerciseId,
  );
  if (sessionExercise.sets.any((SetLog set) => set.setIndex == setIndex)) {
    throw StateError('Set index $setIndex is already logged');
  }
  final SetLog logged = entry.toSetLog(
    id: id,
    setIndex: setIndex,
    loggedAt: loggedAt,
  );
  final AppData next = _replaceSessionExercise(
    data,
    sessionId,
    sessionExerciseId,
    (SessionExercise existing) =>
        existing.copyWith(sets: <SetLog>[...existing.sets, logged]),
  );
  return (
    data: next,
    loggedSet: LoggedSet(
      set: logged,
      personalRecords: personalRecordTypesForSet(
        sessions: next.sessions,
        exerciseId: sessionExercise.exerciseId,
        setId: logged.id,
      ),
    ),
  );
}

/// Edits the values of one logged set, in an active or finished session
/// (`LOG-006`). The set keeps its id, position, and original timestamp.
AppData updateSet(
  AppData data, {
  required String sessionId,
  required String sessionExerciseId,
  required String setId,
  required SetEntry entry,
}) {
  final SessionExercise exercise = _requireSessionExercise(
    _requireSession(data, sessionId),
    sessionExerciseId,
  );
  final int index = exercise.sets.indexWhere((SetLog set) => set.id == setId);
  if (index < 0) {
    throw StateError('Set $setId does not exist');
  }
  final SetLog updated = entry.applyTo(exercise.sets[index]);
  return _replaceSessionExercise(
    data,
    sessionId,
    sessionExerciseId,
    (SessionExercise existing) => existing.copyWith(
      sets: <SetLog>[
        for (final SetLog set in existing.sets)
          if (set.id == setId) updated else set,
      ],
    ),
  );
}

/// Removes one set and returns it for Undo (`LOG-006`).
({AppData data, SetLog set}) deleteSet(
  AppData data, {
  required String sessionId,
  required String sessionExerciseId,
  required String setId,
}) {
  final SessionExercise exercise = _requireSessionExercise(
    _requireSession(data, sessionId),
    sessionExerciseId,
  );
  final int index = exercise.sets.indexWhere((SetLog set) => set.id == setId);
  if (index < 0) {
    throw StateError('Set $setId does not exist');
  }
  final SetLog removed = exercise.sets[index];
  return (
    data: _replaceSessionExercise(
      data,
      sessionId,
      sessionExerciseId,
      (SessionExercise existing) => existing.copyWith(
        sets: <SetLog>[
          for (final SetLog set in existing.sets)
            if (set.id != setId) set,
        ],
      ),
    ),
    set: removed,
  );
}

/// Restores a set removed by [deleteSet] without changing its data.
AppData restoreSet(
  AppData data, {
  required String sessionId,
  required String sessionExerciseId,
  required SetLog set,
}) {
  _requireSessionExercise(_requireSession(data, sessionId), sessionExerciseId);
  return _replaceSessionExercise(
    data,
    sessionId,
    sessionExerciseId,
    (SessionExercise existing) =>
        existing.copyWith(sets: <SetLog>[...existing.sets, set]),
  );
}

/// Deletes a session and everything nested in it.
({AppData data, Session session}) deleteSession(
  AppData data, {
  required String sessionId,
}) {
  final Session session = _requireSession(data, sessionId);
  return (
    data: data.copyWith(
      sessions: <Session>[
        for (final Session existing in data.sessions)
          if (existing.id != sessionId) existing,
      ],
    ),
    session: session,
  );
}

/// Sets or clears the session note (`LOG-007`).
AppData setSessionNote(AppData data, String sessionId, String? note) {
  return _replaceSession(
    data,
    sessionId,
    (Session session) => session.copyWith(note: note),
  );
}

/// Sets or clears one exercise's note inside a session (`LOG-007`).
AppData setSessionExerciseNote(
  AppData data, {
  required String sessionId,
  required String sessionExerciseId,
  required String? note,
}) {
  return _replaceSessionExercise(
    data,
    sessionId,
    sessionExerciseId,
    (SessionExercise exercise) => exercise.copyWith(note: note),
  );
}

/// Ends the active session. Logged sets stay in history.
({AppData data, Session session}) finishSession(
  AppData data, {
  required String sessionId,
  required DateTime endedAt,
}) {
  final Session session = _requireSession(data, sessionId);
  if (!session.isActive) {
    throw StateError('Session $sessionId is already finished');
  }
  final Session finished = session.copyWith(
    endedAt: endedAt.isBefore(session.startedAt)
        ? session.startedAt
        : endedAt.toUtc(),
  );
  return (
    data: data.copyWith(
      sessions: <Session>[
        for (final Session existing in data.sessions)
          if (existing.id == sessionId) finished else existing,
      ],
    ),
    session: finished,
  );
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
          if (exercise.id == sessionExerciseId) update(exercise) else exercise,
      ],
    ),
  );
}
