import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';

import 'app_storage.dart';

/// Metadata for one pre-Replace data snapshot in the private backup folder.
class DataSnapshotInfo {
  const DataSnapshotInfo({required this.fileName, required this.savedAt});

  final String fileName;
  final DateTime savedAt;
}

/// Persistence boundary for exercises, programs, days, and plan items.
abstract interface class AppDataStore {
  Future<AppData> load();

  Future<void> save(AppData data);

  /// Copies the current document into the private backup folder before a
  /// Replace import. A missing document (fresh install) needs no snapshot.
  Future<void> snapshot();

  /// Lists the restorable data snapshots, newest first.
  Future<List<DataSnapshotInfo>> listSnapshots();

  /// Loads one data snapshot by its file name from [listSnapshots].
  Future<AppData> loadSnapshot(String fileName);
}

/// Raised when the on-device document cannot be read or written.
class DataStoreException implements Exception {
  const DataStoreException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'DataStoreException: $message';
}

/// Atomic, versioned JSON document in app-private storage.
///
/// The file is written to a sibling temporary file, flushed, and renamed, so a
/// crash cannot leave a half-written document. Saves are serialized to avoid
/// two snapshots racing. This is the interim store for the exercise/program
/// milestone; the M1 Drift migration must import this document instead of
/// discarding it.
class JsonAppDataStore implements AppDataStore {
  JsonAppDataStore(this._file, {DateTime Function()? snapshotClock})
    : _snapshotClock = snapshotClock ?? DateTime.now;

  final Future<File> _file;
  final DateTime Function() _snapshotClock;
  Future<void> _writeChain = Future<void>.value();

  @override
  Future<AppData> load() async {
    final File file = await _file;
    if (!await file.exists()) {
      return AppData();
    }
    try {
      final String contents = await file.readAsString();
      if (contents.trim().isEmpty) {
        throw const FormatException('Data file is empty');
      }
      final Object? decoded = jsonDecode(contents);
      if (decoded is! Map) {
        throw const FormatException('Data file root must be an object');
      }
      return AppData.fromJson(decoded.cast<String, Object?>());
    } on DataStoreException {
      rethrow;
    } catch (error) {
      throw DataStoreException('Could not read stored data', error);
    }
  }

  @override
  Future<void> save(AppData data) {
    final Completer<void> completer = Completer<void>();
    _writeChain = _writeChain.then((_) async {
      try {
        await _write(data);
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _write(AppData data) async {
    final File file = await _file;
    await file.parent.create(recursive: true);
    final File temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(data.toJson()), flush: true);
    await temporary.rename(file.path);
  }

  /// Copies the live document to `backups/` before Replace writes.
  ///
  /// The copy is the recovery point for an import. It is written before the
  /// in-memory state changes, so a snapshot failure aborts the Replace without
  /// touching data. The last three snapshots are retained (`DAT-003`).
  @override
  Future<void> snapshot() async {
    final File file = await _file;
    if (!await file.exists()) {
      return;
    }
    final Directory backups = _backupsDirectory(file);
    await backups.create(recursive: true);
    final String stamp = _snapshotClock().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    final File target = File(
      '${backups.path}${Platform.pathSeparator}gym_log_data-$stamp.json',
    );
    final List<int> bytes = await file.readAsBytes();
    final File temporary = File('${target.path}.tmp');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } catch (_) {
      if (await temporary.exists()) {
        await temporary.delete();
      }
      rethrow;
    }
    final List<File> snapshots = await backups
        .list()
        .where(
          (FileSystemEntity entity) =>
              entity is File &&
              entity.uri.pathSegments.last.startsWith('gym_log_data-') &&
              entity.path.endsWith('.json') &&
              entity.path != target.path,
        )
        .cast<File>()
        .toList();
    snapshots.sort((File a, File b) => a.path.compareTo(b.path));
    // Keep the just-written recovery point plus the two newest older ones.
    // Excluding `target` prevents a backwards clock from deleting the snapshot
    // this Replace just produced.
    while (snapshots.length > 2) {
      await snapshots.removeAt(0).delete();
    }
  }

  @override
  Future<List<DataSnapshotInfo>> listSnapshots() async {
    final Directory backups = _backupsDirectory(await _file);
    if (!await backups.exists()) {
      return const <DataSnapshotInfo>[];
    }
    final List<DataSnapshotInfo> snapshots = <DataSnapshotInfo>[];
    await for (final FileSystemEntity entity in backups.list()) {
      if (entity is! File) {
        continue;
      }
      final String fileName = entity.uri.pathSegments.last;
      if (!_isSnapshotFileName(fileName)) {
        continue;
      }
      try {
        final FileStat stat = await entity.stat();
        snapshots.add(
          DataSnapshotInfo(fileName: fileName, savedAt: stat.modified),
        );
      } on FileSystemException {
        // A file that vanished between listing and stat is not restorable.
      }
    }
    snapshots.sort((DataSnapshotInfo a, DataSnapshotInfo b) {
      final int byDate = b.savedAt.compareTo(a.savedAt);
      return byDate != 0 ? byDate : b.fileName.compareTo(a.fileName);
    });
    return snapshots;
  }

  @override
  Future<AppData> loadSnapshot(String fileName) async {
    if (!_isSnapshotFileName(fileName)) {
      throw const DataStoreException('Could not read the data snapshot');
    }
    final Directory backups = _backupsDirectory(await _file);
    final File snapshot = File(
      '${backups.path}${Platform.pathSeparator}$fileName',
    );
    try {
      final String contents = await snapshot.readAsString();
      final Object? decoded = jsonDecode(contents);
      if (decoded is! Map) {
        throw const FormatException('Snapshot root must be an object');
      }
      return AppData.fromJson(decoded.cast<String, Object?>());
    } catch (error) {
      throw DataStoreException('Could not read the data snapshot', error);
    }
  }

  Directory _backupsDirectory(File file) {
    return Directory('${file.parent.path}${Platform.pathSeparator}backups');
  }

  static final RegExp _snapshotName = RegExp(r'^gym_log_data-.+\.json$');

  bool _isSnapshotFileName(String fileName) {
    if (fileName.contains('/') ||
        fileName.contains(r'\') ||
        fileName.contains('..')) {
      return false;
    }
    return _snapshotName.hasMatch(fileName);
  }
}

/// Resolves the app-private data document. Tests override this provider.
final Provider<Future<File>> appDataFileProvider = Provider<Future<File>>(
  (Ref ref) => appSupportFile(ref, 'gym_log_data.json'),
);
