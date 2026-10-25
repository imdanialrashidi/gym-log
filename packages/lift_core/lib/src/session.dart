import 'json_reader.dart';
import 'rep_range.dart';
import 'weight.dart';

const Object _absent = Object();

/// RIR chips 0–4 plus 5+, represented as 5. `null` means the user left RIR
/// untouched (`LOG-005`); it is never defaulted silently.
const int maximumStoredRir = 5;

/// Plain-text note limit for a session and for each session exercise
/// (`LOG-007`). Longer input is rejected at the model boundary; the editor also
/// shows this limit as its counter.
const int maximumNoteLength = 2000;

/// Trims note whitespace and stores whitespace-only notes as `null`.
String? _normalizeNote(String? note) {
  if (note == null) {
    return null;
  }
  final String trimmed = note.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.length > maximumNoteLength) {
    throw ArgumentError.value(
      note,
      'note',
      'Notes are limited to $maximumNoteLength characters',
    );
  }
  return trimmed;
}

/// One completed set inside an active or finished session (`LOG-001`, `LOG-003`).
class SetLog {
  factory SetLog({
    required String id,
    required int weightGrams,
    required int reps,
    required DateTime loggedAt,
    required int setIndex,
    int? rir,
    bool isWarmup = false,
  }) {
    if (weightGrams < 0 || weightGrams > maximumSetWeightGrams) {
      throw ArgumentError.value(weightGrams, 'weightGrams');
    }
    if (reps < 1 || reps > maximumSetRepetitions) {
      throw ArgumentError.value(reps, 'reps');
    }
    if (rir != null && (rir < 0 || rir > maximumStoredRir)) {
      throw ArgumentError.value(rir, 'rir');
    }
    if (setIndex < 0 || setIndex >= maximumTargetSets) {
      throw ArgumentError.value(setIndex, 'setIndex');
    }
    return SetLog._(
      id: id,
      weightGrams: weightGrams,
      reps: reps,
      rir: rir,
      isWarmup: isWarmup,
      setIndex: setIndex,
      loggedAt: loggedAt.toUtc(),
    );
  }

  const SetLog._({
    required this.id,
    required this.weightGrams,
    required this.reps,
    required this.rir,
    required this.isWarmup,
    required this.setIndex,
    required this.loggedAt,
  });

  final String id;
  final int weightGrams;
  final int reps;
  final int? rir;
  final bool isWarmup;

  /// Zero-based row position inside the session exercise. Stable across
  /// restarts, so logging rows out of order never shifts their values.
  final int setIndex;
  final DateTime loggedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'weightGrams': weightGrams,
    'reps': reps,
    'rir': rir,
    'isWarmup': isWarmup,
    'setIndex': setIndex,
    'loggedAt': loggedAt.toIso8601String(),
  };

  factory SetLog.fromJson(Map<String, Object?> json) {
    return SetLog(
      id: readString(json, 'id'),
      weightGrams: readInt(json, 'weightGrams'),
      reps: readInt(json, 'reps'),
      rir: readOptionalInt(json, 'rir'),
      isWarmup: readBool(json, 'isWarmup'),
      setIndex: readInt(json, 'setIndex'),
      loggedAt: readDateTime(json, 'loggedAt'),
    );
  }
}

/// An exercise inside a session, with a snapshot of the planned targets shown
/// during logging (`LOG-004`, `PLAN-004`).
class SessionExercise {
  factory SessionExercise({
    required String id,
    required String exerciseId,
    required int sortOrder,
    int? targetSets,
    int? repMin,
    int? repMax,
    String? note,
    List<SetLog> sets = const <SetLog>[],
  }) {
    if (sortOrder < 0) {
      throw ArgumentError.value(sortOrder, 'sortOrder');
    }
    if (targetSets != null && !isValidTargetSets(targetSets)) {
      throw ArgumentError.value(targetSets, 'targetSets');
    }
    if ((repMin == null) != (repMax == null)) {
      throw ArgumentError('Rep minimum and maximum must be provided together');
    }
    if (repMin != null && repMax != null) {
      if (validateRepRange(repMin, repMax) != null) {
        throw ArgumentError(
          'Session rep range must satisfy 1 <= min <= max <= 100',
        );
      }
    }
    final Set<String> setIds = <String>{};
    final Set<int> setIndices = <int>{};
    for (final SetLog set in sets) {
      if (!setIds.add(set.id)) {
        throw ArgumentError('Duplicate set id ${set.id}');
      }
      if (!setIndices.add(set.setIndex)) {
        throw ArgumentError('Duplicate set index ${set.setIndex}');
      }
    }
    return SessionExercise._(
      id: id,
      exerciseId: exerciseId,
      sortOrder: sortOrder,
      targetSets: targetSets,
      repMin: repMin,
      repMax: repMax,
      note: _normalizeNote(note),
      sets: List<SetLog>.unmodifiable(
        List<SetLog>.of(sets)
          ..sort((SetLog a, SetLog b) => a.setIndex.compareTo(b.setIndex)),
      ),
    );
  }

