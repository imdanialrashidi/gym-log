import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'photo_processor.dart';

/// Owner-decided session photo limit (ADR-0006).
const int maxSessionPhotos = 3;

final RegExp _safeEntityId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$');
final RegExp _exercisePhotoName = RegExp(
  r'^exercise_[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.jpg$',
);
final RegExp _sessionPhotoName = RegExp(
  r'^session_[A-Za-z0-9][A-Za-z0-9._-]{0,127}_[0-2]\.jpg$',
);

/// Entity IDs become file-name components, so only the backup-safe alphabet
/// is accepted. This blocks path traversal even if a local document is corrupt.
bool isPhotoEntityIdSafe(String id) => _safeEntityId.hasMatch(id);

String _requireSafeEntityId(String id) {
  if (!isPhotoEntityIdSafe(id)) {
    throw ArgumentError.value(id, 'id', 'Unsafe photo entity id');
  }
  return id;
}

String exercisePhotoFileName(String exerciseId) =>
    'exercise_${_requireSafeEntityId(exerciseId)}.jpg';

String sessionPhotoFileName(String sessionId, int slot) {
  if (slot < 0 || slot >= maxSessionPhotos) {
    throw ArgumentError.value(slot, 'slot');
  }
  return 'session_${_requireSafeEntityId(sessionId)}_$slot.jpg';
}

/// Reason a photo operation failed. User-facing copy is mapped in the UI; the
/// exception never carries a file path or image content.
enum PhotoFailure {
  unreadable,
  outOfSpace,
  writeFailed,
  deleteFailed,
  limitReached,
}

class PhotoStorageException implements Exception {
  const PhotoStorageException(this.failure);

  final PhotoFailure failure;

  @override
  String toString() => 'PhotoStorageException(${failure.name})';
}

/// Current private photo directory contents.
class PhotoIndex {
  PhotoIndex({required this.directory, required Set<String> fileNames})
    : fileNames = Set<String>.unmodifiable(fileNames);

  final Directory directory;
  final Set<String> fileNames;

  bool get isEmpty => fileNames.isEmpty;

  String? exerciseFileName(String exerciseId) {
    if (!isPhotoEntityIdSafe(exerciseId)) {
      return null;
    }
    final String name = exercisePhotoFileName(exerciseId);
    return fileNames.contains(name) ? name : null;
  }

  List<int> sessionSlots(String sessionId) {
    if (!isPhotoEntityIdSafe(sessionId)) {
      return const <int>[];
    }
    return <int>[
      for (int slot = 0; slot < maxSessionPhotos; slot++)
        if (fileNames.contains(sessionPhotoFileName(sessionId, slot))) slot,
    ];
  }

  File file(String fileName) {
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }
}

/// Private, app-owned photo files. There is deliberately no photo metadata in
/// the JSON document, so exports and imports cannot carry photo references.
abstract interface class PhotoStorage {
  Future<PhotoIndex> load();

  /// Removes every file that does not belong to a current exercise or session,
  /// then returns the remaining index. Temporary files from interrupted writes
  /// are removed too.
  Future<PhotoIndex> pruneAndLoad({
    required Set<String> exerciseIds,
    required Set<String> sessionIds,
  });

  Future<PhotoIndex> importExercisePhoto({
    required String exerciseId,
    required File source,
  });

  Future<PhotoIndex> importSessionPhoto({
    required String sessionId,
    required File source,
  });

  Future<PhotoIndex> removeExercisePhoto(String exerciseId);

  Future<PhotoIndex> removeSessionPhoto({
    required String sessionId,
    required int slot,
  });

  Future<PhotoIndex> removeSession(String sessionId);
}

/// Photo storage rooted in a directory resolved lazily so tests can redirect
/// it without touching path_provider.
class FilePhotoStorage implements PhotoStorage {
  FilePhotoStorage(this._directoryProvider);

  final Future<Directory> Function() _directoryProvider;
  Future<void> _chain = Future<void>.value();

  @override
  Future<PhotoIndex> load() {
    return _serialized(() async {
      return _indexFromDirectory(await _directoryProvider());
    });
  }

  @override
  Future<PhotoIndex> pruneAndLoad({
    required Set<String> exerciseIds,
    required Set<String> sessionIds,
  }) {
    return _serialized(() async {
      final Directory directory = await _directoryProvider();
      return _indexFromDirectory(
        directory,
        keep: _expectedFileNames(
          exerciseIds: exerciseIds,
          sessionIds: sessionIds,
        ),
      );
    });
  }

  @override
  Future<PhotoIndex> importExercisePhoto({
    required String exerciseId,
    required File source,
  }) {
    return _serialized(() async {
      _requireSafeEntityId(exerciseId);
      final Directory directory = await _directoryProvider();
      final Uint8List bytes = await _process(source);
      await _createDirectory(directory);
      final File target = File(
        '${directory.path}${Platform.pathSeparator}'
        '${exercisePhotoFileName(exerciseId)}',
      );
      await _writeAtomic(target, bytes);
      return _indexFromDirectory(directory);
    });
  }

  @override
  Future<PhotoIndex> importSessionPhoto({
    required String sessionId,
    required File source,
  }) {
    return _serialized(() async {
      _requireSafeEntityId(sessionId);
      final Directory directory = await _directoryProvider();
      final PhotoIndex current = await _indexFromDirectory(directory);
      final int? slot = _firstFreeSlot(current, sessionId);
      if (slot == null) {
        throw const PhotoStorageException(PhotoFailure.limitReached);
      }
      final Uint8List bytes = await _process(source);
      await _createDirectory(directory);
      final File target = File(
        '${directory.path}${Platform.pathSeparator}'
        '${sessionPhotoFileName(sessionId, slot)}',
      );
      await _writeAtomic(target, bytes);
      return _indexFromDirectory(directory);
    });
  }

