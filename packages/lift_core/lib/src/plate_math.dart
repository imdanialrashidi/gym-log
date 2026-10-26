/// Barbell plate math and a warm-up ramp (`PLATE-001`).
///
/// The app stores weights in canonical grams, but plate increments are defined
/// in the display unit. Arithmetic therefore happens in hundredths of the
/// display unit (centi-units) and only the final result is converted back to
/// grams, so 135 lb is exactly one 45 lb plate per side rather than a value
/// distorted by gram conversion.
library;

import 'weight.dart';

/// Bar and plate sets assumed by the in-app calculator.
///
/// This is the common commercial-gym set; the sheet states the assumption so a
/// lifter with calibrated plates knows what was used.
const int standardKilogramBarGrams = 20000;
const int standardPoundBarGrams = 20412; // 45 lb, rounded to grams.
const int standardKilogramPlateIncrementGrams = 2500;
const int standardPoundPlateIncrementGrams = 2250; // 5 lb per side.

const List<int> _kilogramPlateCenti = <int>[
  2500, // 25 kg
  2000, // 20 kg
  1500, // 15 kg
  1000, // 10 kg
  500, // 5 kg
  250, // 2.5 kg
  125, // 1.25 kg
];

const List<int> _poundPlateCenti = <int>[
  4500, // 45 lb
  3500, // 35 lb
  2500, // 25 lb
  1000, // 10 lb
  500, // 5 lb
  250, // 2.5 lb
];

/// One solved barbell load.
class PlateLoadout {
  const PlateLoadout({
    required this.targetGrams,
    required this.barGrams,
    required this.platesPerSideGrams,
    required this.actualGrams,
    required this.remainderGrams,
    required this.isBelowBar,
  });

  final int targetGrams;
  final int barGrams;

  /// Descending plate weights on one side, in canonical grams.
  final List<int> platesPerSideGrams;

  /// The closest weight the standard set can load.
  final int actualGrams;

  /// How far [actualGrams] falls short of [targetGrams], in grams.
  final int remainderGrams;

  /// True when the requested weight is lighter than the empty bar.
  final bool isBelowBar;

  bool get isExact => !isBelowBar && remainderGrams == 0;

  int get plateCountPerSide => platesPerSideGrams.length;

  /// Plate counts keyed by canonical plate gram weight, descending.
  Map<int, int> get plateCounts {
    final Map<int, int> counts = <int, int>{};
    for (final int plate in platesPerSideGrams) {
      counts.update(plate, (int value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}

/// A single ramp step. [fraction] is zero for the empty bar.
class WarmupStep {
  const WarmupStep({
    required this.fraction,
    required this.reps,
    required this.loadout,
  });

  final double fraction;
  final int reps;
  final PlateLoadout loadout;

  bool get isBar => fraction == 0;
  int get weightGrams => loadout.actualGrams;
}

double _gramsPerUnit(WeightUnit unit) => switch (unit) {
  WeightUnit.kilograms => 1000,
  WeightUnit.pounds => 453.59237,
};

int _toCenti(int grams, WeightUnit unit) =>
    (grams / _gramsPerUnit(unit) * 100).round();

int _fromCenti(int centi, WeightUnit unit) =>
    (centi * _gramsPerUnit(unit) / 100).round();

int _barCenti(WeightUnit unit) => _toCenti(
  unit == WeightUnit.kilograms
      ? standardKilogramBarGrams
      : standardPoundBarGrams,
  unit,
);

List<int> _platesFor(WeightUnit unit) =>
    unit == WeightUnit.kilograms ? _kilogramPlateCenti : _poundPlateCenti;

/// Solves the closest symmetric plate load for [targetGrams].
///
/// Greedy descending selection is exact for the standard plates, which are
/// canonical multiples of the smallest plate. If a caller supplies an
/// off-increment target (for example a calibrated 101.7 kg), the result is the
/// nearest lighter load and [PlateLoadout.remainderGrams] records the gap.
PlateLoadout solvePlateLoadout({
  required int targetGrams,
  required WeightUnit unit,
}) {
  if (targetGrams < 0) {
    throw ArgumentError.value(targetGrams, 'targetGrams');
  }
  final int barCenti = _barCenti(unit);
  final int targetCenti = _toCenti(targetGrams, unit);
  if (targetCenti <= barCenti) {
    return PlateLoadout(
      targetGrams: targetGrams,
      barGrams: _fromCenti(barCenti, unit),
      platesPerSideGrams: const <int>[],
      actualGrams: _fromCenti(barCenti, unit),
      remainderGrams: 0,
      isBelowBar: targetCenti < barCenti,
    );
  }

  int remainingPerSide = (targetCenti - barCenti) ~/ 2;
  final List<int> plates = <int>[];
  for (final int plate in _platesFor(unit)) {
    while (remainingPerSide >= plate) {
      plates.add(plate);
      remainingPerSide -= plate;
    }
  }
  final int loadedCenti = plates.fold<int>(0, (int sum, int p) => sum + p);
  final int actualCenti = barCenti + loadedCenti * 2;
  return PlateLoadout(
    targetGrams: targetGrams,
    barGrams: _fromCenti(barCenti, unit),
    platesPerSideGrams: List<int>.unmodifiable(<int>[
      for (final int plate in plates) _fromCenti(plate, unit),
    ]),
    actualGrams: _fromCenti(actualCenti, unit),
    remainderGrams: (targetGrams - _fromCenti(actualCenti, unit)).clamp(
      0,
      targetGrams,
    ),
    isBelowBar: false,
  );
}

/// A bar-first ramp at 40%, 60%, and 80% of the working weight.
///
/// Percentages are rounded to the nearest plate increment (2.5 kg or 5 lb per
/// side), deduplicated, and each is solved with [solvePlateLoadout]. Steps that
/// are not lighter than the working weight are omitted, so a 20 kg working set
/// yields only the empty bar.
List<WarmupStep> warmupRamp({
  required int workingGrams,
  required WeightUnit unit,
}) {
  if (workingGrams < 0) {
    throw ArgumentError.value(workingGrams, 'workingGrams');
  }
  final int barCenti = _barCenti(unit);
  final int increment = unit == WeightUnit.kilograms ? 250 : 500;
  final int workingCenti = _toCenti(workingGrams, unit);
  // A working weight at or below the empty bar has no lighter ramp. Returning
  // early also prevents a clamp with a lower bound above its upper bound.
  if (workingCenti <= barCenti) {
    return const <WarmupStep>[];
  }
  final List<WarmupStep> steps = <WarmupStep>[];
  final Set<int> seen = <int>{};
  void addStep(int targetCenti, double fraction, int reps) {
    final int rounded = ((targetCenti / increment).round() * increment).clamp(
      barCenti,
      workingCenti,
    );
    if (rounded >= workingCenti || !seen.add(rounded)) {
      return;
    }
    steps.add(
      WarmupStep(
        fraction: fraction,
        reps: reps,
        loadout: solvePlateLoadout(
          targetGrams: _fromCenti(rounded, unit),
          unit: unit,
        ),
      ),
    );
  }

  addStep(barCenti, 0, 8);
  addStep((workingCenti * 0.4).round(), 0.4, 5);
  addStep((workingCenti * 0.6).round(), 0.6, 3);
  addStep((workingCenti * 0.8).round(), 0.8, 1);
  return List<WarmupStep>.unmodifiable(steps);
}
