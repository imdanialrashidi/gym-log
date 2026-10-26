import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_store.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

Exercise _exercise() {
  return Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    createdAt: DateTime.utc(2026, 10, 20, 10),
  );
}

Session _history() {
  return Session(
    id: 'prior-session',
    startedAt: DateTime.utc(2026, 10, 20, 10),
    endedAt: DateTime.utc(2026, 10, 20, 11),
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'prior-session-exercise',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        sets: <SetLog>[
          SetLog(
            id: 'prior-set-0',
            setIndex: 0,
            weightGrams: 100000,
            reps: 8,
            rir: 2,
            loggedAt: DateTime.utc(2026, 10, 20, 10),
          ),
        ],
      ),
    ],
  );
}

AppData _seed({DigitStyle? digitStyle, int? defaultIncrementGrams}) {
  return AppData(
    exercises: <Exercise>[_exercise()],
    programs: <Program>[
      Program(
        id: 'program-1',
        name: 'Upper',
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
                targetSets: 1,
                repMin: 8,
                repMax: 12,
                sortOrder: 0,
              ),
            ],
          ),
        ],
      ),
    ],
    sessions: <Session>[_history()],
    settings: AppSettings(
      digitStyle: digitStyle,
      defaultIncrementGrams: defaultIncrementGrams,
    ),
  );
}

String _fieldText(WidgetTester tester, String key) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}

Future<void> _openSettings(
  WidgetTester tester,
  MemoryAppDataStore store, {
  Locale locale = const Locale('en'),
}) async {
  await pumpGymLogApp(
    tester,
    store: store,
    initialLocation: '/settings',
    locale: locale,
  );
}

