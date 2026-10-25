import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/app_data_store.dart';
import 'package:lift_core/lift_core.dart';

Future<File> _tempFile() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'gym_log_workout_test_',
  );
  addTearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });
  return File('${directory.path}${Platform.pathSeparator}data.json');
}

ProviderContainer _container(File file) {
  return ProviderContainer.test(
    overrides: [
      appDataFileProvider.overrideWithValue(Future<File>.value(file)),
    ],
  );
}

Future<
  ({
    ProviderContainer container,
    AppDataController controller,
    Exercise exercise,
    ProgramDay day,
  })
>
_seedDay(File file) async {
  final ProviderContainer container = _container(file);
  await container.read(appDataControllerProvider.future);
  final AppDataController controller = container.read(
    appDataControllerProvider.notifier,
  );
  final Exercise exercise = await controller.createExercise(
    name: 'Bench Press',
  );
  final Program program = await controller.createProgram('Upper/Lower');
  final ProgramDay day = await controller.addDay(program.id, 'Upper');
  await controller.addPlanItem(
    dayId: day.id,
    exerciseId: exercise.id,
    targetSets: 3,
    repMin: 8,
    repMax: 12,
  );
  return (
    container: container,
    controller: controller,
    exercise: exercise,
    day: day,
  );
}

void main() {
  test('active session and all sets survive a reload', () async {
    final File file = await _tempFile();
    final seeded = await _seedDay(file);
    final Session started = await seeded.controller.startSession(
      programDayId: seeded.day.id,
    );
    final SessionExercise exercise = started.exercises.single;

    await seeded.controller.logSet(
      sessionId: started.id,
      sessionExerciseId: exercise.id,
      setIndex: 0,
      weightGrams: 100000,
      reps: 8,
      rir: 2,
    );
    await seeded.controller.logSet(
      sessionId: started.id,
      sessionExerciseId: exercise.id,
      setIndex: 1,
      weightGrams: 20412,
      reps: 7,
    );
    await seeded.controller.logSet(
      sessionId: started.id,
      sessionExerciseId: exercise.id,
      setIndex: 2,
      weightGrams: 60000,
      reps: 10,
      isWarmup: true,
    );

    final AppData reloaded = await _container(file)
        .read(appDataControllerProvider.future);
    final Session active = reloaded.activeSession!;

    expect(active.id, started.id);
    expect(active.isActive, isTrue);
    expect(active.programDayId, seeded.day.id);
    final SessionExercise restoredExercise = active.exercises.single;
    expect(restoredExercise.exerciseId, seeded.exercise.id);
    expect(restoredExercise.targetSets, 3);
    expect(restoredExercise.repMin, 8);
    expect(restoredExercise.repMax, 12);
    expect(restoredExercise.sets, hasLength(3));
    expect(restoredExercise.sets[0].weightGrams, 100000);
    expect(restoredExercise.sets[0].reps, 8);
    expect(restoredExercise.sets[0].rir, 2);
    expect(restoredExercise.sets[1].weightGrams, 20412);
    expect(restoredExercise.sets[1].rir, isNull);
    expect(restoredExercise.sets[2].isWarmup, isTrue);
    expect(restoredExercise.sets[2].weightGrams, 60000);
    expect(restoredExercise.workingSets, hasLength(2));
  });

  test('each check writes through before the controller returns', () async {
    final File file = await _tempFile();
    final seeded = await _seedDay(file);
    final Session started = await seeded.controller.startSession();
    final SessionExercise sessionExercise = (await seeded.controller
        .addExerciseToSession(
          sessionId: started.id,
          exerciseId: seeded.exercise.id,
        ));

    await seeded.controller.logSet(
      sessionId: started.id,
      sessionExerciseId: sessionExercise.id,
      setIndex: 0,
      weightGrams: 80500,
      reps: 8,
    );

    final AppData onDisk = await JsonAppDataStore(Future<File>.value(file))
        .load();
    final SetLog written = onDisk.activeSession!.exercises.single.sets.single;
    expect(written.weightGrams, 80500);
    expect(written.reps, 8);
    expect(written.rir, isNull);
  });

  test('sets keep their row position when logged out of order', () async {
    final File file = await _tempFile();
    final seeded = await _seedDay(file);
    final Session started = await seeded.controller.startSession(
      programDayId: seeded.day.id,
    );
    final SessionExercise exercise = started.exercises.single;

    await seeded.controller.logSet(
      sessionId: started.id,
      sessionExerciseId: exercise.id,
      setIndex: 2,
      weightGrams: 90000,
      reps: 6,
    );
    await seeded.controller.logSet(
      sessionId: started.id,
      sessionExerciseId: exercise.id,
      setIndex: 0,
      weightGrams: 100000,
      reps: 8,
    );

    final AppData reloaded = await _container(file)
        .read(appDataControllerProvider.future);
    final List<SetLog> sets = reloaded.activeSession!.exercises.single.sets;
    expect(sets.map((SetLog set) => set.setIndex), <int>[0, 2]);
    expect(sets.map((SetLog set) => set.weightGrams), <int>[100000, 90000]);
    expect(sets.map((SetLog set) => set.reps), <int>[8, 6]);
  });

  test('the same row cannot be committed twice', () async {
    final File file = await _tempFile();
    final seeded = await _seedDay(file);
    final Session started = await seeded.controller.startSession();
    final SessionExercise exercise = await seeded.controller
        .addExerciseToSession(
          sessionId: started.id,
          exerciseId: seeded.exercise.id,
        );

    await seeded.controller.logSet(
      sessionId: started.id,
      sessionExerciseId: exercise.id,
      setIndex: 0,
      weightGrams: 100000,
      reps: 8,
    );
    await expectLater(
      seeded.controller.logSet(
        sessionId: started.id,
        sessionExerciseId: exercise.id,
        setIndex: 0,
        weightGrams: 100000,
        reps: 8,
      ),
      throwsStateError,
    );
  });

  test('switching units never changes stored sessions', () async {
    final File file = await _tempFile();
    final seeded = await _seedDay(file);
    final Session started = await seeded.controller.startSession(
      programDayId: seeded.day.id,
    );
    await seeded.controller.logSet(
      sessionId: started.id,
      sessionExerciseId: started.exercises.single.id,
      setIndex: 0,
      weightGrams: 20412,
      reps: 8,
    );

    final AppData before = await _container(file)
        .read(appDataControllerProvider.future);
    final List<Map<String, Object?>> sessionsBefore = <Map<String, Object?>>[
      for (final Session session in before.sessions) session.toJson(),
    ];

    await seeded.controller.setWeightUnit(WeightUnit.pounds);
    final AppData pounds = await _container(file)
        .read(appDataControllerProvider.future);
    expect(pounds.settings.weightUnit, WeightUnit.pounds);
    expect(<Map<String, Object?>>[
      for (final Session session in pounds.sessions) session.toJson(),
    ], sessionsBefore);

    await seeded.controller.setWeightUnit(WeightUnit.kilograms);
    final AppData kilograms = await _container(file)
        .read(appDataControllerProvider.future);
    expect(kilograms.settings.weightUnit, WeightUnit.kilograms);
    expect(<Map<String, Object?>>[
      for (final Session session in kilograms.sessions) session.toJson(),
    ], sessionsBefore);
    expect(
      kilograms.sessions.single.exercises.single.sets.single.weightGrams,
      20412,
    );
  });

  test('finishing keeps logged history and releases the active slot', () async {
    final File file = await _tempFile();
    final seeded = await _seedDay(file);
    final Session started = await seeded.controller.startSession(
      programDayId: seeded.day.id,
    );
    await seeded.controller.logSet(
      sessionId: started.id,
      sessionExerciseId: started.exercises.single.id,
      setIndex: 0,
      weightGrams: 100000,
      reps: 8,
    );

    final Session finished = await seeded.controller.finishSession(started.id);
    expect(finished.isActive, isFalse);
    expect(finished.endedAt, isNotNull);

    final AppData reloaded = await _container(file)
        .read(appDataControllerProvider.future);
    expect(reloaded.activeSession, isNull);
    expect(reloaded.sessions.single.endedAt, isNotNull);
    expect(reloaded.sessions.single.exercises.single.sets, hasLength(1));

    final Session next = await seeded.controller.startSession(
      programDayId: seeded.day.id,
    );
    expect(next.id, isNot(started.id));
    final AppData afterNext = await _container(file)
        .read(appDataControllerProvider.future);
    expect(afterNext.sessions, hasLength(2));
    expect(afterNext.activeSession?.id, next.id);
    expect(afterNext.sessions.first.endedAt, isNotNull);
  });
}
