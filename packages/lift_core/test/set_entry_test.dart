import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

void main() {
  final SetLog original = SetLog(
    id: 'set-1',
    weightGrams: 100000,
    reps: 8,
    rir: 2,
    setIndex: 3,
    loggedAt: DateTime.utc(2026, 10, 20, 10),
  );

  test('applyTo changes values and preserves identity and row metadata', () {
    final SetLog updated = SetEntry(
      weightGrams: 105000,
      reps: 12,
    ).applyTo(original);

    expect(updated.id, original.id);
    expect(updated.setIndex, original.setIndex);
    expect(updated.loggedAt, original.loggedAt);
    expect(updated.weightGrams, 105000);
    expect(updated.reps, 12);
    expect(updated.rir, isNull, reason: 'an omitted RIR clears the old one');
    expect(updated.isWarmup, isFalse);
  });

  test('toSetLog creates a new identity with the entry values', () {
    final SetLog created =
        SetEntry(weightGrams: 60000, reps: 10, isWarmup: true).toSetLog(
          id: 'set-2',
          setIndex: 0,
          loggedAt: DateTime.utc(2026, 10, 21, 10),
        );

    expect(created.id, 'set-2');
    expect(created.setIndex, 0);
    expect(created.weightGrams, 60000);
    expect(created.reps, 10);
    expect(created.isWarmup, isTrue);
  });

  test('rejects values outside the set bounds', () {
    expect(() => SetEntry(weightGrams: -1, reps: 5), throwsArgumentError);
    expect(
      () => SetEntry(weightGrams: maximumSetWeightGrams + 1, reps: 5),
      throwsArgumentError,
    );
    expect(() => SetEntry(weightGrams: 100000, reps: 0), throwsArgumentError);
    expect(
      () => SetEntry(weightGrams: 100000, reps: 5, rir: maximumStoredRir + 1),
      throwsArgumentError,
    );
  });
}
