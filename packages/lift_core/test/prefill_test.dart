import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

SetLog _set(
  String id,
  int weightGrams,
  int reps, {
  int? rir,
  bool warmup = false,
  int order = 0,
}) {
  return SetLog(
    id: id,
    setIndex: order,
    weightGrams: weightGrams,
    reps: reps,
    rir: rir,
    isWarmup: warmup,
    loggedAt: DateTime.utc(2026, 10, 20, 10),
  );
}

SessionExercise _exercise(
  String id,
  String exerciseId,
  List<SetLog> sets, {
  int sortOrder = 0,
}) {
  return SessionExercise(
    id: id,
    exerciseId: exerciseId,
    sortOrder: sortOrder,
    targetSets: 3,
    repMin: 8,
    repMax: 12,
    sets: sets,
  );
}

Session _session(
  String id,
  DateTime startedAt,
  List<SessionExercise> exercises,
) {
  return Session(
    id: id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(hours: 1)),
    exercises: exercises,
  );
}

void main() {
  final Session history = _session(
    'session-1',
    DateTime.utc(2026, 10, 19, 10),
    <SessionExercise>[
      _exercise('session-exercise-1', 'bench', <SetLog>[
        _set('set-1', 100000, 8, rir: 2, order: 0),
        _set('set-2', 100000, 8, rir: 2, order: 1),
        _set('set-3', 97500, 7, rir: 1, order: 2),
      ]),
    ],
  );

  group('prefillForExercise', () {
    test('first session has no prefill', () {
      final SetPrefill prefill = prefillForExercise(
        sessions: const <Session>[],
        exerciseId: 'bench',
        setIndex: 0,
      );

      expect(prefill.isEmpty, isTrue);
    });

    test('uses the same working-set index', () {
      for (final (int index, int grams, int reps, int rir)
          in <(int, int, int, int)>[
            (0, 100000, 8, 2),
            (1, 100000, 8, 2),
            (2, 97500, 7, 1),
          ]) {
        final SetPrefill prefill = prefillForExercise(
          sessions: <Session>[history],
          exerciseId: 'bench',
          setIndex: index,
        );
        expect(prefill.weightGrams, grams);
        expect(prefill.reps, reps);
        expect(prefill.rir, rir);
      }
    });

    test('fewer historical sets falls back to the last working set', () {
      final SetPrefill prefill = prefillForExercise(
        sessions: <Session>[history],
        exerciseId: 'bench',
        setIndex: 5,
      );

      expect(prefill.weightGrams, 97500);
      expect(prefill.reps, 7);
      expect(prefill.rir, 1);
    });

    test('more historical sets still uses the same index', () {
      final Session fourSets = _session(
        'session-4',
        DateTime.utc(2026, 10, 19, 10),
        <SessionExercise>[
          _exercise('session-exercise-4', 'bench', <SetLog>[
            _set('set-4-0', 90000, 10, order: 0),
            _set('set-4-1', 90000, 9, order: 1),
            _set('set-4-2', 90000, 8, order: 2),
            _set('set-4-3', 87500, 8, order: 3),
          ]),
        ],
      );

      final SetPrefill prefill = prefillForExercise(
        sessions: <Session>[fourSets],
        exerciseId: 'bench',
        setIndex: 2,
      );

      expect(prefill.weightGrams, 90000);
      expect(prefill.reps, 8);
    });

    test('ignores warm-ups by index and never prefills them', () {
      final Session mixed = _session(
        'session-mixed',
        DateTime.utc(2026, 10, 19, 10),
        <SessionExercise>[
          _exercise('session-exercise-mixed', 'squat', <SetLog>[
            _set('warm-1', 200000, 5, warmup: true, order: 0),
            _set('work-1', 140000, 8, order: 1),
            _set('warm-2', 150000, 5, warmup: true, order: 2),
            _set('work-2', 135000, 7, order: 3),
          ]),
        ],
      );

      expect(
        prefillForExercise(
          sessions: <Session>[mixed],
          exerciseId: 'squat',
          setIndex: 0,
        ).weightGrams,
        140000,
      );
      expect(
        prefillForExercise(
          sessions: <Session>[mixed],
          exerciseId: 'squat',
          setIndex: 1,
        ).weightGrams,
        135000,
      );
      expect(
        prefillForExercise(
          sessions: <Session>[mixed],
          exerciseId: 'squat',
          setIndex: 9,
        ).weightGrams,
        135000,
      );
      expect(
        prefillForExercise(
          sessions: <Session>[mixed],
          exerciseId: 'squat',
          setIndex: 0,
        ).reps,
        8,
      );
    });

    test('a warm-ups-only session yields no prefill, not older history', () {
      final Session warmupsOnly = _session(
        'session-warmups',
        DateTime.utc(2026, 10, 20, 10),
        <SessionExercise>[
          _exercise('session-exercise-warmups', 'bench', <SetLog>[
            _set('warm-only-1', 60000, 10, warmup: true, order: 0),
            _set('warm-only-2', 80000, 8, warmup: true, order: 1),
          ]),
        ],
      );

      final SetPrefill prefill = prefillForExercise(
        sessions: <Session>[history, warmupsOnly],
        exerciseId: 'bench',
        setIndex: 0,
      );

      expect(prefill.isEmpty, isTrue);
    });

    test(
      'archived exercises still prefill because history references them',
      () {
        final Exercise archived = Exercise(
          id: 'bench',
          name: 'Bench Press',
          archivedAt: DateTime.utc(2026, 10, 20, 12),
          createdAt: DateTime.utc(2026, 10, 18, 10),
        );
        final AppData data = AppData(
          exercises: <Exercise>[archived],
          sessions: <Session>[history],
        );

        final SetPrefill prefill = prefillForExercise(
          sessions: data.sessions,
          exerciseId: archived.id,
          setIndex: 0,
        );

        expect(archived.isArchived, isTrue);
        expect(prefill.weightGrams, 100000);
        expect(prefill.reps, 8);
      },
    );

    test('mixed historical units stay canonical grams', () {
      final Session mixedUnits = _session(
        'session-units',
        DateTime.utc(2026, 10, 19, 10),
        <SessionExercise>[
          _exercise('session-exercise-units', 'bench', <SetLog>[
            _set('unit-set-1', 20412, 8, order: 0),
            _set('unit-set-2', 100000, 5, order: 1),
          ]),
        ],
      );

      expect(
        prefillForExercise(
          sessions: <Session>[mixedUnits],
          exerciseId: 'bench',
          setIndex: 0,
        ).weightGrams,
        20412,
      );
      expect(
        prefillForExercise(
          sessions: <Session>[mixedUnits],
          exerciseId: 'bench',
          setIndex: 1,
        ).weightGrams,
        100000,
      );
    });

    test('uses the most recent session and excludes the active session', () {
      final Session newer = _session(
        'session-2',
        DateTime.utc(2026, 10, 20, 10),
        <SessionExercise>[
          _exercise('session-exercise-2', 'bench', <SetLog>[
            _set('newer-set', 102500, 6, order: 0),
          ]),
        ],
      );
      final Session active = Session(
        id: 'session-active',
        startedAt: DateTime.utc(2026, 10, 21, 10),
        exercises: <SessionExercise>[
          _exercise('active-exercise', 'bench', <SetLog>[
            _set('active-set', 90000, 10, order: 0),
          ]),
        ],
      );

      final SetPrefill prefill = prefillForExercise(
        sessions: <Session>[history, newer, active],
        exerciseId: 'bench',
        setIndex: 0,
        excludeSessionId: active.id,
      );

      expect(prefill.weightGrams, 102500);
      expect(prefill.reps, 6);
    });

    test('returns empty when the exercise has no history', () {
      final SetPrefill prefill = prefillForExercise(
        sessions: <Session>[history],
        exerciseId: 'squat',
        setIndex: 0,
      );

      expect(prefill.isEmpty, isTrue);
    });
  });
}