  @override
  Future<PhotoIndex> removeExercisePhoto(String exerciseId) {
    return _serialized(() async {
      _requireSafeEntityId(exerciseId);
      final Directory directory = await _directoryProvider();
      await _delete(
        File(
          '${directory.path}${Platform.pathSeparator}'
          '${exercisePhotoFileName(exerciseId)}',
        ),
      );
      return _indexFromDirectory(directory);
    });
  }

  @override
  Future<PhotoIndex> removeSessionPhoto({
    required String sessionId,
    required int slot,
  }) {
    return _serialized(() async {
      final Directory directory = await _directoryProvider();
      await _delete(
        File(
          '${directory.path}${Platform.pathSeparator}'
          '${sessionPhotoFileName(sessionId, slot)}',
        ),
      );
      return _indexFromDirectory(directory);
    });
  }

  @override
  Future<PhotoIndex> removeSession(String sessionId) {
    return _serialized(() async {
      _requireSafeEntityId(sessionId);
      final Directory directory = await _directoryProvider();
      for (int slot = 0; slot < maxSessionPhotos; slot++) {
        await _delete(
          File(
            '${directory.path}${Platform.pathSeparator}'
            '${sessionPhotoFileName(sessionId, slot)}',
          ),
        );
      }
      return _indexFromDirectory(directory);
    });
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final Completer<T> completer = Completer<T>();
    _chain = _chain.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<Uint8List> _process(File source) async {
    try {
      if (!await source.exists()) {
        throw const PhotoStorageException(PhotoFailure.unreadable);
      }
      final int length = await source.length();
      if (length <= 0 || length > photoMaximumSourceBytes) {
        throw const PhotoStorageException(PhotoFailure.unreadable);
      }
      final Uint8List sourceBytes = await source.readAsBytes();
      return await Isolate.run<Uint8List>(
        () => processPhotoBytes(sourceBytes).bytes,
      );
    } on PhotoStorageException {
      rethrow;
    } catch (_) {
      throw const PhotoStorageException(PhotoFailure.unreadable);
    }
  }

  Future<void> _createDirectory(Directory directory) async {
    try {
      await directory.create(recursive: true);
    } catch (_) {
      throw const PhotoStorageException(PhotoFailure.writeFailed);
    }
  }

  Future<void> _writeAtomic(File target, Uint8List bytes) async {
    File? temporary;
    try {
      temporary = File('${target.path}.tmp');
      if (await temporary.exists()) {
        await temporary.delete();
      }
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } on FileSystemException catch (error) {
      await _deleteQuietly(temporary);
      if (_isOutOfSpace(error)) {
        throw const PhotoStorageException(PhotoFailure.outOfSpace);
      }
      throw const PhotoStorageException(PhotoFailure.writeFailed);
    } catch (_) {
      await _deleteQuietly(temporary);
      throw const PhotoStorageException(PhotoFailure.writeFailed);
    }
  }

  bool _isOutOfSpace(FileSystemException error) {
    final OSError? osError = error.osError;
    if (osError == null) {
      return false;
    }
    final String message = osError.message.toLowerCase();
    return osError.errorCode == 28 ||
        message.contains('no space') ||
        message.contains('enospc');
  }

  Future<void> _delete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      throw const PhotoStorageException(PhotoFailure.deleteFailed);
    }
  }

  Future<void> _deleteQuietly(File? file) async {
    if (file == null) {
      return;
    }
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // A stale temporary file is removed by the next prune pass.
    }
  }

  Future<PhotoIndex> _indexFromDirectory(
    Directory directory, {
    Set<String>? keep,
  }) async {
    final Set<String> names = <String>{};
    if (!await directory.exists()) {
      return PhotoIndex(directory: directory, fileNames: names);
    }

    try {
      await for (final FileSystemEntity entity in directory.list(
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }
        final String name = entity.path.split(Platform.pathSeparator).last;
        if (name.endsWith('.tmp')) {
          await _delete(entity);
          continue;
        }
        if (keep != null && !keep.contains(name)) {
          await _delete(entity);
          continue;
        }
        if (_exercisePhotoName.hasMatch(name) ||
            _sessionPhotoName.hasMatch(name)) {
          names.add(name);
        }
      }
    } on FileSystemException {
      throw const PhotoStorageException(PhotoFailure.unreadable);
    }
    return PhotoIndex(directory: directory, fileNames: names);
  }

  Set<String> _expectedFileNames({
    required Set<String> exerciseIds,
    required Set<String> sessionIds,
  }) {
    final Set<String> names = <String>{};
    for (final String id in exerciseIds) {
      if (isPhotoEntityIdSafe(id)) {
        names.add(exercisePhotoFileName(id));
      }
    }
    for (final String id in sessionIds) {
      if (!isPhotoEntityIdSafe(id)) {
        continue;
      }
      for (int slot = 0; slot < maxSessionPhotos; slot++) {
        names.add(sessionPhotoFileName(id, slot));
      }
    }
    return names;
  }

  int? _firstFreeSlot(PhotoIndex index, String sessionId) {
    for (int slot = 0; slot < maxSessionPhotos; slot++) {
      if (!index.fileNames.contains(sessionPhotoFileName(sessionId, slot))) {
        return slot;
      }
    }
    return null;
  }
}

/// Resolves the private `photos/` directory next to the data document.
///
/// On Android this is the app's internal files directory; the release manifest
/// disables Android Auto Backup and the data-extraction rules exclude the file
/// domain (`PHO-003`, `DAT-007`).
final Provider<PhotoStorage> photoStorageProvider = Provider<PhotoStorage>((
  Ref ref,
) {
  return FilePhotoStorage(() async {
    final Directory support = await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}photos');
  });
});
