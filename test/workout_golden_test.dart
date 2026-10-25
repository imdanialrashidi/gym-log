import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/test_app.dart';

Exercise _exercise(String id, String name) {
  return Exercise(
    id: id,
    name: name,
    createdAt: DateTime.utc(2026, 10, 20, 10),
  );
}

Program _program() {
  return Program(
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
      ProgramDay(id: 'day-2', name: 'Lower', sortOrder: 1),
    ],
  );
}

Session _history() {
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
          SetLog(
            id: 'prior-set-0',
            weightGrams: 100000,
            reps: 8,
            rir: 2,
            setIndex: 0,
            loggedAt: DateTime.utc(2026, 10, 20, 10),
          ),
          SetLog(
            id: 'prior-set-1',
            weightGrams: 100000,
            reps: 8,
            rir: 2,
            setIndex: 1,
            loggedAt: DateTime.utc(2026, 10, 20, 10, 10),
          ),
          SetLog(
            id: 'prior-set-2',
            weightGrams: 97500,
            reps: 7,
            rir: 1,
            setIndex: 2,
            loggedAt: DateTime.utc(2026, 10, 20, 10, 20),
          ),
        ],
      ),
    ],
  );
}

Session _activeSession({bool personalRecord = false}) {
  return Session(
    id: 'active-session',
    startedAt: DateTime.utc(2026, 10, 21, 10),
    programDayId: 'day-1',
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'active-session-exercise',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        sets: <SetLog>[
          SetLog(
            id: 'active-set-0',
            weightGrams: personalRecord ? 102500 : 100000,
            reps: 8,
            rir: 2,
            setIndex: 0,
            loggedAt: DateTime.utc(2026, 10, 21, 10, 5),
          ),
        ],
      ),
    ],
  );
}

AppData _data({bool active = false, bool personalRecord = false}) {
  return AppData(
    exercises: <Exercise>[_exercise('exercise-1', 'Bench Press')],
    programs: <Program>[_program()],
    sessions: <Session>[
      _history(),
      if (active) _activeSession(personalRecord: personalRecord),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required bool active,
  bool personalRecord = false,
}) async {
  await pumpGymLogApp(
    tester,
    store: MemoryAppDataStore(
      _data(active: active, personalRecord: personalRecord),
    ),
    initialLocation: '/workout',
    locale: locale,
  );
}

Finder get _screen => find.byType(Scaffold).first;

void main() {
  testWidgets('English LTR workout start golden', (WidgetTester tester) async {
    await _pump(tester, locale: const Locale('en'), active: false);

    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/workout_start_en.png'),
    );
  });

  testWidgets('Persian RTL workout start golden', (WidgetTester tester) async {
    await _pump(tester, locale: const Locale('fa'), active: false);

    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/workout_start_fa.png'),
    );
  });

  testWidgets('English LTR active workout golden', (WidgetTester tester) async {
    await _pump(tester, locale: const Locale('en'), active: true);

    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    expect(find.text('Saved'), findsOneWidget);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/workout_active_en.png'),
    );
  });

  testWidgets('Persian RTL active workout golden', (WidgetTester tester) async {
    await _pump(tester, locale: const Locale('fa'), active: true);

    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    expect(find.text('ذخیره شد'), findsOneWidget);
    await expectLater(
      _screen,
      matchesGoldenFile('goldens/workout_active_fa.png'),
    );
  });

  testWidgets('English LTR PR badge golden', (WidgetTester tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      active: true,
      personalRecord: true,
    );

    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    expect(find.byKey(const Key('set-0-0-pr')), findsOneWidget);
    await expectLater(_screen, matchesGoldenFile('goldens/workout_pr_en.png'));
  });

  testWidgets('Persian RTL PR badge golden', (WidgetTester tester) async {
    await _pump(
      tester,
      locale: const Locale('fa'),
      active: true,
      personalRecord: true,
    );

    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    expect(find.byKey(const Key('set-0-0-pr')), findsOneWidget);
    await expectLater(_screen, matchesGoldenFile('goldens/workout_pr_fa.png'));
  });
}
