import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

Exercise _exercise() {
  return Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    createdAt: DateTime(2026, 10, 1, 9),
  );
}

Session _priorSession() {
  return Session(
    id: 'prior-session',
    startedAt: DateTime(2026, 10, 20, 10),
    endedAt: DateTime(2026, 10, 20, 11),
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'prior-exercise',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        sets: <SetLog>[
          for (int index = 0; index < 3; index++)
            SetLog(
              id: 'prior-set-$index',
              setIndex: index,
              weightGrams: 100000,
              reps: 8,
              rir: 2,
              loggedAt: DateTime(2026, 10, 20, 10, index),
            ),
        ],
      ),
    ],
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

AppData _seed({bool timerEnabled = true, int timerSeconds = 60}) {
  return AppData(
    exercises: <Exercise>[_exercise()],
    sessions: <Session>[_priorSession(), _activeSession()],
    settings: AppSettings(
      restTimerEnabled: timerEnabled,
      restTimerDurationSeconds: timerSeconds,
    ),
  );
}

void main() {
  testWidgets(
    'timer starts after a set, never blocks, and completes on resume',
    (WidgetTester tester) async {
      final List<MethodCall> platformCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall call,
          ) async {
            platformCalls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      DateTime now = DateTime(2026, 10, 21, 11);
      final MemoryAppDataStore store = MemoryAppDataStore(_seed());

      await pumpGymLogApp(
        tester,
        store: store,
        initialLocation: '/workout',
        clock: () => now,
      );

      await tester.tap(find.byKey(const Key('set-0-0-check')));
      await tester.pumpAndSettle();

      expect(store.data.activeSession!.exercises.single.sets, hasLength(1));
      expect(find.byKey(const Key('rest-timer-banner')), findsOneWidget);
      expect(find.text('Rest 01:00'), findsOneWidget);

      // The timer is only visual state; logging the next row still works.
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('set-0-1-check'))),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set-0-1-check')));
      await tester.pumpAndSettle();
      expect(store.data.activeSession!.exercises.single.sets, hasLength(2));

      now = now.add(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Rest 00:40'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 61));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.text('Rest complete'), findsOneWidget);
      expect(
        platformCalls.any(
          (MethodCall call) => call.method == 'HapticFeedback.vibrate',
        ),
        isTrue,
      );
    },
  );

  testWidgets('only the finished rest state is a live region', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    DateTime now = DateTime(2026, 10, 21, 11);

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_seed()),
      initialLocation: '/workout',
      clock: () => now,
    );
    await tester.tap(find.byKey(const Key('set-0-0-check')));
    await tester.pumpAndSettle();

    final running = tester
        .getSemantics(find.byKey(const Key('rest-timer-banner')))
        .getSemanticsData();
    expect(running.flagsCollection.isLiveRegion, isFalse);
    expect(running.label, contains('Rest timer running'));
    expect(running.label, isNot(contains('00:')));

    now = now.add(const Duration(seconds: 61));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    final finished = tester
        .getSemantics(find.byKey(const Key('rest-timer-banner')))
        .getSemanticsData();
    expect(finished.flagsCollection.isLiveRegion, isTrue);
    expect(finished.label, contains('Rest complete'));
    expect(find.text('Rest complete'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('disabled timer never starts', (WidgetTester tester) async {
    final DateTime now = DateTime(2026, 10, 21, 11);
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(timerEnabled: false),
    );

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/workout',
      clock: () => now,
    );
    await tester.tap(find.byKey(const Key('set-0-0-check')));
    await tester.pumpAndSettle();

    expect(store.data.activeSession!.exercises.single.sets, hasLength(1));
    expect(find.byKey(const Key('rest-timer-banner')), findsNothing);
  });

  testWidgets('timer settings persist from the settings screen', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(AppData());

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      clock: () => DateTime(2026, 10, 21, 12),
    );

    expect(store.data.settings.restTimerEnabled, isFalse);
    expect(store.data.settings.restTimerDurationSeconds, 90);

    await tester.tap(find.byKey(const Key('rest-timer-enabled')));
    await tester.pumpAndSettle();
    expect(store.data.settings.restTimerEnabled, isTrue);

    await tester.tap(find.byKey(const Key('rest-timer-duration-plus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rest-timer-duration-plus')));
    await tester.pumpAndSettle();

    expect(store.data.settings.restTimerDurationSeconds, 120);
    expect(find.text('02:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rest-timer-duration-minus')));
    await tester.pumpAndSettle();
    expect(store.data.settings.restTimerDurationSeconds, 105);
  });
}
