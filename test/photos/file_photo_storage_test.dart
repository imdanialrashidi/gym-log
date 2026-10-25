import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/photo_storage.dart';
import 'package:image/image.dart' as image;

Future<Directory> _tempDirectory() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'gym_log_photos_',
  );
  addTearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });
  return directory;
}

File _fixture() => File('test/fixtures/photos/geotagged.jpg');

List<String> _names(Directory directory) {
  if (!directory.existsSync()) {
    return <String>[];
  }
  return directory
      .listSync()
      .whereType<File>()
      .map((File file) => file.uri.pathSegments.last)
      .toList()
    ..sort();
}

void main() {
  test(
    'session photos stop at three and removal deletes only that file',
    () async {
      final Directory directory = await _tempDirectory();
      final FilePhotoStorage storage = FilePhotoStorage(() async => directory);

      PhotoIndex index = await storage.load();
      expect(index.isEmpty, isTrue);

      for (int slot = 0; slot < maxSessionPhotos; slot++) {
        index = await storage.importSessionPhoto(
          sessionId: 'session-1',
          source: _fixture(),
        );
        expect(index.sessionSlots('session-1'), hasLength(slot + 1));
      }
      expect(_names(directory), <String>[
        'session_session-1_0.jpg',
        'session_session-1_1.jpg',
        'session_session-1_2.jpg',
      ]);
      final File stored = File(
        '${directory.path}${Platform.pathSeparator}session_session-1_0.jpg',
      );
      final image.Image decoded = image.decodeJpg(stored.readAsBytesSync())!;
      expect(decoded.width, 1600);
      expect(decoded.height, 1200);
      expect(decoded.exif.gpsIfd.isEmpty, isTrue);
      expect(decoded.exif.isEmpty, isTrue);
      expect(
        String.fromCharCodes(stored.readAsBytesSync())
            .contains('GymLog Test Camera'),
        isFalse,
      );

      await expectLater(
        storage.importSessionPhoto(sessionId: 'session-1', source: _fixture()),
        throwsA(
          isA<PhotoStorageException>().having(
            (PhotoStorageException error) => error.failure,
            'failure',
            PhotoFailure.limitReached,
          ),
        ),
      );
      expect(_names(directory), hasLength(3), reason: 'the fourth is refused');

      index = await storage.removeSessionPhoto(sessionId: 'session-1', slot: 1);
      expect(index.sessionSlots('session-1'), <int>[0, 2]);
      expect(_names(directory), <String>[
        'session_session-1_0.jpg',
        'session_session-1_2.jpg',
      ]);
    },
  );

  test(
    'session deletion removes every slot and exercise removal works',
    () async {
      final Directory directory = await _tempDirectory();
      final FilePhotoStorage storage = FilePhotoStorage(() async => directory);

      await storage.importSessionPhoto(
        sessionId: 'session-1',
        source: _fixture(),
      );
      await storage.importSessionPhoto(
        sessionId: 'session-1',
        source: _fixture(),
      );
      await storage.importExercisePhoto(
        exerciseId: 'exercise-1',
        source: _fixture(),
      );
      final image.Image exerciseCopy = image.decodeJpg(
        File(
          '${directory.path}${Platform.pathSeparator}exercise_exercise-1.jpg',
        ).readAsBytesSync(),
      )!;
      expect(exerciseCopy.width, 1600);
      expect(exerciseCopy.height, 1200);
      expect(exerciseCopy.exif.gpsIfd.isEmpty, isTrue);
      expect(exerciseCopy.exif.isEmpty, isTrue);
      expect(_names(directory), hasLength(3));

      PhotoIndex index = await storage.removeSession('session-1');
      expect(index.sessionSlots('session-1'), isEmpty);
      expect(index.exerciseFileName('exercise-1'), isNotNull);
      expect(_names(directory), <String>['exercise_exercise-1.jpg']);

      index = await storage.removeExercisePhoto('exercise-1');
      expect(index.exerciseFileName('exercise-1'), isNull);
      expect(_names(directory), isEmpty);
    },
  );

  test(
    'prune deletes orphans, unknown files, and interrupted temp writes',
    () async {
      final Directory directory = await _tempDirectory();
      final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
      await storage.importExercisePhoto(
        exerciseId: 'exercise-live',
        source: _fixture(),
      );
      await storage.importSessionPhoto(
        sessionId: 'session-live',
        source: _fixture(),
      );
      for (final String name in <String>[
        'exercise_deleted.jpg',
        'session_deleted_0.jpg',
        'session_session-live_2.jpg.tmp',
        'notes.txt',
      ]) {
        File('${directory.path}${Platform.pathSeparator}$name')
            .writeAsBytesSync(<int>[1, 2, 3]);
      }

      final PhotoIndex index = await storage.pruneAndLoad(
        exerciseIds: <String>{'exercise-live'},
        sessionIds: <String>{'session-live'},
      );

      expect(index.exerciseFileName('exercise-live'), isNotNull);
      expect(index.sessionSlots('session-live'), <int>[0]);
      expect(_names(directory), <String>[
        'exercise_exercise-live.jpg',
        'session_session-live_0.jpg',
      ]);
    },
  );

  test('a write failure leaves no partial or temporary file', () async {
    final Directory directory = await _tempDirectory();
    final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
    // A directory at the target path makes the final rename fail after the
    // temporary file was written.
    Directory(
      '${directory.path}${Platform.pathSeparator}exercise_exercise-1.jpg',
    ).createSync();

    await expectLater(
      storage.importExercisePhoto(exerciseId: 'exercise-1', source: _fixture()),
      throwsA(
        isA<PhotoStorageException>().having(
          (PhotoStorageException error) => error.failure,
          'failure',
          PhotoFailure.writeFailed,
        ),
      ),
    );

    expect(_names(directory), isEmpty);
    expect(
      directory.listSync().where((FileSystemEntity entity) {
        return entity.path.endsWith('.tmp');
      }),
      isEmpty,
    );
  });

  test(
    'an unreadable source is rejected without creating a stored file',
    () async {
      final Directory directory = await _tempDirectory();
      final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
      final Directory sourceDirectory = await _tempDirectory();
      final File source = File(
        '${sourceDirectory.path}${Platform.pathSeparator}broken.jpg',
      )..writeAsBytesSync(<int>[1, 2, 3, 4, 5]);

      await expectLater(
        storage.importSessionPhoto(sessionId: 'session-1', source: source),
        throwsA(
          isA<PhotoStorageException>().having(
            (PhotoStorageException error) => error.failure,
            'failure',
            PhotoFailure.unreadable,
          ),
        ),
      );
      expect(_names(directory), isEmpty);
    },
  );
}
