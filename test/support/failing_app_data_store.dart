import 'package:gym_log/data/app_data_store.dart';
import 'package:lift_core/lift_core.dart';

/// Wraps a real store and can inject snapshot or save failures.
class FailingAppDataStore implements AppDataStore {
  FailingAppDataStore(
    this.inner, {
    this.failSnapshot = false,
    this.failSave = false,
    this.failLoadSnapshot = false,
  });

  final AppDataStore inner;
  final bool failSnapshot;
  final bool failSave;
  final bool failLoadSnapshot;
  int snapshotCount = 0;
  int saveAttempts = 0;

  @override
  Future<AppData> load() => inner.load();

  @override
  Future<void> snapshot() async {
    snapshotCount += 1;
    if (failSnapshot) {
      throw const DataStoreException('injected snapshot failure');
    }
    await inner.snapshot();
  }

  @override
  Future<void> save(AppData data) async {
    saveAttempts += 1;
    if (failSave) {
      throw const DataStoreException('injected save failure');
    }
    await inner.save(data);
  }

  @override
  Future<List<DataSnapshotInfo>> listSnapshots() => inner.listSnapshots();

  @override
  Future<AppData> loadSnapshot(String fileName) async {
    if (failLoadSnapshot) {
      throw const DataStoreException('injected snapshot read failure');
    }
    return inner.loadSnapshot(fileName);
  }
}

/// Document that cannot be read, for the corrupt/newer-schema recovery path.
class UnreadableAppDataStore implements AppDataStore {
  UnreadableAppDataStore({this.failSnapshot = false});

  final bool failSnapshot;
  AppData? saved;
  int snapshotCount = 0;
  int saveAttempts = 0;

  @override
  Future<AppData> load() async {
    throw const DataStoreException('injected unreadable document');
  }

  @override
  Future<void> snapshot() async {
    snapshotCount += 1;
    if (failSnapshot) {
      throw const DataStoreException('injected snapshot failure');
    }
  }

  @override
  Future<void> save(AppData data) async {
    saveAttempts += 1;
    saved = data;
  }

  @override
  Future<List<DataSnapshotInfo>> listSnapshots() async =>
      const <DataSnapshotInfo>[];

  @override
  Future<AppData> loadSnapshot(String fileName) async {
    throw const DataStoreException('injected missing snapshot');
  }
}
