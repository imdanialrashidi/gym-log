import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

SetLog _set(
  String id,
  int weightGrams,
  int reps, {
  int? rir,
  bool warmup = false,
  int index = 0,
  DateTime? loggedAt,
}) {
  return SetLog(
    id: id,
    setIndex: index,
    weightGrams: weightGrams,
    reps: reps,
    rir: rir,
    isWarmup: warmup,
    loggedAt: loggedAt ?? DateTime.utc(2026, 10, 1, 10, index),
  );
}

Session _session(String id, DateTime startedAt, List<SetLog> sets) {
  return Session(
    id: id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(hours: 1)),
    exercises: <SessionExercise>[
      SessionExercise(
        id: '$id-exercise',
        exerciseId: 'bench',
        sortOrder: 0,
        sets: <SetLog>[
          for (final SetLog set in sets)
            SetLog(
              id: set.id,
              weightGrams: set.weightGrams,
              reps: set.reps,
              rir: set.rir,
              isWarmup: set.isWarmup,
              setIndex: set.setIndex,
              loggedAt: startedAt.add(Duration(minutes: set.setIndex)),
            ),
        ],
      ),
    ],
  );
}

PersonalRecordsBySet _records(List<Session> sessions) {
  return personalRecordsForExercise(sessions: sessions, exerciseId: 'bench');
}

void main() {
  group('personal records', () {
    test('the first working set is a baseline, not a PR', () {
      final PersonalRecordsBySet records = _records(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', 100000, 5),
        ]),
      ]);

      expect(records['set-1'], isEmpty);
    });

    test('warm-ups are ignored and never count as a baseline or PR', () {
      final PersonalRecordsBySet records = _records(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('warmup-heavy', 150000, 5, warmup: true),
          _set('set-1', 100000, 5, index: 1),
        ]),
        _session('s2', DateTime.utc(2026, 10, 2), <SetLog>[
          _set('set-2', 110000, 5),
        ]),
      ]);

      expect(records.containsKey('warmup-heavy'), isFalse);
      expect(records['set-1'], isEmpty);
      expect(
        records['set-2'],
        containsAll(<PersonalRecordType>[
          PersonalRecordType.heaviestWeight,
          PersonalRecordType.estimatedOneRepMax,
        ]),
      );
    });

    test('equalling a record is not a PR', () {
      final PersonalRecordsBySet records = _records(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', 100000, 5),
          _set('set-2', 100000, 5, index: 1),
          _set('set-3', 100000, 8, index: 2),
          _set('set-4', 100000, 8, index: 3),
        ]),
      ]);

      expect(records['set-1'], isEmpty);
      expect(records['set-2'], isEmpty);
      expect(
        records['set-3'],
        containsAll(<PersonalRecordType>[
          PersonalRecordType.mostRepsAtWeight,
          PersonalRecordType.estimatedOneRepMax,
        ]),
      );
      expect(
        records['set-3'],
        isNot(contains(PersonalRecordType.heaviestWeight)),
      );
      expect(records['set-4'], isEmpty);
    });

    test('a heavier working set earns weight and e1RM PRs', () {
      final PersonalRecordsBySet records = _records(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', 100000, 5),
        ]),
        _session('s2', DateTime.utc(2026, 10, 2), <SetLog>[
          _set('set-2', 110000, 5),
        ]),
      ]);

      expect(
        records['set-2'],
        containsAll(<PersonalRecordType>[
          PersonalRecordType.heaviestWeight,
          PersonalRecordType.estimatedOneRepMax,
        ]),
      );
    });

    test('most reps at a weight uses each weight as its own baseline', () {
      final PersonalRecordsBySet records = _records(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', 100000, 5),
          _set('set-2', 90000, 8, index: 1),
          _set('set-3', 100000, 6, index: 2),
          _set('set-4', 90000, 9, index: 3),
        ]),
      ]);

      expect(records['set-2'], isEmpty);
      expect(records['set-3'], contains(PersonalRecordType.mostRepsAtWeight));
      expect(
        records['set-3'],
        isNot(contains(PersonalRecordType.heaviestWeight)),
      );
      expect(records['set-4'], contains(PersonalRecordType.mostRepsAtWeight));
    });

    test('an equal e1RM is a tie, not a PR', () {
      // 100 kg × 2 reps and 80 kg × 10 reps both estimate 106.67 kg.
      final PersonalRecordsBySet records = _records(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', 100000, 2),
          _set('set-2', 80000, 10, index: 1),
        ]),
      ]);

      expect(records['set-2'], isEmpty);
    });

    test('reps above 12 never produce an e1RM PR', () {
      final PersonalRecordsBySet records = _records(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', 100000, 13),
        ]),
        _session('s2', DateTime.utc(2026, 10, 2), <SetLog>[
          _set('set-2', 110000, 13),
        ]),
        _session('s3', DateTime.utc(2026, 10, 3), <SetLog>[
          _set('set-3', 100000, 14),
        ]),
      ]);

      expect(records['set-1'], isEmpty);
      expect(records['set-2'], contains(PersonalRecordType.heaviestWeight));
      expect(
        records['set-2'],
        isNot(contains(PersonalRecordType.estimatedOneRepMax)),
      );
      expect(records['set-3'], contains(PersonalRecordType.mostRepsAtWeight));
      expect(
        records['set-3'],
        isNot(contains(PersonalRecordType.estimatedOneRepMax)),
      );
    });

    test('deleting the record set recalculates later status', () {
      final Session first = _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
        _set('set-1', 100000, 5),
      ]);
      final Session record = _session('s2', DateTime.utc(2026, 10, 2), <SetLog>[
        _set('set-2', 110000, 5),
      ]);
      final Session later = _session('s3', DateTime.utc(2026, 10, 3), <SetLog>[
        _set('set-3', 105000, 5),
      ]);

      final PersonalRecordsBySet before = _records(<Session>[
        first,
        record,
        later,
      ]);
      expect(before['set-2'], contains(PersonalRecordType.heaviestWeight));
      expect(before['set-3'], isEmpty);

      final PersonalRecordsBySet after = _records(<Session>[first, later]);
      expect(after.containsKey('set-2'), isFalse);
      expect(
        after['set-3'],
        containsAll(<PersonalRecordType>[
          PersonalRecordType.heaviestWeight,
          PersonalRecordType.estimatedOneRepMax,
        ]),
      );
    });

    test('both display units feed the same canonical comparison', () {
      final int baselineGrams = parseWeightInput(
        '100',
        WeightUnit.kilograms,
      ).grams!;
      final int heavierGrams = parseWeightInput(
        '225',
        WeightUnit.pounds,
      ).grams!;
      expect(heavierGrams, greaterThan(baselineGrams));

      final PersonalRecordsBySet records = _records(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', baselineGrams, 5),
        ]),
        _session('s2', DateTime.utc(2026, 10, 2), <SetLog>[
          _set('set-2', heavierGrams, 5),
        ]),
      ]);

      expect(records['set-2'], contains(PersonalRecordType.heaviestWeight));
    });
  });
}
