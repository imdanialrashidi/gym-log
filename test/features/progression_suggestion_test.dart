import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

Exercise _exercise({int incrementGrams = defaultKilogramIncrementGrams}) {
  return Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    incrementGrams: incrementGrams,
    createdAt: DateTime.utc(2026, 10, 20, 10),
  );
}

Session _history(List<int> weights, List<int> reps) {
  return Session(
    id: 'prior-session',
    startedAt: DateTime.utc(2026, 10, 20, 10),
    endedAt: DateTime.utc(2026, 10, 20, 11),
    programDayId: 'day-1',
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'prior-session-exercise',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        sets: <SetLog>[
          for (int index = 0; index < weights.length; index++)
            SetLog(
              id: 'prior-set-$index',
              weightGrams: weights[index],
              reps: reps[index],
              rir: 2,
              setIndex: index,
              loggedAt: DateTime.utc(2026, 10, 20, 10, index),
            ),
        ],
      ),
    ],
  );
}

AppData _seed({
  required List<int> weights,
  required List<int> reps,
  WeightUnit unit = WeightUnit.kilograms,
  int incrementGrams = defaultKilogramIncrementGrams,
}) {
  return AppData(
    exercises: <Exercise>[_exercise(incrementGrams: incrementGrams)],
    programs: <Program>[
      Program(
        id: 'program-1',
        name: 'Upper/Lower',
        createdAt: DateTime.utc(2026, 10, 20, 9),
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
        ],
      ),
    ],
    sessions: <Session>[_history(weights, reps)],
    settings: AppSettings(weightUnit: unit),
  );
}

String _fieldText(WidgetTester tester, String key) {
  return tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
}

