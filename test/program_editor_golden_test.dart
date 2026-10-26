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

void main() {
  testWidgets('English LTR program editor golden', (WidgetTester tester) async {
    await _pump(
      tester,
      initialLocation: '/program-editor/program-1',
      locale: const Locale('en'),
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/program_editor_en.png'),
    );
  });

  testWidgets('Persian RTL program editor golden', (WidgetTester tester) async {
    await _pump(
      tester,
      initialLocation: '/program-editor/program-1',
      locale: const Locale('fa'),
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/program_editor_fa.png'),
    );
  });

  testWidgets('English LTR plan item editor golden', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      initialLocation: '/plan-item-editor/day-1/item-1',
      locale: const Locale('en'),
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/plan_item_editor_en.png'),
    );
  });

  testWidgets('Persian RTL plan item editor golden', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      initialLocation: '/plan-item-editor/day-1/item-1',
      locale: const Locale('fa'),
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/plan_item_editor_fa.png'),
    );
  });

  testWidgets('English LTR plan item validation golden', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      initialLocation: '/plan-item-editor/day-1/new',
      locale: const Locale('en'),
    );

    await tester.enterText(find.byKey(const Key('target-sets-field')), '0');
    await tester.enterText(find.byKey(const Key('plan-rep-min-field')), '0');
    await tester.enterText(find.byKey(const Key('plan-rep-max-field')), '101');
    await tester.tap(find.byKey(const Key('save-plan-item')));
    await tester.pumpAndSettle();

    expect(find.text('Choose an exercise.'), findsOneWidget);
    expect(find.text('Use 1 to 20 sets.'), findsOneWidget);
    expect(find.text('Use 1 to 100.'), findsNWidgets(2));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/plan_item_validation_en.png'),
    );
  });

  testWidgets('Persian RTL plan item validation golden', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      initialLocation: '/plan-item-editor/day-1/new',
      locale: const Locale('fa'),
    );

    await tester.enterText(find.byKey(const Key('target-sets-field')), '0');
    await tester.enterText(find.byKey(const Key('plan-rep-min-field')), '0');
    await tester.enterText(find.byKey(const Key('plan-rep-max-field')), '101');
    await tester.tap(find.byKey(const Key('save-plan-item')));
    await tester.pumpAndSettle();

    expect(find.text('یک حرکت انتخاب کن.'), findsOneWidget);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/plan_item_validation_fa.png'),
    );
  });
}
