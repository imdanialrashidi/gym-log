/// Chart data preparation for per-exercise progress (`PRG-001`–`PRG-003`,
/// `PRG-005`).
///
/// Each finished session contributes its best working set: highest weight,
/// then most reps, with earlier and lower-index sets winning remaining ties.
/// Warm-ups never contribute. Missing RIR and e1RM values are represented as
/// `null` points so charts draw gaps instead of zeros.
library;

import 'e1rm.dart';
import 'session.dart';

/// Selectable chart range (`PRG-005`).
enum ProgressRange { fourWeeks, twelveWeeks, oneYear, all }

/// Fixed day windows for the range filter. A year is 365 days, not a calendar
/// year, so filtering is deterministic across leap years.
const int fourWeeksProgressDays = 28;
const int twelveWeeksProgressDays = 84;
const int oneYearProgressDays = 365;

/// One date/value pair. A `null` [value] is a gap.
class ProgressPoint {
  const ProgressPoint({required this.date, required this.value});

  final DateTime date;
  final double? value;
}

/// Prepared series for one exercise and one range.
class ExerciseProgress {
  const ExerciseProgress({
    required this.hasHistory,
    required this.sessionCount,
    required this.bestWeightSeries,
    required this.estimatedOneRepMaxSeries,
    required this.repsSeries,
    required this.rirSeries,
    required this.bestWeightGrams,
    required this.bestOneRepMaxGrams,
    required this.bestOneRepMaxConfidence,
  });

  /// Whether the exercise has any finished session with a working set,
  /// regardless of the selected range.
  final bool hasHistory;

  /// Number of finished sessions in the selected range.
  final int sessionCount;

  /// Best working-set weight per session, in grams.
  final List<ProgressPoint> bestWeightSeries;

  /// Highest e1RM of the best set per session, in grams. Points are `null`
  /// when the best set has more than [e1rmLessReliableMaxReps] reps.
  final List<ProgressPoint> estimatedOneRepMaxSeries;

  /// Reps of the best working set per session.
  final List<ProgressPoint> repsSeries;

  /// RIR of the best working set per session; `null` when it was not logged.
  final List<ProgressPoint> rirSeries;

  /// Highest best-set weight in the selected range, in grams.
  final double? bestWeightGrams;

  /// Highest estimated one-rep maximum in the selected range, in grams.
  final double? bestOneRepMaxGrams;

  /// Confidence of the best e1RM; `null` when no supported rep count exists.
  final E1rmConfidence? bestOneRepMaxConfidence;

  bool get bestOneRepMaxLessReliable =>
      bestOneRepMaxConfidence == E1rmConfidence.lessReliable;

  bool get hasData => sessionCount > 0;
}

/// Builds the progress series for [exerciseId] using sessions whose start is
/// within [range] of [now].
///
/// Active sessions are excluded, matching history: progress describes finished
/// training. Points are ordered oldest to newest so charts can draw time from
/// left to right without depending on text direction.
ExerciseProgress prepareExerciseProgress({
  required List<Session> sessions,
  required String exerciseId,
  required DateTime now,
  ProgressRange range = ProgressRange.all,
}) {
  final DateTime? cutoff = _cutoff(range, now);
  final List<_SessionBest> bestSets = <_SessionBest>[];
  bool hasHistory = false;

  for (final Session session in sessions) {
    if (session.isActive) {
      continue;
    }
    final List<SetLog> workingSets = <SetLog>[];
    for (final SessionExercise exercise in session.exercises) {
      if (exercise.exerciseId == exerciseId) {
        workingSets.addAll(exercise.workingSets);
      }
    }
    if (workingSets.isEmpty) {
      continue;
    }
    hasHistory = true;
    if (cutoff != null && session.startedAt.isBefore(cutoff)) {
      continue;
    }
    workingSets.sort(_compareBestSets);
    bestSets.add(_SessionBest(session: session, bestSet: workingSets.first));
  }

  bestSets.sort((_SessionBest a, _SessionBest b) {
    final int result = a.session.startedAt.compareTo(b.session.startedAt);
    if (result != 0) {
      return result;
    }
    return a.session.id.compareTo(b.session.id);
  });

  final List<ProgressPoint> bestWeights = <ProgressPoint>[];
  final List<ProgressPoint> estimatedOneRepMaxes = <ProgressPoint>[];
  final List<ProgressPoint> reps = <ProgressPoint>[];
  final List<ProgressPoint> rirs = <ProgressPoint>[];
  double? bestWeight;
  double? bestOneRepMax;
  E1rmConfidence? bestOneRepMaxConfidence;

  for (final _SessionBest entry in bestSets) {
    final SetLog set = entry.bestSet;
    final DateTime date = entry.session.startedAt;
    final E1rmEstimate? estimate = estimateOneRepMax(
      weightGrams: set.weightGrams,
      reps: set.reps,
    );
    final double weight = set.weightGrams.toDouble();
    final double? oneRepMax = estimate?.grams.toDouble();

    bestWeights.add(ProgressPoint(date: date, value: weight));
    estimatedOneRepMaxes.add(ProgressPoint(date: date, value: oneRepMax));
    reps.add(ProgressPoint(date: date, value: set.reps.toDouble()));
    rirs.add(ProgressPoint(date: date, value: set.rir?.toDouble()));

    if (bestWeight == null || weight > bestWeight) {
      bestWeight = weight;
    }
    if (oneRepMax != null &&
        (bestOneRepMax == null || oneRepMax > bestOneRepMax)) {
      bestOneRepMax = oneRepMax;
      bestOneRepMaxConfidence = estimate!.confidence;
    }
  }

  return ExerciseProgress(
    hasHistory: hasHistory,
    sessionCount: bestSets.length,
    bestWeightSeries: List<ProgressPoint>.unmodifiable(bestWeights),
    estimatedOneRepMaxSeries: List<ProgressPoint>.unmodifiable(
      estimatedOneRepMaxes,
    ),
    repsSeries: List<ProgressPoint>.unmodifiable(reps),
    rirSeries: List<ProgressPoint>.unmodifiable(rirs),
    bestWeightGrams: bestWeight,
    bestOneRepMaxGrams: bestOneRepMax,
    bestOneRepMaxConfidence: bestOneRepMaxConfidence,
  );
}

class _SessionBest {
  const _SessionBest({required this.session, required this.bestSet});

  final Session session;
  final SetLog bestSet;
}

int _compareBestSets(SetLog a, SetLog b) {
  int result = b.weightGrams.compareTo(a.weightGrams);
  if (result != 0) {
    return result;
  }
  result = b.reps.compareTo(a.reps);
  if (result != 0) {
    return result;
  }
  result = a.loggedAt.compareTo(b.loggedAt);
  if (result != 0) {
    return result;
  }
  result = a.setIndex.compareTo(b.setIndex);
  if (result != 0) {
    return result;
  }
  return a.id.compareTo(b.id);
}

DateTime? _cutoff(ProgressRange range, DateTime now) {
  final int? days = switch (range) {
    ProgressRange.fourWeeks => fourWeeksProgressDays,
    ProgressRange.twelveWeeks => twelveWeeksProgressDays,
    ProgressRange.oneYear => oneYearProgressDays,
    ProgressRange.all => null,
  };
  if (days == null) {
    return null;
  }
  return now.toUtc().subtract(Duration(days: days));
}
