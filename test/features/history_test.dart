import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/core/calendar/calendar_service.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

Exercise _exercise() {
  return Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    createdAt: DateTime(2026, 10, 1, 9),
  );
}

Session _session(
  String id,
  DateTime startedAt, {
  String? note,
  String? exerciseNote,
  int weightGrams = 100000,
  int reps = 8,
  int? rir = 2,
}) {
  return Session(
    id: id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(hours: 1)),
    note: note,
    exercises: <SessionExercise>[
      SessionExercise(
        id: '$id-exercise',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        note: exerciseNote,
        sets: <SetLog>[
          SetLog(
            id: '$id-set',
            setIndex: 0,
            weightGrams: weightGrams,
            reps: reps,
            rir: rir,
            loggedAt: startedAt.add(const Duration(minutes: 5)),
          ),
        ],
      ),
    ],
  );
}

AppData _seed(List<Session> sessions) {
  return AppData(exercises: <Exercise>[_exercise()], sessions: sessions);
}

final DateTime _now = DateTime(2026, 10, 21, 12);

Future<void> _openHistory(
  WidgetTester tester,
  MemoryAppDataStore store, {
  Locale locale = const Locale('en'),
  DateTime? now,
}) async {
  await pumpGymLogApp(
    tester,
    store: store,
    initialLocation: '/history',
    locale: locale,
    clock: () => now ?? _now,
  );
}

Future<void> _openDetail(WidgetTester tester, String sessionId) async {
  await pumpGymLogApp(
    tester,
    store: MemoryAppDataStore(
      _seed(<Session>[
        _session(
          sessionId,
          DateTime(2026, 10, 20, 10),
          note: 'Good session',
          exerciseNote: 'Pause on the chest.',
        ),
      ]),
    ),
    initialLocation: '/session/$sessionId',
    clock: () => _now,
  );
}

