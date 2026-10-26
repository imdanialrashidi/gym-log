/// Derived training statistics shared by the dashboard, history, and progress.
///
/// Everything here is pure and one-pass: a screen asks for a week or a session
/// and gets every number it needs without rescanning the document per card.
/// Warm-ups are excluded from working-set counts and volume (`LOG-003`);
/// bodyweight sets (`weightGrams == 0`) contribute reps but no volume.
library;

import 'body_weight.dart';
import 'exercise.dart';
import 'session.dart';

/// Stats for one exercise block inside a session.
class SessionExerciseStats {
  const SessionExerciseStats({
    required this.sessionExerciseId,
    required this.exerciseId,
    required this.muscleGroup,
    required this.setCount,
    required this.workingSetCount,
    required this.volumeGrams,
    required this.setSpan,
  });

  final String sessionExerciseId;
  final String exerciseId;
  final MuscleGroup? muscleGroup;

  /// All logged sets, including warm-ups.
  final int setCount;

  /// Sets that are not warm-ups; the number the weekly split counts.
  final int workingSetCount;

  /// Working weight × reps, in gram-reps.
  final int volumeGrams;

  /// Time from the first to the last logged set in this block.
  ///
  /// `null` when no set was logged. A single set yields [Duration.zero]
  /// because the app cannot know how long that set took.
  final Duration? setSpan;
}

/// Stats for one finished (or active) session.
class SessionStats {
  const SessionStats({
    required this.sessionId,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.setCount,
    required this.workingSetCount,
    required this.volumeGrams,
    required this.exercises,
    required this.workingSetsByMuscle,
  });

  final String sessionId;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Wall-clock length of the session; `null` when an active session has no
  /// current clock and no end timestamp.
  final Duration? duration;

  final int setCount;
  final int workingSetCount;
  final int volumeGrams;
  final List<SessionExerciseStats> exercises;

  /// Working sets per muscle group. The `null` key is an exercise without a
  /// muscle group.
  final Map<MuscleGroup?, int> workingSetsByMuscle;

  bool get isFinished => endedAt != null;
}

/// One calendar week of finished training plus its body-weight check-in.
class WeekStats {
  const WeekStats({
    required this.weekStart,
    required this.weekEndExclusive,
    required this.isCurrentWeek,
    required this.sessions,
    required this.duration,
    required this.setCount,
    required this.workingSetCount,
    required this.volumeGrams,
    required this.workingSetsByMuscle,
    required this.bodyWeight,
  });

  /// Local midnight of the week's first day.
  final DateTime weekStart;

  /// Exclusive end boundary: local midnight seven days after [weekStart].
  final DateTime weekEndExclusive;

  final bool isCurrentWeek;

  /// Finished sessions in this week, newest first.
  final List<SessionStats> sessions;

  final Duration duration;
  final int setCount;
  final int workingSetCount;
  final int volumeGrams;
  final Map<MuscleGroup?, int> workingSetsByMuscle;

  /// The latest check-in in the week (with its weekly change), if any.
  final BodyWeightWeek? bodyWeight;

  int get sessionCount => sessions.length;

  bool get hasTraining => sessions.isNotEmpty;
}

/// Computes the stats for [session] with a one-time exercise lookup.
SessionStats sessionStatsFor(
  Session session, {
  required List<Exercise> exercises,
  DateTime? now,
}) {
  final Map<String, Exercise> byId = <String, Exercise>{
    for (final Exercise exercise in exercises) exercise.id: exercise,
  };
  return _sessionStats(session, byId, now);
}

/// Same as [sessionStatsFor] but reuses an exercise lookup.
///
/// History builds one map for the whole list instead of rebuilding it per
/// visible session.
SessionStats sessionStatsUsingMap(
  Session session, {
  required Map<String, Exercise> exerciseById,
  DateTime? now,
}) {
  return _sessionStats(session, exerciseById, now);
}

/// Latest finished session with its stats, for the dashboard.
SessionStats? latestFinishedSessionStats(
  List<Session> sessions, {
  required List<Exercise> exercises,
  DateTime? now,
}) {
  final Map<String, Exercise> byId = <String, Exercise>{
    for (final Exercise exercise in exercises) exercise.id: exercise,
  };
  Session? latest;
  for (final Session session in sessions) {
    if (session.isActive) {
      continue;
    }
    if (latest == null || session.startedAt.isAfter(latest.startedAt)) {
      latest = session;
    }
  }
  return latest == null ? null : _sessionStats(latest, byId, now);
}

