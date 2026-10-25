import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

void main() {
  group('Epley estimate', () {
    test('rounds half away from zero at the gram boundary', () {
      expect(estimateOneRepMax(weightGrams: 3, reps: 5)!.grams, 4);
    });

    test('rejects negative weight', () {
      expect(
        () => estimateOneRepMax(weightGrams: -1, reps: 5),
        throwsArgumentError,
      );
    });

    test('table: threshold boundaries at 10, 11, 12, and 13 reps', () {
      final List<({int reps, E1rmConfidence? confidence, int? grams})> cases =
          <({int reps, E1rmConfidence? confidence, int? grams})>[
            (reps: 10, confidence: E1rmConfidence.normal, grams: 133333),
            (reps: 11, confidence: E1rmConfidence.lessReliable, grams: 136667),
            (reps: 12, confidence: E1rmConfidence.lessReliable, grams: 140000),
            (reps: 13, confidence: null, grams: null),
          ];

      for (final ({int reps, E1rmConfidence? confidence, int? grams}) row
          in cases) {
        final E1rmEstimate? estimate = estimateOneRepMax(
          weightGrams: 100000,
          reps: row.reps,
        );
        expect(
          estimate?.confidence,
          row.confidence,
          reason: 'reps ${row.reps}',
        );
        expect(estimate?.grams, row.grams, reason: 'reps ${row.reps}');
      }
    });

    test('table: every supported rep count has the expected confidence', () {
      for (int reps = 1; reps <= 12; reps++) {
        final E1rmEstimate? estimate = estimateOneRepMax(
          weightGrams: 100000,
          reps: reps,
        );
        expect(estimate, isNotNull, reason: 'reps $reps');
        expect(
          estimate!.confidence,
          reps <= e1rmNormalMaxReps
              ? E1rmConfidence.normal
              : E1rmConfidence.lessReliable,
          reason: 'reps $reps',
        );
      }
      expect(estimateOneRepMax(weightGrams: 100000, reps: 0), isNull);
      expect(estimateOneRepMax(weightGrams: 100000, reps: 13), isNull);
    });

    test('table: both display units format the same canonical estimate', () {
      final List<
        ({String input, WeightUnit unit, int weightGrams, String expected})
      >
      cases =
          <({String input, WeightUnit unit, int weightGrams, String expected})>[
            (
              input: '100',
              unit: WeightUnit.kilograms,
              weightGrams: 100000,
              expected: '133.33',
            ),
            (
              input: '225',
              unit: WeightUnit.pounds,
              weightGrams: 102058,
              expected: '300',
            ),
          ];

      for (final row in cases) {
        final WeightParseResult parsed = parseWeightInput(row.input, row.unit);
        expect(parsed.grams, row.weightGrams, reason: row.input);
        final E1rmEstimate estimate = estimateOneRepMax(
          weightGrams: parsed.grams!,
          reps: 10,
        )!;
        expect(estimate.confidence, E1rmConfidence.normal);
        expect(
          formatWeight(estimate.grams, row.unit),
          row.expected,
          reason: '${row.input} ${row.unit.name}',
        );
      }
    });
  });
}
