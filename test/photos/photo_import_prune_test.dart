import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/photo_storage.dart';
import 'package:lift_core/lift_core.dart';

import '../support/memory_app_data_store.dart';

void main() {
  test(
    'a successful Replace import prunes photos for removed identities',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'gym_log_photo_import_prune_',
      );
      addTearDown(() async {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      });
      final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
      final File fixture = File('test/fixtures/photos/geotagged.jpg');
      await storage.importExercisePhoto(
        exerciseId: 'exercise-1',
        source: fixture,
      );
      await storage.importSessionPhoto(sessionId: 'session-1', source: fixture);

      final AppData seed = AppData(
        exercises: <Exercise>[
          Exercise(
            id: 'exercise-1',
            name: 'Bench Press',
            createdAt: DateTime.utc(2026, 10),
          ),
        ],
        sessions: <Session>[
          Session(
            id: 'session-1',
            startedAt: DateTime.utc(2026, 10, 20, 10),
            endedAt: DateTime.utc(2026, 10, 20, 11),
          ),
        ],
      );
      final ProviderContainer container = ProviderContainer.test(
        overrides: [
          appDataStoreProvider.overrideWithValue(MemoryAppDataStore(seed)),
          photoStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      final AppData current = await container.read(
        appDataControllerProvider.future,
      );
      final BackupDocument document = parseBackup(
        buildBackupJson(
          AppData(),
          appVersion: '0.1.0',
          exportedAt: DateTime.utc(2026, 10, 25),
        ),
      );
      final ImportPreview preview = previewImport(
        current: current,
        document: document,
        mode: ImportMode.replace,
      );

      await container
          .read(appDataControllerProvider.notifier)
          .applyImport(preview);

      expect(
        container.read(appDataControllerProvider).requireValue.sessions,
        isEmpty,
      );
      expect(
        directory.listSync().whereType<File>(),
        isEmpty,
        reason: 'photos of removed exercises and sessions must not remain',
      );
    },
  );
}
