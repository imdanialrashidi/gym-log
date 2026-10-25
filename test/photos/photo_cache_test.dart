import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/photo_index_controller.dart';
import 'package:gym_log/data/photo_storage.dart';
import 'package:lift_core/lift_core.dart';

import '../support/memory_app_data_store.dart';
import '../support/photo_fakes.dart';

const String _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
    '+A8AAQUBAScY42YAAAAASUVORK5CYII=';

AppData _seed() {
  return AppData(
    exercises: <Exercise>[
      Exercise(
        id: 'exercise-1',
        name: 'Bench Press',
        createdAt: DateTime.utc(2026, 10),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'replacing an exercise photo evicts the decoded image for its path',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'gym_log_photo_cache_',
      );
      addTearDown(() async {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      });
      final File source = File(
        '${directory.path}${Platform.pathSeparator}source.png',
      )..writeAsBytesSync(base64Decode(_onePixelPng));
      final MemoryPhotoStorage storage = MemoryPhotoStorage(
        directory: directory,
      );
      final ProviderContainer container = ProviderContainer.test(
        overrides: [
          appDataStoreProvider.overrideWithValue(MemoryAppDataStore(_seed())),
          photoStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appDataControllerProvider.future);
      final ProviderSubscription<AsyncValue<PhotoIndex>> indexSubscription =
          container.listen<AsyncValue<PhotoIndex>>(
            photoIndexProvider,
            (AsyncValue<PhotoIndex>? previous, AsyncValue<PhotoIndex> next) {},
          );
      addTearDown(indexSubscription.close);
      await container.read(photoIndexProvider.future);

      final File target = File(
        '${directory.path}${Platform.pathSeparator}'
        'exercise_exercise-1.jpg',
      );
      final ImageProvider provider = FileImage(target);
      final ImageCache cache = PaintingBinding.instance.imageCache;
      cache.clear();
      cache.putIfAbsent(
        provider,
        () => OneFrameImageStreamCompleter(Completer<ImageInfo>().future),
      );
      addTearDown(cache.clear);
      expect(cache.containsKey(provider), isTrue);

      await container
          .read(photoIndexProvider.notifier)
          .addExercisePhoto('exercise-1', source);

      expect(storage.index.exerciseFileName('exercise-1'), isNotNull);
      expect(
        cache.containsKey(provider),
        isFalse,
        reason: 'a deterministic path must not keep serving the old pixels',
      );
    },
  );
}
