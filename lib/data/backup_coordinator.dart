import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';

import '../app/app_clock.dart';
import '../app/app_info.dart';
import 'app_data_controller.dart';
import 'backup_codec.dart';
import 'backup_gateway.dart';
import 'export_reminder.dart';

/// Coordinates the user-facing export/import flow. JSON work stays in the
/// [BackupCodec] isolate; the data write stays in the controller transaction.
class BackupCoordinator {
  const BackupCoordinator({
    required this.ref,
    required this.gateway,
    required this.codec,
    required this.clock,
  });

  final Ref ref;
  final BackupFileGateway gateway;
  final BackupCodec codec;
  final AppClock clock;

  Future<bool> export(AppData data) async {
    final DateTime exportedAt = clock().toUtc();
    final String contents = await codec.encode(
      data,
      appVersion: appVersion,
      exportedAt: exportedAt,
    );
    final bool saved = await gateway.saveExport(
      fileName: exportFileName(exportedAt),
      contents: contents,
    );
    if (!saved) {
      return false;
    }
    try {
      await ref
          .read(exportReminderControllerProvider.notifier)
          .markExported(exportedAt);
    } catch (_) {
      // The file is already safe. A metadata failure may show the reminder
      // again later, but must not turn a successful export into an error.
    }
    return true;
  }

  /// Opens the picker and validates the file. Returns null when cancelled;
  /// throws [BackupError] for a rejected file.
  Future<BackupDocument?> pickImport() async {
    final String? text = await gateway.pickImport();
    if (text == null) {
      return null;
    }
    return codec.parse(text);
  }

  Future<void> apply(ImportPreview preview) {
    return ref.read(appDataControllerProvider.notifier).applyImport(preview);
  }
}

/// Local date and time keep the suggested name understandable; the file
/// content still stores UTC.
String exportFileName(DateTime exportedAt) {
  final DateTime local = exportedAt.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return 'gym-log-${local.year}-${two(local.month)}-${two(local.day)}'
      '-${two(local.hour)}${two(local.minute)}.json';
}

final Provider<BackupCoordinator> backupCoordinatorProvider =
    Provider<BackupCoordinator>((Ref ref) {
      return BackupCoordinator(
        ref: ref,
        gateway: ref.watch(backupFileGatewayProvider),
        codec: ref.watch(backupCodecProvider),
        clock: ref.watch(appClockProvider),
      );
    });
