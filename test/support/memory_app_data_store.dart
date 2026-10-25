import 'package:gym_log/data/app_data_store.dart';
import 'package:lift_core/lift_core.dart';

/// In-memory store for widget tests. Widget tests run in a fake-async zone and
/// must not wait on real file I/O; persistence through the real JSON store is
/// covered by `test/data/`.
class MemoryAppDataStore implements AppDataStore {
  MemoryAppDataStore([AppData? initial]) : data = initial ?? AppData();

  AppData data;
  int saveCount = 0;
  int snapshotCount = 0;

  @override
  Future<AppData> load() async => data;

  @override
  Future<void> save(AppData next) async {
    data = next;
    saveCount += 1;
  }

  @override
  Future<void> snapshot() async {
    snapshotCount += 1;
  }
}
