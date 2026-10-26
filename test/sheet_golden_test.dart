import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/test_app.dart';

Exercise _exercise() => Exercise(
  id: 'exercise-1',
  name: 'Bench Press',
  muscleGroup: MuscleGroup.chest,
  createdAt: DateTime.utc(2026, 10, 20, 9),
);

Session _active() => Session(
  id: 'active',
  startedAt: DateTime.utc(2026, 10, 21, 10),
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

AppData _data({bool active = false}) => AppData(
  exercises: <Exercise>[_exercise()],
  sessions: active ? <Session>[_active()] : const <Session>[],
  settings: const AppSettings(weeklySessionGoal: 3, weeklySetGoal: 12),
);

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required bool active,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpGymLogApp(
    tester,
    store: MemoryAppDataStore(_data(active: active)),
    initialLocation: '/workout',
    locale: locale,
    clock: () => DateTime.utc(2026, 10, 21, 12),
  );
}

Future<void> _reveal(WidgetTester tester, Key key) async {
  final Finder finder = find.byKey(key);
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Finder get _screen => find.byType(Overlay).first;

void main() {
  for (final Locale locale in <Locale>[
    const Locale('en'),
    const Locale('fa'),
  ]) {
    final String suffix = locale.languageCode;
    testWidgets('plate sheet $suffix golden', (WidgetTester tester) async {
      await _pump(tester, locale: locale, active: true);
      await _reveal(tester, const Key('plate-calc-0'));
      await tester.tap(find.byKey(const Key('plate-calc-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('plate-target')), findsOneWidget);
      await expectLater(
        _screen,
        matchesGoldenFile('goldens/plate_sheet_$suffix.png'),
      );
    });

    testWidgets('goal sheet $suffix golden', (WidgetTester tester) async {
      await _pump(tester, locale: locale, active: false);
      await _reveal(tester, const Key('dashboard-goal-block'));
      await tester.tap(find.byKey(const Key('dashboard-goal-block')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('goal-save')), findsOneWidget);
      await expectLater(
        _screen,
        matchesGoldenFile('goldens/goal_sheet_$suffix.png'),
      );
    });
  }
}
