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
        muscleGroup: MuscleGroup.chest,
        createdAt: DateTime.utc(2026, 10, 20, 9),
      ),
    ],
    sessions: <Session>[
      Session(
        id: 'prior',
        startedAt: DateTime.utc(2026, 10, 19, 10),
        endedAt: DateTime.utc(2026, 10, 19, 11),
        exercises: <SessionExercise>[
          SessionExercise(
            id: 'prior-exercise',
            exerciseId: 'exercise-1',
            sortOrder: 0,
            sets: <SetLog>[
              SetLog(
                id: 'prior-set',
                weightGrams: 95000,
                reps: 8,
                setIndex: 0,
                loggedAt: DateTime.utc(2026, 10, 19, 10, 5),
              ),
            ],
          ),
        ],
      ),
      Session(
        id: 'summary',
        startedAt: DateTime.utc(2026, 10, 21, 10),
        endedAt: DateTime.utc(2026, 10, 21, 11, 5),
        exercises: <SessionExercise>[
          SessionExercise(
            id: 'summary-exercise',
            exerciseId: 'exercise-1',
            sortOrder: 0,
            sets: <SetLog>[
              SetLog(
                id: 'summary-set',
                weightGrams: 100000,
                reps: 8,
                setIndex: 0,
                loggedAt: DateTime.utc(2026, 10, 21, 10, 5),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('summary shows the session, records, split, and the way home', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/session-summary/summary',
      clock: () => DateTime.utc(2026, 10, 21, 12),
    );

    expect(find.byKey(const Key('session-summary-screen')), findsOneWidget);
    expect(find.byKey(const Key('workout-done-cat')), findsOneWidget);
    expect(find.text('Workout done!'), findsOneWidget);
    expect(find.text('Meow! Time to rest and stretch.'), findsOneWidget);
    expect(find.text('Workout complete.'), findsOneWidget);
    expect(find.text('1 new record'), findsOneWidget);
    expect(find.textContaining('vs last session'), findsOneWidget);
    expect(find.text('Chest'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('summary-back-home')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('summary-back-home')));
    await tester.pumpAndSettle();

    expect(find.text('No active workout.'), findsOneWidget);
  });

  testWidgets('Persian summary shows the cat finishing the workout', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/session-summary/summary',
      locale: const Locale('fa'),
      clock: () => DateTime.utc(2026, 10, 21, 12),
    );

    expect(find.byKey(const Key('workout-done-cat')), findsOneWidget);
    expect(find.text('تمرین تموم شد!'), findsOneWidget);
    expect(find.text('میو! حالا وقت استراحت و کششه.'), findsOneWidget);
  });
}
