import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

final DateTime _now = DateTime(2026, 10, 21, 12);

AppData _seed() {
  return AppData(
    exercises: <Exercise>[
      Exercise(
        id: 'exercise-1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        createdAt: DateTime(2026, 9, 1, 9),
      ),
    ],
    sessions: <Session>[
      Session(
        id: 'active',
        startedAt: DateTime(2026, 10, 21, 10).toUtc(),
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
    initialLocation: '/workout',
    locale: locale,
    clock: () => _now,
  );
}

void main() {
  testWidgets('RIR opens a plain-language explainer from a set row', (
    WidgetTester tester,
  ) async {
    await _open(tester);

    final Finder info = find.byKey(const Key('set-0-0-rir-info'));
    await tester.scrollUntilVisible(
      info,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(info);
    await tester.pumpAndSettle();

    expect(find.text('What is RIR?'), findsOneWidget);
    expect(
      find.textContaining('how many good reps you could still complete'),
      findsOneWidget,
    );
    expect(find.text('Reading the scale'), findsOneWidget);
    expect(find.byKey(const Key('rir-info-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const Key('rir-info-close')));
    await tester.pumpAndSettle();
    expect(find.text('What is RIR?'), findsNothing);
  });

  testWidgets('selecting an RIR chip explains the number in place', (
    WidgetTester tester,
  ) async {
    await _open(tester);

    final Finder row = find.byKey(const Key('set-0-0'));
    expect(
      find.descendant(of: row, matching: find.text('Reps left before failure')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('set-0-0-rir-3')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-0-0-rir-3')));
    await tester.pumpAndSettle();

    expect(find.text('3 reps in reserve'), findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text('Reps left before failure')),
      findsNothing,
    );
  });

  testWidgets('RIR explainer and hint exist in Persian', (
    WidgetTester tester,
  ) async {
    await _open(tester, locale: const Locale('fa'));

    expect(find.text('تکرارهای باقی‌مانده تا ناتوانی'), findsWidgets);
    final Finder info = find.byKey(const Key('set-0-0-rir-info'));
    await tester.scrollUntilVisible(
      info,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect(find.text('RIR چیست؟'), findsOneWidget);
    expect(find.text('راهنمای مقیاس'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rir-info-close')));
    await tester.pumpAndSettle();
  });

  testWidgets('RIR explainer stays usable at 200% text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester);
    final Finder info = find.byKey(const Key('set-0-0-rir-info'));
    await tester.scrollUntilVisible(
      info,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(info), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('rir-info-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rir-info-close')));
    await tester.pumpAndSettle();
  });
}
