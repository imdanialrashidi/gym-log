import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

int _gramsForPounds(double pounds) => (pounds * 453.59237).round();

void main() {
  group('plate loadout', () {
    test('solves a symmetric 100 kg load exactly', () {
      final PlateLoadout loadout = solvePlateLoadout(
        targetGrams: 100000,
        unit: WeightUnit.kilograms,
      );
      expect(loadout.isExact, isTrue);
      expect(loadout.actualGrams, 100000);
      expect(loadout.plateCounts, <int, int>{25000: 1, 15000: 1});
      expect(loadout.plateCountPerSide, 2);
    });

    test('uses the smallest plate when the load needs it', () {
      final PlateLoadout loadout = solvePlateLoadout(
        targetGrams: 102500,
        unit: WeightUnit.kilograms,
      );
      expect(loadout.isExact, isTrue);
      expect(loadout.actualGrams, 102500);
      expect(loadout.plateCounts, <int, int>{25000: 1, 15000: 1, 1250: 1});
    });

    test('an empty bar is loadable and lighter targets are flagged', () {
      final PlateLoadout bar = solvePlateLoadout(
        targetGrams: standardKilogramBarGrams,
        unit: WeightUnit.kilograms,
      );
      expect(bar.isExact, isTrue);
      expect(bar.isBelowBar, isFalse);
      expect(bar.platesPerSideGrams, isEmpty);

      final PlateLoadout tooLight = solvePlateLoadout(
        targetGrams: 10000,
        unit: WeightUnit.kilograms,
      );
      expect(tooLight.isBelowBar, isTrue);
      expect(tooLight.isExact, isFalse);
      expect(tooLight.actualGrams, standardKilogramBarGrams);
    });

    test('pound plates stay exact instead of drifting through grams', () {
      final PlateLoadout loadout = solvePlateLoadout(
        targetGrams: _gramsForPounds(135),
        unit: WeightUnit.pounds,
      );
      expect(loadout.isExact, isTrue);
      expect(loadout.plateCounts.keys, contains(20412));
      expect(loadout.actualGrams, closeTo(_gramsForPounds(135), 2));
    });

    test('reports the remainder for an off-increment target', () {
      final PlateLoadout loadout = solvePlateLoadout(
        targetGrams: 22600,
        unit: WeightUnit.kilograms,
      );
      expect(loadout.isExact, isFalse);
      expect(loadout.actualGrams, 22500);
      expect(loadout.remainderGrams, 100);
    });

    test('rejects a negative target', () {
      expect(
        () => solvePlateLoadout(targetGrams: -1, unit: WeightUnit.kilograms),
        throwsArgumentError,
      );
    });
  });

  group('warm-up ramp', () {
    test('starts with the bar then 40/60/80 percent', () {
      final List<WarmupStep> steps = warmupRamp(
        workingGrams: 100000,
        unit: WeightUnit.kilograms,
      );
      expect(steps, hasLength(4));
      expect(steps.first.isBar, isTrue);
      expect(steps.first.reps, 8);
      expect(steps.first.weightGrams, 20000);
      expect(steps[1].weightGrams, 40000);
      expect(steps[1].reps, 5);
      expect(steps[2].weightGrams, 60000);
      expect(steps[2].reps, 3);
      expect(steps[3].weightGrams, 80000);
      expect(steps[3].reps, 1);
      for (final WarmupStep step in steps) {
        expect(step.weightGrams, lessThan(100000));
      }
    });

    test('rounds to a loadable increment and deduplicates the bar', () {
      final List<WarmupStep> steps = warmupRamp(
        workingGrams: 30000,
        unit: WeightUnit.kilograms,
      );
      expect(steps.map((WarmupStep s) => s.weightGrams), <int>[20000, 25000]);
    });

    test('returns no ramp when the working weight is at or below the bar', () {
      expect(
        warmupRamp(
          workingGrams: standardKilogramBarGrams,
          unit: WeightUnit.kilograms,
        ),
        isEmpty,
      );
      expect(
        warmupRamp(workingGrams: 10000, unit: WeightUnit.kilograms),
        isEmpty,
      );
      expect(warmupRamp(workingGrams: 0, unit: WeightUnit.kilograms), isEmpty);
      expect(warmupRamp(workingGrams: 13600, unit: WeightUnit.pounds), isEmpty);
    });

    test('works in pounds with a 45 lb bar', () {
      final List<WarmupStep> steps = warmupRamp(
        workingGrams: _gramsForPounds(225),
        unit: WeightUnit.pounds,
      );
      expect(steps.first.weightGrams, closeTo(_gramsForPounds(45), 2));
      expect(steps.length, greaterThanOrEqualTo(3));
      for (final WarmupStep step in steps) {
        expect(step.weightGrams, lessThan(_gramsForPounds(225)));
      }
    });
  });
}