  const SessionExercise._({
    required this.id,
    required this.exerciseId,
    required this.sortOrder,
    required this.targetSets,
    required this.repMin,
    required this.repMax,
    required this.note,
    required this.sets,
  });

  final String id;
  final String exerciseId;
  final int sortOrder;
  final int? targetSets;
  final int? repMin;
  final int? repMax;

  /// Plain text, limited to [maximumNoteLength] characters (`LOG-007`).
  final String? note;
  final List<SetLog> sets;

  /// Warm-ups are excluded from prefill and every derived statistic
  /// (`LOG-003`, `INT-001`).
  List<SetLog> get workingSets =>
      List<SetLog>.unmodifiable(sets.where((SetLog set) => !set.isWarmup));

  SessionExercise copyWith({
    int? targetSets,
    int? repMin,
    int? repMax,
    Object? note = _absent,
    List<SetLog>? sets,
  }) {
    return SessionExercise(
      id: id,
      exerciseId: exerciseId,
      sortOrder: sortOrder,
      targetSets: targetSets ?? this.targetSets,
      repMin: repMin ?? this.repMin,
      repMax: repMax ?? this.repMax,
      note: identical(note, _absent) ? this.note : note as String?,
      sets: sets ?? this.sets,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'exerciseId': exerciseId,
    'sortOrder': sortOrder,
    'targetSets': targetSets,
    'repMin': repMin,
    'repMax': repMax,
    'note': note,
    'sets': <Object?>[for (final SetLog set in sets) set.toJson()],
  };

  factory SessionExercise.fromJson(Map<String, Object?> json) {
    return SessionExercise(
      id: readString(json, 'id'),
      exerciseId: readString(json, 'exerciseId'),
      sortOrder: readInt(json, 'sortOrder'),
      targetSets: readOptionalInt(json, 'targetSets'),
      repMin: readOptionalInt(json, 'repMin'),
      repMax: readOptionalInt(json, 'repMax'),
      note: readOptionalString(json, 'note'),
      sets: <SetLog>[
        for (final Object? set in readList(json, 'sets'))
          SetLog.fromJson(readMap(set, 'sets')),
      ],
    );
  }
}

/// A workout session. `endedAt == null` means it is the active session.
///
/// Session exercises and their sets are snapshots: editing a program later
/// never changes logged history (`LOG-009`).
class Session {
  factory Session({
    required String id,
    required DateTime startedAt,
    DateTime? endedAt,
    String? programDayId,
    String? note,
    List<SessionExercise> exercises = const <SessionExercise>[],
  }) {
    final DateTime startedUtc = startedAt.toUtc();
    final DateTime? endedUtc = endedAt?.toUtc();
    if (endedUtc != null && endedUtc.isBefore(startedUtc)) {
      throw ArgumentError('A session cannot end before it starts');
    }
    final Set<String> exerciseIds = <String>{};
    for (final SessionExercise exercise in exercises) {
      if (!exerciseIds.add(exercise.id)) {
        throw ArgumentError('Duplicate session exercise id ${exercise.id}');
      }
    }
    return Session._(
      id: id,
      startedAt: startedUtc,
      endedAt: endedUtc,
      programDayId: programDayId,
      note: _normalizeNote(note),
      exercises: List<SessionExercise>.unmodifiable(
        List<SessionExercise>.of(exercises)..sort(
          (SessionExercise a, SessionExercise b) =>
              a.sortOrder.compareTo(b.sortOrder),
        ),
      ),
    );
  }

  const Session._({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.programDayId,
    required this.note,
    required this.exercises,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? programDayId;

  /// Plain text, limited to [maximumNoteLength] characters (`LOG-007`).
  final String? note;
  final List<SessionExercise> exercises;

  bool get isActive => endedAt == null;

  SessionExercise? exerciseById(String sessionExerciseId) {
    for (final SessionExercise exercise in exercises) {
      if (exercise.id == sessionExerciseId) {
        return exercise;
      }
    }
    return null;
  }

  Session copyWith({
    Object? endedAt = _absent,
    Object? note = _absent,
    List<SessionExercise>? exercises,
  }) {
    return Session(
      id: id,
      startedAt: startedAt,
      endedAt: identical(endedAt, _absent)
          ? this.endedAt
          : endedAt as DateTime?,
      programDayId: programDayId,
      note: identical(note, _absent) ? this.note : note as String?,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'programDayId': programDayId,
    'note': note,
    'exercises': <Object?>[
      for (final SessionExercise exercise in exercises) exercise.toJson(),
    ],
  };

  factory Session.fromJson(Map<String, Object?> json) {
    return Session(
      id: readString(json, 'id'),
      startedAt: readDateTime(json, 'startedAt'),
      endedAt: readOptionalDateTime(json, 'endedAt'),
      programDayId: readOptionalString(json, 'programDayId'),
      note: readOptionalString(json, 'note'),
      exercises: <SessionExercise>[
        for (final Object? exercise in readList(json, 'exercises'))
          SessionExercise.fromJson(readMap(exercise, 'exercises')),
      ],
    );
  }
}
