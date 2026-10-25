import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

SetLog _set(int weightGrams, int reps, {bool warmup = false, int index = 0}) {
  return SetLog(
    id: 'set-$weightGrams-$reps-$index-${warmup ? 'warm' : 'work'}',
    weightGrams: weightGrams,
    reps: reps,
    isWarmup: warmup,
    setIndex: index,
    loggedAt: DateTime.utc(2026, 10, 20, 10, index),
  );
}

List<SetLog> _sets(int weightGrams, List<int> reps) {
  return <SetLog>[
    for (int index = 0; index < reps.length; index++)
      _set(weightGrams, reps[index], index: index),
  ];
}

Session _session(
  String id,
  DateTime startedAt,
  List<SessionExercise> exercises, {
  bool active = false,
}) {
  return Session(
    id: id,
    startedAt: startedAt,
    endedAt: active ? null : startedAt.add(const Duration(hours: 1)),
    exercises: exercises,
  );
}

SessionExercise _exercise(String id, String exerciseId, List<SetLog> sets) {
  return SessionExercise(
    id: id,
    exerciseId: exerciseId,
    sortOrder: 0,
    targetSets: 3,
    repMin: 8,
    repMax: 12,
    sets: sets,
  );
}

class _Case {
  const _Case(
    this.name,
    this.workingSets, {
    this.targetSets = 3,
    this.repMin = 8,
    this.repMax = 12,
    this.incrementGrams = defaultKilogramIncrementGrams,
    this.rule,
    this.weightGrams,
    this.targetReps,
    this.reasonType,
  });

  final String name;
  final List<SetLog> workingSets;
  final int? targetSets;
  final int? repMin;
  final int? repMax;
  final int incrementGrams;
  final ProgressionRule? rule;
  final int? weightGrams;
  final int? targetReps;
  final Type? reasonType;

  bool get expectsNoSuggestion => rule == null;
}

