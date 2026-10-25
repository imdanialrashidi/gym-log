import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/features/workout/presentation/set_row.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

Exercise _exercise(
  String id,
  String name, {
  bool archived = false,
  int incrementGrams = 2500,
}) {
  return Exercise(
    id: id,
    name: name,
    incrementGrams: incrementGrams,
    archivedAt: archived ? DateTime.utc(2026, 10, 21, 12) : null,
    createdAt: DateTime.utc(2026, 10, 20, 10),
  );
}

Session _history({
  List<int> weights = const <int>[100000, 100000, 97500],
  List<int> reps = const <int>[8, 8, 7],
  List<int?> rirs = const <int?>[2, 2, 1],
}) {
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
              rir: rirs[index],
              setIndex: index,
              loggedAt: DateTime.utc(2026, 10, 20, 10, index),
            ),
        ],
      ),
    ],
  );
}

AppData _seed({
  bool withHistory = true,
  bool withProgram = true,
  bool withSecondExercise = false,
  bool archivedPrimary = false,
  WeightUnit unit = WeightUnit.kilograms,
  List<int> historyWeights = const <int>[100000, 100000, 97500],
  List<int> historyReps = const <int>[8, 8, 7],
  List<int?> historyRirs = const <int?>[2, 2, 1],
}) {
  return AppData(
    exercises: <Exercise>[
      _exercise('exercise-1', 'Bench Press', archived: archivedPrimary),
      if (withSecondExercise) _exercise('exercise-2', 'Squat'),
    ],
    programs: withProgram
        ? <Program>[
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
          ]
        : const <Program>[],
    sessions: withHistory
        ? <Session>[
            _history(
              weights: historyWeights,
              reps: historyReps,
              rirs: historyRirs,
            ),
          ]
        : const <Session>[],
    settings: AppSettings(weightUnit: unit),
  );
}

String _fieldText(WidgetTester tester, String key) {
  return tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
}

Future<void> _startDay(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('start-day-day-1')));
  await tester.pumpAndSettle();
}

Future<void> _startEmpty(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('start-empty-workout')));
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

