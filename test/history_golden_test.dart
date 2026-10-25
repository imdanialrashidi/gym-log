import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/test_app.dart';

Exercise _exercise() {
  return Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    createdAt: DateTime(2026, 10, 1, 9),
  );
}

Session _session(String id, DateTime startedAt) {
  return Session(
    id: id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(hours: 1)),
    note: 'Felt strong. Keep the same weight next week.',
    exercises: <SessionExercise>[
      SessionExercise(
        id: '$id-exercise',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        note: 'Pause briefly on the chest.',
        sets: <SetLog>[
          for (int index = 0; index < 3; index++)
            SetLog(
              id: '$id-set-$index',
              setIndex: index,
              weightGrams: 100000,
              reps: 8,
              rir: 2,
              loggedAt: startedAt.add(Duration(minutes: index * 5)),
            ),
        ],
      ),
    ],
  );
}

AppData _data() {
  return AppData(
    exercises: <Exercise>[_exercise()],
    sessions: <Session>[
      _session('session-1', DateTime(2026, 10, 20, 10)),
      _session('session-2', DateTime(2026, 10, 18, 18)),
      _session('session-3', DateTime(2026, 10, 15, 9)),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required String location,
}) async {
  await pumpGymLogApp(
    tester,
    store: MemoryAppDataStore(_data()),
    initialLocation: location,
    locale: locale,
    clock: () => DateTime(2026, 10, 21, 12),
  );
}

Finder get _screen => find.byType(Scaffold).first;

void main() {
  testWidgets('English LTR history golden', (WidgetTester tester) async {
    await _pump(tester, locale: const Locale('en'), location: '/history');
    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    await expectLater(_screen, matchesGoldenFile('goldens/history_en.png'));
  });

  testWidgets('Persian RTL history golden', (WidgetTester tester) async {
    await _pump(tester, locale: const Locale('fa'), location: '/history');
    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    await expectLater(_screen, matchesGoldenFile('goldens/history_fa.png'));
  });

  testWidgets('English LTR session detail golden', (WidgetTester tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      location: '/session/session-1',
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/session_detail_en.png'),
    );
  });

  testWidgets('Persian RTL session detail golden', (WidgetTester tester) async {
    await _pump(
      tester,
      locale: const Locale('fa'),
      location: '/session/session-1',
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/session_detail_fa.png'),
    );
  });
}
