import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/test_app.dart';

AppData _data() {
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
    ],
    programs: <Program>[
      Program(
        id: 'program-1',
        name: 'Upper/Lower',
        createdAt: DateTime.utc(2026, 10, 20, 11),
        days: <ProgramDay>[
          ProgramDay(
            id: 'day-1',
            name: 'Upper',
            sortOrder: 0,
            items: <PlanItem>[
              PlanItem(
                id: 'item-1',
                exerciseId: 'exercise-1',
                targetSets: 4,
                repMin: 6,
                repMax: 10,
                sortOrder: 0,
              ),
              PlanItem(
                id: 'item-2',
                exerciseId: 'exercise-2',
                targetSets: 3,
                repMin: 8,
                repMax: 12,
                sortOrder: 1,
              ),
            ],
          ),
          ProgramDay(id: 'day-2', name: 'Lower', sortOrder: 1),
        ],
      ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required String initialLocation,
  required Locale locale,
}) async {
  await pumpGymLogApp(
    tester,
    store: MemoryAppDataStore(_data()),
    initialLocation: initialLocation,
    locale: locale,
  );
}

Finder get _screen => find.byType(Scaffold).first;

void main() {
  testWidgets('English LTR exercise picker golden', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      initialLocation: '/exercise-picker',
      locale: const Locale('en'),
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/exercise_picker_en.png'),
    );
  });

  testWidgets('Persian RTL exercise picker golden', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      initialLocation: '/exercise-picker',
      locale: const Locale('fa'),
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/exercise_picker_fa.png'),
    );
  });

  testWidgets('English LTR exercise creator golden', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      initialLocation: '/exercise-editor/new',
      locale: const Locale('en'),
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/exercise_creator_en.png'),
    );
  });

  testWidgets('Persian RTL exercise creator golden', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      initialLocation: '/exercise-editor/new',
      locale: const Locale('fa'),
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/exercise_creator_fa.png'),
    );
  });

  testWidgets('English LTR day editor golden', (WidgetTester tester) async {
    await _pump(
      tester,
      initialLocation: '/day-editor/program-1/day-1',
      locale: const Locale('en'),
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    await expectLater(_screen, matchesGoldenFile('goldens/day_editor_en.png'));
  });

  testWidgets('Persian RTL day editor golden', (WidgetTester tester) async {
    await _pump(
      tester,
      initialLocation: '/day-editor/program-1/day-1',
      locale: const Locale('fa'),
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    await expectLater(_screen, matchesGoldenFile('goldens/day_editor_fa.png'));
  });

  testWidgets('English LTR programs list golden', (WidgetTester tester) async {
    await _pump(
      tester,
      initialLocation: '/programs',
      locale: const Locale('en'),
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/programs_list_en.png'),
    );
  });

  testWidgets('Persian RTL programs list golden', (WidgetTester tester) async {
    await _pump(
      tester,
      initialLocation: '/programs',
      locale: const Locale('fa'),
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/programs_list_fa.png'),
    );
  });
}
