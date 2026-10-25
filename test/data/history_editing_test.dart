import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/app_data_store.dart';
import 'package:lift_core/lift_core.dart';

Future<File> _tempFile() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'gym_log_history_test_',
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

Future<AppData> _load(File file) {
  return _container(file).read(appDataControllerProvider.future);
}

Future<Session> _finishedSession(
  AppDataController controller,
  ProgramDay day,
) async {
  final Session started = await controller.startSession(programDayId: day.id);
  return controller.finishSession(started.id);
}

void main() {
  test('editing a set persists and changes the next prefill', () async {
    final File file = await _tempFile();
    final seeded = await _seedDay(file);
    final Session started = await seeded.controller.startSession(
      programDayId: seeded.day.id,
    );
    final SessionExercise exercise = started.exercises.single;
    final SetLog original = await seeded.controller.logSet(
      sessionId: started.id,
      sessionExerciseId: exercise.id,
      setIndex: 0,
      weightGrams: 100000,
      reps: 8,
      rir: 2,
    );
    await seeded.controller.finishSession(started.id);

    final SetLog edited = SetLog(
      id: original.id,
      setIndex: original.setIndex,
      weightGrams: 105000,
      reps: 12,
      loggedAt: original.loggedAt,
    );
    await seeded.controller.updateSet(
      sessionId: started.id,
      sessionExerciseId: exercise.id,
      set: edited,
    );

    final AppData reloaded = await _load(file);
    final SetLog restored =
        reloaded.sessions.single.exercises.single.sets.single;
    expect(restored.weightGrams, 105000);
    expect(restored.reps, 12);
    expect(restored.rir, isNull);
    expect(restored.setIndex, original.setIndex);
    expect(restored.loggedAt, original.loggedAt);

    final SetPrefill prefill = prefillForExercise(
      sessions: reloaded.sessions,
      exerciseId: seeded.exercise.id,
      setIndex: 0,
    );
    expect(prefill.weightGrams, 105000);
    expect(prefill.reps, 12);
    expect(prefill.rir, isNull);
  });

  test(
    'deleting a set leaves no orphan and Undo restores it exactly',
    () async {
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
      final SetLog second = await seeded.controller.logSet(
        sessionId: started.id,
        sessionExerciseId: exercise.id,
        setIndex: 1,
        weightGrams: 97500,
        reps: 7,
      );
      await seeded.controller.finishSession(started.id);

      final AppData before = await _load(file);
      final Map<String, Object?> beforeSession = before.sessions.single
          .toJson();
      final SetLog removed = await seeded.controller.deleteSet(
        sessionId: started.id,
        sessionExerciseId: exercise.id,
        setId: second.id,
      );
      expect(removed.id, second.id);

      final AppData afterDelete = await _load(file);
      expect(afterDelete.sessions.single.exercises.single.sets, hasLength(1));
      expect(
        afterDelete.sessions.single.exercises.single.sets.single.id,
        isNot(second.id),
      );
      expect(await file.readAsString(), isNot(contains(second.id)));

      await seeded.controller.restoreSet(
        sessionId: started.id,
        sessionExerciseId: exercise.id,
        set: removed,
      );

      final AppData afterUndo = await _load(file);
      expect(afterUndo.sessions.single.toJson(), beforeSession);
    },
  );

  test('deleting a session removes its nested sets from storage', () async {
    final File file = await _tempFile();
    final seeded = await _seedDay(file);
    final Session firstStarted = await seeded.controller.startSession(
      programDayId: seeded.day.id,
    );
    final SetLog firstSet = await seeded.controller.logSet(
      sessionId: firstStarted.id,
      sessionExerciseId: firstStarted.exercises.single.id,
      setIndex: 0,
      weightGrams: 100000,
      reps: 8,
    );
    final Session first = await seeded.controller.finishSession(
      firstStarted.id,
    );
    final Session second = await _finishedSession(
      seeded.controller,
      seeded.day,
    );

    final Session removed = await seeded.controller.deleteSession(first.id);
    expect(removed.id, first.id);

    final AppData reloaded = await _load(file);
    expect(reloaded.sessions.map((Session session) => session.id), <String>[
      second.id,
    ]);
    final String contents = await file.readAsString();
    expect(contents, isNot(contains(first.id)));
    expect(contents, isNot(contains(firstSet.id)));
  });

  test('session and exercise notes persist and can be cleared', () async {
    final File file = await _tempFile();
    final seeded = await _seedDay(file);
    final Session started = await seeded.controller.startSession(
      programDayId: seeded.day.id,
    );
    final SessionExercise exercise = started.exercises.single;

    await seeded.controller.setSessionNote(
      started.id,
      '  Heavy day, sleep was short.  ',
    );
    await seeded.controller.setSessionExerciseNote(
      sessionId: started.id,
      sessionExerciseId: exercise.id,
      note: 'Pause on the chest.',
    );

    final AppData reloaded = await _load(file);
    final Session restored = reloaded.sessions.single;
    expect(restored.note, 'Heavy day, sleep was short.');
    expect(restored.exercises.single.note, 'Pause on the chest.');

    await seeded.controller.setSessionNote(started.id, '   ');
    await seeded.controller.setSessionExerciseNote(
      sessionId: started.id,
      sessionExerciseId: exercise.id,
      note: null,
    );
    final AppData cleared = await _load(file);
    expect(cleared.sessions.single.note, isNull);
    expect(cleared.sessions.single.exercises.single.note, isNull);
  });
}
