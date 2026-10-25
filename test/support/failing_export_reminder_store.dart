import 'package:gym_log/data/export_reminder.dart';

/// Reminder store with an injected save failure for rollback/banner tests.
class FailingExportReminderStore implements ExportReminderStore {
  FailingExportReminderStore(this.state);

  ExportReminderState state;
  bool failSave = true;
  int saveAttempts = 0;

  @override
  Future<ExportReminderState> load() async => state;

  @override
  Future<void> save(ExportReminderState next) async {
    saveAttempts += 1;
    if (failSave) {
      throw StateError('injected reminder save failure');
    }
    state = next;
  }
}
