import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

Exercise _exercise(String id, String name, {MuscleGroup? muscleGroup}) {
  return Exercise(
    id: id,
    name: name,
    muscleGroup: muscleGroup,
    createdAt: DateTime.utc(2026, 9, 1),
  );
}

SetLog _set(
  String id,
  int index,
  int weightGrams,
  int reps,
  DateTime localTime, {
  bool warmup = false,
  int? rir,
}) {
  return SetLog(
    id: id,
    setIndex: index,
    weightGrams: weightGrams,
    reps: reps,
    isWarmup: warmup,
    rir: rir,
    loggedAt: localTime.toUtc(),
  );
}

SessionExercise _block(
  String id,
  String exerciseId,
  List<SetLog> sets, {
  int sortOrder = 0,
}) {
  return SessionExercise(
    id: id,
    exerciseId: exerciseId,
    sortOrder: sortOrder,
    sets: sets,
  );
}

Session _session(
  String id,
  DateTime startLocal,
  DateTime? endLocal,
  List<SessionExercise> exercises,
) {
  return Session(
    id: id,
    startedAt: startLocal.toUtc(),
    endedAt: endLocal?.toUtc(),
    exercises: exercises,
  );
}

List<Exercise> _exercises() {
  return <Exercise>[
    _exercise('bench', 'Bench Press', muscleGroup: MuscleGroup.chest),
    _exercise('squat', 'Squat', muscleGroup: MuscleGroup.quadriceps),
    _exercise('row', 'Row', muscleGroup: MuscleGroup.back),
    _exercise('curl', 'Curl', muscleGroup: MuscleGroup.biceps),
  ];
}

