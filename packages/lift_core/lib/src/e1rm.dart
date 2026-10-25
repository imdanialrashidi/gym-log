/// Estimated one-rep maximum (e1RM) rules (`INT-003`, ADR-0004).
///
/// The estimate uses the Epley formula `weight × (1 + reps / 30)`. It is an
/// estimate, never a measured maximum, and the display thresholds are fixed:
/// normal for 1–10 reps, a "less reliable" hint for 11–12, and no value above
/// 12. Warm-up exclusion and PR comparison live in `personal_records.dart`.
library;

/// Lowest repetition count with a defined estimate.
const int e1rmMinimumReps = 1;

/// Highest repetition count shown without a reliability hint.
const int e1rmNormalMaxReps = 10;

/// Highest repetition count with any estimate. Above this no e1RM is shown.
const int e1rmLessReliableMaxReps = 12;

/// How much confidence the display should convey for an estimate.
enum E1rmConfidence { normal, lessReliable }

/// A rounded Epley estimate in canonical grams.
class E1rmEstimate {
  const E1rmEstimate({required this.grams, required this.confidence});

  final int grams;
  final E1rmConfidence confidence;

  bool get isLessReliable => confidence == E1rmConfidence.lessReliable;
}

/// Returns the Epley estimate for [weightGrams] at [reps], or `null` when
/// [reps] is outside [e1rmMinimumReps]–[e1rmLessReliableMaxReps].
///
/// The result is rounded half away from zero to the nearest gram so both
/// display units format from the same canonical value.
E1rmEstimate? estimateOneRepMax({required int weightGrams, required int reps}) {
  if (weightGrams < 0) {
    throw ArgumentError.value(weightGrams, 'weightGrams');
  }
  if (reps < e1rmMinimumReps || reps > e1rmLessReliableMaxReps) {
    return null;
  }
  final int numerator = weightGrams * (30 + reps);
  final int grams = (numerator + 15) ~/ 30;
  return E1rmEstimate(
    grams: grams,
    confidence: reps <= e1rmNormalMaxReps
        ? E1rmConfidence.normal
        : E1rmConfidence.lessReliable,
  );
}