/// The last [weeks] weeks, oldest first, ending with the week containing
/// [now].
///
/// Empty weeks are kept so the weekly chart and list show real gaps. Only
/// finished sessions count; the active session is already visible elsewhere.
List<WeekStats> recentWeekStats({
  required List<Session> sessions,
  required List<Exercise> exercises,
  required List<BodyWeightEntry> bodyWeights,
  required DateTime now,
  int weekStartsOn = defaultWeekStartsOn,
  int weeks = 8,
}) {
  if (weeks < 1) {
    throw ArgumentError.value(weeks, 'weeks');
  }
  final DateTime currentWeek = startOfWeek(now, weekStartsOn);
  final DateTime oldestWeek = DateTime(
    currentWeek.year,
    currentWeek.month,
    currentWeek.day - (weeks - 1) * 7,
  );
  final Map<DateTime, List<Session>> sessionsByWeek = <DateTime, List<Session>>{
    for (int index = weeks - 1; index >= 0; index -= 1)
      DateTime(
        currentWeek.year,
        currentWeek.month,
        currentWeek.day - index * 7,
      ): <Session>[],
  };
  for (final Session session in sessions) {
    if (session.isActive) {
      continue;
    }
    // Cheap cutoff first: a years-long history must not pay calendar
    // arithmetic for sessions outside the requested window.
    final DateTime local = session.startedAt.toLocal();
    if (local.isBefore(oldestWeek)) {
      continue;
    }
    final int offset = (local.weekday - weekStartsOn + 7) % 7;
    final DateTime week = DateTime(local.year, local.month, local.day - offset);
    sessionsByWeek[week]?.add(session);
  }

  final Map<String, Exercise> exerciseById = <String, Exercise>{
    for (final Exercise exercise in exercises) exercise.id: exercise,
  };
  final List<BodyWeightWeek> weights = weeklyBodyWeight(
    entries: bodyWeights,
    now: now,
    weekStartsOn: weekStartsOn,
    weeks: weeks,
  );
  final Map<DateTime, BodyWeightWeek> weightByWeek = <DateTime, BodyWeightWeek>{
    for (final BodyWeightWeek week in weights) week.weekStart: week,
  };

  final List<WeekStats> result = <WeekStats>[];
  for (final MapEntry<DateTime, List<Session>> entry
      in sessionsByWeek.entries) {
    final List<Session> weekSessions = entry.value
      ..sort((Session a, Session b) => b.startedAt.compareTo(a.startedAt));
    final List<SessionStats> stats = <SessionStats>[];
    final Map<MuscleGroup?, int> muscleSets = <MuscleGroup?, int>{};
    Duration duration = Duration.zero;
    int setCount = 0;
    int workingSets = 0;
    int volume = 0;
    for (final Session session in weekSessions) {
      final SessionStats sessionStat = _sessionStats(
        session,
        exerciseById,
        now,
      );
      stats.add(sessionStat);
      duration += sessionStat.duration ?? Duration.zero;
      setCount += sessionStat.setCount;
      workingSets += sessionStat.workingSetCount;
      volume += sessionStat.volumeGrams;
      for (final MapEntry<MuscleGroup?, int> muscle
          in sessionStat.workingSetsByMuscle.entries) {
        muscleSets.update(
          muscle.key,
          (int current) => current + muscle.value,
          ifAbsent: () => muscle.value,
        );
      }
    }
    result.add(
      WeekStats(
        weekStart: entry.key,
        weekEndExclusive: DateTime(
          entry.key.year,
          entry.key.month,
          entry.key.day + 7,
        ),
        isCurrentWeek: entry.key == currentWeek,
        sessions: List<SessionStats>.unmodifiable(stats),
        duration: duration,
        setCount: setCount,
        workingSetCount: workingSets,
        volumeGrams: volume,
        workingSetsByMuscle: Map<MuscleGroup?, int>.unmodifiable(muscleSets),
        bodyWeight: weightByWeek[entry.key],
      ),
    );
  }
  return List<WeekStats>.unmodifiable(result);
}

/// Total time, sets, and volume for one exercise across finished sessions.
class ExerciseTrainingStats {
  const ExerciseTrainingStats({
    required this.sessionCount,
    required this.spanSessionCount,
    required this.workingSetCount,
    required this.volumeGrams,
    required this.totalSpan,
    required this.lastTrainedAt,
  });

  final int sessionCount;

  /// Sessions whose first-to-last-set span was actually measurable.
  final int spanSessionCount;

  final int workingSetCount;
  final int volumeGrams;

  /// Sum of first-to-last-set spans across the exercise's session blocks.
  final Duration totalSpan;

  final DateTime? lastTrainedAt;

  /// Average block time over sessions with a measurable span.
  ///
  /// A one-set session has no measurable in-exercise time, so it is excluded
  /// from the divisor rather than dragging the average to zero.
  Duration? get averageSpan => spanSessionCount == 0
      ? null
      : Duration(microseconds: totalSpan.inMicroseconds ~/ spanSessionCount);
}

/// Aggregates one exercise in a single pass over [sessions].
ExerciseTrainingStats exerciseTrainingStats({
  required List<Session> sessions,
  required String exerciseId,
}) {
  return exerciseTrainingStatsMap(
    sessions: sessions,
    exerciseIds: <String>[exerciseId],
  )[exerciseId]!;
}

