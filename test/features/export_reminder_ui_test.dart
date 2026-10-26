import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/export_reminder.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/backup_fakes.dart';
import '../support/failing_export_reminder_store.dart';
import '../support/memory_app_data_store.dart';
import '../support/memory_export_reminder_store.dart';
import '../support/test_app.dart';

AppData _dataCreatedAt(DateTime createdAt) {
  return AppData(
    exercises: <Exercise>[
      Exercise(id: 'exercise-1', name: 'Bench Press', createdAt: createdAt),
    ],
  );
}

void main() {
  final DateTime now = DateTime.utc(2026, 10, 22, 12);

  testWidgets('reminder is hidden when there is no data', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(),
      initialLocation: '/workout',
      clock: () => now,
      reminderStore: MemoryExportReminderStore(),
    );

    expect(find.byKey(const Key('export-reminder-banner')), findsNothing);
  });

  testWidgets('reminder is hidden before 30 days without an export', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(
        _dataCreatedAt(now.subtract(const Duration(days: 29))),
      ),
      initialLocation: '/workout',
      clock: () => now,
      reminderStore: MemoryExportReminderStore(),
    );

    expect(find.byKey(const Key('export-reminder-banner')), findsNothing);
  });

  testWidgets('reminder appears after 30 days and can be snoozed', (
    WidgetTester tester,
  ) async {
    final MemoryExportReminderStore reminders = MemoryExportReminderStore();
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(
        _dataCreatedAt(now.subtract(const Duration(days: 30))),
      ),
      initialLocation: '/workout',
      clock: () => now,
      reminderStore: reminders,
    );

    expect(find.byKey(const Key('export-reminder-banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('export-reminder-later')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('export-reminder-banner')), findsNothing);
    expect(reminders.saveCount, 1);
    expect(reminders.state.snoozedUntil, now.add(exportReminderSnooze));
  });

  testWidgets('reminder is dismissible for the current baseline', (
    WidgetTester tester,
  ) async {
    final MemoryExportReminderStore reminders = MemoryExportReminderStore();
    final DateTime createdAt = now.subtract(const Duration(days: 45));
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_dataCreatedAt(createdAt)),
      initialLocation: '/workout',
      clock: () => now,
      reminderStore: reminders,
    );

    await tester.tap(find.byKey(const Key('export-reminder-dismiss')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('export-reminder-banner')), findsNothing);
    expect(reminders.state.dismissedForBaseline, createdAt);
  });

  testWidgets('export from the reminder saves a file and clears it', (
    WidgetTester tester,
  ) async {
    final MemoryExportReminderStore reminders = MemoryExportReminderStore();
    final FakeBackupFileGateway gateway = FakeBackupFileGateway();
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(
        _dataCreatedAt(now.subtract(const Duration(days: 40))),
      ),
      initialLocation: '/workout',
      clock: () => now,
      reminderStore: reminders,
      backupGateway: gateway,
      backupCodec: const InlineBackupCodec(),
    );

    await tester.tap(find.byKey(const Key('export-reminder-export')));
    await tester.pumpAndSettle();

    expect(gateway.saveCalls, 1);
    expect(gateway.savedFileName, endsWith('.json'));
    expect(parseBackup(gateway.savedContents!).data.exercises, hasLength(1));
    expect(reminders.state.lastExportedAt, now);
    expect(find.byKey(const Key('export-reminder-banner')), findsNothing);
    expect(find.text('Backup saved.'), findsOneWidget);
  });

  testWidgets('failed snooze keeps the banner and reports a save failure', (
    WidgetTester tester,
  ) async {
    final FailingExportReminderStore reminders = FailingExportReminderStore(
      const ExportReminderState(),
    );
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(
        _dataCreatedAt(now.subtract(const Duration(days: 30))),
      ),
      initialLocation: '/workout',
      clock: () => now,
      reminderStore: reminders,
    );

    expect(find.byKey(const Key('export-reminder-banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('export-reminder-later')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('export-reminder-banner')), findsOneWidget);
    expect(find.text('Could not save. Try again.'), findsOneWidget);
    expect(reminders.saveAttempts, 1);
  });

  testWidgets('reminder copy is Persian in the fa locale', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(
        _dataCreatedAt(now.subtract(const Duration(days: 30))),
      ),
      initialLocation: '/workout',
      locale: const Locale('fa'),
      clock: () => now,
      reminderStore: MemoryExportReminderStore(),
    );

    expect(find.text('از داده‌هایت پشتیبان بگیر'), findsOneWidget);
    expect(find.text('بعداً'), findsOneWidget);
    expect(find.text('همین حالا خروجی بگیر'), findsOneWidget);
  });
}
