import 'package:gym_log/data/export_reminder.dart';

class MemoryExportReminderStore implements ExportReminderStore {
  MemoryExportReminderStore([ExportReminderState? initial])
    : state = initial ?? const ExportReminderState();

  ExportReminderState state;
  int saveCount = 0;

  @override
  Future<ExportReminderState> load() async => state;

  @override
  Future<void> save(ExportReminderState next) async {
    state = next;
    saveCount += 1;
  }
}
