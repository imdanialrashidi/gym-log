import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

SetLog _set(
  String id,
  int weightGrams,
  int reps, {
  int? rir,
  bool warmup = false,
  int index = 0,
  int minute = 0,
}) {
  return SetLog(
    id: id,
    setIndex: index,
    weightGrams: weightGrams,
    reps: reps,
    rir: rir,
    isWarmup: warmup,
    loggedAt: DateTime.utc(2026, 1, 1, 10, minute),
  );
}

Session _session(
  String id,
  DateTime startedAt,
  List<SetLog> sets, {
  String exerciseId = 'bench',
  bool active = false,
}) {
  return Session(
    id: id,
    startedAt: startedAt,
    endedAt: active ? null : startedAt.add(const Duration(hours: 1)),
    exercises: <SessionExercise>[
      SessionExercise(
        id: '$id-exercise',
        exerciseId: exerciseId,
        sortOrder: 0,
        sets: sets,
      ),
    ],
  );
}

ExerciseProgress _progress(
  List<Session> sessions, {
  ProgressRange range = ProgressRange.all,
  DateTime? now,
}) {
  return prepareExerciseProgress(
    sessions: sessions,
    exerciseId: 'bench',
    range: range,
    now: now ?? DateTime.utc(2026, 10, 21, 12),
  );
}

void _expectSameProgress(ExerciseProgress actual, ExerciseProgress expected) {
  expect(actual.hasHistory, expected.hasHistory);
  expect(actual.sessionCount, expected.sessionCount);
  for (final (List<ProgressPoint> a, List<ProgressPoint> b)
      in <(List<ProgressPoint>, List<ProgressPoint>)>[
        (actual.bestWeightSeries, expected.bestWeightSeries),
        (actual.estimatedOneRepMaxSeries, expected.estimatedOneRepMaxSeries),
        (actual.repsSeries, expected.repsSeries),
        (actual.rirSeries, expected.rirSeries),
      ]) {
    expect(a.length, b.length);
    for (int index = 0; index < a.length; index++) {
      expect(a[index].date, b[index].date, reason: 'point $index');
      expect(a[index].value, b[index].value, reason: 'point $index');
    }
  }
  expect(actual.bestWeightGrams, expected.bestWeightGrams);
  expect(actual.bestOneRepMaxGrams, expected.bestOneRepMaxGrams);
  expect(actual.bestOneRepMaxConfidence, expected.bestOneRepMaxConfidence);
}