String _text(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

Future<void> _startDay(WidgetTester tester) async {
  await _reveal(tester, 'start-day-day-1');
  await tester.tap(find.byKey(const Key('start-day-day-1')));
  await tester.pumpAndSettle();
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

Future<void> _tap(WidgetTester tester, String key) async {
  await _reveal(tester, key);
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('all-at-max shows the add-weight reason, prefills it visibly, '
      'and reverts in one tap without writing', (WidgetTester tester) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(weights: <int>[100000, 100000, 100000], reps: <int>[12, 12, 12]),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    expect(
      _text(tester, 'set-0-0-suggestion-reason'),
      'All working sets reached 12 reps last time (sets: 3), so add 2.5 kg.',
    );
    expect(
      _text(tester, 'set-0-1-suggestion-reason'),
      'All working sets reached 12 reps last time (sets: 3), so add 2.5 kg.',
    );
    expect(
      _text(tester, 'set-0-2-suggestion-reason'),
      'All working sets reached 12 reps last time (sets: 3), so add 2.5 kg.',
    );
    expect(_text(tester, 'set-0-0-suggestion-last'), 'Last time: 100 × 12');
    expect(_fieldText(tester, 'set-0-0-weight'), '102.5');
    expect(_fieldText(tester, 'set-0-0-reps'), '8');
    expect(find.byKey(const Key('set-0-0-suggestion')), findsOneWidget);
    expect(store.data.activeSession!.exercises.single.sets, isEmpty);

    await _tap(tester, 'set-0-0-suggestion-revert');

    expect(_fieldText(tester, 'set-0-0-weight'), '100');
    expect(_fieldText(tester, 'set-0-0-reps'), '12');
    expect(find.byKey(const Key('set-0-0-suggestion')), findsNothing);
    expect(find.byKey(const Key('set-0-1-suggestion')), findsOneWidget);
    expect(find.byKey(const Key('set-0-1-suggestion-reason')), findsOneWidget);

    await _tap(tester, 'set-0-0-check');

    final SetLog logged =
        store.data.activeSession!.exercises.single.sets.single;
    expect(logged.weightGrams, 100000);
    expect(logged.reps, 12);
    expect(find.byKey(const Key('set-0-0-suggestion')), findsNothing);
  });

  testWidgets('a set below the minimum shows the hold reason and reverts', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(weights: <int>[100000, 100000, 100000], reps: <int>[12, 12, 7]),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    expect(
      _text(tester, 'set-0-0-suggestion-reason'),
      'Below 8 reps last time; keep the weight and rebuild.',
    );
    expect(_fieldText(tester, 'set-0-0-weight'), '100');
    expect(_fieldText(tester, 'set-0-0-reps'), '8');
    expect(_text(tester, 'set-0-0-suggestion-last'), 'Last time: 100 × 12');

    await _reveal(tester, 'set-0-2-suggestion-last');
    expect(_text(tester, 'set-0-2-suggestion-last'), 'Last time: 100 × 7');
    await _tap(tester, 'set-0-2-suggestion-revert');
    expect(_fieldText(tester, 'set-0-2-reps'), '7');
    await _tap(tester, 'set-0-2-check');

    final SetLog logged = store.data.activeSession!.exercises.single.sets
        .singleWhere((SetLog set) => set.setIndex == 2);
    expect(logged.weightGrams, 100000);
    expect(logged.reps, 7);
  });

  testWidgets('Persian renders the same reason numbers and revert action', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(weights: <int>[100000, 100000, 100000], reps: <int>[12, 12, 12]),
    );

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/workout',
      locale: const Locale('fa'),
    );
    await _startDay(tester);

    expect(
      _text(tester, 'set-0-0-suggestion-reason'),
      'دفعه قبل هر ۳ ست به ۱۲ تکرار رسیدی؛ ۲.۵ کیلوگرم اضافه کن.',
    );
    expect(_text(tester, 'set-0-0-suggestion-last'), 'دفعه قبل: ۱۰۰ × ۱۲');
    expect(find.text('پیشنهاد'), findsWidgets);
    expect(find.text('همان دفعه قبل'), findsWidgets);
    expect(_fieldText(tester, 'set-0-0-weight'), '۱۰۲.۵');
    expect(_fieldText(tester, 'set-0-0-reps'), '۸');
  });

  testWidgets('suggestion stays usable at 200% text scale', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(weights: <int>[100000, 100000, 100000], reps: <int>[12, 12, 12]),
    );
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    expect(tester.takeException(), isNull);
    await _reveal(tester, 'set-0-0-suggestion');
    expect(find.byKey(const Key('set-0-0-suggestion')), findsOneWidget);
    await _tap(tester, 'set-0-0-suggestion-revert');
    expect(tester.takeException(), isNull);
    expect(_fieldText(tester, 'set-0-0-reps'), '12');
    await _tap(tester, 'set-0-0-check');
    expect(tester.takeException(), isNull);
    expect(store.data.activeSession!.exercises.single.sets.single.reps, 12);
  });

  testWidgets('editing prior history does not desync an open draft', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(weights: <int>[100000, 100000, 100000], reps: <int>[12, 12, 12]),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    const String initialReason =
        'All working sets reached 12 reps last time (sets: 3), so add 2.5 kg.';
    expect(_text(tester, 'set-0-0-suggestion-reason'), initialReason);
    expect(_fieldText(tester, 'set-0-0-weight'), '102.5');
    expect(_fieldText(tester, 'set-0-0-reps'), '8');

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final SetLog priorSet = store.data
        .sessionById('prior-session')!
        .exercises
        .single
        .sets
        .last;
    await container
        .read(appDataControllerProvider.notifier)
        .updateSet(
          sessionId: 'prior-session',
          sessionExerciseId: 'prior-session-exercise',
          setId: priorSet.id,
          entry: SetEntry(
            weightGrams: priorSet.weightGrams,
            reps: 11,
            rir: priorSet.rir,
          ),
        );
    expect(
      store.data.sessionById('prior-session')!.exercises.single.sets.last.reps,
      11,
    );

    // Force the workout screen to rebuild from the changed document. The
    // fourth row can only appear if the rebuild happened.
    await _tap(tester, 'add-set-0');
    expect(find.byKey(const Key('set-0-3-suggestion-reason')), findsOneWidget);

    expect(_text(tester, 'set-0-0-suggestion-reason'), initialReason);
    expect(_fieldText(tester, 'set-0-0-weight'), '102.5');
    expect(_fieldText(tester, 'set-0-0-reps'), '8');
  });

  testWidgets('mixed working weights show no suggestion', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(weights: <int>[100000, 102500, 100000], reps: <int>[12, 12, 12]),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    expect(find.text('Suggestion'), findsNothing);
    expect(find.byKey(const Key('set-0-0-suggestion')), findsNothing);
    expect(_fieldText(tester, 'set-0-0-weight'), '100');
    expect(_fieldText(tester, 'set-0-0-reps'), '12');
    expect(store.data.activeSession!.exercises.single.sets, isEmpty);
  });

  testWidgets('bodyweight suggests reps only and never a weight increase', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(weights: <int>[0, 0, 0], reps: <int>[12, 12, 12]),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    expect(
      _text(tester, 'set-0-0-suggestion-reason'),
      'Your weakest set was 12 reps; aim for 13 reps.',
    );
    expect(_fieldText(tester, 'set-0-0-weight'), '0');
    expect(_fieldText(tester, 'set-0-0-reps'), '13');

    await _tap(tester, 'set-0-0-check');

    final SetLog logged =
        store.data.activeSession!.exercises.single.sets.single;
    expect(logged.weightGrams, 0);
    expect(logged.reps, 13);
  });
}
