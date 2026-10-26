import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

AppData _data() {
  return AppData(
    exercises: <Exercise>[
      Exercise(
        id: 'exercise-1',
        name: 'Bench Press',
        createdAt: DateTime.utc(2026, 10, 20, 9),
      ),
    ],
    sessions: <Session>[
      Session(
        id: 'active',
        startedAt: DateTime.utc(2026, 10, 21, 10),
        exercises: <SessionExercise>[
          SessionExercise(
            id: 'active-exercise',
            exerciseId: 'exercise-1',
            sortOrder: 0,
            targetSets: 3,
            repMin: 8,
            repMax: 12,
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('plate sheet solves the load and shows the warm-up ramp', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/workout',
      clock: () => DateTime.utc(2026, 10, 21, 12),
    );

    final Finder button = find.byKey(const Key('plate-calc-0'));
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Plate calculator'), findsOneWidget);
    expect(find.byKey(const Key('plate-target')), findsOneWidget);
    expect(find.text('Exact load'), findsOneWidget);
    expect(find.text('Warm-up ramp'), findsOneWidget);
    expect(find.text('Empty bar'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('2 per side'), findsWidgets);

    await tester.enterText(find.byKey(const Key('plate-target')), '100');
    await tester.pumpAndSettle();
    expect(find.text('100'), findsWidgets);
    expect(find.text('2 per side'), findsWidgets);

    // A below-bar target is a supported state: never throw while editing.
    await tester.enterText(find.byKey(const Key('plate-target')), '10');
    await tester.pumpAndSettle();
    expect(find.text('Lighter than the bar'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('plate-close')));
    await tester.tap(find.byKey(const Key('plate-close')));
    await tester.pumpAndSettle();
    expect(find.text('Plate calculator'), findsNothing);
  });
}
