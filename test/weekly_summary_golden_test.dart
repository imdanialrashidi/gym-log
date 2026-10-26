import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/test_app.dart';

Exercise _exercise(String id, String name, MuscleGroup group) {
  return Exercise(
    id: id,
    name: name,
    muscleGroup: group,
    createdAt: DateTime.utc(2026, 9, 1, 9),
  );
}

Session _session(
  String id,
  DateTime start,
  String exerciseId,
  int weight,
  int reps,
) {
  return Session(
    id: id,
    startedAt: start.toUtc(),
    endedAt: start.add(const Duration(minutes: 72)).toUtc(),
    exercises: <SessionExercise>[
      SessionExercise(
        id: '$id-exercise',
        exerciseId: exerciseId,
        sortOrder: 0,
        sets: <SetLog>[
          SetLog(
            id: '$id-1',
            setIndex: 0,
            weightGrams: weight,
            reps: reps,
            rir: 2,
            loggedAt: start.add(const Duration(minutes: 5)).toUtc(),
          ),
          SetLog(
            id: '$id-2',
            setIndex: 1,
            weightGrams: weight,
            reps: reps - 1,
            rir: 1,
            loggedAt: start.add(const Duration(minutes: 35)).toUtc(),
          ),
        ],
      ),
    ],
  );
}

AppData _data() {
  return AppData(
    exercises: <Exercise>[
      _exercise('bench', 'Bench Press', MuscleGroup.chest),
      _exercise('row', 'Barbell Row', MuscleGroup.back),
      _exercise('squat', 'Squat', MuscleGroup.quadriceps),
    ],
    sessions: <Session>[
      _session('w1', DateTime(2026, 10, 6, 18), 'squat', 120000, 5),
      _session('w2a', DateTime(2026, 10, 13, 18), 'bench', 100000, 8),
      _session('w2b', DateTime(2026, 10, 15, 18), 'row', 80000, 10),
      _session('w3a', DateTime(2026, 10, 19, 18), 'bench', 102500, 8),
      _session('w3b', DateTime(2026, 10, 20, 18), 'row', 82500, 10),
    ],
    bodyWeights: <BodyWeightEntry>[
      BodyWeightEntry(
        id: 'weight-1',
        weightGrams: 80000,
        recordedAt: DateTime(2026, 10, 14, 8).toUtc(),
      ),
      BodyWeightEntry(
        id: 'weight-2',
        weightGrams: 79500,
        recordedAt: DateTime(2026, 10, 19, 8).toUtc(),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, Locale locale) async {
  await pumpGymLogApp(
    tester,
    store: MemoryAppDataStore(_data()),
    initialLocation: '/weekly-summary',
    locale: locale,
    clock: () => DateTime.utc(2026, 10, 21, 12),
  );
}

Finder get _screen => find.byType(Scaffold).first;

void main() {
  testWidgets('English LTR weekly summary golden', (WidgetTester tester) async {
    await _pump(tester, const Locale('en'));
    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    expect(tester.takeException(), isNull);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/weekly_summary_en.png'),
    );
  });

  testWidgets('Persian RTL weekly summary golden', (WidgetTester tester) async {
    await _pump(tester, const Locale('fa'));
    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/weekly_summary_fa.png'),
    );
  });
}
