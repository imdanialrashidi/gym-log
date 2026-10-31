// Temporary poster renderer: renders real app screens with rich demo data at
// 3x pixel density. Not part of the test suite.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app/app.dart';
import 'package:gym_log/app/app_clock.dart';
import 'package:gym_log/app/router.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/export_reminder.dart';
import 'package:gym_log/data/photo_pending_store.dart';
import 'package:gym_log/data/photo_picker_service.dart';
import 'package:gym_log/data/photo_storage.dart';
import 'package:gym_log/data/rest_timer_store.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../test/support/memory_app_data_store.dart';
import '../../test/support/memory_export_reminder_store.dart';
import '../../test/support/memory_rest_timer_store.dart';
import '../../test/support/photo_fakes.dart';

Exercise _ex(String id, String name) =>
    Exercise(id: id, name: name, createdAt: DateTime.utc(2026, 7));

SetLog _set(
  String id,
  int grams,
  int reps,
  int? rir,
  DateTime at, {
  int index = 0,
}) => SetLog(
  id: id,
  weightGrams: grams,
  reps: reps,
  rir: rir,
  setIndex: index,
  loggedAt: at,
);

SessionExercise _sx(
  String id,
  String exerciseId,
  List<SetLog> sets, {
  int? targetSets,
  int? repMin,
  int? repMax,
  String? note,
  int sortOrder = 0,
}) => SessionExercise(
  id: id,
  exerciseId: exerciseId,
  sortOrder: sortOrder,
  targetSets: targetSets,
  repMin: repMin,
  repMax: repMax,
  note: note,
  sets: sets,
);

Session _session(
  String id,
  DateTime start,
  int minutes,
  List<SessionExercise> exercises, {
  String? dayId,
  String? note,
}) => Session(
  id: id,
  startedAt: start,
  endedAt: start.add(Duration(minutes: minutes)),
  programDayId: dayId,
  note: note,
  exercises: exercises,
);

/// One exercise across weekly sessions, 3 working sets each.
Session _weekSession({
  required String id,
  required DateTime start,
  required String exerciseId,
  required List<int> weightGrams,
  required int reps,
  required int rir,
  int sets = 3,
  int minutes = 68,
  String? dayId,
  String? note,
}) {
  final List<SetLog> logs = <SetLog>[
    for (int i = 0; i < sets; i++)
      _set(
        '$id-set-$i',
        weightGrams[i < weightGrams.length ? i : weightGrams.length - 1],
        reps - i,
        rir,
        start.add(Duration(minutes: 8 + i * 4)),
        index: i,
      ),
  ];
  return _session(
    id,
    start,
    minutes,
    <SessionExercise>[
      _sx('$id-sx', exerciseId, logs, targetSets: 3, repMin: 8, repMax: 12),
    ],
    dayId: dayId,
    note: note,
  );
}

Program _program() => Program(
  id: 'program-1',
  name: 'برنامهٔ حجم چهار روزه',
  createdAt: DateTime.utc(2026, 7, 2),
  days: <ProgramDay>[
    ProgramDay(
      id: 'day-upper',
      name: 'بالاتنه',
      sortOrder: 0,
      items: <PlanItem>[
        PlanItem(
          id: 'item-bench',
          exerciseId: 'ex-bench',
          targetSets: 3,
          repMin: 8,
          repMax: 12,
          sortOrder: 0,
        ),
        PlanItem(
          id: 'item-row',
          exerciseId: 'ex-row',
          targetSets: 3,
          repMin: 8,
          repMax: 12,
          sortOrder: 1,
        ),
        PlanItem(
          id: 'item-ohp',
          exerciseId: 'ex-ohp',
          targetSets: 3,
          repMin: 8,
          repMax: 12,
          sortOrder: 2,
        ),
      ],
    ),
    ProgramDay(
      id: 'day-lower',
      name: 'پایین‌تنه',
      sortOrder: 1,
      items: <PlanItem>[
        PlanItem(
          id: 'item-squat',
          exerciseId: 'ex-squat',
          targetSets: 3,
          repMin: 6,
          repMax: 10,
          sortOrder: 0,
        ),
        PlanItem(
          id: 'item-dead',
          exerciseId: 'ex-dead',
          targetSets: 3,
          repMin: 5,
          repMax: 8,
          sortOrder: 1,
        ),
      ],
    ),
  ],
);

