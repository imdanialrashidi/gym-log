import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/rest_timer_store.dart';
import 'package:gym_log/features/workout/presentation/set_row.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/memory_rest_timer_store.dart';
import '../support/test_app.dart';

Exercise _exercise() {
  return Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    createdAt: DateTime(2026, 10, 20, 9),
  );
}

Session _activeSession() {
  return Session(
    id: 'active-session',
    startedAt: DateTime(2026, 10, 21, 11),
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
  );
}

AppData _seed({bool timerEnabled = true}) {
  return AppData(
    exercises: <Exercise>[_exercise()],
    sessions: <Session>[_activeSession()],
    settings: AppSettings(
      restTimerEnabled: timerEnabled,
      restTimerDurationSeconds: 60,
    ),
  );
}

Future<void> _reveal(WidgetTester tester, String key) async {
  final Finder finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> _logFirstSet(WidgetTester tester) async {
  await _reveal(tester, 'set-0-0-weight');
  await tester.enterText(find.byKey(const Key('set-0-0-weight')), '100');
  await tester.enterText(find.byKey(const Key('set-0-0-reps')), '8');
  await _reveal(tester, 'set-0-0-check');
  await tester.tap(find.byKey(const Key('set-0-0-check')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the elapsed session clock ticks without a document write', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    DateTime now = DateTime(2026, 10, 21, 11);

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/workout',
      clock: () => now,
    );

    expect(
      tester.widget<Text>(find.byKey(const Key('active-session-elapsed'))).data,
      '00:00',
    );
    expect(store.saveCount, 0);

    final List<String> rebuiltRows = <String>[];
    debugOnRebuildDirtyWidget = (Element element, bool _) {
      final Widget widget = element.widget;
      if (widget is SetRow && widget.key is ValueKey<String>) {
        rebuiltRows.add((widget.key! as ValueKey<String>).value);
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    now = now.add(const Duration(minutes: 1, seconds: 5));
    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.widget<Text>(find.byKey(const Key('active-session-elapsed'))).data,
      '01:05',
    );
    expect(store.saveCount, 0);
    expect(rebuiltRows, isEmpty);
  });

  testWidgets('the live bar names the exercise and follows rest progress', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    final MemoryRestTimerStore restStore = MemoryRestTimerStore();

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/workout',
      clock: () => DateTime(2026, 10, 21, 11),
      restTimerStore: restStore,
    );

    expect(find.byKey(const Key('workout-live-bar')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('live-exercise-name'))).data,
      'Bench Press',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('live-set-progress'))).data,
      '0 of 3 sets',
    );

    await _logFirstSet(tester);

    expect(
      tester.widget<Text>(find.byKey(const Key('live-set-progress'))).data,
      '1 of 3 sets',
    );
    expect(find.byKey(const Key('rest-timer-banner')), findsOneWidget);
    expect(find.text('Rest 01:00'), findsOneWidget);
    expect(find.byKey(const Key('rest-timer-progress')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('live-next-label'))).data,
      contains('set 2'),
    );
    expect(restStore.value, isNotNull);
    expect(restStore.value!.duration, const Duration(seconds: 60));
  });

  testWidgets('a rest countdown restores after process death', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 10, 21, 11);
    final MemoryRestTimerStore restStore = MemoryRestTimerStore(
      PersistedRestTimer(
        endsAt: now.add(const Duration(seconds: 30)),
        duration: const Duration(seconds: 60),
      ),
    );

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_seed()),
      initialLocation: '/workout',
      clock: () => now,
      restTimerStore: restStore,
    );

    expect(find.byKey(const Key('rest-timer-banner')), findsOneWidget);
    expect(find.text('Rest 00:30'), findsOneWidget);
    expect(find.byKey(const Key('workout-live-bar')), findsOneWidget);
  });

  testWidgets('dismissing rest clears the persisted marker', (
    WidgetTester tester,
  ) async {
    final MemoryRestTimerStore restStore = MemoryRestTimerStore();

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_seed()),
      initialLocation: '/workout',
      clock: () => DateTime(2026, 10, 21, 11),
      restTimerStore: restStore,
    );
    await _logFirstSet(tester);
    expect(restStore.value, isNotNull);

    await tester.tap(find.byKey(const Key('rest-timer-stop')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rest-timer-banner')), findsNothing);
    expect(restStore.value, isNull);
  });
}
