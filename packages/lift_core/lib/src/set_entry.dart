import 'session.dart';
import 'weight.dart';

/// The four values a user can change on one logged set.
///
/// Identity ([SetLog.id]), row position ([SetLog.setIndex]), and the original
/// timestamp are deliberately absent: editing values never rewrites them
/// (`LOG-006`). The constructor enforces the same bounds as [SetLog].
class SetEntry {
  factory SetEntry({
    required int weightGrams,
    required int reps,
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
    return SetEntry._(
      weightGrams: weightGrams,
      reps: reps,
      rir: rir,
      isWarmup: isWarmup,
    );
  }

  const SetEntry._({
    required this.weightGrams,
    required this.reps,
    required this.rir,
    required this.isWarmup,
  });

  final int weightGrams;
  final int reps;
  final int? rir;
  final bool isWarmup;

  /// Copies these values onto [set], preserving its identity, position, and
  /// timestamp.
  SetLog applyTo(SetLog set) {
    return SetLog(
      id: set.id,
      weightGrams: weightGrams,
      reps: reps,
      rir: rir,
      isWarmup: isWarmup,
      setIndex: set.setIndex,
      loggedAt: set.loggedAt,
    );
  }

  /// Creates a new logged set carrying this entry's values.
  SetLog toSetLog({
    required String id,
    required int setIndex,
    required DateTime loggedAt,
  }) {
    return SetLog(
      id: id,
      weightGrams: weightGrams,
      reps: reps,
      rir: rir,
      isWarmup: isWarmup,
      setIndex: setIndex,
      loggedAt: loggedAt,
    );
  }
}
