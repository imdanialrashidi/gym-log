import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

final DateTime _now = DateTime(2026, 10, 21, 12);

Exercise _exercise(String id, String name, MuscleGroup muscle) {
  return Exercise(
    id: id,
    name: name,
    muscleGroup: muscle,
    createdAt: DateTime(2026, 9, 1, 9),
  );
}

Session _session({
  required String id,
  required DateTime localStart,
  required String exerciseId,
  required int weightGrams,
  required int reps,
}) {
  return Session(
    id: id,
    startedAt: localStart.toUtc(),
    endedAt: localStart.add(const Duration(hours: 1)).toUtc(),
    exercises: <SessionExercise>[
      SessionExercise(
        id: '$id-exercise',
        exerciseId: exerciseId,
        sortOrder: 0,
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        sets: <SetLog>[
          SetLog(
            id: '$id-set-0',
            setIndex: 0,
            weightGrams: weightGrams,
            reps: reps,
            rir: 2,
            loggedAt: localStart.add(const Duration(minutes: 5)).toUtc(),
          ),
          SetLog(
            id: '$id-set-1',
            setIndex: 1,
            weightGrams: weightGrams,
            reps: reps - 1,
            rir: 1,
            loggedAt: localStart.add(const Duration(minutes: 25)).toUtc(),
          ),
        ],
      ),
    ],
  );
}

AppData _seed() {
  return AppData(
    exercises: <Exercise>[
      _exercise('bench', 'Bench Press', MuscleGroup.chest),
      _exercise('row', 'Barbell Row', MuscleGroup.back),
      _exercise('squat', 'Squat', MuscleGroup.quadriceps),
    ],
    sessions: <Session>[
      _session(
        id: 'this-week-bench',
        localStart: DateTime(2026, 10, 19, 18),
        exerciseId: 'bench',
        weightGrams: 100000,
        reps: 8,
      ),
      _session(
        id: 'this-week-row',
        localStart: DateTime(2026, 10, 20, 18),
        exerciseId: 'row',
        weightGrams: 80000,
        reps: 10,
      ),
      _session(
        id: 'last-week-squat',
        localStart: DateTime(2026, 10, 14, 18),
        exerciseId: 'squat',
        weightGrams: 120000,
        reps: 5,
      ),
    ],
    bodyWeights: <BodyWeightEntry>[
      BodyWeightEntry(
        id: 'weight-last',
        weightGrams: 80000,
        recordedAt: DateTime(2026, 10, 14, 8).toUtc(),
      ),
      BodyWeightEntry(
        id: 'weight-this',
        weightGrams: 79000,
        recordedAt: DateTime(2026, 10, 19, 8).toUtc(),
      ),
    ],
  );
}

Future<void> _open(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  await pumpGymLogApp(
    tester,
    store: MemoryAppDataStore(_seed()),
    initialLocation: '/weekly-summary',
    locale: locale,
    clock: () => _now,
  );
}

void main() {
  testWidgets('summarises the current week with volume, sets, time, weight', (
    WidgetTester tester,
  ) async {
    await _open(tester);

    expect(find.text('Weekly summary'), findsOneWidget);
    expect(find.text('This week'), findsWidgets);
    expect(find.byKey(const Key('weekly-summary-list')), findsOneWidget);
    expect(find.text('No training logged this week yet.'), findsNothing);
    expect(
      find.byKey(const Key('weekly-session-this-week-bench')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('weekly-session-this-week-row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('weekly-session-last-week-squat')),
      findsNothing,
    );
    // 2 sessions, 4 working sets, 100·8 + 100·7 + 80·10 + 80·9 = 3020 kg.
    expect(find.text('3020'), findsWidgets);
    expect(find.text('Workouts'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    // Weekly weight change 80 → 79 kg.
    expect(find.text('−1 kg since last check-in'), findsWidgets);
  });

  testWidgets('shows the muscle split and opens a session', (
    WidgetTester tester,
  ) async {
    await _open(tester);

    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Quads'), findsNothing);
    expect(
      find.byKey(const Key('muscle-bar-quadriceps')),
      findsNothing,
      reason: 'Last week is not part of the current-week split.',
    );

    await tester.tap(find.byKey(const Key('weekly-session-this-week-bench')));
    await tester.pumpAndSettle();
    expect(find.text('Session'), findsOneWidget);
    expect(
      find.byKey(const Key('history-set-this-week-bench-set-0')),
      findsOneWidget,
    );
  });

  testWidgets('Persian RTL renders the weekly summary', (
    WidgetTester tester,
  ) async {
    await _open(tester, locale: const Locale('fa'));
    expect(find.text('خلاصهٔ هفته'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly summary is usable at 200% text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const Key('weekly-summary-body-weight')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