Future<void> _addExercise(WidgetTester tester, String name) async {
  await _reveal(tester, 'session-add-exercise');
  await tester.tap(find.byKey(const Key('session-add-exercise')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  await _reveal(tester, key);
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('program day prelists targets and prefill; one tap logs', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    expect(find.text('3 × 8–12'), findsOneWidget);
    expect(_fieldText(tester, 'set-0-0-weight'), '100');
    expect(_fieldText(tester, 'set-0-0-reps'), '8');
    expect(_fieldText(tester, 'set-0-1-weight'), '100');
    expect(_fieldText(tester, 'set-0-2-weight'), '97.5');
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('set-0-0-rir-2')))
          .selected,
      isTrue,
    );

    // One tap: check.
    await _tap(tester, 'set-0-0-check');

    final List<SetLog> sets = store.data.activeSession!.exercises.single.sets;
    expect(sets, hasLength(1));
    expect(sets.single.weightGrams, 100000);
    expect(sets.single.reps, 8);
    expect(sets.single.rir, 2);
    expect(sets.single.isWarmup, isFalse);
    expect(find.byKey(const Key('set-0-0-saved')), findsOneWidget);
  });

  testWidgets('interactive set-row controls meet the 48 dp target', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    for (final String key in <String>[
      'finish-workout',
      'set-0-0-check',
      'set-0-0-warmup',
      'set-0-0-weight-minus',
      'set-0-0-weight-plus',
      'set-0-0-reps-minus',
      'set-0-0-reps-plus',
      'set-0-0-rir-0',
      'set-0-0-rir-5',
      'add-set-0',
    ]) {
      await _reveal(tester, key);
      final Size size = tester.getSize(find.byKey(Key(key)));
      expect(
        size.width,
        greaterThanOrEqualTo(48),
        reason: '$key width was ${size.width}',
      );
      expect(
        size.height,
        greaterThanOrEqualTo(48),
        reason: '$key height was ${size.height}',
      );
    }
    await _reveal(tester, 'session-add-exercise');
    expect(
      tester.getSize(find.byKey(const Key('session-add-exercise'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('set-row controls keep 48 dp targets at 200% text', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    for (final String key in <String>[
      'finish-workout',
      'set-0-0-check',
      'set-0-0-warmup',
      'set-0-0-weight-minus',
      'set-0-0-weight-plus',
      'set-0-0-reps-minus',
      'set-0-0-reps-plus',
      'set-0-0-rir-0',
      'set-0-0-rir-5',
      'add-set-0',
    ]) {
      await _reveal(tester, key);
      final Size size = tester.getSize(find.byKey(Key(key)));
      expect(size.width, greaterThanOrEqualTo(48), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(48), reason: '$key height');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a changed weight logs within three taps', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    // Two taps: +2.5 kg, then check.
    await _tap(tester, 'set-0-1-weight-plus');
    expect(_fieldText(tester, 'set-0-1-weight'), '102.5');
    await _tap(tester, 'set-0-1-check');

    final SetLog logged =
        store.data.activeSession!.exercises.single.sets.single;
    expect(logged.weightGrams, 102500);
    expect(logged.reps, 8);
  });

  testWidgets('empty start adds an exercise and parses Persian digits', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(withHistory: false, withProgram: false),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startEmpty(tester);
    expect(
      find.text('No exercises yet. Add one to start logging.'),
      findsOneWidget,
    );

    await _addExercise(tester, 'Bench Press');
    await tester.enterText(find.byKey(const Key('set-0-0-weight')), '۸۰٫۵');
    await tester.enterText(find.byKey(const Key('set-0-0-reps')), '۸');
    await _tap(tester, 'set-0-0-check');

    final SetLog logged =
        store.data.activeSession!.exercises.single.sets.single;
    expect(logged.weightGrams, 80500);
    expect(logged.reps, 8);
    expect(logged.rir, isNull);
  });

  testWidgets('invalid numeric input shows a typed error and writes nothing', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(withHistory: false, withProgram: false),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startEmpty(tester);
    await _addExercise(tester, 'Bench Press');

    await tester.enterText(find.byKey(const Key('set-0-0-weight')), 'abc');
    await tester.enterText(find.byKey(const Key('set-0-0-reps')), '8');
    await _tap(tester, 'set-0-0-check');
    expect(find.text('Use digits only.'), findsOneWidget);
    expect(store.data.activeSession!.exercises.single.sets, isEmpty);

    await tester.enterText(find.byKey(const Key('set-0-0-weight')), '80,5');
    await _tap(tester, 'set-0-0-check');
    expect(find.text('Use digits only.'), findsOneWidget);
    expect(store.data.activeSession!.exercises.single.sets, isEmpty);

    await tester.enterText(find.byKey(const Key('set-0-0-weight')), '');
    await _tap(tester, 'set-0-0-check');
    expect(find.text('Enter a weight.'), findsOneWidget);
    expect(store.data.activeSession!.exercises.single.sets, isEmpty);
  });

  testWidgets('out-of-target reps stay neutral and save', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    await tester.enterText(find.byKey(const Key('set-0-0-reps')), '5');
    await _tap(tester, 'set-0-0-check');

    expect(find.text('3 × 8–12'), findsOneWidget);
    expect(find.text('Use 1 to 1000 reps.'), findsNothing);
    expect(find.text('Use digits only.'), findsNothing);
    expect(find.byKey(const Key('set-0-0-saved')), findsOneWidget);
    expect(store.data.activeSession!.exercises.single.sets.single.reps, 5);
  });

  testWidgets('checking one row rebuilds only that row', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    final List<String> rebuiltRowKeys = <String>[];
    debugOnRebuildDirtyWidget = (Element element, bool _) {
      final Widget widget = element.widget;
      if (widget is SetRow) {
        final Key? key = widget.key;
        if (key is ValueKey<String>) {
          rebuiltRowKeys.add(key.value);
        }
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    await _tap(tester, 'set-0-0-check');

    expect(rebuiltRowKeys, isNotEmpty);
    expect(rebuiltRowKeys.toSet(), <String>{'set-0-0'});
    expect(store.data.activeSession!.exercises.single.sets, hasLength(1));
  });

  testWidgets('warm-up toggle is stored with the set', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    await _tap(tester, 'set-0-0-warmup');
    await _tap(tester, 'set-0-0-rir-5');
    await _tap(tester, 'set-0-0-check');

    final SetLog logged =
        store.data.activeSession!.exercises.single.sets.single;
    expect(logged.isWarmup, isTrue);
    expect(logged.rir, 5);
  });

  testWidgets('switching units repeatedly changes display only', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(
        unit: WeightUnit.pounds,
        historyWeights: const <int>[20412, 20412, 20412],
        historyReps: const <int>[8, 8, 8],
        historyRirs: const <int?>[2, 2, 2],
      ),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);
    expect(_fieldText(tester, 'set-0-0-weight'), '45');

    await _tap(tester, 'set-0-0-check');
    expect(
      store.data.activeSession!.exercises.single.sets.single.weightGrams,
      20412,
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('kg'));
    await tester.pumpAndSettle();
    expect(store.data.settings.weightUnit, WeightUnit.kilograms);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'set-0-0-weight'), '20.41');
    await _reveal(tester, 'set-0-1-weight');
    expect(_fieldText(tester, 'set-0-1-weight'), '20.41');

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('lb'));
    await tester.pumpAndSettle();
    expect(store.data.settings.weightUnit, WeightUnit.pounds);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'set-0-1-weight'), '45');
    expect(
      store.data.activeSession!.exercises.single.sets.single.weightGrams,
      20412,
    );
  });

  testWidgets('finishing ends the session and keeps logged sets', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);
    await _tap(tester, 'set-0-0-check');

    await _tap(tester, 'finish-workout');
    await tester.pumpAndSettle();
    expect(find.text('Finish workout?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-finish-workout')));
    await tester.pumpAndSettle();

    expect(store.data.activeSession, isNull);
    expect(store.data.sessions.last.endedAt, isNotNull);
    expect(store.data.sessions.last.exercises.single.sets, hasLength(1));
    expect(find.text('No active workout.'), findsOneWidget);
  });

  testWidgets('mid-session add hides exercises already in the workout', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(withSecondExercise: true),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);
    await _reveal(tester, 'session-add-exercise');
    await tester.tap(find.byKey(const Key('session-add-exercise')));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsNothing);
    expect(find.text('Squat'), findsOneWidget);
    await tester.tap(find.text('Squat'));
    await tester.pumpAndSettle();

    expect(store.data.activeSession!.exercises, hasLength(2));
    expect(store.data.activeSession!.exercises.last.exerciseId, 'exercise-2');
  });

  testWidgets('active workout remains usable at 200% text scale', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('set-0-0-weight')), findsOneWidget);
    await _tap(tester, 'set-0-0-check');
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('set-0-0-saved')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _reveal(tester, 'session-add-exercise');
    expect(tester.takeException(), isNull);
  });

  testWidgets('archived exercises still prefill when started from a day', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(archivedPrimary: true),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    expect(find.text('Bench Press'), findsOneWidget);
    expect(_fieldText(tester, 'set-0-0-weight'), '100');
    expect(_fieldText(tester, 'set-0-0-reps'), '8');
  });

  testWidgets('clearing a prefilled RIR is not restored after logging', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);

    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('set-0-0-rir-2')))
          .selected,
      isTrue,
    );
    await _tap(tester, 'set-0-0-rir-2');
    await _tap(tester, 'set-0-0-check');

    final SetLog logged =
        store.data.activeSession!.exercises.single.sets.single;
    expect(logged.rir, isNull);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('set-0-0-rir-2')))
          .selected,
      isFalse,
    );
  });

  testWidgets('re-logging a deleted row dismisses stale Undo', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);
    await _tap(tester, 'set-0-0-check');

    await tester.tap(find.byKey(const Key('set-0-0-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-0-0-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);

    await _tap(tester, 'set-0-0-check');

    expect(store.data.activeSession!.exercises.single.sets, hasLength(1));
    expect(find.text('Undo'), findsNothing);
    expect(find.text('Could not save. Try again.'), findsNothing);
  });

  testWidgets('active-session sets can be edited and deleted with Undo', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await pumpGymLogApp(tester, store: store, initialLocation: '/workout');
    await _startDay(tester);
    await _tap(tester, 'set-0-0-check');

    await tester.tap(find.byKey(const Key('set-0-0-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-0-0-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('edit-set-weight')), '102.5');
    await tester.enterText(find.byKey(const Key('edit-set-reps')), '9');
    await tester.tap(find.byKey(const Key('edit-set-save')));
    await tester.pumpAndSettle();

    expect(
      store.data.activeSession!.exercises.single.sets.single.weightGrams,
      102500,
    );
    expect(store.data.activeSession!.exercises.single.sets.single.reps, 9);

    final Map<String, Object?> beforeDelete = store.data.activeSession!
        .toJson();
    await tester.tap(find.byKey(const Key('set-0-0-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-0-0-delete')));
    await tester.pumpAndSettle();

    expect(store.data.activeSession!.exercises.single.sets, isEmpty);
    expect(find.byKey(const Key('set-0-0-check')), findsOneWidget);
    expect(find.byKey(const Key('set-0-0-saved')), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(store.data.activeSession!.toJson(), beforeDelete);
  });
}