AppData _data() {
  final DateTime base = DateTime.utc(2026, 8, 26, 16);
  final List<Session> bench = <Session>[
    for (int i = 0; i < 8; i++)
      _weekSession(
        id: 'bench-$i',
        start: base.add(Duration(days: i * 8)),
        exerciseId: 'ex-bench',
        weightGrams: <List<int>>[
          <int>[90000, 87500, 85000],
          <int>[92500, 90000, 87500],
          <int>[95000, 92500, 90000],
          <int>[97500, 95000, 92500],
          <int>[100000, 97500, 95000],
          <int>[102500, 100000, 97500],
          <int>[105000, 102500, 100000],
          <int>[107500, 105000, 102500],
        ][i],
        reps: <int>[10, 9, 8, 8, 7, 7, 6, 5][i],
        rir: <int>[2, 2, 1, 1, 2, 1, 1, 0][i],
        dayId: 'day-upper',
        note: i == 7 ? 'فرم عالی، آمادهٔ افزایش بار هفتهٔ بعد.' : null,
      ),
  ];
  final List<Session> squat = <Session>[
    for (int i = 0; i < 5; i++)
      _weekSession(
        id: 'squat-$i',
        start: DateTime.utc(2026, 9, 20, 17).add(Duration(days: i * 10)),
        exerciseId: 'ex-squat',
        weightGrams: <List<int>>[
          <int>[80000, 77500, 75000],
          <int>[85000, 82500, 80000],
          <int>[90000, 87500, 85000],
          <int>[95000, 92500, 90000],
          <int>[100000, 95000, 92500],
        ][i],
        reps: <int>[8, 8, 7, 6, 6][i],
        rir: <int>[2, 1, 1, 0, 0][i],
        dayId: 'day-lower',
      ),
  ];
  final Session active = Session(
    id: 'session-active',
    startedAt: DateTime.utc(2026, 10, 21, 15, 20),
    programDayId: 'day-upper',
    exercises: <SessionExercise>[
      _sx(
        'active-bench',
        'ex-bench',
        <SetLog>[
          _set('ab-0', 107500, 8, 1, DateTime.utc(2026, 10, 21, 15, 28)),
          _set(
            'ab-1',
            105000,
            8,
            2,
            DateTime.utc(2026, 10, 21, 15, 33),
            index: 1,
          ),
        ],
        targetSets: 2,
        repMin: 8,
        repMax: 12,
      ),
      _sx(
        'active-row',
        'ex-row',
        <SetLog>[
          _set('ar-0', 70000, 10, 2, DateTime.utc(2026, 10, 21, 15, 47)),
        ],
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        sortOrder: 1,
      ),
    ],
  );
  return AppData(
    exercises: <Exercise>[
      _ex('ex-bench', 'پرس سینه'),
      _ex('ex-squat', 'اسکات'),
      _ex('ex-dead', 'ددلیفت'),
      _ex('ex-row', 'زیر بغل سیم‌کش'),
      _ex('ex-ohp', 'پرس سرشانه'),
    ],
    programs: <Program>[_program()],
    bodyWeights: <BodyWeightEntry>[
      for (int i = 0; i < 6; i++)
        BodyWeightEntry(
          id: 'bw-$i',
          weightGrams: 78200 + i * 400,
          recordedAt: DateTime.utc(2026, 10, 21 - i, 7),
        ),
    ],
    sessions: <Session>[
      ...bench,
      ...squat,
      _session(
        'dead-1',
        DateTime.utc(2026, 10, 19, 17),
        74,
        <SessionExercise>[
          _sx(
            'dead-1-sx',
            'ex-dead',
            <SetLog>[
              _set(
                'dead-1-0',
                130000,
                5,
                1,
                DateTime.utc(2026, 10, 19, 17, 10),
              ),
              _set(
                'dead-1-1',
                120000,
                6,
                2,
                DateTime.utc(2026, 10, 19, 17, 18),
                index: 1,
              ),
              _set(
                'dead-1-2',
                120000,
                6,
                1,
                DateTime.utc(2026, 10, 19, 17, 26),
                index: 2,
              ),
            ],
            targetSets: 3,
            repMin: 5,
            repMax: 8,
          ),
        ],
        dayId: 'day-lower',
        note: 'قفل بالا، بدون کمردرد.',
      ),
      _session(
        'hist-upper',
        DateTime.utc(2026, 10, 18, 16),
        81,
        <SessionExercise>[
          _sx('hist-upper-sx', 'ex-bench', <SetLog>[
            _set('hu-0', 102500, 7, 1, DateTime.utc(2026, 10, 18, 16, 10)),
            _set(
              'hu-1',
              100000,
              8,
              1,
              DateTime.utc(2026, 10, 18, 16, 18),
              index: 1,
            ),
            _set(
              'hu-2',
              97500,
              8,
              0,
              DateTime.utc(2026, 10, 18, 16, 26),
              index: 2,
            ),
          ]),
          _sx('hist-upper-row', 'ex-row', <SetLog>[
            _set('hur-0', 67500, 10, 2, DateTime.utc(2026, 10, 18, 16, 40)),
            _set(
              'hur-1',
              67500,
              9,
              2,
              DateTime.utc(2026, 10, 18, 16, 48),
              index: 1,
            ),
          ], sortOrder: 1),
        ],
        dayId: 'day-upper',
        note: 'تمرین خوب، انرژی بالا.',
      ),
      active,
    ],
  );
}

