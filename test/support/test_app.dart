import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app/app.dart';
import 'package:gym_log/app/app_clock.dart';
import 'package:gym_log/app/router.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/app_data_store.dart';
import 'package:gym_log/data/backup_codec.dart';
import 'package:gym_log/data/backup_gateway.dart';
import 'package:gym_log/data/export_reminder.dart';
import 'package:gym_log/data/photo_pending_store.dart';
import 'package:gym_log/data/photo_picker.dart';
import 'package:gym_log/data/photo_picker_service.dart';
import 'package:gym_log/data/photo_storage.dart';
import 'package:gym_log/features/exercises/presentation/exercise_lookup_action.dart';
import 'package:material_ui/material_ui.dart';

import 'memory_export_reminder_store.dart';
import 'photo_fakes.dart';

/// Pumps the real app at [initialLocation] with an isolated in-memory store.
Future<void> pumpGymLogApp(
  WidgetTester tester, {
  required AppDataStore store,
  required String initialLocation,
  Locale locale = const Locale('en'),
  ExerciseLookupLauncher? lookupLauncher,
  DateTime Function()? clock,
  ExportReminderStore? reminderStore,
  BackupFileGateway? backupGateway,
  BackupCodec? backupCodec,
  PhotoStorage? photoStorage,
  PhotoPicker? photoPicker,
  PhotoPendingStore? photoPendingStore,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.localesTestValue = <Locale>[locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  final DateTime now = clock?.call() ?? DateTime.now();
  final ExportReminderStore reminders =
      reminderStore ??
      MemoryExportReminderStore(ExportReminderState(lastExportedAt: now));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDataStoreProvider.overrideWithValue(store),
        exportReminderStoreProvider.overrideWithValue(reminders),
        photoStorageProvider.overrideWithValue(
          photoStorage ?? MemoryPhotoStorage(),
        ),
        photoPickerProvider.overrideWithValue(photoPicker ?? FakePhotoPicker()),
        photoPendingStoreProvider.overrideWithValue(
          photoPendingStore ?? MemoryPhotoPendingStore(),
        ),
        routerProvider.overrideWithValue(
          buildRouter(initialLocation: initialLocation),
        ),
        if (lookupLauncher != null)
          exerciseLookupLauncherProvider.overrideWithValue(lookupLauncher),
        if (clock != null) appClockProvider.overrideWithValue(clock),
        if (backupGateway != null)
          backupFileGatewayProvider.overrideWithValue(backupGateway),
        if (backupCodec != null)
          backupCodecProvider.overrideWithValue(backupCodec),
      ],
      child: const GymLogApp(),
    ),
  );
  await tester.pumpAndSettle();
}
