import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

SetLog _set(int index, int weightGrams, int reps, {bool warmup = false}) {
  return SetLog(
    id: 'set-$index',
    weightGrams: weightGrams,
    reps: reps,
    setIndex: index,
    loggedAt: DateTime.utc(2026, 10, 20, 10, index),
    isWarmup: warmup,
  );
}

SessionExercise _exercise({
  int? targetSets,
  List<SetLog> sets = const <SetLog>[],
}) {
  return SessionExercise(
    id: 'session-exercise',
    exerciseId: 'bench',
    sortOrder: 0,
    targetSets: targetSets,
    sets: sets,
  );
}

void main() {
  final List<SetLog> previous = <SetLog>[
    _set(0, 100000, 8),
    _set(1, 100000, 7),
  ];

  test('plans the target rows and prefills them by working position', () {
    final List<SessionRowPlan> rows = planSessionRows(
      sessionExercise: _exercise(targetSets: 3),
      previousWorkingSets: previous,
    );

    expect(rows.map((SessionRowPlan row) => row.index), <int>[0, 1, 2]);
    expect(rows.every((SessionRowPlan row) => row.savedSet == null), isTrue);
    expect(rows[0].prefill!.weightGrams, 100000);
    expect(rows[0].prefill!.reps, 8);
    expect(rows[1].prefill!.reps, 7);
    expect(rows[2].prefill!.reps, 7, reason: 'past the end uses the last set');
  });

  test('warm-ups do not consume a prefill index', () {
    final List<SessionRowPlan> rows = planSessionRows(
      sessionExercise: _exercise(
        targetSets: 4,
        sets: <SetLog>[_set(0, 60000, 10, warmup: true), _set(1, 100000, 8)],
      ),
      previousWorkingSets: previous,
    );

    expect(rows, hasLength(4));
    expect(rows[0].savedSet!.isWarmup, isTrue);
    expect(rows[1].savedSet!.reps, 8);
    expect(rows[2].prefill!.reps, 7, reason: 'next working position');
    expect(rows[3].prefill!.reps, 7, reason: 'past the end repeats the last');
  });

  test('extra rows extend the plan and a set past the target grows it', () {
    final List<SessionRowPlan> rows = planSessionRows(
      sessionExercise: _exercise(
        targetSets: 2,
        sets: <SetLog>[_set(0, 100000, 8), _set(3, 97500, 6)],
      ),
      previousWorkingSets: previous,
      extraRows: 1,
    );

    expect(rows.map((SessionRowPlan row) => row.index), <int>[0, 1, 2, 3, 4]);
    expect(rows[3].savedSet!.reps, 6);
    expect(rows[4].prefill, isNotNull);
  });

  test('no target sets still opens one editable row', () {
    final List<SessionRowPlan> rows = planSessionRows(
      sessionExercise: _exercise(),
      previousWorkingSets: const <SetLog>[],
    );

    expect(rows, hasLength(1));
    expect(rows.single.prefill!.isEmpty, isTrue);
  });

  test('rejects a negative extra row count', () {
    expect(
      () => planSessionRows(
        sessionExercise: _exercise(),
        previousWorkingSets: const <SetLog>[],
        extraRows: -1,
      ),
      throwsArgumentError,
    );
  });
}