void main() {
  testWidgets(
    'digit setting changes display and persists without touching data',
    (WidgetTester tester) async {
      final MemoryAppDataStore store = MemoryAppDataStore(_seed());
      final String exercisesBefore = store.data
          .toJson()['exercises']
          .toString();
      final String sessionsBefore = store.data.toJson()['sessions'].toString();

      await _openSettings(tester, store);
      expect(find.text('01:30'), findsOneWidget);

      await tester.tap(find.text('Persian digits'));
      await tester.pumpAndSettle();

      expect(find.text('۰۱:۳۰'), findsOneWidget);
      expect(store.data.settings.digitStyle, DigitStyle.persian);
      expect(store.data.toJson()['exercises'].toString(), exercisesBefore);
      expect(store.data.toJson()['sessions'].toString(), sessionsBefore);

      await tester.tap(find.text('Latin digits'));
      await tester.pumpAndSettle();
      expect(find.text('01:30'), findsOneWidget);
      expect(store.data.settings.digitStyle, DigitStyle.latin);
    },
  );

  testWidgets('unset digit style follows the UI language', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore faStore = MemoryAppDataStore(_seed());
    await _openSettings(tester, faStore, locale: const Locale('fa'));
    expect(find.text('۰۱:۳۰'), findsOneWidget);

    final MemoryAppDataStore enStore = MemoryAppDataStore(_seed());
    await _openSettings(tester, enStore);
    expect(find.text('01:30'), findsOneWidget);
  });

  testWidgets('Persian set row accepts Latin and Persian input', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/workout',
      locale: const Locale('fa'),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('start-day-day-1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('start-day-day-1'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-day-day-1')));
    await tester.pumpAndSettle();

    // Locale default: Persian digits in prefilled fields.
    expect(_fieldText(tester, 'set-0-0-weight'), '۱۰۰');
    expect(
      _fieldText(tester, 'set-0-0-reps'),
      isNot(matches(RegExp(r'[0-9]'))),
    );
    expect(_fieldText(tester, 'set-0-0-reps'), matches(RegExp(r'[۰-۹]')));

    // Latin input still parses.
    await tester.enterText(find.byKey(const Key('set-0-0-weight')), '102.5');
    await tester.enterText(find.byKey(const Key('set-0-0-reps')), '9');
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('set-0-0-check'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-0-0-check')));
    await tester.pumpAndSettle();

    final SetLog logged = store.data.sessions.last.exercises.single.sets.single;
    expect(logged.weightGrams, 102500);
    expect(logged.reps, 9);
    expect(store.data.sessions.last.exercises.single.sets, hasLength(1));
  });

  testWidgets('planner and exercise inputs accept Persian digits', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/plan-item-editor/day-1/item-1',
      locale: const Locale('fa'),
    );

    await tester.enterText(find.byKey(const Key('target-sets-field')), '۴');
    await tester.enterText(find.byKey(const Key('plan-rep-min-field')), '۶');
    await tester.enterText(find.byKey(const Key('plan-rep-max-field')), '۱۰');
    await tester.tap(find.byKey(const Key('save-plan-item')));
    await tester.pumpAndSettle();

    final PlanItem updated =
        store.data.programs.single.days.single.items.single;
    expect(updated.targetSets, 4);
    expect(updated.repMin, 6);
    expect(updated.repMax, 10);

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/exercise-editor/exercise-1',
      locale: const Locale('fa'),
    );
    await tester.enterText(
      find.byKey(const Key('exercise-rep-min-field')),
      '۵',
    );
    await tester.enterText(
      find.byKey(const Key('exercise-rep-max-field')),
      '۹',
    );
    await tester.enterText(
      find.byKey(const Key('exercise-increment-field')),
      '۲٫۵',
    );
    await tester.tap(find.byKey(const Key('save-exercise')));
    await tester.pumpAndSettle();

    final Exercise exercise = store.data.exerciseById('exercise-1')!;
    expect(exercise.defaultRepMin, 5);
    expect(exercise.defaultRepMax, 9);
    expect(exercise.incrementGrams, 2500);
  });

  testWidgets('reps stepper keeps Persian digits in the field', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/workout',
      locale: const Locale('fa'),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('start-day-day-1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('start-day-day-1'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-day-day-1')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('set-0-0-reps-plus')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-0-0-reps-plus')));
    await tester.pumpAndSettle();

    final String text = _fieldText(tester, 'set-0-0-reps');
    expect(text, matches(RegExp(r'^[۰-۹]+$')));
  });

  testWidgets('digit control is disabled when app data cannot load', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: _LoadFailingStore(),
      initialLocation: '/settings',
    );

    final SegmentedButton<DigitStyle> control = tester.widget(
      find.byKey(const Key('digit-style-control')),
    );
    expect(control.onSelectionChanged, isNull);
    expect(find.text('Could not open your data.'), findsWidgets);
  });

  testWidgets('unit and digit changes leave exercise and session JSON intact', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    final Map<String, Object?> before = store.data.toJson();
    final String exercises = before['exercises'].toString();
    final String programs = before['programs'].toString();
    final String sessions = before['sessions'].toString();

    await _openSettings(tester, store);
    await tester.tap(find.text('lb'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Persian digits'));
    await tester.pumpAndSettle();

    expect(store.data.settings.weightUnit, WeightUnit.pounds);
    expect(store.data.settings.digitStyle, DigitStyle.persian);
    expect(store.data.toJson()['exercises'].toString(), exercises);
    expect(store.data.toJson()['programs'].toString(), programs);
    expect(store.data.toJson()['sessions'].toString(), sessions);
  });

  testWidgets('default increment setting feeds a new exercise', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await _openSettings(tester, store);

    await tester.scrollUntilVisible(
      find.byKey(const Key('default-increment-row')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('default-increment-row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('default-increment-field')),
      '5',
    );
    await tester.tap(find.byKey(const Key('default-increment-save')));
    await tester.pumpAndSettle();

    expect(store.data.settings.defaultIncrementGrams, 5000);

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/exercise-editor/new',
    );
    expect(_fieldText(tester, 'exercise-increment-field'), '5');
  });

  testWidgets('confirming the default increment unchanged keeps null', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    expect(store.data.settings.defaultIncrementGrams, isNull);
    await _openSettings(tester, store);

    await tester.scrollUntilVisible(
      find.byKey(const Key('default-increment-row')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('default-increment-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('default-increment-save')));
    await tester.pumpAndSettle();

    expect(store.data.settings.defaultIncrementGrams, isNull);
    expect(store.data.settings.incrementFor(WeightUnit.kilograms), 2500);
  });

  testWidgets('increment dialog accepts Persian digits and rejects zero', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await _openSettings(tester, store, locale: const Locale('fa'));

    await tester.scrollUntilVisible(
      find.byKey(const Key('default-increment-row')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('default-increment-row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('default-increment-field')),
      '۰',
    );
    await tester.tap(find.byKey(const Key('default-increment-save')));
    await tester.pumpAndSettle();
    expect(find.text('یک مقدار مثبت وارد کن.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('default-increment-field')),
      '۲٫۵',
    );
    await tester.tap(find.byKey(const Key('default-increment-save')));
    await tester.pumpAndSettle();
    // 2.5 kg is the unit default, so confirming it keeps the null
    // "follow the unit" state instead of pinning an explicit override.
    expect(store.data.settings.defaultIncrementGrams, isNull);
    expect(store.data.settings.incrementFor(WeightUnit.kilograms), 2500);
  });
}

class _LoadFailingStore implements AppDataStore {
  @override
  Future<AppData> load() async {
    throw const DataStoreException('injected load failure');
  }

  @override
  Future<void> save(AppData data) async {}

  @override
  Future<void> snapshot() async {}

  @override
  Future<List<DataSnapshotInfo>> listSnapshots() async =>
      const <DataSnapshotInfo>[];

  @override
  Future<AppData> loadSnapshot(String fileName) async {
    throw const DataStoreException('injected missing snapshot');
  }
}
