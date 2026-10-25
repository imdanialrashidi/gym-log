import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/core/widgets/pr_badge.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

Exercise _exercise() {
  return Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    createdAt: DateTime.utc(2026, 10, 1, 9),
  );
}

Session _history({int weightGrams = 100000, int reps = 5}) {
  return Session(
    id: 'history-session',
    startedAt: DateTime.utc(2026, 10, 20, 10),
    endedAt: DateTime.utc(2026, 10, 20, 11),
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'history-exercise',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        sets: <SetLog>[
          SetLog(
            id: 'history-set',
            setIndex: 0,
            weightGrams: weightGrams,
            reps: reps,
            rir: 2,
            loggedAt: DateTime.utc(2026, 10, 20, 10, 5),
          ),
        ],
      ),
    ],
  );
}

AppData _seed({bool withHistory = true}) {
  return AppData(
    exercises: <Exercise>[_exercise()],
    sessions: withHistory ? <Session>[_history()] : const <Session>[],
  );
}

Future<void> _startAndAddExercise(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('start-empty-workout')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('session-add-exercise')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Bench Press'));
  await tester.pumpAndSettle();
}

Future<void> _logSet(
  WidgetTester tester, {
  required String weight,
  required int reps,
  bool warmup = false,
}) async {
  if (warmup) {
    await tester.tap(find.byKey(const Key('set-0-0-warmup')));
    await tester.pumpAndSettle();
  }
  await tester.enterText(find.byKey(const Key('set-0-0-weight')), weight);
  await tester.enterText(
    find.byKey(const Key('set-0-0-reps')),
    reps.toString(),
  );
  await tester.tap(find.byKey(const Key('set-0-0-check')));
  await tester.pumpAndSettle();
}

List<Session> _progressionSessions() {
  return <Session>[
    Session(
      id: 'baseline-session',
      startedAt: DateTime.utc(2026, 10, 19, 10),
      endedAt: DateTime.utc(2026, 10, 19, 11),
      exercises: <SessionExercise>[
        SessionExercise(
          id: 'baseline-exercise',
          exerciseId: 'exercise-1',
          sortOrder: 0,
          sets: <SetLog>[
            SetLog(
              id: 'baseline-set',
              setIndex: 0,
              weightGrams: 100000,
              reps: 5,
              rir: 2,
              loggedAt: DateTime.utc(2026, 10, 19, 10, 5),
            ),
          ],
        ),
      ],
    ),
    Session(
      id: 'later-session',
      startedAt: DateTime.utc(2026, 10, 20, 10),
      endedAt: DateTime.utc(2026, 10, 20, 11),
      exercises: <SessionExercise>[
        SessionExercise(
          id: 'later-exercise',
          exerciseId: 'exercise-1',
          sortOrder: 0,
          sets: <SetLog>[
            SetLog(
              id: 'warmup-set',
              setIndex: 0,
              weightGrams: 150000,
              reps: 5,
              isWarmup: true,
              loggedAt: DateTime.utc(2026, 10, 20, 10, 1),
            ),
            SetLog(
              id: 'later-set',
              setIndex: 1,
              weightGrams: 105000,
              reps: 5,
              rir: 2,
              loggedAt: DateTime.utc(2026, 10, 20, 10, 5),
            ),
          ],
        ),
      ],
    ),
  ];
}

void main() {
  testWidgets('a heavier set shows a PR badge', (WidgetTester tester) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startAndAddExercise(tester);

    await _logSet(tester, weight: '102.5', reps: 5);

    expect(find.byKey(const Key('set-0-0-pr')), findsOneWidget);
    expect(find.byType(PrBadge), findsOneWidget);
    expect(store.data.activeSession!.exercises.single.sets, hasLength(1));
  });

  testWidgets('the first-ever set is a baseline with no PR badge', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(withHistory: false),
    );
    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startAndAddExercise(tester);

    await _logSet(tester, weight: '100', reps: 5);

    expect(find.byKey(const Key('set-0-0-pr')), findsNothing);
    expect(find.byType(PrBadge), findsNothing);
  });

  testWidgets('a heavier warm-up set never shows a PR badge', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startAndAddExercise(tester);

    await _logSet(tester, weight: '150', reps: 5, warmup: true);

    expect(find.byKey(const Key('set-0-0-pr')), findsNothing);
    expect(find.byType(PrBadge), findsNothing);
  });

  testWidgets('equalling the record does not show a PR badge', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startAndAddExercise(tester);

    await _logSet(tester, weight: '100', reps: 5);

    expect(find.byKey(const Key('set-0-0-pr')), findsNothing);
  });
  testWidgets('session detail marks the PR set but not the warm-up', (
    WidgetTester tester,
  ) async {
    final AppData data = AppData(
      exercises: <Exercise>[_exercise()],
      sessions: _progressionSessions(),
    );
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(data),
      initialLocation: '/session/later-session',
    );

    expect(find.byKey(const Key('history-set-later-set-pr')), findsOneWidget);
    expect(find.byKey(const Key('history-set-warmup-set-pr')), findsNothing);
  });

  testWidgets('session detail leaves the baseline set unbadged', (
    WidgetTester tester,
  ) async {
    final AppData data = AppData(
      exercises: <Exercise>[_exercise()],
      sessions: _progressionSessions(),
    );
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(data),
      initialLocation: '/session/baseline-session',
    );

    expect(find.byKey(const Key('history-set-baseline-set-pr')), findsNothing);
    expect(find.byType(PrBadge), findsNothing);
  });
}
