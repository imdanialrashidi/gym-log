import 'dart:math' as math;

import 'rep_range.dart';
import 'session.dart';
import 'session_history.dart';
import 'weight.dart';

/// Which `INT-002` branch produced a suggestion.
enum ProgressionRule {
  /// Rule A: every working set reached the top of the range.
  addWeight,

  /// Rule B: add repetitions at the same weight.
  addReps,

  /// Rule C: rebuild at the bottom of the range.
  hold,
}

/// Structured reason codes; the app layer localizes them (`INT-002`).
///
/// Parameters stay numeric or canonical grams so the UI can format weights in
/// the active display unit and the domain never contains user-facing strings.
sealed class ProgressionReason {
  const ProgressionReason();
}

/// Rule A reason: all counted sets reached the top of the rep range.
final class ProgressionReasonAddWeight extends ProgressionReason {
  const ProgressionReasonAddWeight({
    required this.setCount,
    required this.maxReps,
    required this.incrementGrams,
  });

  final int setCount;
  final int maxReps;
  final int incrementGrams;
}

/// Rule B reason: the weakest set sets the next repetition target.
final class ProgressionReasonAddReps extends ProgressionReason {
  const ProgressionReasonAddReps({
    required this.weakestReps,
    required this.targetReps,
  });

  final int weakestReps;
  final int targetReps;
}

/// Rule C reason: at least one set fell below the range minimum.
final class ProgressionReasonHold extends ProgressionReason {
  const ProgressionReasonHold({required this.minReps});

  final int minReps;
}

/// A double-progression target for the next session (`INT-002`).
///
/// The suggestion only supplies draft values; nothing is auto-applied to a
/// logged set. See ADR-0009 for the prefill-precedence reading.
final class ProgressionSuggestion {
  const ProgressionSuggestion({
    required this.rule,
    required this.weightGrams,
    required this.targetReps,
    required this.reason,
  });

  final ProgressionRule rule;

  /// Canonical grams to prefill. A bodyweight suggestion always keeps `0`.
  final int weightGrams;
  final int targetReps;
  final ProgressionReason reason;
}

/// The last session's working sets for [exerciseId] (`INT-002`).
///
/// Warm-ups are excluded. A latest session with only warm-ups yields an empty
/// list rather than falling back to older history, matching `INT-001`.
List<SetLog> lastWorkingSetsForExercise({
  required List<Session> sessions,
  required String exerciseId,
  String? excludeSessionId,
}) {
  final Session? latest = latestSessionForExercise(
    sessions: sessions,
    exerciseId: exerciseId,
    excludeSessionId: excludeSessionId,
  );
  if (latest == null) {
    return const <SetLog>[];
  }
  return <SetLog>[
    for (final SessionExercise exercise in latest.exercises)
      if (exercise.exerciseId == exerciseId) ...exercise.workingSets,
  ];
}

/// Applies the `INT-002` double-progression rules to one exercise.
///
/// Inputs are the active plan item's target sets and rep range, the exercise's
/// increment in grams (`EXR-007`), and the last session's working sets.
/// Returns `null` for the specified no-suggestion cases (first session, no rep
/// range, no working sets) and for mixed working weights; a mixed-weight
/// history has no unambiguous "same working weight", so this implementation
/// conservatively offers no suggestion instead of guessing (ADR-0009).
/// Without target sets, the weight-increase rule cannot run, but the rep-based
/// rules still can. When Rule A cannot run and the weakest set already reached
/// the top of the range (or the repetition cap for bodyweight), there is no
/// progression left to suggest, so the result is `null` rather than a
/// downgrade.
///
/// Order is Rule A, then the below-minimum hold, then Rule B. The spec lists
/// Rule C after Rule B, but a below-minimum set must not produce an "add reps"
/// target below the range; scenario A5 requires the hold.
///
/// Bodyweight sets (`0` grams) never receive a weight increase. Their
/// progression is reps-only and may target one repetition above the range
/// maximum, because there is no load to add.
ProgressionSuggestion? progressionSuggestion({
  required int? targetSets,
  required int? repMin,
  required int? repMax,
  required int incrementGrams,
  required List<SetLog> lastWorkingSets,
}) {
  if (repMin == null || repMax == null) {
    return null;
  }
  if (targetSets != null && !isValidTargetSets(targetSets)) {
    return null;
  }
  if (validateRepRange(repMin, repMax) != null) {
    return null;
  }
  if (incrementGrams <= 0) {
    return null;
  }

  final List<SetLog> workingSets = <SetLog>[
    for (final SetLog set in lastWorkingSets)
      if (!set.isWarmup) set,
  ];
  if (workingSets.isEmpty) {
    return null;
  }

  final int weightGrams = workingSets.first.weightGrams;
  for (final SetLog set in workingSets) {
    if (set.weightGrams != weightGrams) {
      return null;
    }
  }

  int weakestReps = workingSets.first.reps;
  bool allAtMax = true;
  bool anyBelowMin = false;
  for (final SetLog set in workingSets) {
    weakestReps = math.min(weakestReps, set.reps);
    if (set.reps < repMax) {
      allAtMax = false;
    }
    if (set.reps < repMin) {
      anyBelowMin = true;
    }
  }

  if (anyBelowMin) {
    return ProgressionSuggestion(
      rule: ProgressionRule.hold,
      weightGrams: weightGrams,
      targetReps: repMin,
      reason: ProgressionReasonHold(minReps: repMin),
    );
  }

  if (weightGrams == 0) {
    if (weakestReps >= maximumSetRepetitions) {
      return null;
    }
    return ProgressionSuggestion(
      rule: ProgressionRule.addReps,
      weightGrams: 0,
      targetReps: weakestReps + 1,
      reason: ProgressionReasonAddReps(
        weakestReps: weakestReps,
        targetReps: weakestReps + 1,
      ),
    );
  }

  if (targetSets != null && workingSets.length >= targetSets && allAtMax) {
    final int nextWeightGrams = weightGrams + incrementGrams;
    if (nextWeightGrams > maximumSetWeightGrams) {
      return null;
    }
    return ProgressionSuggestion(
      rule: ProgressionRule.addWeight,
      weightGrams: nextWeightGrams,
      targetReps: repMin,
      reason: ProgressionReasonAddWeight(
        setCount: workingSets.length,
        maxReps: repMax,
        incrementGrams: incrementGrams,
      ),
    );
  }

  // Rule A was unavailable (no target sets or too few sets) and the weakest
  // set already reached the top. There is no rep increase left to suggest.
  if (weakestReps >= repMax) {
    return null;
  }

  final int targetReps = weakestReps + 1;
  return ProgressionSuggestion(
    rule: ProgressionRule.addReps,
    weightGrams: weightGrams,
    targetReps: targetReps,
    reason: ProgressionReasonAddReps(
      weakestReps: weakestReps,
      targetReps: targetReps,
    ),
  );
}
