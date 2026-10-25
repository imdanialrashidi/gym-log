import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

AppData _seed() {
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
          ProgramDay(id: 'day-1', name: 'Upper', sortOrder: 0),
          ProgramDay(id: 'day-2', name: 'Lower', sortOrder: 1),
        ],
      ),
    ],
  );
}

AppData _programOnlySeed() {
  return AppData(
    programs: <Program>[
      Program(
        id: 'program-1',
        name: 'Upper/Lower',
        createdAt: DateTime.utc(2026, 10, 20, 11),
        days: <ProgramDay>[
          ProgramDay(id: 'day-1', name: 'Upper', sortOrder: 0),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('creating an exercise inside the picker selects it immediately', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_programOnlySeed());

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/program-editor/program-1',
    );
    await tester.tap(find.text('Upper'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-first-plan-item')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('choose-exercise')));
    await tester.pumpAndSettle();

    expect(find.text('No exercises yet.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('picker-add-first-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('exercise-name-field')),
      'Squat',
    );
    await tester.tap(find.byKey(const Key('save-exercise')));
    await tester.pumpAndSettle();

    expect(find.text('Squat'), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-plan-item')));
    await tester.pumpAndSettle();

    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('3 × 8–12'), findsOneWidget);
    expect(store.data.exercises.single.name, 'Squat');
    expect(
      store.data.dayById('day-1')!.items.single.exerciseId,
      store.data.exercises.single.id,
    );
  });

  testWidgets('plan item saves with inline validation and persists', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/program-editor/program-1',
    );

    await tester.tap(find.text('Upper'));
    await tester.pumpAndSettle();
    expect(find.text('No plan items yet.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-first-plan-item')));
    await tester.pumpAndSettle();
    expect(find.text('New plan item'), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-plan-item')));
    await tester.pumpAndSettle();
    expect(find.text('Choose an exercise.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('choose-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    expect(find.text('Bench Press'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('target-sets-field')), '4');
    await tester.enterText(find.byKey(const Key('plan-rep-min-field')), '0');
    await tester.enterText(find.byKey(const Key('plan-rep-max-field')), '101');
    await tester.tap(find.byKey(const Key('save-plan-item')));
    await tester.pumpAndSettle();
    expect(find.text('Use 1 to 100.'), findsNWidgets(2));

    await tester.enterText(find.byKey(const Key('plan-rep-min-field')), '12');
    await tester.enterText(find.byKey(const Key('plan-rep-max-field')), '8');
    await tester.tap(find.byKey(const Key('save-plan-item')));
    await tester.pumpAndSettle();
    expect(
      find.text('Minimum reps must not exceed maximum reps.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('plan-rep-min-field')), '6');
    await tester.enterText(find.byKey(const Key('plan-rep-max-field')), '10');
    await tester.tap(find.byKey(const Key('save-plan-item')));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('4 × 6–10'), findsOneWidget);
    expect(find.byTooltip('Reorder'), findsOneWidget);

    final PlanItem item = store.data.dayById('day-1')!.items.single;
    expect(item.targetSets, 4);
    expect(item.repMin, 6);
    expect(item.repMax, 10);
    expect(item.exerciseId, 'exercise-1');
  });

  testWidgets('deleting a program keeps the exercise records', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());

    await pumpGymLogApp(tester, store: store, initialLocation: '/programs');
    await tester.tap(find.text('Upper/Lower'));
    await tester.pumpAndSettle();
    expect(find.text('Upper'), findsOneWidget);

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete program?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No programs yet.'), findsOneWidget);
    expect(store.data.programs, isEmpty);
    expect(store.data.exerciseById('exercise-1')?.name, 'Bench Press');
  });
}