void main() {
  group('sessionStatsFor', () {
    test('excludes warm-ups from sets and volume but counts them', () {
      final Session session = _session(
        'session-1',
        DateTime(2026, 10, 21, 18),
        DateTime(2026, 10, 21, 19, 20),
        <SessionExercise>[
          _block('block-1', 'bench', <SetLog>[
            _set('w-1', 0, 40000, 10, DateTime(2026, 10, 21, 18), warmup: true),
            _set('s-1', 1, 80000, 8, DateTime(2026, 10, 21, 18, 5)),
            _set('s-2', 2, 80000, 7, DateTime(2026, 10, 21, 18, 20)),
          ]),
        ],
      );

      final SessionStats stats = sessionStatsFor(
        session,
        exercises: _exercises(),
      );

      expect(stats.duration, const Duration(minutes: 80));
      expect(stats.setCount, 3);
      expect(stats.workingSetCount, 2);
      expect(stats.volumeGrams, 80000 * 8 + 80000 * 7);
      expect(stats.exercises.single.setSpan, const Duration(minutes: 20));
      expect(stats.workingSetsByMuscle, <MuscleGroup?, int>{
        MuscleGroup.chest: 2,
      });
    });

    test('uses the clock for an active session and never goes negative', () {
      final Session active = _session(
        'active',
        DateTime(2026, 10, 21, 18),
        null,
        <SessionExercise>[
          _block('block-1', 'row', <SetLog>[
            _set('s-1', 0, 60000, 10, DateTime(2026, 10, 21, 18, 5)),
          ]),
        ],
      );
      final SessionStats stats = sessionStatsFor(
        active,
        exercises: _exercises(),
        now: DateTime(2026, 10, 21, 18, 45),
      );
      expect(stats.duration, const Duration(minutes: 45));
      expect(stats.exercises.single.setSpan, Duration.zero);
      final SessionStats noClock = sessionStatsFor(
        active,
        exercises: _exercises(),
      );
      expect(noClock.duration, isNull);
    });

    test('buckets an unassigned exercise under the null muscle key', () {
      final Session session = _session(
        'session-1',
        DateTime(2026, 10, 21, 18),
        DateTime(2026, 10, 21, 19),
        <SessionExercise>[
          _block('block-1', 'curl', <SetLog>[
            _set('s-1', 0, 20000, 12, DateTime(2026, 10, 21, 18, 10)),
          ]),
          _block('block-2', 'mystery', <SetLog>[
            _set('s-2', 0, 30000, 10, DateTime(2026, 10, 21, 18, 30)),
          ], sortOrder: 1),
        ],
      );
      final SessionStats stats = sessionStatsFor(
        session,
        exercises: _exercises(),
      );
      expect(stats.workingSetsByMuscle[MuscleGroup.biceps], 1);
      expect(stats.workingSetsByMuscle[null], 1);
    });
  });

  group('recentWeekStats', () {
    final DateTime now = DateTime(2026, 10, 21, 12);

    test('returns the requested weeks oldest first with gaps', () {
      final List<WeekStats> weeks = recentWeekStats(
        sessions: <Session>[
          _session(
            'this-week',
            DateTime(2026, 10, 19, 18),
            DateTime(2026, 10, 19, 19),
            <SessionExercise>[
              _block('block-1', 'bench', <SetLog>[
                _set('s-1', 0, 100000, 5, DateTime(2026, 10, 19, 18, 10)),
              ]),
            ],
          ),
          _session(
            'three-weeks-ago',
            DateTime(2026, 9, 30, 18),
            DateTime(2026, 9, 30, 19),
            <SessionExercise>[
              _block('block-2', 'squat', <SetLog>[
                _set('s-2', 0, 120000, 3, DateTime(2026, 9, 30, 18, 10)),
              ]),
            ],
          ),
        ],
        exercises: _exercises(),
        bodyWeights: <BodyWeightEntry>[
          BodyWeightEntry(
            id: 'w-1',
            weightGrams: 80000,
            recordedAt: DateTime(2026, 10, 18, 8).toUtc(),
          ),
        ],
        now: now,
        weekStartsOn: DateTime.saturday,
        weeks: 4,
      );

      expect(weeks, hasLength(4));
      expect(weeks.first.weekStart, DateTime(2026, 9, 26));
      expect(weeks.first.weekStart, DateTime(2026, 9, 26));
      expect(weeks.first.sessionCount, 1);
      expect(weeks.first.workingSetsByMuscle[MuscleGroup.quadriceps], 1);
      expect(weeks[1].weekStart, DateTime(2026, 10, 3));
      expect(weeks[1].hasTraining, isFalse);
      expect(weeks.last.weekStart, DateTime(2026, 10, 17));
      expect(weeks.last.isCurrentWeek, isTrue);
      expect(weeks.last.sessionCount, 1);
      expect(weeks.last.volumeGrams, 500000);
      expect(weeks.last.workingSetsByMuscle[MuscleGroup.chest], 1);
      expect(weeks.last.bodyWeight?.entry?.weightGrams, 80000);
    });

    test('ignores the active session', () {
      final List<WeekStats> weeks = recentWeekStats(
        sessions: <Session>[
          _session(
            'active',
            DateTime(2026, 10, 21, 10),
            null,
            <SessionExercise>[
              _block('block-1', 'bench', <SetLog>[
                _set('s-1', 0, 100000, 5, DateTime(2026, 10, 21, 10, 10)),
              ]),
            ],
          ),
        ],
        exercises: _exercises(),
        bodyWeights: const <BodyWeightEntry>[],
        now: now,
        weeks: 2,
      );
      expect(weeks.every((WeekStats week) => !week.hasTraining), isTrue);
    });
  });

  group('exerciseTrainingStats', () {
    test('omits one-set sessions from the time average', () {
      final List<Session> sessions = <Session>[
        _session(
          'single',
          DateTime(2026, 10, 7, 18),
          DateTime(2026, 10, 7, 18, 30),
          <SessionExercise>[
            _block('b-1', 'bench', <SetLog>[
              _set('s-1', 0, 80000, 8, DateTime(2026, 10, 7, 18, 5)),
            ]),
          ],
        ),
        _session(
          'double',
          DateTime(2026, 10, 14, 18),
          DateTime(2026, 10, 14, 19),
          <SessionExercise>[
            _block('b-2', 'bench', <SetLog>[
              _set('s-2', 0, 80000, 8, DateTime(2026, 10, 14, 18)),
              _set('s-3', 1, 80000, 8, DateTime(2026, 10, 14, 18, 10)),
            ]),
          ],
        ),
      ];
      final ExerciseTrainingStats stats = exerciseTrainingStats(
        sessions: sessions,
        exerciseId: 'bench',
      );
      expect(stats.spanSessionCount, 1);
      expect(stats.totalSpan, const Duration(minutes: 10));
      expect(stats.averageSpan, const Duration(minutes: 10));
    });

    test('sums working sets, volume, and block spans across sessions', () {
      final List<Session> sessions = <Session>[
        _session(
          's-1',
          DateTime(2026, 10, 14, 18),
          DateTime(2026, 10, 14, 19),
          <SessionExercise>[
            _block('b-1', 'bench', <SetLog>[
              _set('s-1', 0, 80000, 8, DateTime(2026, 10, 14, 18)),
              _set('s-2', 1, 80000, 8, DateTime(2026, 10, 14, 18, 10)),
              _set(
                's-3',
                2,
                40000,
                10,
                DateTime(2026, 10, 14, 18, 2),
                warmup: true,
              ),
            ]),
          ],
        ),
        _session(
          's-2',
          DateTime(2026, 10, 21, 18),
          DateTime(2026, 10, 21, 19),
          <SessionExercise>[
            _block('b-2', 'bench', <SetLog>[
              _set('s-4', 0, 82500, 8, DateTime(2026, 10, 21, 18)),
              _set('s-5', 1, 82500, 7, DateTime(2026, 10, 21, 18, 6)),
            ]),
          ],
        ),
      ];

      final ExerciseTrainingStats stats = exerciseTrainingStats(
        sessions: sessions,
        exerciseId: 'bench',
      );

      expect(stats.sessionCount, 2);
      expect(stats.workingSetCount, 4);
      expect(stats.volumeGrams, 80000 * 8 * 2 + 82500 * 8 + 82500 * 7);
      expect(stats.totalSpan, const Duration(minutes: 16));
      expect(stats.averageSpan, const Duration(minutes: 8));
      expect(stats.lastTrainedAt, DateTime(2026, 10, 21, 18).toUtc());
    });
  });

  group('latestFinishedSessionStats', () {
    test('picks the latest finished session and ignores the active one', () {
      final SessionStats? stats = latestFinishedSessionStats(<Session>[
        _session(
          'older',
          DateTime(2026, 10, 14, 18),
          DateTime(2026, 10, 14, 19),
          <SessionExercise>[_block('b-1', 'bench', const <SetLog>[])],
        ),
        _session('active', DateTime(2026, 10, 22, 18), null, <SessionExercise>[
          _block('b-2', 'bench', const <SetLog>[]),
        ]),
        _session(
          'newer',
          DateTime(2026, 10, 21, 18),
          DateTime(2026, 10, 21, 19),
          <SessionExercise>[_block('b-3', 'bench', const <SetLog>[])],
        ),
      ], exercises: _exercises());
      expect(stats?.sessionId, 'newer');
    });
  });
}