void main() {
  final List<_Case> cases = <_Case>[
    const _Case('first session has no suggestion', <SetLog>[]),
    _Case('warm-ups only yield no suggestion', <SetLog>[
      _set(100000, 12, warmup: true),
    ]),
    _Case(
      'missing rep minimum yields no suggestion',
      _sets(100000, <int>[12, 12, 12]),
      repMin: null,
    ),
    _Case(
      'missing rep maximum yields no suggestion',
      _sets(100000, <int>[12, 12, 12]),
      repMax: null,
    ),
    _Case(
      'missing rep range yields no suggestion',
      _sets(100000, <int>[12, 12, 12]),
      repMin: null,
      repMax: null,
    ),
    _Case(
      'missing target sets cannot add weight but still adds reps',
      _sets(100000, <int>[11, 11, 11]),
      targetSets: null,
      rule: ProgressionRule.addReps,
      weightGrams: 100000,
      targetReps: 12,
      reasonType: ProgressionReasonAddReps,
    ),
    _Case(
      'all three sets at the top add one increment',
      _sets(100000, <int>[12, 12, 12]),
      rule: ProgressionRule.addWeight,
      weightGrams: 102500,
      targetReps: 8,
      reasonType: ProgressionReasonAddWeight,
    ),
    _Case(
      'four sets above the target still add weight',
      _sets(100000, <int>[12, 12, 12, 12]),
      rule: ProgressionRule.addWeight,
      weightGrams: 102500,
      targetReps: 8,
      reasonType: ProgressionReasonAddWeight,
    ),
    _Case(
      'one set short of the top adds reps at the same weight',
      _sets(100000, <int>[12, 12, 11]),
      rule: ProgressionRule.addReps,
      weightGrams: 100000,
      targetReps: 12,
      reasonType: ProgressionReasonAddReps,
    ),
    _Case(
      'one set below the minimum holds and rebuilds',
      _sets(100000, <int>[12, 8, 7]),
      rule: ProgressionRule.hold,
      weightGrams: 100000,
      targetReps: 8,
      reasonType: ProgressionReasonHold,
    ),
    _Case(
      'every set below the minimum holds',
      _sets(100000, <int>[6, 7, 6]),
      rule: ProgressionRule.hold,
      weightGrams: 100000,
      targetReps: 8,
      reasonType: ProgressionReasonHold,
    ),
    _Case(
      'below the minimum wins over add-reps even beside top sets',
      _sets(100000, <int>[12, 9, 5]),
      rule: ProgressionRule.hold,
      weightGrams: 100000,
      targetReps: 8,
      reasonType: ProgressionReasonHold,
    ),
    _Case(
      'all sets at the minimum add one rep',
      _sets(100000, <int>[8, 8, 8]),
      rule: ProgressionRule.addReps,
      weightGrams: 100000,
      targetReps: 9,
      reasonType: ProgressionReasonAddReps,
    ),
    _Case(
      'all sets one rep short of the top add one rep',
      _sets(100000, <int>[11, 11, 11]),
      rule: ProgressionRule.addReps,
      weightGrams: 100000,
      targetReps: 12,
      reasonType: ProgressionReasonAddReps,
    ),
    _Case(
      'fewer sets than the target at the top yields no suggestion',
      _sets(100000, <int>[12, 12]),
    ),
    _Case(
      'fewer sets below the top still add one rep',
      _sets(100000, <int>[11, 11]),
      rule: ProgressionRule.addReps,
      weightGrams: 100000,
      targetReps: 12,
      reasonType: ProgressionReasonAddReps,
    ),
    _Case(
      'reps above the top with too few sets yield no suggestion',
      _sets(100000, <int>[13, 13]),
    ),
    _Case(
      'missing target sets at the top yields no suggestion',
      _sets(100000, <int>[12, 12, 12]),
      targetSets: null,
    ),
    _Case(
      'a single planned set at the top adds weight',
      _sets(100000, <int>[12]),
      targetSets: 1,
      rule: ProgressionRule.addWeight,
      weightGrams: 102500,
      targetReps: 8,
      reasonType: ProgressionReasonAddWeight,
    ),
    _Case(
      'a warm-up below the minimum is ignored',
      <SetLog>[
        _set(100000, 5, warmup: true),
        ..._sets(100000, <int>[12, 12, 12]),
      ],
      rule: ProgressionRule.addWeight,
      weightGrams: 102500,
      targetReps: 8,
      reasonType: ProgressionReasonAddWeight,
    ),
    _Case(
      'a heavier warm-up does not set the working weight',
      <SetLog>[
        _set(120000, 5, warmup: true),
        ..._sets(100000, <int>[12, 12, 12]),
      ],
      rule: ProgressionRule.addWeight,
      weightGrams: 102500,
      targetReps: 8,
      reasonType: ProgressionReasonAddWeight,
    ),
    _Case(
      'a warm-up at the top does not count toward target sets',
      <SetLog>[
        _set(100000, 12, warmup: true),
        ..._sets(100000, <int>[12, 12]),
      ],
      // Only two working sets exist, so rule A cannot apply and there is no
      // rep increase left at the top.
    ),
    _Case(
      'visible reps above the maximum still count as reaching the top',
      _sets(100000, <int>[13, 13, 13]),
      rule: ProgressionRule.addWeight,
      weightGrams: 102500,
      targetReps: 8,
      reasonType: ProgressionReasonAddWeight,
    ),
    _Case(
      'a fixed rep range adds weight at the single target',
      _sets(100000, <int>[10, 10, 10]),
      repMin: 10,
      repMax: 10,
      rule: ProgressionRule.addWeight,
      weightGrams: 102500,
      targetReps: 10,
      reasonType: ProgressionReasonAddWeight,
    ),
    _Case('mixed working weights yield no suggestion', <SetLog>[
      _set(100000, 10, index: 0),
      _set(97500, 11, index: 1),
      _set(100000, 12, index: 2),
    ]),
    _Case('mixed weights at the top never add weight', <SetLog>[
      _set(100000, 12, index: 0),
      _set(102500, 12, index: 1),
      _set(100000, 12, index: 2),
    ]),
    _Case('mixed weights below the minimum yield no suggestion', <SetLog>[
      _set(100000, 7, index: 0),
      _set(97500, 12, index: 1),
    ]),
    _Case('mixed weights including bodyweight yield no suggestion', <SetLog>[
      _set(0, 12, index: 0),
      _set(100000, 12, index: 1),
    ]),
    _Case(
      'bodyweight at the top adds reps instead of weight',
      _sets(0, <int>[12, 12, 12]),
      rule: ProgressionRule.addReps,
      weightGrams: 0,
      targetReps: 13,
      reasonType: ProgressionReasonAddReps,
    ),
    _Case(
      'bodyweight one rep short adds one rep',
      _sets(0, <int>[12, 12, 11]),
      rule: ProgressionRule.addReps,
      weightGrams: 0,
      targetReps: 12,
      reasonType: ProgressionReasonAddReps,
    ),
    _Case(
      'bodyweight below the minimum holds at the minimum',
      _sets(0, <int>[12, 8, 7]),
      rule: ProgressionRule.hold,
      weightGrams: 0,
      targetReps: 8,
      reasonType: ProgressionReasonHold,
    ),
    _Case(
      'bodyweight at the minimum adds one rep',
      _sets(0, <int>[8, 8, 8]),
      rule: ProgressionRule.addReps,
      weightGrams: 0,
      targetReps: 9,
      reasonType: ProgressionReasonAddReps,
    ),
    _Case(
      'bodyweight reps at the stored limit yield no suggestion',
      _sets(0, <int>[1000, 1000, 1000]),
    ),
    _Case(
      'a five-pound exercise increment stays canonical grams',
      _sets(20412, <int>[12, 12, 12]),
      incrementGrams: defaultPoundIncrementGrams,
      rule: ProgressionRule.addWeight,
      weightGrams: 22680,
      targetReps: 8,
      reasonType: ProgressionReasonAddWeight,
    ),
    _Case(
      'a one-kilogram exercise increment is honored',
      _sets(100000, <int>[12, 12, 12]),
      incrementGrams: 1000,
      rule: ProgressionRule.addWeight,
      weightGrams: 101000,
      targetReps: 8,
      reasonType: ProgressionReasonAddWeight,
    ),
    _Case(
      'a weight increase beyond the stored maximum yields no suggestion',
      _sets(999000, <int>[12, 12, 12]),
      incrementGrams: 2500,
    ),
    _Case(
      'an invalid incremental range yields no suggestion',
      _sets(100000, <int>[12, 12, 12]),
      repMin: 12,
      repMax: 8,
    ),
  ];

  group('progressionSuggestion', () {
    for (final _Case testCase in cases) {
      test(testCase.name, () {
        final ProgressionSuggestion? suggestion = progressionSuggestion(
          targetSets: testCase.targetSets,
          repMin: testCase.repMin,
          repMax: testCase.repMax,
          incrementGrams: testCase.incrementGrams,
          lastWorkingSets: testCase.workingSets,
        );

        if (testCase.expectsNoSuggestion) {
          expect(suggestion, isNull);
          return;
        }
        expect(suggestion, isNotNull);
        expect(suggestion!.rule, testCase.rule);
        expect(suggestion.weightGrams, testCase.weightGrams);
        expect(suggestion.targetReps, testCase.targetReps);
        expect(suggestion.reason.runtimeType, testCase.reasonType);
      });
    }

    test('the rule A reason carries count, top, and increment', () {
      final ProgressionSuggestion suggestion = progressionSuggestion(
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        incrementGrams: 2500,
        lastWorkingSets: _sets(100000, <int>[12, 12, 12]),
      )!;

      final ProgressionReasonAddWeight reason =
          suggestion.reason as ProgressionReasonAddWeight;
      expect(reason.setCount, 3);
      expect(reason.maxReps, 12);
      expect(reason.incrementGrams, 2500);
    });

    test('the rule B reason carries weakest and target reps', () {
      final ProgressionSuggestion suggestion = progressionSuggestion(
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        incrementGrams: 2500,
        lastWorkingSets: _sets(100000, <int>[12, 8, 10]),
      )!;

      final ProgressionReasonAddReps reason =
          suggestion.reason as ProgressionReasonAddReps;
      expect(reason.weakestReps, 8);
      expect(reason.targetReps, 9);
    });

    test('the rule C reason carries the range minimum', () {
      final ProgressionSuggestion suggestion = progressionSuggestion(
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        incrementGrams: 2500,
        lastWorkingSets: _sets(100000, <int>[12, 8, 7]),
      )!;

      final ProgressionReasonHold reason =
          suggestion.reason as ProgressionReasonHold;
      expect(reason.minReps, 8);
    });
  });

  group('lastWorkingSetsForExercise', () {
    test('returns working sets from the most recent session', () {
      final Session older = _session(
        'older',
        DateTime.utc(2026, 10, 19, 10),
        <SessionExercise>[
          _exercise('older-exercise', 'bench', _sets(90000, <int>[8, 8, 8])),
        ],
      );
      final Session newer = _session(
        'newer',
        DateTime.utc(2026, 10, 20, 10),
        <SessionExercise>[
          _exercise('newer-exercise', 'bench', <SetLog>[
            _set(100000, 5, warmup: true),
            _set(100000, 12, index: 1),
            _set(100000, 11, index: 2),
          ]),
        ],
      );

      final List<SetLog> sets = lastWorkingSetsForExercise(
        sessions: <Session>[older, newer],
        exerciseId: 'bench',
      );

      expect(sets, hasLength(2));
      expect(sets.map((SetLog set) => set.reps), <int>[12, 11]);
      expect(sets.every((SetLog set) => !set.isWarmup), isTrue);
    });

    test('a latest warm-up-only session yields no working sets', () {
      final Session older = _session(
        'older',
        DateTime.utc(2026, 10, 19, 10),
        <SessionExercise>[
          _exercise('older-exercise', 'bench', _sets(100000, <int>[12, 12])),
        ],
      );
      final Session warmupsOnly = _session(
        'warmups',
        DateTime.utc(2026, 10, 20, 10),
        <SessionExercise>[
          _exercise('warmups-exercise', 'bench', <SetLog>[
            _set(100000, 5, warmup: true),
          ]),
        ],
      );

      expect(
        lastWorkingSetsForExercise(
          sessions: <Session>[older, warmupsOnly],
          exerciseId: 'bench',
        ),
        isEmpty,
      );
    });

    test('the active session is excluded from its own history', () {
      final Session previous = _session(
        'previous',
        DateTime.utc(2026, 10, 19, 10),
        <SessionExercise>[
          _exercise('previous-exercise', 'bench', _sets(100000, <int>[12])),
        ],
      );
      final Session active = _session(
        'active',
        DateTime.utc(2026, 10, 20, 10),
        <SessionExercise>[
          _exercise('active-exercise', 'bench', _sets(80000, <int>[8])),
        ],
        active: true,
      );

      final List<SetLog> sets = lastWorkingSetsForExercise(
        sessions: <Session>[previous, active],
        exerciseId: 'bench',
        excludeSessionId: active.id,
      );

      expect(sets.single.weightGrams, 100000);
      expect(sets.single.reps, 12);
    });

    test('an exercise without history yields no working sets', () {
      expect(
        lastWorkingSetsForExercise(
          sessions: const <Session>[],
          exerciseId: 'bench',
        ),
        isEmpty,
      );
    });
  });
}
