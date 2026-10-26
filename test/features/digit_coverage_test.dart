import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

Exercise _exercise(String id, String name) {
  return Exercise(id: id, name: name, createdAt: DateTime.utc(2026, 9, 1, 9));
}

SetLog _set(String id, int grams, int reps, {int? rir}) {
  return SetLog(
    id: id,
    setIndex: 0,
    weightGrams: grams,
    reps: reps,
    rir: rir,
    loggedAt: DateTime.utc(2026, 10, 20, 10),
  );
}

Session _history() {
  return Session(
    id: 'history-1',
    startedAt: DateTime.utc(2026, 10, 20, 10),
    endedAt: DateTime.utc(2026, 10, 20, 11),
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'history-1-exercise',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        sets: <SetLog>[_set('history-set', 100000, 8, rir: 2)],
      ),
    ],
  );
}

Session _active() {
  return Session(
    id: 'active-1',
    startedAt: DateTime.utc(2026, 10, 21, 10),
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'active-1-exercise',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        targetSets: 2,
        repMin: 8,
        repMax: 12,
        sets: <SetLog>[_set('active-set', 100000, 8, rir: 2)],
      ),
    ],
  );
}

AppData _data({DigitStyle? digitStyle}) {
  return AppData(
    exercises: <Exercise>[
      _exercise('exercise-1', 'Bench Press'),
      _exercise('exercise-2', 'Squat'),
    ],
    programs: <Program>[
      Program(
        id: 'program-1',
        name: 'Upper/Lower',
        createdAt: DateTime.utc(2026, 9, 1, 10),
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
    sessions: <Session>[_history(), _active()],
    settings: AppSettings(digitStyle: digitStyle),
  );
}

const List<String> _routes = <String>[
  '/workout',
  '/programs',
  '/program-editor/program-1',
  '/day-editor/program-1/day-1',
  '/plan-item-editor/day-1/item-1',
  '/history',
  '/session/history-1',
  '/progress',
  '/progress/exercise-1',
  '/body-weight',
  '/weekly-summary',
  '/exercises',
  '/exercise-picker',
  '/exercise-editor/exercise-1',
  '/settings',
];

Set<String> _visibleStrings(WidgetTester tester) {
  final Set<String> values = <String>{};
  for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
    if (text.data != null) {
      values.add(text.data!);
    }
  }
  for (final EditableText text in tester.widgetList<EditableText>(
    find.byType(EditableText),
  )) {
    values.add(text.controller.text);
  }
  return values;
}

void main() {
  testWidgets('Persian digit style covers session dialogs too', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/session/history-1',
      locale: const Locale('fa'),
      clock: () => DateTime.utc(2026, 10, 21, 12),
    );

    await tester.tap(find.byKey(const Key('history-set-actions-history-set')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-set-edit-history-set')));
    await tester.pumpAndSettle();

    List<String> offenders = _visibleStrings(tester)
        .where((String value) => RegExp(r'[0-9]').hasMatch(value))
        .toList();
    expect(offenders, isEmpty, reason: 'edit-set dialog leaked Latin digits');
    await tester.tap(find.byKey(const Key('edit-set-cancel')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-session-note')));
    await tester.pumpAndSettle();
    offenders = _visibleStrings(tester)
        .where((String value) => RegExp(r'[0-9]').hasMatch(value))
        .toList();
    expect(offenders, isEmpty, reason: 'note dialog leaked Latin digits');
  });

  testWidgets('Persian digit style covers every visible number', (
    WidgetTester tester,
  ) async {
    for (final String route in _routes) {
      await pumpGymLogApp(
        tester,
        store: MemoryAppDataStore(_data()),
        initialLocation: route,
        locale: const Locale('fa'),
        clock: () => DateTime.utc(2026, 10, 21, 12),
      );
      expect(tester.takeException(), isNull, reason: route);
      final List<String> offenders = _visibleStrings(tester)
          .where((String value) => RegExp(r'[0-9]').hasMatch(value))
          .toList();
      expect(
        offenders,
        isEmpty,
        reason: '$route leaked Latin digits: $offenders',
      );
    }
  });

  testWidgets('Latin digit style covers every visible number', (
    WidgetTester tester,
  ) async {
    for (final String route in _routes) {
      await pumpGymLogApp(
        tester,
        store: MemoryAppDataStore(_data(digitStyle: DigitStyle.latin)),
        initialLocation: route,
        locale: const Locale('fa'),
        clock: () => DateTime.utc(2026, 10, 21, 12),
      );
      expect(tester.takeException(), isNull, reason: route);
      final List<String> offenders = _visibleStrings(tester)
          .where(
            (String value) =>
                RegExp(r'[\u06F0-\u06F9\u0660-\u0669]').hasMatch(value),
          )
          .toList();
      expect(
        offenders,
        isEmpty,
        reason: '$route leaked Persian digits: $offenders',
      );
    }
  });
}
