import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app/app_info.dart';
import 'package:gym_log/data/export_reminder.dart';
import 'package:lift_core/lift_core.dart';

import '../support/failing_export_reminder_store.dart';
import '../support/memory_export_reminder_store.dart';

void main() {
  test('export app version matches pubspec', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? match = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(appVersion, match!.group(1));
  });

  group('export reminder policy', () {
    final AppData data = AppData(
      exercises: <Exercise>[
        Exercise(
          id: 'exercise-1',
          name: 'Bench Press',
          createdAt: DateTime.utc(2026, 8, 1, 10),
        ),
      ],
    );

    test('is hidden without training data', () {
      expect(
        shouldShowExportReminder(
          data: AppData(),
          state: const ExportReminderState(),
          now: DateTime.utc(2026, 10, 22),
        ),
        isFalse,
      );
    });

    test('appears only after 30 full days without an export', () {
      final DateTime firstDay = DateTime.utc(2026, 8, 1, 10);
      expect(
        shouldShowExportReminder(
          data: data,
          state: const ExportReminderState(),
          now: firstDay.add(const Duration(days: 29, hours: 23)),
        ),
        isFalse,
      );
      expect(
        shouldShowExportReminder(
          data: data,
          state: const ExportReminderState(),
          now: firstDay.add(const Duration(days: 30)),
        ),
        isTrue,
      );
    });

    test('uses the last export as the baseline', () {
      final ExportReminderState state = ExportReminderState(
        lastExportedAt: DateTime.utc(2026, 10, 1, 10),
      );
      expect(
        shouldShowExportReminder(
          data: data,
          state: state,
          now: DateTime.utc(2026, 10, 22),
        ),
        isFalse,
      );
      expect(
        shouldShowExportReminder(
          data: data,
          state: state,
          now: DateTime.utc(2026, 10, 31, 10),
        ),
        isTrue,
      );
    });

    test('snooze hides it until the snooze expires', () {
      final ExportReminderState state = ExportReminderState(
        snoozedUntil: DateTime.utc(2026, 11),
      );
      expect(
        shouldShowExportReminder(
          data: data,
          state: state,
          now: DateTime.utc(2026, 10, 22),
        ),
        isFalse,
      );
      expect(
        shouldShowExportReminder(
          data: data,
          state: state,
          now: DateTime.utc(2026, 11),
        ),
        isTrue,
      );
    });

    test('dismissal applies to the current baseline only', () {
      final DateTime baseline = DateTime.utc(2026, 8, 1, 10);
      final ExportReminderState state = ExportReminderState(
        dismissedForBaseline: baseline,
      );
      expect(
        shouldShowExportReminder(
          data: data,
          state: state,
          now: DateTime.utc(2026, 10, 22),
        ),
        isFalse,
      );
      expect(
        shouldShowExportReminder(
          data: data,
          state: ExportReminderState(
            lastExportedAt: DateTime.utc(2026, 9, 1, 10),
            dismissedForBaseline: baseline,
          ),
          now: DateTime.utc(2026, 10, 22),
        ),
        isTrue,
      );
    });

    test('a future baseline never triggers the reminder', () {
      expect(
        shouldShowExportReminder(
          data: data,
          state: ExportReminderState(lastExportedAt: DateTime.utc(2027)),
          now: DateTime.utc(2026, 10, 22),
        ),
        isFalse,
      );
    });
  });

  test('reminder controller persists snooze and export', () async {
    final MemoryExportReminderStore store = MemoryExportReminderStore();
    final ProviderContainer container = ProviderContainer.test(
      overrides: [exportReminderStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await container.read(exportReminderControllerProvider.future);
    final ExportReminderController controller = container.read(
      exportReminderControllerProvider.notifier,
    );
    final DateTime now = DateTime.utc(2026, 10, 22, 12);

    await controller.snooze(now);
    expect(store.state.snoozedUntil, now.add(exportReminderSnooze));
    expect(store.saveCount, 1);

    await controller.markExported(now);
    expect(store.state.lastExportedAt, now);
    expect(store.state.snoozedUntil, isNull);
    expect(store.saveCount, 2);
  });

  test(
    'JSON reminder metadata round-trips and corrupt metadata falls back',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'gym_log_reminder_store_',
      );
      addTearDown(() async {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      });
      final File file = File(
        '${directory.path}${Platform.pathSeparator}meta.json',
      );
      final JsonExportReminderStore store = JsonExportReminderStore(
        Future<File>.value(file),
      );
      expect((await store.load()).lastExportedAt, isNull);

      final ExportReminderState saved = ExportReminderState(
        lastExportedAt: DateTime.utc(2026, 10, 22, 12),
        snoozedUntil: DateTime.utc(2026, 11, 21, 12),
        dismissedForBaseline: DateTime.utc(2026, 10, 1, 9),
      );
      await store.save(saved);
      final ExportReminderState loaded = await store.load();
      expect(loaded.lastExportedAt, saved.lastExportedAt);
      expect(loaded.snoozedUntil, saved.snoozedUntil);
      expect(loaded.dismissedForBaseline, saved.dismissedForBaseline);
      expect(File('${file.path}.tmp').existsSync(), isFalse);

      await file.writeAsString('not reminder metadata');
      final ExportReminderState fallback = await store.load();
      expect(fallback.lastExportedAt, isNull);
      expect(fallback.snoozedUntil, isNull);
      expect(fallback.dismissedForBaseline, isNull);
    },
  );

  test(
    'a failed reminder save restores the previous in-memory state',
    () async {
      final ExportReminderState initial = ExportReminderState(
        lastExportedAt: DateTime.utc(2026, 10, 1, 9),
      );
      final FailingExportReminderStore store = FailingExportReminderStore(
        initial,
      );
      final ProviderContainer container = ProviderContainer.test(
        overrides: [exportReminderStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(exportReminderControllerProvider.future);
      final ExportReminderController controller = container.read(
        exportReminderControllerProvider.notifier,
      );
      final ExportReminderState before = container
          .read(exportReminderControllerProvider)
          .requireValue;

      await expectLater(
        controller.snooze(DateTime.utc(2026, 10, 22, 12)),
        throwsStateError,
      );

      final ExportReminderState after = container
          .read(exportReminderControllerProvider)
          .requireValue;
      expect(after.lastExportedAt, before.lastExportedAt);
      expect(after.snoozedUntil, isNull);
      expect(store.saveAttempts, 1);
    },
  );
}
