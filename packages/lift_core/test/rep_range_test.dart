import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

void main() {
  group('validateRepRange', () {
    final List<({int min, int max, RepRangeProblem? expected})> cases =
        <({int min, int max, RepRangeProblem? expected})>[
          (min: 1, max: 1, expected: null),
          (min: 1, max: 100, expected: null),
          (min: 8, max: 12, expected: null),
          (min: 0, max: 10, expected: RepRangeProblem.minBelowMinimum),
          (min: -1, max: 10, expected: RepRangeProblem.minBelowMinimum),
          (min: 10, max: 0, expected: RepRangeProblem.maxBelowMinimum),
          (min: 1, max: 101, expected: RepRangeProblem.maxAboveMaximum),
          (min: 10, max: 9, expected: RepRangeProblem.minGreaterThanMax),
        ];

    for (final ({int min, int max, RepRangeProblem? expected}) testCase
        in cases) {
      test('${testCase.min}..${testCase.max}', () {
        expect(validateRepRange(testCase.min, testCase.max), testCase.expected);
      });
    }
  });

  group('PlanItem', () {
    PlanItem item(int min, int max) => PlanItem(
      id: 'item',
      exerciseId: 'exercise',
      targetSets: 3,
      repMin: min,
      repMax: max,
      sortOrder: 0,
    );

    test('accepts boundary ranges', () {
      expect(item(1, 1).repMin, 1);
      expect(item(1, 100).repMax, 100);
    });

    test('rejects invalid ranges at construction', () {
      expect(() => item(0, 10), throwsArgumentError);
      expect(() => item(1, 101), throwsArgumentError);
      expect(() => item(10, 9), throwsArgumentError);
    });

    test('rejects non-positive target sets', () {
      expect(
        () => PlanItem(
          id: 'item',
          exerciseId: 'exercise',
          targetSets: 0,
          repMin: 8,
          repMax: 12,
          sortOrder: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('defaultIncrementGrams', () {
    test('2.5 kg and 5 lb are stored in grams', () {
      expect(defaultIncrementGrams(WeightUnit.kilograms), 2500);
      expect(defaultIncrementGrams(WeightUnit.pounds), 2268);
    });
  });
}
