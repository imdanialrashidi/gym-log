import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/test_app.dart';

Exercise _exercise(String id, String name) {
  return Exercise(id: id, name: name, createdAt: DateTime.utc(2026, 9, 1, 9));
}

SetLog _set(String id, int weightGrams, int reps, {int? rir}) {
  return SetLog(
    id: id,
    setIndex: 0,
    weightGrams: weightGrams,
    reps: reps,
    rir: rir,
    loggedAt: DateTime.utc(2026, 1, 1, 10),
  );
}

Session _session(
  String id,
  DateTime startedAt,
  int weightGrams,
  int reps, {
  int? rir,
  String exerciseId = 'exercise-1',
}) {
  return Session(
    id: id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(hours: 1)),
    exercises: <SessionExercise>[
      SessionExercise(
        id: '$id-exercise',
        exerciseId: exerciseId,
        sortOrder: 0,
        sets: <SetLog>[_set('$id-set', weightGrams, reps, rir: rir)],
      ),
    ],
  );
}

AppData _data() {
  return AppData(
    exercises: <Exercise>[
      _exercise('exercise-1', 'Bench Press'),
      _exercise('exercise-2', 'Squat'),
    ],
    sessions: <Session>[
      _session('bench-1', DateTime.utc(2026, 9, 1, 10), 95000, 8),
      _session('bench-2', DateTime.utc(2026, 9, 8, 10), 90000, 13, rir: 3),
      _session('bench-3', DateTime.utc(2026, 9, 15, 10), 100000, 7, rir: 2),
      _session('bench-4', DateTime.utc(2026, 9, 22, 10), 100000, 8, rir: 2),
      _session('bench-5', DateTime.utc(2026, 9, 29, 10), 102500, 6, rir: 1),
      _session('bench-6', DateTime.utc(2026, 10, 6, 10), 102500, 8, rir: 2),
      _session('bench-7', DateTime.utc(2026, 10, 13, 10), 105000, 5),
      _session('bench-8', DateTime.utc(2026, 10, 20, 10), 107500, 4, rir: 1),
      _session(
        'squat-1',
        DateTime.utc(2026, 10, 19, 10),
        80000,
        5,
        rir: 2,
        exerciseId: 'exercise-2',
      ),
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
    clock: () => DateTime.utc(2026, 10, 21, 12),
  );
}

Finder get _screen => find.byType(Scaffold).first;

void main() {
  testWidgets('English LTR progress overview golden', (
    WidgetTester tester,
  ) async {
    await _pump(tester, locale: const Locale('en'), location: '/progress');
    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    expect(tester.takeException(), isNull);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/progress_overview_en.png'),
    );
  });

  testWidgets('Persian RTL progress overview golden', (
    WidgetTester tester,
  ) async {
    await _pump(tester, locale: const Locale('fa'), location: '/progress');
    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/progress_overview_fa.png'),
    );
  });

  testWidgets('English LTR exercise progress golden', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      location: '/progress/exercise-1',
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    expect(tester.takeException(), isNull);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/progress_detail_en.png'),
    );
  });

  testWidgets('Persian RTL exercise progress golden', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      locale: const Locale('fa'),
      location: '/progress/exercise-1',
    );
    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/progress_detail_fa.png'),
    );
  });
}
