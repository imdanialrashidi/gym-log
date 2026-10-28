import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/core/widgets/square_switch.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

Exercise _exercise() {
  return Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    createdAt: DateTime.utc(2026, 10, 20, 9),
  );
}

Session _session() {
  return Session(
    id: 'session-1',
    startedAt: DateTime.utc(2026, 10, 20, 10),
    endedAt: DateTime.utc(2026, 10, 20, 11),
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'session-exercise-1',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        sets: <SetLog>[
          SetLog(
            id: 'set-1',
            weightGrams: 100000,
            reps: 8,
            setIndex: 0,
            loggedAt: DateTime.utc(2026, 10, 20, 10, 5),
          ),
          SetLog(
            id: 'set-2',
            weightGrams: 100000,
            reps: 8,
            setIndex: 1,
            loggedAt: DateTime.utc(2026, 10, 20, 10, 10),
          ),
          SetLog(
            id: 'set-3',
            weightGrams: 100000,
            reps: 8,
            setIndex: 2,
            loggedAt: DateTime.utc(2026, 10, 20, 10, 15),
          ),
        ],
      ),
    ],
  );
}

AppData _data({bool withGoal = true}) {
  return AppData(
    exercises: <Exercise>[_exercise()],
    sessions: <Session>[_session()],
    settings: AppSettings(
      weeklySessionGoal: withGoal ? 3 : null,
      weeklySetGoal: withGoal ? 12 : null,
    ),
  );
}

Future<void> _pump(WidgetTester tester, MemoryAppDataStore store) async {
  await pumpGymLogApp(
    tester,
    store: store,
    initialLocation: '/workout',
    clock: () => DateTime.utc(2026, 10, 21, 12),
  );
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard shows the weekly goal and edits it in place', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_data());
    await _pump(tester, store);

    await _reveal(tester, find.byKey(const Key('dashboard-goal-block')));
    expect(find.text('Weekly goal'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('3 of 12'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dashboard-goal-block')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('goal-save')), findsOneWidget);

    await tester.tap(find.byKey(const Key('goal-session-plus')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('goal-save')));
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();

    expect(store.data.settings.weeklySessionGoal, 4);
    expect(store.data.settings.weeklySetGoal, 12);
    expect(find.text('1 of 4'), findsOneWidget);
  });

  testWidgets('no goal shows a calm call to action', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_data(withGoal: false));
    await _pump(tester, store);

    final Finder cta = find.byKey(const Key('dashboard-set-goal'));
    await _reveal(tester, cta);
    expect(find.text('Set a weekly goal'), findsOneWidget);

    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('goal-save')), findsOneWidget);
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();

    expect(store.data.settings.weeklySessionGoal, defaultWeeklySessionGoal);
    expect(store.data.settings.weeklySetGoal, defaultWeeklySetGoal);
  });

  testWidgets('a single-target goal stays single when saved unchanged', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _data(withGoal: false)
          .copyWith(settings: const AppSettings(weeklySessionGoal: 4)),
    );
    await _pump(tester, store);

    await _reveal(tester, find.byKey(const Key('dashboard-goal-block')));
    await tester.tap(find.byKey(const Key('dashboard-goal-block')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SquareSwitch>(find.byKey(const Key('goal-session-enabled')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SquareSwitch>(find.byKey(const Key('goal-set-enabled')))
          .value,
      isFalse,
    );
    await tester.ensureVisible(find.byKey(const Key('goal-save')));
    await tester.tap(find.byKey(const Key('goal-save')));
    await tester.pumpAndSettle();

    expect(store.data.settings.weeklySessionGoal, 4);
    expect(store.data.settings.weeklySetGoal, isNull);
  });

  testWidgets('removing the goal clears both targets', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_data());
    await _pump(tester, store);

    await _reveal(tester, find.byKey(const Key('dashboard-goal-block')));
    await tester.tap(find.byKey(const Key('dashboard-goal-block')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('goal-remove')));
    await tester.tap(find.byKey(const Key('goal-remove')));
    await tester.pumpAndSettle();

    expect(store.data.settings.hasWeeklyGoal, isFalse);
    expect(find.byKey(const Key('dashboard-set-goal')), findsOneWidget);
  });

  test('weekly goals survive the JSON backup format', () {
    final String json = buildBackupJson(
      _data(),
      appVersion: '0.1.0',
      exportedAt: DateTime.utc(2026, 10, 21, 12),
    );
    final BackupDocument parsed = parseBackup(json);
    expect(parsed.data.settings.weeklySessionGoal, 3);
    expect(parsed.data.settings.weeklySetGoal, 12);
  });
}
