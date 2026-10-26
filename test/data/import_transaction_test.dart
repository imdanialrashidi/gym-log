import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/app_data_store.dart';
import 'package:lift_core/lift_core.dart';

import '../support/backup_data.dart';
import '../support/failing_app_data_store.dart';
import '../support/memory_app_data_store.dart';

ProviderContainer _container(AppDataStore store) {
  return ProviderContainer.test(
    overrides: [appDataStoreProvider.overrideWithValue(store)],
  );
}

Future<File> _tempDataFile() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'gym_log_import_tx_',
  );
  addTearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });
  return File('${directory.path}${Platform.pathSeparator}data.json');
}

void main() {
  test('dry-run Merge counts equal the records the commit adds', () async {
    final MemoryAppDataStore store = MemoryAppDataStore();
    final ProviderContainer container = _container(store);
    addTearDown(container.dispose);
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

    expect(store.saveCount, 1);
    expect(store.data.exercises, hasLength(preview.summary.added.exercises));
    expect(store.data.programs, hasLength(preview.summary.added.programs));
    expect(store.data.sessions, hasLength(preview.summary.added.sessions));
    expect(
      store.data.sessions
          .expand((Session session) => session.exercises)
          .expand((SessionExercise exercise) => exercise.sets)
          .length,
      preview.summary.added.sets,
    );
    expect(
      countAppData(store.data),
      preview.summary.added,
      reason: 'The empty database gains exactly the previewed records.',
    );
  });

  test('Merge keeps a same-ID local record and reports a conflict', () async {
    final Exercise local = Exercise(
      id: 'exercise-1',
      name: 'Local Press',
      createdAt: DateTime.utc(2026, 9, 1, 9),
    );
    final MemoryAppDataStore store = MemoryAppDataStore(
      AppData(exercises: <Exercise>[local]),
    );
    final ProviderContainer container = _container(store);
    addTearDown(container.dispose);
    await container.read(appDataControllerProvider.future);
    final BackupDocument document = parseBackup(backupJson());

    final ImportPreview preview = previewImport(
      current: store.data,
      document: document,
      mode: ImportMode.merge,
    );
    expect(preview.summary.conflicts, 1);
    await container
        .read(appDataControllerProvider.notifier)
        .applyImport(preview);

    expect(store.data.exerciseById('exercise-1')!.name, 'Local Press');
    expect(store.data.sessions, hasLength(1));
  });

  test('Replace snapshots and applies the incoming document', () async {
    final MemoryAppDataStore inner = MemoryAppDataStore(
      AppData(
        exercises: <Exercise>[
          Exercise(
            id: 'old',
            name: 'Old Exercise',
            createdAt: DateTime.utc(2026, 9, 1, 9),
          ),
        ],
      ),
    );
    final FailingAppDataStore store = FailingAppDataStore(inner);
    final ProviderContainer container = _container(store);
    addTearDown(container.dispose);
    await container.read(appDataControllerProvider.future);
    final BackupDocument document = parseBackup(backupJson());
    final ImportPreview preview = previewImport(
      current: inner.data,
      document: document,
      mode: ImportMode.replace,
    );

    await container
        .read(appDataControllerProvider.notifier)
        .applyImport(preview);

    expect(store.snapshotCount, 1);
    expect(store.saveAttempts, 1);
    expect(inner.data.exerciseById('old'), isNull);
    expect(inner.data.exercises.first.name, 'Bench Press');
  });

  test('Replace aborts before writing when the snapshot fails', () async {
    final MemoryAppDataStore inner = MemoryAppDataStore();
    final FailingAppDataStore store = FailingAppDataStore(
      inner,
      failSnapshot: true,
    );
    final ProviderContainer container = _container(store);
    addTearDown(container.dispose);
    await container.read(appDataControllerProvider.future);
    final BackupDocument document = parseBackup(backupJson());
    final ImportPreview preview = previewImport(
      current: inner.data,
      document: document,
      mode: ImportMode.replace,
    );

    await expectLater(
      container.read(appDataControllerProvider.notifier).applyImport(preview),
      throwsA(isA<DataStoreException>()),
    );
    expect(store.snapshotCount, 1);
    expect(store.saveAttempts, 0);
    expect(inner.data.exercises, isEmpty);
    expect(
      container.read(appDataControllerProvider).requireValue.exercises,
      isEmpty,
    );
  });

  test(
    'Merge save failure restores state and leaves the store unchanged',
    () async {
      final MemoryAppDataStore inner = MemoryAppDataStore();
      final FailingAppDataStore store = FailingAppDataStore(
        inner,
        failSave: true,
      );
      final ProviderContainer container = _container(store);
      addTearDown(container.dispose);
      await container.read(appDataControllerProvider.future);
      final BackupDocument document = parseBackup(backupJson());
      final ImportPreview preview = previewImport(
        current: inner.data,
        document: document,
        mode: ImportMode.merge,
      );

      await expectLater(
        container.read(appDataControllerProvider.notifier).applyImport(preview),
        throwsA(isA<DataStoreException>()),
      );

      expect(store.saveAttempts, 1);
      expect(inner.data.exercises, isEmpty);
      expect(
        container.read(appDataControllerProvider).requireValue.exercises,
        isEmpty,
      );
    },
  );

  test('Replace with the JSON store snapshots first and survives a mid-import failure', () async {
    final File file = await _tempDataFile();
    final AppData original = AppData(
      exercises: <Exercise>[
        Exercise(
          id: 'old',
          name: 'Old Exercise',
          createdAt: DateTime.utc(2026, 9, 1, 9),
        ),
      ],
    );
    final JsonAppDataStore json = JsonAppDataStore(Future<File>.value(file));
    await json.save(original);
    final List<int> before = await file.readAsBytes();
    final FailingAppDataStore store = FailingAppDataStore(json, failSave: true);
    final ProviderContainer container = _container(store);
    addTearDown(container.dispose);
    await container.read(appDataControllerProvider.future);
    final BackupDocument document = parseBackup(backupJson());
    final ImportPreview preview = previewImport(
      current: await json.load(),
      document: document,
      mode: ImportMode.replace,
    );

    await expectLater(
      container.read(appDataControllerProvider.notifier).applyImport(preview),
      throwsA(isA<DataStoreException>()),
    );

    expect(store.snapshotCount, 1);
    expect(store.saveAttempts, 1);
    expect(await file.readAsBytes(), before);
    final Directory backups = Directory(
      '${file.parent.path}${Platform.pathSeparator}backups',
    );
    final List<File> snapshots = backups.listSync().whereType<File>().toList();
    expect(snapshots, hasLength(1));
    expect(await snapshots.single.readAsBytes(), before);
    expect(
      container
          .read(appDataControllerProvider)
          .requireValue
          .exerciseById('old'),
      isNotNull,
    );
  });

  test('a preview whose counts no longer match is refused', () async {
    final MemoryAppDataStore store = MemoryAppDataStore();
    final ProviderContainer container = _container(store);
    addTearDown(container.dispose);
    await container.read(appDataControllerProvider.future);
    final BackupDocument document = parseBackup(backupJson());
    final ImportCounts incoming = countAppData(document.data);
    final ImportPreview stale = ImportPreview(
      mode: ImportMode.merge,
      document: document,
      summary: MergeSummary(
        incoming: incoming,
        added: ImportCounts.zero,
        unchanged: ImportCounts.zero,
        conflicts: 0,
      ),
      data: document.data,
    );

    await expectLater(
      container.read(appDataControllerProvider.notifier).applyImport(stale),
      throwsA(isA<ImportPreviewMismatch>()),
    );
    expect(store.saveCount, 0);
    expect(store.data.exercises, isEmpty);
  });

  test(
    'restoring a data snapshot publishes it and keeps a recovery point',
    () async {
      final File file = await _tempDataFile();
      DateTime now = DateTime.utc(2026, 10, 23, 10);
      final JsonAppDataStore store = JsonAppDataStore(
        Future<File>.value(file),
        snapshotClock: () => now,
      );
      await store.save(
        AppData(
          exercises: <Exercise>[
            Exercise(
              id: 'exercise-1',
              name: 'Alpha',
              createdAt: DateTime.utc(2026, 10, 20),
            ),
          ],
        ),
      );
      now = now.add(const Duration(minutes: 1));
      await store.snapshot();
      await store.save(
        AppData(
          exercises: <Exercise>[
            Exercise(
              id: 'exercise-1',
              name: 'Bravo',
              createdAt: DateTime.utc(2026, 10, 20),
            ),
          ],
        ),
      );
      final ProviderContainer container = _container(store);
      addTearDown(container.dispose);
      await container.read(appDataControllerProvider.future);
      final DataSnapshotInfo recovery = (await store.listSnapshots()).single;
      now = now.add(const Duration(minutes: 1));

      await container
          .read(appDataControllerProvider.notifier)
          .restoreSnapshot(recovery.fileName);

      expect(
        container
            .read(appDataControllerProvider)
            .requireValue
            .exercises
            .single
            .name,
        'Alpha',
      );
      expect((await store.load()).exercises.single.name, 'Alpha');
      final List<DataSnapshotInfo> after = await store.listSnapshots();
      expect(
        after,
        hasLength(2),
        reason: 'The pre-restore data is recoverable',
      );
      expect(
        (await store.loadSnapshot(after.first.fileName)).exercises.single.name,
        'Bravo',
      );
    },
  );

  test('a failed snapshot load writes nothing and keeps the state', () async {
    final Exercise current = Exercise(
      id: 'exercise-1',
      name: 'Bravo',
      createdAt: DateTime.utc(2026, 10, 20),
    );
    final MemoryAppDataStore memory = MemoryAppDataStore(
      AppData(exercises: <Exercise>[current]),
    );
    memory.seedSnapshot(
      'gym_log_data-2026-10-23T10-00-00.000Z.json',
      AppData(
        exercises: <Exercise>[
          Exercise(
            id: 'exercise-1',
            name: 'Alpha',
            createdAt: DateTime.utc(2026, 10, 20),
          ),
        ],
      ),
    );
    final FailingAppDataStore store = FailingAppDataStore(
      memory,
      failLoadSnapshot: true,
    );
    final ProviderContainer container = _container(store);
    addTearDown(container.dispose);
    await container.read(appDataControllerProvider.future);

    await expectLater(
      container
          .read(appDataControllerProvider.notifier)
          .restoreSnapshot('gym_log_data-2026-10-23T10-00-00.000Z.json'),
      throwsA(isA<DataStoreException>()),
    );

    expect(memory.saveCount, 0);
    expect(memory.snapshotCount, 0);
    expect(
      container
          .read(appDataControllerProvider)
          .requireValue
          .exercises
          .single
          .name,
      'Bravo',
    );
  });

  test('restoring a snapshot snapshots once then saves once', () async {
    final MemoryAppDataStore store = MemoryAppDataStore();
    store.seedSnapshot('gym_log_data-2026-10-23T10-00-00.000Z.json', AppData());
    final ProviderContainer container = _container(store);
    addTearDown(container.dispose);
    await container.read(appDataControllerProvider.future);

    await container
        .read(appDataControllerProvider.notifier)
        .restoreSnapshot('gym_log_data-2026-10-23T10-00-00.000Z.json');

    expect(store.snapshotCount, 1);
    expect(store.saveCount, 1);
  });

  test(
    'restoreFromBackup snapshots an unreadable document before replacing it',
    () async {
      final File file = await _tempDataFile();
      const String corrupt = '{"schemaVersion": 1, "exercises": [';
      await file.writeAsString(corrupt);
      final JsonAppDataStore json = JsonAppDataStore(Future<File>.value(file));
      final ProviderContainer container = _container(json);
      addTearDown(container.dispose);

      await expectLater(
        container.read(appDataControllerProvider.future),
        throwsA(isA<DataStoreException>()),
      );

      final BackupDocument document = parseBackup(backupJson());
      final ImportPreview preview = previewImport(
        current: AppData(),
        document: document,
        mode: ImportMode.replace,
      );
      await container
          .read(appDataControllerProvider.notifier)
          .restoreFromBackup(preview);

      final AppData restored = container
          .read(appDataControllerProvider)
          .requireValue;
      expect(restored.sessions, hasLength(1));
      expect((await json.load()).sessions, hasLength(1));

      final Directory backups = Directory(
        '${file.parent.path}${Platform.pathSeparator}backups',
      );
      final List<File> snapshots = backups
          .listSync()
          .whereType<File>()
          .toList();
      expect(snapshots, hasLength(1));
      expect(await snapshots.single.readAsString(), corrupt);
      expect(File('${file.path}.tmp').existsSync(), isFalse);
    },
  );
}
