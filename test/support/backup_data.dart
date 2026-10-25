import 'package:lift_core/lift_core.dart';

final DateTime backupTestExportedAt = DateTime.utc(2026, 10, 22, 12);

AppData backupSampleData() {
  final Exercise bench = Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    searchTerm: 'bench',
    muscleGroup: MuscleGroup.chest,
    defaultRepMin: 8,
    defaultRepMax: 12,
    createdAt: DateTime.utc(2026, 9, 1, 10),
  );
  final Exercise squat = Exercise(
    id: 'exercise-2',
    name: 'Squat',
    createdAt: DateTime.utc(2026, 9, 2, 10),
  );
  final Program program = Program(
    id: 'program-1',
    name: 'Upper/Lower',
    createdAt: DateTime.utc(2026, 9, 3, 10),
    days: <ProgramDay>[
      ProgramDay(
        id: 'day-1',
        name: 'Upper',
        sortOrder: 0,
        items: <PlanItem>[
          PlanItem(
            id: 'item-1',
            exerciseId: bench.id,
            targetSets: 3,
            repMin: 8,
            repMax: 12,
            sortOrder: 0,
          ),
        ],
      ),
    ],
  );
  final Session session = Session(
    id: 'session-1',
    startedAt: DateTime.utc(2026, 9, 4, 17),
    endedAt: DateTime.utc(2026, 9, 4, 18, 30),
    programDayId: 'day-1',
    note: 'Good day',
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'session-exercise-1',
        exerciseId: bench.id,
        sortOrder: 0,
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        note: 'Felt strong',
        sets: <SetLog>[
          SetLog(
            id: 'set-1',
            weightGrams: 80000,
            reps: 10,
            rir: 2,
            setIndex: 0,
            loggedAt: DateTime.utc(2026, 9, 4, 18),
          ),
        ],
      ),
    ],
  );
  return AppData(
    exercises: <Exercise>[bench, squat],
    programs: <Program>[program],
    sessions: <Session>[session],
    settings: const AppSettings(
      weightUnit: WeightUnit.pounds,
      digitStyle: DigitStyle.persian,
      defaultIncrementGrams: 5000,
      restTimerEnabled: true,
      restTimerDurationSeconds: 120,
    ),
  );
}

String backupJson({
  AppData? data,
  String appVersion = '0.1.0',
  DateTime? exportedAt,
}) {
  return buildBackupJson(
    data ?? backupSampleData(),
    appVersion: appVersion,
    exportedAt: exportedAt ?? backupTestExportedAt,
  );
}

AppData backupTenThousandSetData() {
  final Exercise exercise = Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    createdAt: DateTime.utc(2026, 9, 1, 10),
  );
  final List<SessionExercise> exercises = <SessionExercise>[];
  for (int exerciseIndex = 0; exerciseIndex < 100; exerciseIndex += 1) {
    final List<SetLog> sets = <SetLog>[];
    for (int setIndex = 0; setIndex < 100; setIndex += 1) {
      sets.add(
        SetLog(
          id: 'set-$exerciseIndex-$setIndex',
          weightGrams: 60000 + setIndex * 2500,
          reps: 5 + (setIndex % 8),
          rir: setIndex % 6,
          isWarmup: setIndex == 0,
          setIndex: setIndex,
          loggedAt: DateTime.utc(
            2026,
            9,
            4,
            17,
          ).add(Duration(minutes: exerciseIndex * 3 + setIndex)),
        ),
      );
    }
    exercises.add(
      SessionExercise(
        id: 'session-exercise-$exerciseIndex',
        exerciseId: exercise.id,
        sortOrder: exerciseIndex,
        sets: sets,
      ),
    );
  }
  return AppData(
    exercises: <Exercise>[exercise],
    sessions: <Session>[
      Session(
        id: 'session-1',
        startedAt: DateTime.utc(2026, 9, 4, 17),
        endedAt: DateTime.utc(2026, 9, 4, 22),
        exercises: exercises,
      ),
    ],
  );
}
