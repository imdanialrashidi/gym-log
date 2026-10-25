import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:path_provider/path_provider.dart';

/// Persistence boundary for exercises, programs, days, and plan items.
abstract interface class AppDataStore {
  Future<AppData> load();

  Future<void> save(AppData data);

  /// Copies the current document into the private backup folder before a
  /// Replace import. A missing document (fresh install) needs no snapshot.
  Future<void> snapshot();
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
    final Directory backups = Directory(
      '${file.parent.path}${Platform.pathSeparator}backups',
    );
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
}

/// Resolves the app-private data document. Tests override this provider.
final Provider<Future<File>> appDataFileProvider = Provider<Future<File>>((_) {
  return _defaultDataFile();
});

Future<File> _defaultDataFile() async {
  final Directory directory = await getApplicationSupportDirectory();
  return File('${directory.path}${Platform.pathSeparator}gym_log_data.json');
}
