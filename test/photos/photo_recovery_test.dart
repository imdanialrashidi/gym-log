import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/photo_pending_store.dart';
import 'package:gym_log/data/photo_picker.dart';
import 'package:gym_log/data/photo_picker_service.dart';
import 'package:gym_log/data/photo_storage.dart';
import 'package:image/image.dart' as image;

import '../support/photo_fakes.dart';

Future<Directory> _tempDirectory() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'gym_log_photo_recovery_',
  );
  addTearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });
  return directory;
}

File _lostCopy(Directory directory) {
  return File('test/fixtures/photos/geotagged.jpg')
      .copySync('${directory.path}${Platform.pathSeparator}lost.jpg');
}

void main() {
  test(
    'a pending picker result is imported once and the cache copy is removed',
    () async {
      final Directory directory = await _tempDirectory();
      final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
      final MemoryPhotoPendingStore pending = MemoryPhotoPendingStore()
        ..target = PhotoTarget.session('session-1');
      final File lost = _lostCopy(directory);
      final FakePhotoPicker picker = FakePhotoPicker(lost: lost);
      final PhotoPickerService service = PhotoPickerService(
        picker: picker,
        pending: pending,
        storage: storage,
      );

      final PhotoRecoveryOutcome outcome = await service.recover(
        exerciseIds: <String>{},
        sessionIds: <String>{'session-1'},
      );

      expect(outcome, PhotoRecoveryOutcome.recovered);
      expect(pending.target, isNull);
      expect(lost.existsSync(), isFalse);
      final File stored = File(
        '${directory.path}${Platform.pathSeparator}session_session-1_0.jpg',
      );
      expect(stored.existsSync(), isTrue);
      final image.Image decoded = image.decodeJpg(stored.readAsBytesSync())!;
      expect(decoded.width, 1600);
      expect(decoded.height, 1200);
      expect(decoded.exif.gpsIfd.isEmpty, isTrue);
      expect(decoded.exif.isEmpty, isTrue);
      expect(picker.retrieveCount, 1);
    },
  );

  test(
    'a lost file without a surviving target is discarded, not stored',
    () async {
      final Directory directory = await _tempDirectory();
      final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
      final MemoryPhotoPendingStore pending = MemoryPhotoPendingStore()
        ..target = PhotoTarget.session('deleted-session');
      final File lost = _lostCopy(directory);
      final PhotoPickerService service = PhotoPickerService(
        picker: FakePhotoPicker(lost: lost),
        pending: pending,
        storage: storage,
      );

      final PhotoRecoveryOutcome outcome = await service.recover(
        exerciseIds: <String>{},
        sessionIds: <String>{'session-1'},
      );

      expect(outcome, PhotoRecoveryOutcome.discarded);
      expect(pending.target, isNull);
      expect(lost.existsSync(), isFalse);
      expect((await storage.load()).isEmpty, isTrue);
    },
  );

  test('a lost file with no pending marker is discarded', () async {
    final Directory directory = await _tempDirectory();
    final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
    final File lost = _lostCopy(directory);
    final PhotoPickerService service = PhotoPickerService(
      picker: FakePhotoPicker(lost: lost),
      pending: MemoryPhotoPendingStore(),
      storage: storage,
    );

    final PhotoRecoveryOutcome outcome = await service.recover(
      exerciseIds: <String>{'exercise-1'},
      sessionIds: <String>{'session-1'},
    );

    expect(outcome, PhotoRecoveryOutcome.discarded);
    expect(lost.existsSync(), isFalse);
    expect((await storage.load()).isEmpty, isTrue);
  });

  test(
    'an unreadable lost file leaves no partial photo and clears the marker',
    () async {
      final Directory directory = await _tempDirectory();
      final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
      final MemoryPhotoPendingStore pending = MemoryPhotoPendingStore()
        ..target = PhotoTarget.exercise('exercise-1');
      final File lost = File(
        '${directory.path}${Platform.pathSeparator}lost.jpg',
      )..writeAsBytesSync(<int>[9, 8, 7]);
      final PhotoPickerService service = PhotoPickerService(
        picker: FakePhotoPicker(lost: lost),
        pending: pending,
        storage: storage,
      );

      final PhotoRecoveryOutcome outcome = await service.recover(
        exerciseIds: <String>{'exercise-1'},
        sessionIds: <String>{},
      );

      expect(outcome, PhotoRecoveryOutcome.failed);
      expect(pending.target, isNull);
      expect(lost.existsSync(), isFalse);
      expect((await storage.load()).isEmpty, isTrue);
    },
  );

  test('a picker failure clears the marker and writes nothing', () async {
    final Directory directory = await _tempDirectory();
    final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
    final MemoryPhotoPendingStore pending = MemoryPhotoPendingStore()
      ..target = PhotoTarget.session('session-1');
    final PhotoPickerService service = PhotoPickerService(
      picker: FakePhotoPicker(lost: File('/missing'))..throwOnLost = true,
      pending: pending,
      storage: storage,
    );

    final PhotoRecoveryOutcome outcome = await service.recover(
      exerciseIds: <String>{},
      sessionIds: <String>{'session-1'},
    );

    expect(outcome, PhotoRecoveryOutcome.failed);
    expect(pending.target, isNull);
    expect((await storage.load()).isEmpty, isTrue);
  });

  test('cancelled picks and pick errors clear the pending marker', () async {
    final Directory directory = await _tempDirectory();
    final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
    final MemoryPhotoPendingStore pending = MemoryPhotoPendingStore();
    final FakePhotoPicker picker = FakePhotoPicker();
    final PhotoPickerService service = PhotoPickerService(
      picker: picker,
      pending: pending,
      storage: storage,
    );

    expect(
      await service.pick(
        source: PhotoSource.gallery,
        target: PhotoTarget.session('session-1'),
      ),
      isNull,
    );
    expect(pending.writeCount, 1);
    expect(pending.target, isNull);

    picker.throwOnPick = true;
    await expectLater(
      service.pick(
        source: PhotoSource.camera,
        target: PhotoTarget.session('session-1'),
      ),
      throwsA(isA<PhotoPickException>()),
    );
    expect(pending.target, isNull);
  });
}
