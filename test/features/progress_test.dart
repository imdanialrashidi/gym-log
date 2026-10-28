import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/features/progress/presentation/progress_chart.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

final DateTime _now = DateTime.utc(2026, 10, 21, 12);

Exercise _exercise(String id, String name) {
  return Exercise(id: id, name: name, createdAt: DateTime.utc(2026, 9, 1, 9));
}

SetLog _set(
  String id,
  int weightGrams,
  int reps, {
  int? rir,
  bool warmup = false,
  int index = 0,
}) {
  return SetLog(
    id: id,
    setIndex: index,
    weightGrams: weightGrams,
    reps: reps,
    rir: rir,
    isWarmup: warmup,
    loggedAt: DateTime.utc(2026, 1, 1, 10).add(Duration(minutes: index)),
  );
}

Session _session(
  String id,
  DateTime startedAt,
  List<SetLog> sets, {
  String exerciseId = 'exercise-1',
  bool active = false,
}) {
  return Session(
    id: id,
    startedAt: startedAt,
    endedAt: active ? null : startedAt.add(const Duration(hours: 1)),
    exercises: <SessionExercise>[
      SessionExercise(
        id: '$id-exercise',
        exerciseId: exerciseId,
        sortOrder: 0,
        sets: sets,
      ),
    ],
  );
}

AppData _data({List<Session> sessions = const <Session>[]}) {
  return AppData(
    exercises: <Exercise>[
      _exercise('exercise-1', 'Bench Press'),
      _exercise('exercise-2', 'Squat'),
    ],
    sessions: sessions,
  );
}

Future<void> _pumpProgress(
  WidgetTester tester,
  MemoryAppDataStore store, {
  String location = '/progress',
  Locale locale = const Locale('en'),
}) async {
  await pumpGymLogApp(
    tester,
    store: store,
    initialLocation: location,
    locale: locale,
    clock: () => _now,
  );
}

List<Session> _twoExercises() {
  return <Session>[
    _session('bench-session', DateTime.utc(2026, 10, 20), <SetLog>[
      _set('bench-warmup', 120000, 5, warmup: true),
      _set('bench-1', 100000, 8, rir: 2, index: 1),
      _set('bench-2', 105000, 6, rir: 3, index: 2),
    ]),
    _session('squat-session', DateTime.utc(2026, 10, 18), <SetLog>[
      _set('squat-1', 80000, 5),
    ], exerciseId: 'exercise-2'),
  ];
}

