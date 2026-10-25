import 'dart:io';

import 'package:gym_log/data/photo_pending_store.dart';
import 'package:gym_log/data/photo_picker.dart';
import 'package:gym_log/data/photo_storage.dart';

/// In-memory photo directory for widget tests. Real EXIF/downscale/atomic
/// behavior is covered by `test/photos/` against `FilePhotoStorage`.
class MemoryPhotoStorage implements PhotoStorage {
  MemoryPhotoStorage({
    Directory? directory,
    Set<String>? fileNames,
    this.importFailure,
    this.removeFailure,
  }) : directory = directory ?? Directory('/tmp/gym_log_memory_photos'),
       _fileNames = <String>{...?fileNames};

  final Directory directory;
  final PhotoFailure? importFailure;
  final PhotoFailure? removeFailure;
  final Set<String> _fileNames;
  int importCount = 0;
  int removeCount = 0;

  PhotoIndex get index =>
      PhotoIndex(directory: directory, fileNames: _fileNames);

  void _storeSource(String name, File source) {
    directory.createSync(recursive: true);
    final File target = File('${directory.path}${Platform.pathSeparator}$name');
    if (source.existsSync()) {
      source.copySync(target.path);
    } else {
      target.writeAsBytesSync(<int>[0]);
    }
    _fileNames.add(name);
  }

  void _removeFile(String name) {
    _fileNames.remove(name);
    final File file = File('${directory.path}${Platform.pathSeparator}$name');
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  @override
  Future<PhotoIndex> load() async => index;

  @override
  Future<PhotoIndex> pruneAndLoad({
    required Set<String> exerciseIds,
    required Set<String> sessionIds,
  }) async {
    final Set<String> expected = <String>{};
    for (final String id in exerciseIds) {
      if (isPhotoEntityIdSafe(id)) {
        expected.add(exercisePhotoFileName(id));
      }
    }
    for (final String id in sessionIds) {
      if (!isPhotoEntityIdSafe(id)) {
        continue;
      }
      for (int slot = 0; slot < maxSessionPhotos; slot++) {
        expected.add(sessionPhotoFileName(id, slot));
      }
    }
    _fileNames.retainAll(expected);
    return index;
  }

  @override
  Future<PhotoIndex> importExercisePhoto({
    required String exerciseId,
    required File source,
  }) async {
    importCount += 1;
    if (importFailure != null) {
      throw PhotoStorageException(importFailure!);
    }
    _storeSource(exercisePhotoFileName(exerciseId), source);
    return index;
  }

  @override
  Future<PhotoIndex> importSessionPhoto({
    required String sessionId,
    required File source,
  }) async {
    importCount += 1;
    if (importFailure != null) {
      throw PhotoStorageException(importFailure!);
    }
    for (int slot = 0; slot < maxSessionPhotos; slot++) {
      final String name = sessionPhotoFileName(sessionId, slot);
      if (!_fileNames.contains(name)) {
        _storeSource(name, source);
        return index;
      }
    }
    throw const PhotoStorageException(PhotoFailure.limitReached);
  }

  @override
  Future<PhotoIndex> removeExercisePhoto(String exerciseId) async {
    removeCount += 1;
    if (removeFailure != null) {
      throw PhotoStorageException(removeFailure!);
    }
    _removeFile(exercisePhotoFileName(exerciseId));
    return index;
  }

  @override
  Future<PhotoIndex> removeSessionPhoto({
    required String sessionId,
    required int slot,
  }) async {
    removeCount += 1;
    if (removeFailure != null) {
      throw PhotoStorageException(removeFailure!);
    }
    _removeFile(sessionPhotoFileName(sessionId, slot));
    return index;
  }

  @override
  Future<PhotoIndex> removeSession(String sessionId) async {
    removeCount += 1;
    if (removeFailure != null) {
      throw PhotoStorageException(removeFailure!);
    }
    for (int slot = 0; slot < maxSessionPhotos; slot++) {
      _removeFile(sessionPhotoFileName(sessionId, slot));
    }
    return index;
  }
}

class MemoryPhotoPendingStore implements PhotoPendingStore {
  PhotoTarget? target;
  int writeCount = 0;
  int clearCount = 0;

  @override
  Future<PhotoTarget?> read() async => target;

  @override
  Future<void> write(PhotoTarget next) async {
    writeCount += 1;
    target = next;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    target = null;
  }
}

class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker({this.next, this.lost});

  File? next;
  File? lost;
  bool throwOnPick = false;
  bool throwOnLost = false;
  int pickCount = 0;
  int retrieveCount = 0;
  PhotoSource? lastSource;

  @override
  Future<File?> pick(PhotoSource source) async {
    pickCount += 1;
    lastSource = source;
    if (throwOnPick) {
      throw const PhotoPickException();
    }
    return next;
  }

  @override
  Future<File?> retrieveLost() async {
    retrieveCount += 1;
    if (throwOnLost) {
      throw const PhotoPickException();
    }
    return lost;
  }
}
