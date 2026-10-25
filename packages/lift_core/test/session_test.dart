import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

SetLog _set(String id, {int? rir, bool warmup = false, int order = 0}) {
  return SetLog(
    id: id,
    setIndex: order,
    weightGrams: 100000,
    reps: 8,
    rir: rir,
    isWarmup: warmup,
    loggedAt: DateTime.utc(2026, 10, 21, 10),
  );
}

SessionExercise _exercise({
  String id = 'session-exercise-1',
  String exerciseId = 'exercise-1',
  List<SetLog> sets = const <SetLog>[],
}) {
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

Session _session({
  String id = 'session-1',
  DateTime? endedAt,
  List<SessionExercise>? exercises,
}) {
  return Session(
    id: id,
    startedAt: DateTime.utc(2026, 10, 21, 10),
    endedAt: endedAt,
    programDayId: 'day-1',
    exercises: exercises ?? <SessionExercise>[_exercise()],
  );
}

Exercise _exerciseRecord() {
  return Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    createdAt: DateTime.utc(2026, 10, 20, 10),
  );
}

void main() {
  group('SetLog', () {
    test('round-trips with null RIR and warm-up flag', () {
      final SetLog original = SetLog(
        id: 'set-1',
        weightGrams: 20412,
        reps: 5,
        rir: null,
        isWarmup: true,
        setIndex: 2,
        loggedAt: DateTime.utc(2026, 10, 21, 10),
      );

      final SetLog restored = SetLog.fromJson(original.toJson());

      expect(restored.weightGrams, 20412);
      expect(restored.reps, 5);
      expect(restored.rir, isNull);
      expect(restored.isWarmup, isTrue);
      expect(restored.setIndex, 2);
      expect(restored.loggedAt, DateTime.utc(2026, 10, 21, 10));
    });

    test('rejects values outside the schema', () {
      expect(
        () => SetLog(
          id: 'set-1',
          setIndex: -1,
          weightGrams: 1000,
          reps: 8,
          loggedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
      expect(
        () => SetLog(
          id: 'set-1',
          setIndex: maximumTargetSets,
          weightGrams: 1000,
          reps: 8,
          loggedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
      expect(
        () => SetLog(
          id: 'set-1',
          setIndex: 0,
          weightGrams: -1,
          reps: 8,
          loggedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
      expect(
        () => SetLog(
          id: 'set-1',
          setIndex: 0,
          weightGrams: maximumSetWeightGrams + 1,
          reps: 8,
          loggedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
      expect(
        () => SetLog(
          id: 'set-1',
          setIndex: 0,
          weightGrams: 1000,
          reps: 0,
          loggedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
      expect(
        () => SetLog(
          id: 'set-1',
          setIndex: 0,
          weightGrams: 1000,
          reps: 8,
          rir: 6,
          loggedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
    });
  });

  group('SessionExercise and Session', () {
    test('keeps working sets and ignores warm-ups', () {
      final SessionExercise exercise = _exercise(
        sets: <SetLog>[
          _set('warm', warmup: true, order: 0),
          _set('work-1', order: 1),
          _set('work-2', order: 2),
        ],
      );

      expect(exercise.sets.map((SetLog set) => set.id), <String>[
        'warm',
        'work-1',
        'work-2',
      ]);
      expect(exercise.workingSets.map((SetLog set) => set.id), <String>[
        'work-1',
        'work-2',
      ]);
      expect(exercise.workingSets.last.id, 'work-2');
    });

    test('normalizes notes and enforces the documented limit', () {
      final Session session = Session(
        id: 'session-1',
        startedAt: DateTime.utc(2026, 10, 21, 10),
        note: '  felt strong  ',
        exercises: <SessionExercise>[
          SessionExercise(
            id: 'session-exercise-1',
            exerciseId: 'exercise-1',
            sortOrder: 0,
            note: '  elbow tucked  ',
          ),
        ],
      );

      expect(session.note, 'felt strong');
      expect(session.exercises.single.note, 'elbow tucked');
      expect(
        Session(
          id: 'session-2',
          startedAt: DateTime.utc(2026, 10, 21, 10),
          note: '   ',
        ).note,
        isNull,
      );
      expect(
        () => Session(
          id: 'session-2',
          startedAt: DateTime.utc(2026, 10, 21, 10),
          note: 'x' * (maximumNoteLength + 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => Session(
          id: 'session-2',
          startedAt: DateTime.utc(2026, 10, 21, 10),
          note: 'x' * maximumNoteLength,
        ),
        returnsNormally,
      );
      expect(
        () => SessionExercise(
          id: 'session-exercise-2',
          exerciseId: 'exercise-1',
          sortOrder: 0,
          note: 'x' * (maximumNoteLength + 1),
        ),
        throwsArgumentError,
      );

      final Session restored = Session.fromJson(session.toJson());
      expect(restored.note, 'felt strong');
      expect(restored.exercises.single.note, 'elbow tucked');
    });

    test('round-trips nested sessions with explicit nulls', () {
      final Session original = _session(
        endedAt: DateTime.utc(2026, 10, 21, 11),
        exercises: <SessionExercise>[
          _exercise(sets: <SetLog>[_set('set-1', rir: 2)]),
        ],
      );

      final Map<String, Object?> json = original.toJson();
      final Session restored = Session.fromJson(json);

      expect(restored.id, 'session-1');
      expect(restored.programDayId, 'day-1');
      expect(restored.endedAt, DateTime.utc(2026, 10, 21, 11));
      expect(restored.exercises.single.targetSets, 3);
      expect(restored.exercises.single.sets.single.rir, 2);
      expect(restored.exercises.single.sets.single.loggedAt.isUtc, isTrue);
      expect(json['endedAt'], isNotNull);
      expect(json['exercises'], isA<List<Object?>>());
    });

    test('rejects an end before the start and duplicate exercise entries', () {
      expect(
        () => _session(endedAt: DateTime.utc(2026, 10, 21, 9)),
        throwsArgumentError,
      );
      expect(
        () => _session(exercises: <SessionExercise>[_exercise(), _exercise()]),
        throwsArgumentError,
      );
      expect(
        () => _exercise(sets: <SetLog>[_set('same'), _set('same')]),
        throwsArgumentError,
      );
      expect(
        () => _exercise(sets: <SetLog>[_set('a'), _set('b')]),
        throwsArgumentError,
      );
    });

    test('requires rep bounds together and valid targets', () {
      expect(
        () => SessionExercise(
          id: 'session-exercise-1',
          exerciseId: 'exercise-1',
          sortOrder: 0,
          targetSets: 3,
          repMin: 8,
        ),
        throwsArgumentError,
      );
      expect(
        () => SessionExercise(
          id: 'session-exercise-1',
          exerciseId: 'exercise-1',
          sortOrder: 0,
          targetSets: 0,
          repMin: 8,
          repMax: 12,
        ),
        throwsArgumentError,
      );
    });
  });

  group('AppData', () {
    test('round-trips sessions and settings', () {
      final AppData original = AppData(
        exercises: <Exercise>[_exerciseRecord()],
        sessions: <Session>[_session(endedAt: DateTime.utc(2026, 10, 21, 11))],
        settings: const AppSettings(
          weightUnit: WeightUnit.pounds,
          restTimerEnabled: true,
          restTimerDurationSeconds: 120,
        ),
      );

      final AppData restored = AppData.fromJson(original.toJson());

      expect(restored.sessions.single.id, 'session-1');
      expect(restored.settings.weightUnit, WeightUnit.pounds);
      expect(restored.settings.restTimerEnabled, isTrue);
      expect(restored.settings.restTimerDurationSeconds, 120);
      expect(restored.toJson()['schemaVersion'], appDataSchemaVersion);
    });

    test('rejects an out-of-range rest duration on the read path', () {
      expect(
        () => AppSettings.fromJson(<String, Object?>{
          'weightUnit': 'kilograms',
          'restTimerDurationSeconds': maximumRestTimerSeconds + 1,
        }),
        throwsFormatException,
      );
    });

    test('reads a version 1 document with empty history and defaults', () {
      final AppData restored = AppData.fromJson(<String, Object?>{
        'schemaVersion': 1,
        'exercises': <Object?>[_exerciseRecord().toJson()],
        'programs': const <Object?>[],
      });

      expect(restored.sessions, isEmpty);
      expect(restored.settings.weightUnit, WeightUnit.kilograms);
    });

    test('rejects a tampered set index on the read path', () {
      final Map<String, Object?> json = _session(
        endedAt: DateTime.utc(2026, 10, 21, 11),
        exercises: <SessionExercise>[
          _exercise(sets: <SetLog>[_set('set-1')]),
        ],
      ).toJson();
      final List<Object?> exercises = json['exercises']! as List<Object?>;
      final Map<String, Object?> sessionExercise =
          (exercises.first! as Map<Object?, Object?>).cast<String, Object?>();
      final List<Object?> sets = sessionExercise['sets']! as List<Object?>;
      (sets.first! as Map<Object?, Object?>)['setIndex'] = 1000000000;

      expect(() => Session.fromJson(json), throwsArgumentError);
    });

    test(
      'rejects multiple active sessions and missing exercise references',
      () {
        expect(
          () => AppData(
            exercises: <Exercise>[_exerciseRecord()],
            sessions: <Session>[
              _session(),
              _session(id: 'session-2'),
            ],
          ),
          throwsArgumentError,
        );
        expect(
          () => AppData(
            exercises: <Exercise>[_exerciseRecord()],
            sessions: <Session>[
              _session(
                endedAt: DateTime.utc(2026, 10, 21, 11),
                exercises: <SessionExercise>[_exercise(exerciseId: 'missing')],
              ),
            ],
          ),
          throwsFormatException,
        );
      },
    );

    test('rejects duplicate set and session ids across the document', () {
      expect(
        () => AppData(
          exercises: <Exercise>[_exerciseRecord()],
          sessions: <Session>[
            _session(
              endedAt: DateTime.utc(2026, 10, 21, 11),
              exercises: <SessionExercise>[
                _exercise(sets: <SetLog>[_set('duplicate-set')]),
              ],
            ),
            _session(
              id: 'session-2',
              endedAt: DateTime.utc(2026, 10, 21, 12),
              exercises: <SessionExercise>[
                _exercise(
                  id: 'session-exercise-2',
                  sets: <SetLog>[_set('duplicate-set')],
                ),
              ],
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
