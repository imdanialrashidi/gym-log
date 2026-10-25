/// Rep-range limits for exercises and plan items (`PLAN-002`).
library;

const int minimumReps = 1;
const int maximumReps = 100;

/// The first rule a rep range violates, in validation order.
enum RepRangeProblem {
  /// Minimum is below one repetition.
  minBelowMinimum,

  /// Maximum is below one repetition.
  maxBelowMinimum,

  /// Maximum is above 100 repetitions.
  maxAboveMaximum,

  /// Minimum is greater than maximum.
  minGreaterThanMax,
}

/// Validates `1 <= min <= max <= 100`.
///
/// Returns `null` for a valid range.
RepRangeProblem? validateRepRange(int min, int max) {
  if (min < minimumReps) {
    return RepRangeProblem.minBelowMinimum;
  }
  if (max < minimumReps) {
    return RepRangeProblem.maxBelowMinimum;
  }
  if (max > maximumReps) {
    return RepRangeProblem.maxAboveMaximum;
  }
  if (min > max) {
    return RepRangeProblem.minGreaterThanMax;
  }
  return null;
}

/// Validates a plan item's target set count. The UI narrows this to 1..20.
const int minimumTargetSets = 1;
const int maximumTargetSets = 100;

bool isValidTargetSets(int sets) =>
    sets >= minimumTargetSets && sets <= maximumTargetSets;
