import 'package:gym_log/data/rest_timer_store.dart';

/// In-memory rest-timer marker for widget tests.
class MemoryRestTimerStore implements RestTimerStore {
  MemoryRestTimerStore([this.value]);

  PersistedRestTimer? value;
  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<PersistedRestTimer?> load() async => value;

  @override
  Future<void> save(PersistedRestTimer timer) async {
    value = timer;
    saveCount += 1;
  }

  @override
  Future<void> clear() async {
    value = null;
    clearCount += 1;
  }
}
