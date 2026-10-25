import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/app_data_store.dart';
import 'package:gym_log/data/photo_index_controller.dart';
import 'package:gym_log/data/photo_pending_store.dart';
import 'package:gym_log/data/photo_picker_service.dart';
import 'package:gym_log/data/photo_storage.dart';
import 'package:lift_core/lift_core.dart';

import '../support/memory_app_data_store.dart';
import '../support/photo_fakes.dart';

class _DelayedFailingStore implements AppDataStore {
  _DelayedFailingStore(this.inner);

  final AppDataStore inner;
  final Completer<void> _gate = Completer<void>();

  void release() {
    if (!_gate.isCompleted) {
      _gate.complete();
    }
  }

  @override
  Future<AppData> load() => inner.load();

  @override
  Future<void> snapshot() => inner.snapshot();

  @override
  Future<void> save(AppData data) async {
    await _gate.future;
    throw const DataStoreException('injected delayed save failure');
  }
}

Future<Directory> _tempDirectory() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'gym_log_photo_rollback_',
  );
  addTearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });
  return directory;
}

AppData _seed() {
  return AppData(
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
}

void main() {
  test('a failed session save keeps every stored photo', () async {
    final Directory directory = await _tempDirectory();
    final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
    await storage.importSessionPhoto(
      sessionId: 'session-1',
      source: File('test/fixtures/photos/geotagged.jpg'),
    );
    await storage.importExercisePhoto(
      exerciseId: 'exercise-1',
      source: File('test/fixtures/photos/geotagged.jpg'),
    );
    final _DelayedFailingStore store = _DelayedFailingStore(
      MemoryAppDataStore(_seed()),
    );
    final FakePhotoPicker picker = FakePhotoPicker();
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        appDataStoreProvider.overrideWithValue(store),
        photoStorageProvider.overrideWithValue(storage),
        photoPickerProvider.overrideWithValue(picker),
        photoPendingStoreProvider.overrideWithValue(MemoryPhotoPendingStore()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(appDataControllerProvider.future);
    final ProviderSubscription<AsyncValue<PhotoIndex>> subscription = container
        .listen<AsyncValue<PhotoIndex>>(
          photoIndexProvider,
          (AsyncValue<PhotoIndex>? previous, AsyncValue<PhotoIndex> next) {},
          fireImmediately: true,
        );
    addTearDown(subscription.close);
    final ProviderSubscription<AsyncValue<PhotoRecoveryOutcome>>
    recoverySubscription = container.listen<AsyncValue<PhotoRecoveryOutcome>>(
      photoRecoveryProvider,
      (
        AsyncValue<PhotoRecoveryOutcome>? previous,
        AsyncValue<PhotoRecoveryOutcome> next,
      ) {},
      fireImmediately: true,
    );
    addTearDown(recoverySubscription.close);
    await container.read(photoIndexProvider.future);
    await container.read(photoRecoveryProvider.future);
    expect(picker.retrieveCount, 1);

    final Future<void> deletion = container
        .read(appDataControllerProvider.notifier)
        .deleteSession('session-1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    store.release();
    await expectLater(deletion, throwsA(isA<DataStoreException>()));

    expect(
      File('${directory.path}${Platform.pathSeparator}session_session-1_0.jpg')
          .existsSync(),
      isTrue,
    );
    expect(
      File('${directory.path}${Platform.pathSeparator}exercise_exercise-1.jpg')
          .existsSync(),
      isTrue,
    );
    expect(
      container
          .read(appDataControllerProvider)
          .requireValue
          .sessionById('session-1'),
      isNotNull,
    );
    expect(
      picker.retrieveCount,
      1,
      reason: 'startup recovery must not re-run on a data save',
    );
  });

  test(
    'a successful save does not re-run startup recovery or clear a pick',
    () async {
      final Directory directory = await _tempDirectory();
      final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
      final FakePhotoPicker picker = FakePhotoPicker();
      final MemoryPhotoPendingStore pending = MemoryPhotoPendingStore();
      final ProviderContainer container = ProviderContainer.test(
        overrides: [
          appDataStoreProvider.overrideWithValue(MemoryAppDataStore(_seed())),
          photoStorageProvider.overrideWithValue(storage),
          photoPickerProvider.overrideWithValue(picker),
          photoPendingStoreProvider.overrideWithValue(pending),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appDataControllerProvider.future);
      final ProviderSubscription<AsyncValue<PhotoRecoveryOutcome>>
      recoverySubscription = container.listen<AsyncValue<PhotoRecoveryOutcome>>(
        photoRecoveryProvider,
        (
          AsyncValue<PhotoRecoveryOutcome>? previous,
          AsyncValue<PhotoRecoveryOutcome> next,
        ) {},
        fireImmediately: true,
      );
      addTearDown(recoverySubscription.close);
      await container.read(photoRecoveryProvider.future);
      expect(picker.retrieveCount, 1);

      // Simulate a picker that is in front of the app while an unrelated save
      // commits.
      pending.target = PhotoTarget.session('session-1');
      await container
          .read(appDataControllerProvider.notifier)
          .setWeightUnit(WeightUnit.pounds);

      expect(picker.retrieveCount, 1);
      expect(pending.target, isNotNull);
      expect(
        container
            .read(appDataControllerProvider)
            .requireValue
            .settings
            .weightUnit,
        WeightUnit.pounds,
      );
    },
  );

  test('a failed Replace save keeps the pre-import photo set', () async {
    final Directory directory = await _tempDirectory();
    final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
    await storage.importSessionPhoto(
      sessionId: 'session-1',
      source: File('test/fixtures/photos/geotagged.jpg'),
    );
    final _DelayedFailingStore store = _DelayedFailingStore(
      MemoryAppDataStore(_seed()),
    );
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        appDataStoreProvider.overrideWithValue(store),
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

    final Future<void> replace = container
        .read(appDataControllerProvider.notifier)
        .applyImport(preview);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    store.release();
    await expectLater(replace, throwsA(isA<DataStoreException>()));

    expect(
      File('${directory.path}${Platform.pathSeparator}session_session-1_0.jpg')
          .existsSync(),
      isTrue,
    );
    expect(
      container
          .read(appDataControllerProvider)
          .requireValue
          .sessionById('session-1'),
      isNotNull,
    );
  });
}