void main() {
  testWidgets('overview lists trained exercises and opens charts', (
    WidgetTester tester,
  ) async {
    await _pumpProgress(
      tester,
      MemoryAppDataStore(_data(sessions: _twoExercises())),
    );

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
    expect(
      find.byKey(const Key('progress-exercise-exercise-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('progress-exercise-exercise-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('progress-chart-weight')), findsOneWidget);
    expect(find.byKey(const Key('progress-chart-e1rm')), findsOneWidget);
    expect(find.text('Best set weight'), findsOneWidget);
    expect(find.text('Estimated 1RM'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('progress-best-weight')),
        matching: find.text('105 kg'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('progress-best-e1rm')),
        matching: find.text('126 kg'),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('progress-chart-rir')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('progress-chart-reps')), findsOneWidget);
    expect(find.byKey(const Key('progress-chart-rir')), findsOneWidget);
    expect(find.text('Missing RIR appears as a gap.'), findsOneWidget);
  });

  testWidgets('a bodyweight working set shows no e1RM instead of 0 kg', (
    WidgetTester tester,
  ) async {
    await _pumpProgress(
      tester,
      MemoryAppDataStore(
        _data(
          sessions: <Session>[
            _session('bw-session', DateTime.utc(2026, 10, 20), <SetLog>[
              _set('bw-set', 0, 5, rir: 0),
            ]),
          ],
        ),
      ),
      location: '/progress/exercise-1',
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('progress-best-e1rm')),
        matching: find.text('Not enough data'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('progress-best-e1rm')),
        matching: find.text('0 kg'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('progress-best-weight')),
        matching: find.text('0 kg'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('progress-chart-e1rm')),
        matching: find.text('No values in this range.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('overview shows an empty state without finished sessions', (
    WidgetTester tester,
  ) async {
    await _pumpProgress(tester, MemoryAppDataStore(_data()));

    expect(find.text('Finish a workout to see progress here.'), findsOneWidget);
  });

  testWidgets('exercise detail explains when there is no history', (
    WidgetTester tester,
  ) async {
    await _pumpProgress(
      tester,
      MemoryAppDataStore(
        _data(
          sessions: <Session>[
            _session('squat-session', DateTime.utc(2026, 10, 18), <SetLog>[
              _set('squat-1', 80000, 5),
            ], exerciseId: 'exercise-2'),
          ],
        ),
      ),
      location: '/progress/exercise-1',
    );

    expect(find.text('Log this exercise to see its progress.'), findsOneWidget);
  });

  testWidgets(
    'range filter switches between data and an in-range empty state',
    (WidgetTester tester) async {
      await _pumpProgress(
        tester,
        MemoryAppDataStore(
          _data(
            sessions: <Session>[
              _session(
                'old',
                _now.subtract(const Duration(days: 100)),
                <SetLog>[_set('old-set', 90000, 5)],
              ),
            ],
          ),
        ),
        location: '/progress/exercise-1',
      );

      expect(find.byKey(const Key('progress-chart-weight')), findsOneWidget);
      expect(find.text('No sessions in this range.'), findsNothing);

      await tester.tap(find.byKey(const Key('progress-range-four-weeks')));
      await tester.pumpAndSettle();
      expect(find.text('No sessions in this range.'), findsOneWidget);
      expect(find.byKey(const Key('progress-chart-weight')), findsNothing);

      await tester.tap(find.byKey(const Key('progress-range-twelve-weeks')));
      await tester.pumpAndSettle();
      expect(find.text('No sessions in this range.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('progress-range-all')));
      await tester.pumpAndSettle();
      expect(find.text('No sessions in this range.'), findsNothing);
      expect(find.byKey(const Key('progress-chart-weight')), findsOneWidget);
    },
  );

  testWidgets('RTL keeps time running left to right and does not clip labels', (
    WidgetTester tester,
  ) async {
    await _pumpProgress(
      tester,
      MemoryAppDataStore(
        _data(
          sessions: <Session>[
            _session('newer', DateTime.utc(2026, 10, 20), <SetLog>[
              _set('newer-set', 105000, 5),
            ]),
            _session('older', DateTime.utc(2026, 9), <SetLog>[
              _set('older-set', 95000, 5),
            ]),
          ],
        ),
      ),
      location: '/progress/exercise-1',
      locale: const Locale('fa'),
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
    final double firstX = tester
        .getCenter(find.byKey(const Key('progress-chart-weight-axis-first')))
        .dx;
    final double lastX = tester
        .getCenter(find.byKey(const Key('progress-chart-weight-axis-last')))
        .dx;
    expect(firstX, lessThan(lastX));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart date labels keep the locale paragraph direction', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      _data(
        sessions: <Session>[
          _session('newer', DateTime.utc(2026, 10, 20), <SetLog>[
            _set('newer-set', 105000, 5),
          ]),
          _session('older', DateTime.utc(2026, 9), <SetLog>[
            _set('older-set', 95000, 5),
          ]),
        ],
      ),
    );

    await _pumpProgress(
      tester,
      store,
      location: '/progress/exercise-1',
      locale: const Locale('fa'),
    );

    for (final String key in <String>[
      'progress-chart-weight-axis-first',
      'progress-chart-weight-axis-last',
    ]) {
      expect(
        tester.widget<Text>(find.byKey(Key(key))).textDirection,
        TextDirection.rtl,
        reason: 'The Persian label must keep its RTL paragraph direction: $key',
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpProgress(tester, store, location: '/progress/exercise-1');

    for (final String key in <String>[
      'progress-chart-weight-axis-first',
      'progress-chart-weight-axis-last',
    ]) {
      expect(
        tester.widget<Text>(find.byKey(Key(key))).textDirection,
        TextDirection.ltr,
      );
    }
  });

  testWidgets('detail stays usable at 200% text with 48dp range chips', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpProgress(
      tester,
      MemoryAppDataStore(
        _data(
          sessions: <Session>[
            _session('newer', DateTime.utc(2026, 10, 20), <SetLog>[
              _set('newer-set', 105000, 8, rir: 2),
            ]),
            _session('older', DateTime.utc(2026, 9), <SetLog>[
              _set('older-set', 95000, 10),
            ]),
          ],
        ),
      ),
      location: '/progress/exercise-1',
      locale: const Locale('fa'),
    );

    expect(tester.takeException(), isNull);
    for (final String key in <String>[
      'progress-range-four-weeks',
      'progress-range-twelve-weeks',
      'progress-range-one-year',
      'progress-range-all',
    ]) {
      final Size size = tester.getSize(find.byKey(Key(key)));
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }

    await tester.scrollUntilVisible(
      find.byKey(const Key('progress-chart-rir')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final Finder rirFirst = find.byKey(
      const Key('progress-chart-rir-axis-first'),
    );
    final Finder rirLast = find.byKey(
      const Key('progress-chart-rir-axis-last'),
    );
    expect(rirFirst, findsOneWidget);
    expect(rirLast, findsOneWidget);
    final Rect screen = tester.getRect(find.byType(Scaffold).first);
    expect(tester.getRect(rirFirst).left, greaterThanOrEqualTo(screen.left));
    expect(tester.getRect(rirLast).right, lessThanOrEqualTo(screen.right));
  });

  testWidgets('a 320px RTL chart keeps its labels inside the card', (
    WidgetTester tester,
  ) async {
    final List<ProgressPoint> points = <ProgressPoint>[
      ProgressPoint(date: DateTime.utc(2026, 9), value: 95000),
      ProgressPoint(date: DateTime.utc(2026, 10), value: null),
      ProgressPoint(date: DateTime.utc(2026, 10, 20), value: 107500),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: ProgressChart(
                  points: points,
                  formatValue: (double value) => value.round().toString(),
                  emptyMessage: 'No values',
                  semanticsLabel: 'Progress',
                  axisKeyPrefix: 'narrow-chart',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final double firstX = tester
        .getCenter(find.byKey(const Key('narrow-chart-axis-first')))
        .dx;
    final double lastX = tester
        .getCenter(find.byKey(const Key('narrow-chart-axis-last')))
        .dx;
    expect(firstX, lessThan(lastX));
  });

  testWidgets('renders 1,000 points and gaps without exceptions', (
    WidgetTester tester,
  ) async {
    final List<ProgressPoint> points = <ProgressPoint>[
      for (int index = 0; index < 1000; index++)
        ProgressPoint(
          date: DateTime.utc(2026).add(Duration(days: index)),
          value: index % 37 == 0 ? null : 100 + index % 50,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressChart(
            points: points,
            formatValue: (double value) => value.round().toString(),
            emptyMessage: 'No values',
            semanticsLabel: 'Progress',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ProgressChart), findsOneWidget);
  });
}