void main() {
  group('progress series', () {
    test('uses the best working set of each finished session', () {
      final ExerciseProgress progress = _progress(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('warmup', 150000, 5, warmup: true),
          _set('set-1', 100000, 8, rir: 2, index: 1),
          _set('set-2', 110000, 5, rir: 3, index: 2),
          _set('set-3', 90000, 12, index: 3),
        ]),
      ]);

      expect(progress.sessionCount, 1);
      expect(progress.bestWeightSeries.single.value, 110000);
      expect(progress.repsSeries.single.value, 5);
      expect(progress.rirSeries.single.value, 3);
      expect(
        progress.estimatedOneRepMaxSeries.single.value,
        (110000 * 35 / 30).roundToDouble(),
      );
    });

    test('breaks a weight tie with the most reps', () {
      final ExerciseProgress progress = _progress(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', 100000, 5),
          _set('set-2', 90000, 8, index: 1),
          _set('set-3', 100000, 9, index: 2),
        ]),
      ]);

      expect(progress.repsSeries.single.value, 9);
    });

    test('combines repeated session exercises for the same exercise', () {
      final Session session = Session(
        id: 's1',
        startedAt: DateTime.utc(2026, 10, 1),
        endedAt: DateTime.utc(2026, 10, 1, 1),
        exercises: <SessionExercise>[
          SessionExercise(
            id: 's1-a',
            exerciseId: 'bench',
            sortOrder: 0,
            sets: <SetLog>[_set('set-1', 100000, 5)],
          ),
          SessionExercise(
            id: 's1-b',
            exerciseId: 'bench',
            sortOrder: 1,
            sets: <SetLog>[_set('set-2', 105000, 5, index: 1)],
          ),
        ],
      );

      final ExerciseProgress progress = _progress(<Session>[session]);
      expect(progress.sessionCount, 1);
      expect(progress.bestWeightSeries.single.value, 105000);
    });

    test('missing RIR is a null gap, not zero', () {
      final ExerciseProgress progress = _progress(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', 100000, 5),
        ]),
        _session('s2', DateTime.utc(2026, 10, 2), <SetLog>[
          _set('set-2', 100000, 5, rir: 0),
        ]),
      ]);

      expect(progress.rirSeries[0].value, isNull);
      expect(progress.rirSeries[1].value, 0);
    });

    test('e1RM above 12 reps is a null gap', () {
      final ExerciseProgress progress = _progress(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', 100000, 13),
        ]),
        _session('s2', DateTime.utc(2026, 10, 2), <SetLog>[
          _set('set-2', 100000, 10),
        ]),
      ]);

      expect(progress.estimatedOneRepMaxSeries[0].value, isNull);
      expect(progress.estimatedOneRepMaxSeries[1].value, isNotNull);
    });

    test(
      'four-week range includes the boundary and excludes older sessions',
      () {
        final DateTime now = DateTime.utc(2026, 10, 21, 12);
        final ExerciseProgress progress = _progress(
          <Session>[
            _session(
              'boundary',
              now.subtract(const Duration(days: fourWeeksProgressDays)),
              <SetLog>[_set('set-1', 100000, 5)],
            ),
            _session(
              'outside',
              now
                  .subtract(const Duration(days: fourWeeksProgressDays))
                  .subtract(const Duration(minutes: 1)),
              <SetLog>[_set('set-2', 100000, 5)],
            ),
          ],
          range: ProgressRange.fourWeeks,
          now: now,
        );

        expect(progress.hasHistory, isTrue);
        expect(progress.sessionCount, 1);
        expect(
          progress.bestWeightSeries.single.date,
          now.subtract(const Duration(days: 28)),
        );
      },
    );

    test('twelve-week and one-year ranges use their fixed windows', () {
      final DateTime now = DateTime.utc(2026, 10, 21, 12);
      final List<Session> sessions = <Session>[
        _session('s-60d', now.subtract(const Duration(days: 60)), <SetLog>[
          _set('set-1', 100000, 5),
        ]),
        _session('s-300d', now.subtract(const Duration(days: 300)), <SetLog>[
          _set('set-2', 100000, 5),
        ]),
        _session('s-400d', now.subtract(const Duration(days: 400)), <SetLog>[
          _set('set-3', 100000, 5),
        ]),
      ];

      expect(
        _progress(
          sessions,
          range: ProgressRange.twelveWeeks,
          now: now,
        ).sessionCount,
        1,
      );
      expect(
        _progress(
          sessions,
          range: ProgressRange.oneYear,
          now: now,
        ).sessionCount,
        2,
      );
      expect(
        _progress(sessions, range: ProgressRange.all, now: now).sessionCount,
        3,
      );
    });

    test('reports history outside the selected range separately', () {
      final DateTime now = DateTime.utc(2026, 10, 21, 12);
      final ExerciseProgress progress = _progress(
        <Session>[
          _session('old', now.subtract(const Duration(days: 100)), <SetLog>[
            _set('set-1', 100000, 5),
          ]),
        ],
        range: ProgressRange.fourWeeks,
        now: now,
      );

      expect(progress.hasHistory, isTrue);
      expect(progress.hasData, isFalse);
      expect(progress.bestWeightSeries, isEmpty);
      expect(progress.bestWeightGrams, isNull);
    });

    test('excludes the active session and sorts points oldest first', () {
      final ExerciseProgress progress = _progress(<Session>[
        _session('newer', DateTime.utc(2026, 10, 3), <SetLog>[
          _set('set-2', 110000, 5),
        ]),
        _session('active', DateTime.utc(2026, 10, 4), <SetLog>[
          _set('set-3', 120000, 5),
        ], active: true),
        _session('older', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', 100000, 5),
        ]),
      ]);

      expect(progress.sessionCount, 2);
      expect(
        progress.bestWeightSeries.map((ProgressPoint p) => p.value).toList(),
        <double>[100000, 110000],
      );
      expect(progress.bestWeightGrams, 110000);
    });

    test('flags a best e1RM from 11–12 reps as less reliable', () {
      final ExerciseProgress normal = _progress(<Session>[
        _session('normal', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('normal-set', 100000, 10),
        ]),
      ]);
      expect(normal.bestOneRepMaxLessReliable, isFalse);
      expect(normal.bestOneRepMaxConfidence, E1rmConfidence.normal);

      final ExerciseProgress hinted = _progress(<Session>[
        _session('hinted', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('hinted-set', 100000, 11),
        ]),
      ]);
      expect(hinted.bestOneRepMaxLessReliable, isTrue);
      expect(hinted.bestOneRepMaxConfidence, E1rmConfidence.lessReliable);

      final ExerciseProgress hidden = _progress(<Session>[
        _session('hidden', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('hidden-set', 100000, 13),
        ]),
      ]);
      expect(hidden.bestOneRepMaxGrams, isNull);
      expect(hidden.bestOneRepMaxConfidence, isNull);
      expect(hidden.bestOneRepMaxLessReliable, isFalse);
    });

    test('the grouped pass equals the individual pass for every range', () {
      final DateTime now = DateTime.utc(2026, 10, 21, 12);
      final List<Session> sessions = <Session>[
        _session(
          'bench-recent',
          now.subtract(const Duration(days: 2)),
          <SetLog>[
            _set('bench-warmup', 150000, 5, warmup: true),
            _set('bench-1', 100000, 8, rir: 2, index: 1),
            _set('bench-2', 110000, 5, rir: 3, index: 2),
          ],
        ),
        _session('bench-mid', now.subtract(const Duration(days: 40)), <SetLog>[
          _set('bench-mid-1', 105000, 6),
        ]),
        _session('bench-old', now.subtract(const Duration(days: 200)), <SetLog>[
          _set('bench-old-1', 95000, 10),
        ]),
        _session(
          'bench-active',
          now.subtract(const Duration(days: 1)),
          <SetLog>[_set('bench-active-1', 200000, 5)],
          active: true,
        ),
        _session(
          'squat-recent',
          now.subtract(const Duration(days: 1)),
          <SetLog>[
            _set('squat-warmup', 60000, 5, warmup: true),
            _set('squat-1', 80000, 5, index: 1),
          ],
          exerciseId: 'squat',
        ),
        _session('squat-empty', now.subtract(const Duration(days: 3)), <SetLog>[
          _set('squat-warmup-2', 50000, 5, warmup: true),
        ], exerciseId: 'squat'),
      ];
      const List<String> ids = <String>[
        'bench',
        'squat',
        'never-trained',
        'unknown',
      ];

      for (final ProgressRange range in ProgressRange.values) {
        final Map<String, ExerciseProgress> grouped =
            prepareExerciseProgressMap(
              sessions: sessions,
              exerciseIds: ids,
              now: now,
              range: range,
            );
        expect(grouped.keys.toSet(), ids.toSet());
        for (final String id in ids) {
          _expectSameProgress(
            grouped[id]!,
            prepareExerciseProgress(
              sessions: sessions,
              exerciseId: id,
              now: now,
              range: range,
            ),
          );
        }
        expect(grouped['never-trained']!.hasHistory, isFalse);
        expect(grouped['never-trained']!.hasData, isFalse);
        expect(grouped['squat']!.hasHistory, isTrue);
      }
    });

    test('bodyweight sets have no e1RM but keep weight and reps', () {
      final ExerciseProgress progress = _progress(<Session>[
        _session('bodyweight', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('bw-set', 0, 5, rir: 0),
        ]),
      ]);

      expect(progress.sessionCount, 1);
      expect(progress.estimatedOneRepMaxSeries, hasLength(1));
      expect(progress.estimatedOneRepMaxSeries.single.value, isNull);
      expect(progress.bestOneRepMaxGrams, isNull);
      expect(progress.bestOneRepMaxConfidence, isNull);
      expect(progress.bestOneRepMaxLessReliable, isFalse);
      expect(progress.bestWeightGrams, 0.0);
      expect(progress.bestWeightSeries.single.value, 0.0);
      expect(progress.repsSeries.single.value, 5.0);
      expect(progress.rirSeries.single.value, 0.0);
    });

    test('an exercise without history has empty series and no bests', () {
      final ExerciseProgress progress = _progress(<Session>[
        _session('s1', DateTime.utc(2026, 10, 1), <SetLog>[
          _set('set-1', 100000, 5),
        ], exerciseId: 'squat'),
      ]);

      expect(progress.hasHistory, isFalse);
      expect(progress.sessionCount, 0);
      expect(progress.bestWeightSeries, isEmpty);
      expect(progress.estimatedOneRepMaxSeries, isEmpty);
      expect(progress.repsSeries, isEmpty);
      expect(progress.rirSeries, isEmpty);
      expect(progress.bestWeightGrams, isNull);
      expect(progress.bestOneRepMaxGrams, isNull);
    });
  });
}