/// Aggregates several exercises in ONE pass over [sessions].
///
/// The progress overview needs a total time and set count per exercise; doing
/// that per card would rescan the whole document once per exercise.
/// Wanted IDs without data are present with zero values.
Map<String, ExerciseTrainingStats> exerciseTrainingStatsMap({
  required List<Session> sessions,
  required Iterable<String> exerciseIds,
}) {
  final Map<String, _ExerciseTotals> totals = <String, _ExerciseTotals>{
    for (final String id in exerciseIds) id: _ExerciseTotals(),
  };
  for (final Session session in sessions) {
    if (session.isActive) {
      continue;
    }
    final Set<String> touched = <String>{};
    for (final SessionExercise exercise in session.exercises) {
      final _ExerciseTotals? entry = totals[exercise.exerciseId];
      if (entry == null || exercise.sets.isEmpty) {
        continue;
      }
      for (final SetLog set in exercise.sets) {
        if (!set.isWarmup) {
          entry.workingSetCount += 1;
          entry.volumeGrams += set.weightGrams * set.reps;
        }
      }
      final Duration? blockSpan = _setSpan(exercise.sets);
      if (blockSpan != null && blockSpan > Duration.zero) {
        entry.totalSpan += blockSpan;
        entry.spanSessionCount += 1;
      }
      touched.add(exercise.exerciseId);
    }
    for (final String id in touched) {
      final _ExerciseTotals entry = totals[id]!;
      entry.sessionCount += 1;
      if (entry.lastTrainedAt == null ||
          session.startedAt.isAfter(entry.lastTrainedAt!)) {
        entry.lastTrainedAt = session.startedAt;
      }
    }
  }
  return <String, ExerciseTrainingStats>{
    for (final MapEntry<String, _ExerciseTotals> entry in totals.entries)
      entry.key: ExerciseTrainingStats(
        sessionCount: entry.value.sessionCount,
        spanSessionCount: entry.value.spanSessionCount,
        workingSetCount: entry.value.workingSetCount,
        volumeGrams: entry.value.volumeGrams,
        totalSpan: entry.value.totalSpan,
        lastTrainedAt: entry.value.lastTrainedAt,
      ),
  };
}

class _ExerciseTotals {
  int sessionCount = 0;
  int spanSessionCount = 0;
  int workingSetCount = 0;
  int volumeGrams = 0;
  Duration totalSpan = Duration.zero;
  DateTime? lastTrainedAt;
}

SessionStats _sessionStats(
  Session session,
  Map<String, Exercise> exerciseById,
  DateTime? now,
) {
  final DateTime? endedAt = session.endedAt;
  final Duration? duration;
  if (endedAt != null) {
    duration = _positive(endedAt.difference(session.startedAt));
  } else if (now != null) {
    duration = _positive(now.difference(session.startedAt));
  } else {
    duration = null;
  }

  final List<SessionExerciseStats> exercises = <SessionExerciseStats>[];
  final Map<MuscleGroup?, int> muscleSets = <MuscleGroup?, int>{};
  int setCount = 0;
  int workingSets = 0;
  int volume = 0;
  for (final SessionExercise exercise in session.exercises) {
    final List<SetLog> sets = exercise.sets;
    int blockWorking = 0;
    int blockVolume = 0;
    for (final SetLog set in sets) {
      if (set.isWarmup) {
        continue;
      }
      blockWorking += 1;
      blockVolume += set.weightGrams * set.reps;
    }
    final Duration? span = _setSpan(sets);
    final MuscleGroup? muscle = exerciseById[exercise.exerciseId]?.muscleGroup;
    exercises.add(
      SessionExerciseStats(
        sessionExerciseId: exercise.id,
        exerciseId: exercise.exerciseId,
        muscleGroup: muscle,
        setCount: sets.length,
        workingSetCount: blockWorking,
        volumeGrams: blockVolume,
        setSpan: span,
      ),
    );
    setCount += sets.length;
    workingSets += blockWorking;
    volume += blockVolume;
    if (blockWorking > 0) {
      muscleSets.update(
        muscle,
        (int current) => current + blockWorking,
        ifAbsent: () => blockWorking,
      );
    }
  }

  return SessionStats(
    sessionId: session.id,
    startedAt: session.startedAt,
    endedAt: endedAt,
    duration: duration,
    setCount: setCount,
    workingSetCount: workingSets,
    volumeGrams: volume,
    exercises: List<SessionExerciseStats>.unmodifiable(exercises),
    workingSetsByMuscle: Map<MuscleGroup?, int>.unmodifiable(muscleSets),
  );
}

Duration _positive(Duration value) => value.isNegative ? Duration.zero : value;

/// First-to-last *logged* span, independent of row order.
Duration? _setSpan(List<SetLog> sets) {
  if (sets.isEmpty) {
    return null;
  }
  DateTime first = sets.first.loggedAt;
  DateTime last = sets.first.loggedAt;
  for (final SetLog set in sets) {
    if (set.loggedAt.isBefore(first)) {
      first = set.loggedAt;
    }
    if (set.loggedAt.isAfter(last)) {
      last = set.loggedAt;
    }
  }
  return _positive(last.difference(first));
}
