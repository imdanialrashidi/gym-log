import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/app_data_store.dart';
import 'package:lift_core/lift_core.dart';

Future<File> _tempFile() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'gym_log_controller_test_',
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

Future<AppData> _load(File file) async {
  return _container(file).read(appDataControllerProvider.future);
}

void main() {
  test('reordering days and plan items persists across a restart', () async {
    final File file = await _tempFile();
    final ProviderContainer container = _container(file);
    await container.read(appDataControllerProvider.future);
    final AppDataController controller = container.read(
      appDataControllerProvider.notifier,
    );

    final Exercise exercise = await controller.createExercise(
      name: 'Bench Press',
    );
    final Program program = await controller.createProgram('Upper/Lower');
    final ProgramDay upper = await controller.addDay(program.id, 'Upper');
    final ProgramDay lower = await controller.addDay(program.id, 'Lower');
    await controller.addPlanItem(
      dayId: upper.id,
      exerciseId: exercise.id,
      targetSets: 3,
      repMin: 8,
      repMax: 12,
    );
    await controller.addPlanItem(
      dayId: upper.id,
      exerciseId: exercise.id,
      targetSets: 4,
      repMin: 5,
      repMax: 8,
    );

    await controller.reorderDays(program.id, 0, 1);
    await controller.reorderPlanItems(upper.id, 0, 1);

    final AppData reloaded = await _load(file);
    final Program restored = reloaded.programs.single;
    expect(restored.days.map((ProgramDay day) => day.name), <String>[
      'Lower',
      'Upper',
    ]);
    expect(restored.days.first.id, lower.id);
    expect(restored.days.map((ProgramDay day) => day.sortOrder), <int>[0, 1]);

    final ProgramDay restoredUpper = restored.days.last;
    expect(restoredUpper.items.map((PlanItem item) => item.targetSets), <int>[
      4,
      3,
    ]);
    expect(restoredUpper.items.map((PlanItem item) => item.sortOrder), <int>[
      0,
      1,
    ]);
  });

  test(
    'appends new days and items after the highest remaining order',
    () async {
      final File file = await _tempFile();
      final ProviderContainer container = _container(file);
      await container.read(appDataControllerProvider.future);
      final AppDataController controller = container.read(
        appDataControllerProvider.notifier,
      );

      final Exercise exercise = await controller.createExercise(
        name: 'Bench Press',
      );
      final Program program = await controller.createProgram('Upper/Lower');
      final ProgramDay first = await controller.addDay(program.id, 'A');
      final ProgramDay second = await controller.addDay(program.id, 'B');
      final ProgramDay last = await controller.addDay(program.id, 'C');
      final PlanItem one = await controller.addPlanItem(
        dayId: last.id,
        exerciseId: exercise.id,
        targetSets: 1,
        repMin: 8,
        repMax: 12,
      );
      final PlanItem two = await controller.addPlanItem(
        dayId: last.id,
        exerciseId: exercise.id,
        targetSets: 2,
        repMin: 8,
        repMax: 12,
      );
      await controller.addPlanItem(
        dayId: last.id,
        exerciseId: exercise.id,
        targetSets: 3,
        repMin: 8,
        repMax: 12,
      );

      await controller.deleteDay(program.id, first.id);
      await controller.deleteDay(program.id, second.id);
      await controller.deletePlanItem(last.id, one.id);
      await controller.deletePlanItem(last.id, two.id);
      await controller.addDay(program.id, 'D');
      await controller.addPlanItem(
        dayId: last.id,
        exerciseId: exercise.id,
        targetSets: 4,
        repMin: 8,
        repMax: 12,
      );

      final AppData reloaded = await _load(file);
      final Program restored = reloaded.programs.single;
      expect(restored.days.map((ProgramDay day) => day.name), <String>[
        'C',
        'D',
      ]);
      expect(restored.days.map((ProgramDay day) => day.sortOrder), <int>[2, 3]);
      expect(
        restored.days.first.items.map((PlanItem item) => item.targetSets),
        <int>[3, 4],
      );
      expect(
        restored.days.first.items.map((PlanItem item) => item.sortOrder),
        <int>[2, 3],
      );
    },
  );

  test(
    'archive keeps the record for history and hides it from pickers',
    () async {
      final File file = await _tempFile();
      final ProviderContainer container = _container(file);
      await container.read(appDataControllerProvider.future);
      final AppDataController controller = container.read(
        appDataControllerProvider.notifier,
      );
      final Exercise exercise = await controller.createExercise(name: 'Squat');

      await controller.setExerciseArchived(exercise.id, archived: true);

      final AppData reloaded = await _load(file);
      expect(reloaded.activeExercises, isEmpty);
      expect(reloaded.searchExercises('squat'), isEmpty);
      expect(reloaded.exerciseById(exercise.id)?.name, 'Squat');
      expect(reloaded.exerciseById(exercise.id)?.isArchived, isTrue);
    },
  );

  test(
    'program edits and deletion never mutate the referenced exercises',
    () async {
      final File file = await _tempFile();
      final ProviderContainer container = _container(file);
      await container.read(appDataControllerProvider.future);
      final AppDataController controller = container.read(
        appDataControllerProvider.notifier,
      );

      final Exercise exercise = await controller.createExercise(
        name: 'Bench Press',
        searchTerm: 'flat bench press',
        muscleGroup: MuscleGroup.chest,
        defaultRepMin: 8,
        defaultRepMax: 12,
      );
      final Program program = await controller.createProgram('Upper');
      final ProgramDay day = await controller.addDay(program.id, 'Day 1');
      final PlanItem item = await controller.addPlanItem(
        dayId: day.id,
        exerciseId: exercise.id,
        targetSets: 3,
        repMin: 8,
        repMax: 12,
      );

      await controller.updatePlanItem(item.copyWith(repMin: 6, repMax: 10));

      final AppData afterEdit = await _load(file);
      final Exercise afterEditExercise = afterEdit.exerciseById(exercise.id)!;
      expect(afterEditExercise.name, exercise.name);
      expect(afterEditExercise.searchTerm, exercise.searchTerm);
      expect(afterEditExercise.muscleGroup, exercise.muscleGroup);
      expect(afterEditExercise.defaultRepMin, exercise.defaultRepMin);
      expect(afterEditExercise.defaultRepMax, exercise.defaultRepMax);
      expect(
        afterEdit.dayById(day.id)!.items.single.repMin,
        6,
        reason: 'the plan edit applies to the plan item only',
      );

      await controller.deleteProgram(program.id);

      final AppData afterDelete = await _load(file);
      expect(afterDelete.programs, isEmpty);
      expect(afterDelete.exerciseById(exercise.id), isNotNull);
      expect(
        afterDelete.exerciseById(exercise.id)!.name,
        exercise.name,
        reason: 'history references exercises, not programs or plan items',
      );
    },
  );
}
