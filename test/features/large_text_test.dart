import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app/theme/app_tokens.dart';
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
        createdAt: DateTime.utc(2026, 9, 1, 9),
      ),
      Exercise(
        id: 'exercise-2',
        name: 'Barbell Row',
        muscleGroup: MuscleGroup.back,
        createdAt: DateTime.utc(2026, 9, 1, 9),
      ),
    ],
    programs: <Program>[
      Program(
        id: 'program-1',
        name: 'Upper/Lower',
        createdAt: DateTime.utc(2026, 9, 1, 9),
        days: <ProgramDay>[
          ProgramDay(
            id: 'day-1',
            name: 'Upper',
            sortOrder: 0,
            items: <PlanItem>[
              PlanItem(
                id: 'item-1',
                exerciseId: 'exercise-1',
                targetSets: 3,
                repMin: 8,
                repMax: 12,
                sortOrder: 0,
              ),
            ],
          ),
          ProgramDay(id: 'day-2', name: 'Lower', sortOrder: 1),
        ],
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
        endedAt: DateTime.utc(2026, 10, 21, 11),
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
    bodyWeights: <BodyWeightEntry>[
      BodyWeightEntry(
        id: 'weight-1',
        weightGrams: 80000,
        recordedAt: DateTime.utc(2026, 10, 20, 7),
      ),
    ],
    settings: const AppSettings(
      restTimerEnabled: true,
      weeklySessionGoal: 3,
      weeklySetGoal: 12,
    ),
  );
}

Future<void> _pumpAt(WidgetTester tester, String route) async {
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpGymLogApp(
    tester,
    store: MemoryAppDataStore(_seed()),
    initialLocation: route,
    clock: () => DateTime.utc(2026, 10, 21, 12),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollThrough(WidgetTester tester) async {
  for (int index = 0; index < 4; index += 1) {
    final Finder scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }
}

void main() {
  for (final ({String route, String name}) screen
      in <({String route, String name})>[
        (route: '/workout', name: 'dashboard'),
        (route: '/programs', name: 'programs'),
        (route: '/exercises', name: 'exercise library'),
        (route: '/settings', name: 'settings'),
        (route: '/session-summary/summary', name: 'session summary'),
      ]) {
    testWidgets('${screen.name} survives 200% text', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, screen.route);
      expect(tester.takeException(), isNull);
      await _scrollThrough(tester);
      expect(AppTokens.minTouchTarget, 48);
    });
  }
}
