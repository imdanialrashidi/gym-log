import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

final DateTime _now = DateTime(2026, 10, 21, 12);

AppData _seed({List<BodyWeightEntry>? weights}) {
  return AppData(
    exercises: <Exercise>[
      Exercise(
        id: 'exercise-1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        createdAt: DateTime(2026, 9, 1, 9),
      ),
    ],
    programs: <Program>[
      Program(
        id: 'program-1',
        name: 'Upper/Lower',
        createdAt: DateTime(2026, 9, 1, 9),
        days: <ProgramDay>[
          ProgramDay(id: 'day-1', name: 'Upper', sortOrder: 0),
        ],
      ),
    ],
    bodyWeights:
        weights ??
        <BodyWeightEntry>[
          BodyWeightEntry(
            id: 'weight-1',
            weightGrams: 80000,
            recordedAt: DateTime(2026, 10, 7, 8).toUtc(),
          ),
          BodyWeightEntry(
            id: 'weight-2',
            weightGrams: 79500,
            recordedAt: DateTime(2026, 10, 14, 8).toUtc(),
          ),
        ],
  );
}

Future<void> _openWeight(
  WidgetTester tester,
  MemoryAppDataStore store, {
  Locale locale = const Locale('en'),
}) async {
  await pumpGymLogApp(
    tester,
    store: store,
    initialLocation: '/body-weight',
    locale: locale,
    clock: () => _now,
  );
}

void main() {
  testWidgets('logs a valid weight and shows it in the trend and history', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await _openWeight(tester, store);

    await tester.tap(find.byKey(const Key('body-weight-log')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('body-weight-field')), '78.5');
    await tester.tap(find.byKey(const Key('body-weight-save')));
    await tester.pumpAndSettle();

    expect(store.data.bodyWeights, hasLength(3));
    expect(store.data.bodyWeights.last.weightGrams, 78500);
    expect(find.text('Weight logged.'), findsOneWidget);
    expect(find.byKey(const Key('body-weight-chart')), findsOneWidget);
    expect(
      find.byKey(
        ValueKey<String>('body-weight-entry-${store.data.bodyWeights.last.id}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a second check-in in the same week updates the reading', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(
        weights: <BodyWeightEntry>[
          BodyWeightEntry(
            id: 'this-week',
            weightGrams: 79800,
            recordedAt: DateTime(2026, 10, 19, 8).toUtc(),
          ),
        ],
      ),
    );
    await _openWeight(tester, store);

    await tester.tap(find.byKey(const Key('body-weight-log')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('body-weight-field')), '79.1');
    await tester.tap(find.byKey(const Key('body-weight-save')));
    await tester.pumpAndSettle();

    expect(store.data.bodyWeights, hasLength(1));
    expect(store.data.bodyWeights.single.id, 'this-week');
    expect(store.data.bodyWeights.single.weightGrams, 79100);
  });

  testWidgets('rejects an implausible weight without writing', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await _openWeight(tester, store);

    await tester.tap(find.byKey(const Key('body-weight-log')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('body-weight-field')), '5');
    await tester.tap(find.byKey(const Key('body-weight-save')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a realistic body weight.'), findsOneWidget);
    expect(store.data.bodyWeights, hasLength(2));
    expect(store.saveCount, 0);
  });

  testWidgets('delete offers Undo and restores the exact reading', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await _openWeight(tester, store);

    await tester.scrollUntilVisible(
      find.byKey(const Key('delete-body-weight-weight-2')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('delete-body-weight-weight-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(store.data.bodyWeights, hasLength(1));
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(store.data.bodyWeights, hasLength(2));
    expect(store.data.bodyWeights.last.weightGrams, 79500);
  });

  testWidgets('dashboard opens the body-weight screen', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_seed()),
      initialLocation: '/workout',
      clock: () => _now,
    );
    final Finder action = find.byKey(const Key('dashboard-open-body-weight'));
    await tester.scrollUntilVisible(
      action,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(action), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body-weight-log')), findsOneWidget);
  });

  testWidgets('progress opens the body-weight screen', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_seed()),
      initialLocation: '/progress',
      clock: () => _now,
    );
    final Finder action = find.byKey(const Key('progress-open-body-weight'));
    await tester.scrollUntilVisible(
      action,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body-weight-log')), findsOneWidget);
  });

  testWidgets('body weight is usable at 200% text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(
        weights: <BodyWeightEntry>[
          BodyWeightEntry(
            id: 'weight-1',
            weightGrams: 80000,
            recordedAt: DateTime(2026, 10, 21, 8).toUtc(),
          ),
        ],
      ),
    );
    await _openWeight(tester, store);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const Key('body-weight-log-secondary')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Persian RTL renders the weight screen with Persian digits', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(_seed());
    await _openWeight(tester, store, locale: const Locale('fa'));
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
    expect(find.text('وزن بدن'), findsWidgets);
    expect(find.text('۷۹.۵'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
