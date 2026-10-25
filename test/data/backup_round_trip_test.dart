import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:lift_core/lift_core.dart';

import '../support/backup_data.dart';
import '../support/memory_app_data_store.dart';

String _compact(String text) => jsonEncode(jsonDecode(text));

void main() {
  test('export -> import -> export is equivalent', () {
    final String first = backupJson();

    final BackupDocument document = parseBackup(first);
    final String second = buildBackupJson(
      document.data,
      appVersion: document.appVersion,
      exportedAt: document.exportedAt,
      generator: document.generator,
    );

    expect(_compact(second), _compact(first));
  });

  test('import into an empty database and re-export keeps content', () async {
    final MemoryAppDataStore store = MemoryAppDataStore();
    final ProviderContainer container = ProviderContainer.test(
      overrides: [appDataStoreProvider.overrideWithValue(store)],
    );
    await container.read(appDataControllerProvider.future);
    final BackupDocument document = parseBackup(backupJson());

    final ImportPreview preview = previewImport(
      current: store.data,
      document: document,
      mode: ImportMode.merge,
    );
    await container
        .read(appDataControllerProvider.notifier)
        .applyImport(preview);

    final AppData imported = container
        .read(appDataControllerProvider)
        .requireValue;
    expect(imported.exercises, hasLength(2));
    expect(imported.sessions, hasLength(1));
    expect(imported.sessions.single.exercises.single.sets.single.reps, 10);
    expect(imported.settings.weightUnit, WeightUnit.pounds);

    final String reExported = buildBackupJson(
      imported,
      appVersion: document.appVersion,
      exportedAt: document.exportedAt,
      generator: document.generator,
    );
    expect(_compact(reExported), _compact(backupJson()));
  });

  test('every historical fixture imports and round-trips exactly', () {
    final Directory directory = Directory('test/fixtures/export');
    final List<File> fixtures =
        directory
            .listSync()
            .whereType<File>()
            .where((File file) => file.path.endsWith('.json'))
            .toList()
          ..sort((File a, File b) => a.path.compareTo(b.path));

    expect(
      fixtures,
      isNotEmpty,
      reason: 'Add test/fixtures/export/v<version>.json for every release.',
    );

    for (final File file in fixtures) {
      final String original = file.readAsStringSync();
      final BackupDocument document = parseBackup(original);
      final String fileName = file.uri.pathSegments.last;
      expect(
        fileName,
        'v${document.appVersion}.json',
        reason: '${file.path} must be named for its exported app version.',
      );

      final String reEncoded = buildBackupJson(
        document.data,
        appVersion: document.appVersion,
        exportedAt: document.exportedAt,
        generator: document.generator,
      );
      expect(
        _compact(reEncoded),
        _compact(original),
        reason: '${file.path} no longer round-trips to its recorded content.',
      );
    }
  });
}
