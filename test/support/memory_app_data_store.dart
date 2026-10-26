import 'package:gym_log/data/app_data_store.dart';
import 'package:lift_core/lift_core.dart';

/// In-memory store for widget tests. Widget tests run in a fake-async zone and
/// must not wait on real file I/O; persistence through the real JSON store is
/// covered by `test/data/`.
class MemoryAppDataStore implements AppDataStore {
  MemoryAppDataStore([AppData? initial]) : data = initial ?? AppData();

  AppData data;
  int loadCount = 0;
  int saveCount = 0;
  int snapshotCount = 0;
  final List<DataSnapshotInfo> snapshots = <DataSnapshotInfo>[];
  final Map<String, AppData> _snapshotData = <String, AppData>{};

  /// Seeds a restorable snapshot, newest first in [snapshots].
  void seedSnapshot(String fileName, AppData snapshot, {DateTime? savedAt}) {
    snapshots.add(
      DataSnapshotInfo(
        fileName: fileName,
        savedAt: savedAt ?? DateTime.now().toUtc(),
      ),
    );
    _snapshotData[fileName] = snapshot;
  }

  @override
  Future<AppData> load() async {
    loadCount += 1;
    return data;
  }

  @override
  Future<void> save(AppData next) async {
    data = next;
    saveCount += 1;
  }

  @override
  Future<void> snapshot() async {
    snapshotCount += 1;
    seedSnapshot(
      'gym_log_data-memory-${snapshotCount.toString().padLeft(3, '0')}.json',
      data,
    );
  }

  @override
  Future<List<DataSnapshotInfo>> listSnapshots() async {
    return List<DataSnapshotInfo>.of(snapshots)..sort(
      (DataSnapshotInfo a, DataSnapshotInfo b) =>
          b.savedAt.compareTo(a.savedAt),
    );
  }

  @override
  Future<AppData> loadSnapshot(String fileName) async {
    final AppData? snapshot = _snapshotData[fileName];
    if (snapshot == null) {
      throw const DataStoreException('injected missing snapshot');
    }
    return snapshot;
  }
}
