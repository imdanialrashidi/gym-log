import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/backup_data.dart';
import '../support/backup_fakes.dart';
import '../support/memory_app_data_store.dart';
import '../support/memory_export_reminder_store.dart';
import '../support/test_app.dart';

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
}