Future<void> _chooseSetAction(
  WidgetTester tester,
  String setKey,
  String actionKey,
) async {
  await tester.tap(find.byKey(Key('history-set-actions-$setKey')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(actionKey)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a trained day is marked and opens that session', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(<Session>[
        _session(
          'marked-session',
          DateTime(2026, 10, 20, 10),
          note: 'Calendar note',
        ),
      ]),
    );

    await _openHistory(tester, store);

    expect(
      find.byKey(const Key('calendar-trained-2026-10-20')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('calendar-day-2026-10-20')), findsOneWidget);
    expect(find.byKey(const Key('calendar-trained-2026-10-19')), findsNothing);
    final Size daySize = tester.getSize(
      find.byKey(const Key('calendar-day-2026-10-20')),
    );
    expect(daySize.width, greaterThanOrEqualTo(48));
    expect(daySize.height, greaterThanOrEqualTo(48));
    final BuildContext context = tester.element(
      find.byKey(const Key('history-month')),
    );
    expect(
      find.text(
        context.formatDate(DateTime(2026, 10), style: AppDateStyle.monthYear),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('calendar-day-2026-10-20')));
    await tester.pumpAndSettle();

    expect(find.text('Calendar note'), findsOneWidget);
    expect(find.byKey(const Key('session-detail-date')), findsOneWidget);
  });

  testWidgets('history opens the current Jalali month on an early-month day', (
    WidgetTester tester,
  ) async {
    await _openHistory(
      tester,
      MemoryAppDataStore(
        _seed(<Session>[_session('mehr-1', DateTime(2026, 9, 23, 10))]),
      ),
      locale: const Locale('fa'),
      now: DateTime(2026, 9, 25, 12),
    );

    expect(find.text('مهر ۱۴۰۵'), findsOneWidget);
    expect(
      find.byKey(const Key('calendar-trained-2026-09-23')),
      findsOneWidget,
    );
  });

  testWidgets('Persian calendar starts on Saturday and pages Jalali months', (
    WidgetTester tester,
  ) async {
    await _openHistory(
      tester,
      MemoryAppDataStore(_seed(<Session>[])),
      locale: const Locale('fa'),
    );

    expect(find.text('مهر ۱۴۰۵'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('calendar-weekday-0'))).data,
      'ش',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('calendar-weekday-1'))).data,
      'ی',
    );
    final double saturdayX = tester
        .getCenter(find.byKey(const Key('calendar-weekday-0')))
        .dx;
    final double sundayX = tester
        .getCenter(find.byKey(const Key('calendar-weekday-1')))
        .dx;
    expect(saturdayX, greaterThan(sundayX));

    await tester.tap(find.byKey(const Key('history-next-month')));
    await tester.pumpAndSettle();
    expect(find.text('آبان ۱۴۰۵'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-previous-month')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-previous-month')));
    await tester.pumpAndSettle();
    expect(find.text('شهریور ۱۴۰۵'), findsOneWidget);
  });

  testWidgets('history rows are built lazily', (WidgetTester tester) async {
    final List<Session> sessions = <Session>[
      for (int index = 0; index < 24; index++)
        _session(
          'session-$index',
          DateTime(2026, 10, 21, 10).subtract(Duration(hours: index)),
        ),
    ];
    final MemoryAppDataStore store = MemoryAppDataStore(_seed(sessions));

    await _openHistory(tester, store);

    expect(find.byKey(const Key('history-session-session-0')), findsOneWidget);
    expect(find.byKey(const Key('history-session-session-23')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('history-session-session-23')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-session-session-23')), findsOneWidget);
  });

  testWidgets('session detail shows exercises, sets, and both notes', (
    WidgetTester tester,
  ) async {
    await _openDetail(tester, 'session-1');

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Good session'), findsOneWidget);
    expect(find.text('Pause on the chest.'), findsOneWidget);
    expect(find.byKey(const Key('history-set-session-1-set')), findsOneWidget);
    expect(find.text('RIR 2'), findsOneWidget);
    expect(find.text('3 × 8–12'), findsOneWidget);
  });

  testWidgets('editing a set persists; delete Undo restores identical data', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(<Session>[_session('session-1', DateTime(2026, 10, 20, 10))]),
    );
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/session/session-1',
      clock: () => _now,
    );

    await _chooseSetAction(
      tester,
      'session-1-set',
      'history-set-edit-session-1-set',
    );
    await tester.enterText(find.byKey(const Key('edit-set-weight')), '105');
    await tester.enterText(find.byKey(const Key('edit-set-reps')), '10');
    await tester.tap(find.byKey(const Key('edit-set-save')));
    await tester.pumpAndSettle();

    final SetLog edited =
        store.data.sessions.single.exercises.single.sets.single;
    expect(edited.weightGrams, 105000);
    expect(edited.reps, 10);

    final Map<String, Object?> beforeDelete = store.data.sessions.single
        .toJson();

    await _chooseSetAction(
      tester,
      'session-1-set',
      'history-set-delete-session-1-set',
    );
    expect(store.data.sessions.single.exercises.single.sets, isEmpty);
    expect(find.text('Set deleted.'), findsOneWidget);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      greaterThanOrEqualTo(const Duration(seconds: 5)),
    );

    // Fake time: Undo must still be available after four seconds.
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(store.data.sessions.single.toJson(), beforeDelete);
  });

  testWidgets('notes can be added from session detail and persist', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(<Session>[_session('session-1', DateTime(2026, 10, 20, 10))]),
    );
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/session/session-1',
      clock: () => _now,
    );

    await tester.tap(find.byKey(const Key('add-session-note')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-field')),
      'Felt strong today.',
    );
    await tester.tap(find.byKey(const Key('note-save')));
    await tester.pumpAndSettle();

    expect(store.data.sessions.single.note, 'Felt strong today.');
    expect(find.text('Felt strong today.'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('add-exercise-note-session-1-exercise')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-field')),
      'Elbows tucked.',
    );
    await tester.tap(find.byKey(const Key('note-save')));
    await tester.pumpAndSettle();

    expect(store.data.sessions.single.exercises.single.note, 'Elbows tucked.');
    expect(find.text('Elbows tucked.'), findsOneWidget);
  });

  testWidgets('history remains usable at 200% text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(<Session>[_session('session-1', DateTime(2026, 10, 20, 10))]),
    );

    await _openHistory(tester, store);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('history-month')), findsOneWidget);
    expect(
      find.byKey(const Key('calendar-trained-2026-10-20')),
      findsOneWidget,
    );
  });

  testWidgets('session detail remains usable at 200% text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _openDetail(tester, 'session-1');

    expect(tester.takeException(), isNull);
    expect(find.text('Good session'), findsOneWidget);
    expect(find.byKey(const Key('history-set-session-1-set')), findsOneWidget);
  });

  testWidgets('note dialog rejects a note over the model limit', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(<Session>[_session('session-1', DateTime(2026, 10, 20, 10))]),
    );
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/session/session-1',
      clock: () => _now,
    );

    await tester.tap(find.byKey(const Key('add-session-note')));
    await tester.pumpAndSettle();
    // 1,001 emoji fit the field's grapheme counter but exceed 2,000 UTF-16
    // code units, the unit enforced by the model.
    await tester.enterText(find.byKey(const Key('note-field')), '😀' * 1001);
    await tester.tap(find.byKey(const Key('note-save')));
    await tester.pumpAndSettle();

    expect(find.text('This note is too long.'), findsOneWidget);
    expect(store.data.sessions.single.note, isNull);
  });

  testWidgets('Undo still restores after leaving session detail', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(<Session>[_session('session-1', DateTime(2026, 10, 20, 10))]),
    );
    await _openHistory(tester, store);
    await tester.tap(find.byKey(const Key('history-session-session-1')));
    await tester.pumpAndSettle();
    await _chooseSetAction(
      tester,
      'session-1-set',
      'history-set-delete-session-1-set',
    );
    expect(store.data.sessions.single.exercises.single.sets, isEmpty);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(
      store.data.sessions.single.exercises.single.sets.single.id,
      'session-1-set',
    );
  });

  testWidgets('deleting a session requires confirmation and removes it', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _seed(<Session>[_session('session-1', DateTime(2026, 10, 20, 10))]),
    );
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/session/session-1',
      clock: () => _now,
    );

    await tester.tap(find.byKey(const Key('delete-session')));
    await tester.pumpAndSettle();
    expect(find.text('Delete session?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(store.data.sessions, isEmpty);
    expect(find.text('Session deleted.'), findsOneWidget);
  });
}
