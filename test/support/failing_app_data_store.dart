import 'package:gym_log/data/app_data_store.dart';
import 'package:lift_core/lift_core.dart';

/// Wraps a real store and can inject snapshot or save failures.
class FailingAppDataStore implements AppDataStore {
  FailingAppDataStore(
    this.inner, {
    this.failSnapshot = false,
    this.failSave = false,
  });

  final AppDataStore inner;
  final bool failSnapshot;
  final bool failSave;
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
}
