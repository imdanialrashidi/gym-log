import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/test_app.dart';

AppData _populatedData() {
  return AppData(
    exercises: <Exercise>[
      Exercise(
        id: 'exercise-1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        createdAt: DateTime.utc(2026, 10, 20, 10),
      ),
      Exercise(
        id: 'exercise-2',
        name: 'Pull-Up',
        muscleGroup: MuscleGroup.back,
        createdAt: DateTime.utc(2026, 10, 20, 10),
      ),
      Exercise(
        id: 'exercise-3',
        name: 'اسکوات',
        muscleGroup: MuscleGroup.quadriceps,
        createdAt: DateTime.utc(2026, 10, 20, 10),
      ),
    ],
  );
}

void main() {
  testWidgets('English LTR empty exercise library golden', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(),
      initialLocation: '/exercises',
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/exercise_library_empty_en.png'),
    );
  });

  testWidgets('Persian RTL empty exercise library golden', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(),
      initialLocation: '/exercises',
      locale: const Locale('fa'),
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/exercise_library_empty_fa.png'),
    );
  });

  testWidgets('English LTR populated exercise library golden', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_populatedData()),
      initialLocation: '/exercises',
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/exercise_library_populated_en.png'),
    );
  });

  testWidgets('Persian RTL populated exercise library golden', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_populatedData()),
      initialLocation: '/exercises',
      locale: const Locale('fa'),
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/exercise_library_populated_fa.png'),
    );
  });
}