Future<void> _shot(
  WidgetTester tester, {
  required String location,
  required String name,
}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.localesTestValue = const <Locale>[Locale('fa')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  final DateTime now = DateTime.utc(2026, 10, 21, 16, 5);
  final GlobalKey rootKey = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDataStoreProvider.overrideWithValue(MemoryAppDataStore(_data())),
        exportReminderStoreProvider.overrideWithValue(
          MemoryExportReminderStore(ExportReminderState(lastExportedAt: now)),
        ),
        photoStorageProvider.overrideWithValue(MemoryPhotoStorage()),
        photoPickerProvider.overrideWithValue(FakePhotoPicker()),
        photoPendingStoreProvider.overrideWithValue(MemoryPhotoPendingStore()),
        restTimerStoreProvider.overrideWithValue(MemoryRestTimerStore()),
        routerProvider.overrideWithValue(
          buildRouter(initialLocation: location),
        ),
        appClockProvider.overrideWithValue(() => now),
      ],
      child: RepaintBoundary(key: rootKey, child: const GymLogApp()),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  final RenderRepaintBoundary boundary =
      rootKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    Directory('poster/screens').createSync(recursive: true);
    File('poster/screens/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<void> _loadFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('Vazirmatn', <String>[
    'assets/fonts/Vazirmatn-Regular.ttf',
    'assets/fonts/Vazirmatn-Medium.ttf',
    'assets/fonts/Vazirmatn-Bold.ttf',
  ]);
  await _loadFont('MaterialIcons', <String>[_materialIconsPath()]);
}

Future<void> _loadFont(String family, List<String> paths) async {
  final FontLoader loader = FontLoader(family);
  for (final String path in paths) {
    final Uint8List bytes = File(path).readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

String _materialIconsPath() {
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    final String path =
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf';
    if (File(path).existsSync()) {
      return path;
    }
  }
  final Directory cacheDirectory = File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent;
  return '${cacheDirectory.path}/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf';
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('workout', (WidgetTester tester) async {
    await _shot(tester, location: '/workout', name: '01_workout');
  });
  testWidgets('progress detail', (WidgetTester tester) async {
    await _shot(tester, location: '/progress/ex-bench', name: '02_progress');
  });
  testWidgets('weekly summary', (WidgetTester tester) async {
    await _shot(tester, location: '/weekly-summary', name: '03_weekly');
  });
  testWidgets('progress overview', (WidgetTester tester) async {
    await _shot(tester, location: '/progress', name: '04_overview');
  });
  testWidgets('session summary', (WidgetTester tester) async {
    await _shot(
      tester,
      location: '/session-summary/hist-upper',
      name: '05_summary',
    );
  });
  testWidgets('history', (WidgetTester tester) async {
    await _shot(tester, location: '/history', name: '06_history');
  });
}
