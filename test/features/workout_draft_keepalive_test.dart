import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

AppData _seed() {
  return AppData(
    exercises: <Exercise>[
      for (int index = 0; index < 6; index++)
        Exercise(
          id: 'exercise-$index',
          name: 'Exercise $index',
          createdAt: DateTime.utc(2026, 10, 20, 9),
        ),
    ],
    sessions: <Session>[
      Session(
        id: 'active-session',
        startedAt: DateTime.utc(2026, 10, 21, 11),
        exercises: <SessionExercise>[
          for (int index = 0; index < 6; index++)
            SessionExercise(
              id: 'active-exercise-$index',
              exerciseId: 'exercise-$index',
              sortOrder: index,
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
  testWidgets('an unsaved set draft survives scrolling an exercise away', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_seed()),
      initialLocation: '/workout',
      clock: () => DateTime.utc(2026, 10, 21, 11),
    );

    final Finder weight = find.byKey(const Key('set-0-0-weight'));
    await tester.scrollUntilVisible(
      weight,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(weight, '87.5');

    // Travel far enough that the first card leaves the lazy list's cache.
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, -3000),
      3000,
    );
    await tester.pumpAndSettle();
    // The kept-alive draft is still in the tree even though its card is far
    // outside the viewport.
    expect(weight, findsOneWidget);

    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 3000),
      3000,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      weight,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(weight).controller!.text, '87.5');
  });
}
