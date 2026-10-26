import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/backup_data.dart';
import '../support/backup_fakes.dart';
import '../support/failing_app_data_store.dart';
import '../support/memory_app_data_store.dart';
import '../support/memory_export_reminder_store.dart';
import '../support/test_app.dart';

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (int attempt = 0; attempt < 50; attempt += 1) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(finder, findsOneWidget, reason: 'The expected widget never appeared.');
}

Future<void> _startRestore(WidgetTester tester) async {
  final Finder target = find.byKey(const Key('restore-from-backup'));
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(target);
  await tester.pump();
}

Future<void> _tapSnapshotRow(WidgetTester tester) async {
  final Finder tile = find.byIcon(Icons.history).first;
  await Scrollable.ensureVisible(tester.element(tile), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> _tapSettingsAction(WidgetTester tester, String key) async {
  final Finder target = find.byKey(Key(key));
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('export from Settings saves JSON and updates the reminder', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(backupSampleData());
    final FakeBackupFileGateway gateway = FakeBackupFileGateway();
    final MemoryExportReminderStore reminders = MemoryExportReminderStore();
    final DateTime now = DateTime.utc(2026, 10, 22, 12);
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      clock: () => now,
      reminderStore: reminders,
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'export-data');
    await tester.pumpAndSettle();

    expect(gateway.saveCalls, 1);
    expect(gateway.savedContents, isNotNull);
    expect(parseBackup(gateway.savedContents!).data.exercises, hasLength(2));
    expect(reminders.state.lastExportedAt, now);
    expect(find.text('Backup saved.'), findsOneWidget);
  });

  testWidgets('valid import previews counts and commits Merge', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore();
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      importText: backupJson(),
    );
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'import-data');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('import-preview-dialog')), findsOneWidget);
    expect(
      find.textContaining('Will add 2 exercises, 1 program, 1 session'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('import-confirm')));
    await tester.pumpAndSettle();

    expect(store.data.exercises, hasLength(2));
    expect(store.data.programs, hasLength(1));
    expect(store.data.sessions, hasLength(1));
    expect(find.text('Import complete.'), findsOneWidget);
  });

  testWidgets('Replace import snapshots before writing', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore();
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      importText: backupJson(),
    );
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'import-data');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Will replace current data with'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('import-confirm')));
    await tester.pumpAndSettle();

    expect(store.snapshotCount, 1);
    expect(store.data.sessions, hasLength(1));
  });

  testWidgets('settings-only backup can be merged into an empty database', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore();
    final AppData settingsOnly = AppData(
      settings: const AppSettings(weightUnit: WeightUnit.pounds),
    );
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      importText: backupJson(data: settingsOnly),
    );
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'import-data');
    await tester.pumpAndSettle();

    expect(find.text('Settings will be restored.'), findsOneWidget);
    final FilledButton confirm = tester.widget<FilledButton>(
      find.byKey(const Key('import-confirm')),
    );
    expect(confirm.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('import-confirm')));
    await tester.pumpAndSettle();

    expect(store.data.settings.weightUnit, WeightUnit.pounds);
    expect(store.data.exercises, isEmpty);
  });

  testWidgets('cancelled export changes neither data nor reminder', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(backupSampleData());
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      saveResult: false,
    );
    final MemoryExportReminderStore reminders = MemoryExportReminderStore();
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      reminderStore: reminders,
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'export-data');
    await tester.pumpAndSettle();

    expect(gateway.saveCalls, 1);
    expect(reminders.saveCount, 0);
    expect(reminders.state.lastExportedAt, isNull);
    expect(find.text('Backup saved.'), findsNothing);
    expect(store.data.exercises, hasLength(2));
  });

  testWidgets('cancelled file picker leaves the database unchanged', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(backupSampleData());
    final FakeBackupFileGateway gateway = FakeBackupFileGateway();
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'import-data');
    await tester.pumpAndSettle();

    expect(gateway.pickCalls, 1);
    expect(find.byKey(const Key('import-preview-dialog')), findsNothing);
    expect(find.text('Could not import'), findsNothing);
    expect(store.data.exercises, hasLength(2));
  });

  testWidgets('missing document picker shows a picker-specific message', (
    WidgetTester tester,
  ) async {
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      pickError: PlatformException(code: 'unavailable'),
    );
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(backupSampleData()),
      initialLocation: '/settings',
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'import-data');
    await tester.pumpAndSettle();

    expect(find.text('Could not open the file picker.'), findsOneWidget);
  });

  testWidgets('corrupt import shows the clear English message', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(backupSampleData());
    final String valid = backupJson();
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      importText: valid.substring(0, valid.length - 20),
    );
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'import-data');
    await tester.pumpAndSettle();

    expect(find.text('Could not import'), findsOneWidget);
    expect(
      find.text('This file is not valid JSON. It may be truncated.'),
      findsOneWidget,
    );
    expect(store.data.exercises, hasLength(2));
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('corrupt import shows the clear Persian message', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(backupSampleData());
    final String valid = backupJson();
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      importText: valid.substring(0, valid.length - 20),
    );
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      locale: const Locale('fa'),
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'import-data');
    await tester.pumpAndSettle();

    expect(find.text('ورود ممکن نشد'), findsOneWidget);
    expect(
      find.text('این فایل JSON معتبر نیست. ممکن است ناقص باشد.'),
      findsOneWidget,
    );
  });

  testWidgets('newer schemaVersion tells the user to update the app', (
    WidgetTester tester,
  ) async {
    final Map<String, Object?> json = (jsonDecode(backupJson()) as Map)
        .cast<String, Object?>();
    json['schemaVersion'] = backupSchemaVersion + 1;
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      importText: jsonEncode(json),
    );
    final MemoryAppDataStore store = MemoryAppDataStore();

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'import-data');
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This backup was made by a newer version of Gym Log. '
        'Update the app, then try again.',
      ),
      findsOneWidget,
    );
    expect(store.data.exercises, isEmpty);
  });

  testWidgets('Replace exposes the previous data version and restores it', (
    WidgetTester tester,
  ) async {
    final Exercise local = Exercise(
      id: 'local-exercise',
      name: 'Local Press',
      createdAt: DateTime.utc(2026, 10, 20, 9),
    );
    final MemoryAppDataStore store = MemoryAppDataStore(
      AppData(exercises: <Exercise>[local]),
    );
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      importText: backupJson(),
    );
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'import-data');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-confirm')));
    await tester.pumpAndSettle();

    expect(store.data.exerciseById('local-exercise'), isNull);
    expect(find.text('Previous data versions'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);

    await _tapSnapshotRow(tester);
    expect(find.byKey(const Key('restore-snapshot-dialog')), findsOneWidget);
    expect(
      find.textContaining('Photos are not in this snapshot'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('restore-snapshot-confirm')));
    await tester.pumpAndSettle();

    expect(store.data.exerciseById('local-exercise'), isNotNull);
    expect(store.data.exercises, hasLength(1));
    expect(find.text('Import complete.'), findsOneWidget);
  });

  testWidgets('cancelling a data-version restore writes nothing', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      AppData(
        exercises: <Exercise>[
          Exercise(
            id: 'current',
            name: 'Current Press',
            createdAt: DateTime.utc(2026, 10, 20, 9),
          ),
        ],
      ),
    );
    store.seedSnapshot('gym_log_data-previous.json', AppData());
    await pumpGymLogApp(tester, store: store, initialLocation: '/settings');

    await _tapSnapshotRow(tester);
    await tester.tap(find.byKey(const Key('restore-snapshot-cancel')));
    await tester.pumpAndSettle();

    expect(store.saveCount, 0);
    expect(store.snapshotCount, 0);
    expect(store.data.exercises.single.id, 'current');
  });

  testWidgets('the Persian restore confirmation warns about photos', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore();
    store.seedSnapshot('gym_log_data-previous.json', AppData());
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      locale: const Locale('fa'),
    );

    expect(find.text('نسخه‌های قبلی داده‌ها'), findsOneWidget);
    await _tapSnapshotRow(tester);

    expect(find.text('این نسخه از داده‌ها بازگردانی شود؟'), findsOneWidget);
    expect(
      find.text(
        'عکس‌ها در این نسخه نیستند. عکس‌های مربوط به حرکت‌هایی که '
        'دیگر وجود ندارند برای همیشه حذف می‌شوند.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a failed data-version restore reports and keeps the list', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore memory = MemoryAppDataStore();
    memory.seedSnapshot('gym_log_data-previous.json', AppData());
    final FailingAppDataStore store = FailingAppDataStore(
      memory,
      failLoadSnapshot: true,
    );
    await pumpGymLogApp(tester, store: store, initialLocation: '/settings');

    await _tapSnapshotRow(tester);
    await tester.tap(find.byKey(const Key('restore-snapshot-confirm')));
    await _pumpUntilFound(tester, find.text('Could not restore the backup.'));

    expect(find.text('Could not restore the backup.'), findsOneWidget);
    expect(find.text('Previous data versions'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('a long import error scrolls at 200% text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final Map<String, Object?> json = (jsonDecode(backupJson()) as Map)
        .cast<String, Object?>();
    final String longId = 'a' * 120;
    final Map<String, Object?> exercise = (json['exercises']! as List)
        .cast<Map<String, Object?>>()[0];
    exercise['id'] = longId;
    final Map<String, Object?> program = (json['programs']! as List)
        .cast<Map<String, Object?>>()[0];
    program['id'] = longId;
    final MemoryAppDataStore store = MemoryAppDataStore();
    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      backupGateway: FakeBackupFileGateway(importText: jsonEncode(json)),
      backupCodec: const InlineBackupCodec(),
    );

    await _tapSettingsAction(tester, 'import-data');
    await _pumpUntilFound(tester, find.text('Could not import'));

    expect(find.text('Could not import'), findsOneWidget);
    expect(
      find.textContaining('The backup contains the same ID'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    expect(store.data.exercises, isEmpty);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('an unreadable document can be restored from a backup', (
    WidgetTester tester,
  ) async {
    final UnreadableAppDataStore store = UnreadableAppDataStore();
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      importText: backupJson(),
    );

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    expect(find.text('Could not open your data.'), findsWidgets);
    await _startRestore(tester);
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('restore-preview-dialog')),
    );

    expect(find.byKey(const Key('restore-preview-dialog')), findsOneWidget);
    expect(
      find.textContaining('Will replace current data with'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('restore-confirm')));
    await tester.pumpAndSettle();

    expect(store.snapshotCount, 1);
    expect(store.saveAttempts, 1);
    expect(store.saved!.exercises, hasLength(2));
    expect(store.saved!.programs, hasLength(1));
    expect(store.saved!.sessions, hasLength(1));
    expect(find.text('Import complete.'), findsOneWidget);
    expect(find.byKey(const Key('restore-from-backup')), findsNothing);
    expect(find.text('Could not open your data.'), findsNothing);
  });

  testWidgets('restore aborts before writing when the snapshot fails', (
    WidgetTester tester,
  ) async {
    final UnreadableAppDataStore store = UnreadableAppDataStore(
      failSnapshot: true,
    );
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      importText: backupJson(),
    );

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _startRestore(tester);
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('restore-preview-dialog')),
    );
    await tester.tap(find.byKey(const Key('restore-confirm')));
    await _pumpUntilFound(tester, find.text('Could not restore the backup.'));

    expect(store.snapshotCount, 1);
    expect(store.saveAttempts, 0);
    expect(store.saved, isNull);
    expect(find.text('Could not restore the backup.'), findsOneWidget);
    expect(find.byKey(const Key('restore-from-backup')), findsOneWidget);
  });

  testWidgets('restore rejects an invalid backup without writing', (
    WidgetTester tester,
  ) async {
    final Map<String, Object?> json = (jsonDecode(backupJson()) as Map)
        .cast<String, Object?>();
    json['schemaVersion'] = backupSchemaVersion + 1;
    final UnreadableAppDataStore store = UnreadableAppDataStore();
    final FakeBackupFileGateway gateway = FakeBackupFileGateway(
      importText: jsonEncode(json),
    );

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/settings',
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await _startRestore(tester);
    await _pumpUntilFound(
      tester,
      find.text(
        'This backup was made by a newer version of Gym Log. '
        'Update the app, then try again.',
      ),
    );

    expect(
      find.text(
        'This backup was made by a newer version of Gym Log. '
        'Update the app, then try again.',
      ),
      findsOneWidget,
    );
    expect(store.snapshotCount, 0);
    expect(store.saveAttempts, 0);
    expect(find.byKey(const Key('restore-from-backup')), findsOneWidget);
  });
  testWidgets('a pushed editor keeps chrome and recovery on load failure', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: UnreadableAppDataStore(),
      initialLocation: '/program-editor/program-1',
    );

    expect(find.text('Could not open your data.'), findsOneWidget);
    expect(find.byKey(const Key('restore-from-backup')), findsOneWidget);
    expect(find.text('Programs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
