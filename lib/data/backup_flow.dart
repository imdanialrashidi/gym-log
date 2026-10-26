import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';

import '../app/app_clock.dart';
import '../app/app_info.dart';
import 'app_data_controller.dart';
import 'backup_codec.dart';
import 'backup_gateway.dart';
import 'export_reminder.dart';
import 'photo_index_controller.dart';

/// Where an import is being run from. Recovery replaces an unreadable document
/// and therefore previews against an empty one.
enum ImportIntent { normal, recovery }

/// A parsed backup plus both dry runs, ready for one confirm/commit decision.
class ImportDraft {
  const ImportDraft({
    required this.intent,
    required this.document,
    required this.mergePreview,
    required this.replacePreview,
  });

  final ImportIntent intent;
  final BackupDocument document;
  final ImportPreview mergePreview;
  final ImportPreview replacePreview;

  bool get isRecovery => intent == ImportIntent.recovery;

  ImportPreview previewFor(ImportMode mode) {
    return mode == ImportMode.merge ? mergePreview : replacePreview;
  }
}

/// The kinds of failure the import UI must present.
enum ImportFailureKind {
  rejected,
  tooLarge,
  pickerUnavailable,
  unreadable,
  dataChanged,
  restoreFailed,
  failed,
}

/// One failure type for the whole import flow, so the screen has one catch.
class ImportFailure implements Exception {
  const ImportFailure(this.kind, {this.error});

  final ImportFailureKind kind;

  /// The original validation error for [ImportFailureKind.rejected], used to
  /// build the field-specific message.
  final BackupError? error;

  @override
  String toString() => 'ImportFailure(${kind.name})';
}

/// Runs the user-facing export/import flow.
///
/// This module owns what an import *means*: pick, parse, dry-run both modes,
/// hand one preview out, commit the chosen mode, and refresh derived state.
/// The screen renders the preview and the outcome; it does not re-derive the
/// protocol or map storage errors itself.
class BackupFlow {
  const BackupFlow({
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

  /// Opens the picker and dry-runs both modes. Returns null when cancelled;
  /// throws [ImportFailure] for a file that cannot be used.
  Future<ImportDraft?> pickImport() => _pick(ImportIntent.normal);

  /// Opens the picker for the unreadable-document recovery path.
  Future<ImportDraft?> pickRecovery() => _pick(ImportIntent.recovery);

  Future<ImportDraft?> _pick(ImportIntent intent) async {
    final String? text;
    try {
      text = await gateway.pickImport();
    } on PlatformException catch (error) {
      throw _platformFailure(error);
    } catch (_) {
      throw const ImportFailure(ImportFailureKind.pickerUnavailable);
    }
    if (text == null) {
      return null;
    }

    final BackupDocument document;
    try {
      document = await codec.parse(text);
    } on BackupError catch (error) {
      throw ImportFailure(ImportFailureKind.rejected, error: error);
    } catch (_) {
      throw const ImportFailure(ImportFailureKind.unreadable);
    }

    final AppData current = intent == ImportIntent.recovery
        ? AppData()
        : ref.read(appDataControllerProvider).value ?? AppData();
    try {
      return ImportDraft(
        intent: intent,
        document: document,
        mergePreview: previewImport(
          current: current,
          document: document,
          mode: ImportMode.merge,
        ),
        replacePreview: previewImport(
          current: current,
          document: document,
          mode: ImportMode.replace,
        ),
      );
    } catch (_) {
      throw const ImportFailure(ImportFailureKind.failed);
    }
  }

  /// Commits [draft] in [mode] and refreshes the snapshot list and photo index.
  ///
  /// The preview is re-planned by the controller against current data; if the
  /// data changed, this throws [ImportFailureKind.dataChanged] without writing.
  Future<void> commit(ImportDraft draft, ImportMode mode) async {
    final AppDataController controller = ref.read(
      appDataControllerProvider.notifier,
    );
    try {
      if (draft.isRecovery) {
        await controller.restoreFromBackup(draft.replacePreview);
      } else {
        await controller.applyImport(draft.previewFor(mode));
      }
    } on ImportPreviewMismatch {
      throw const ImportFailure(ImportFailureKind.dataChanged);
    } on BackupError catch (error) {
      throw ImportFailure(ImportFailureKind.rejected, error: error);
    } catch (_) {
      throw ImportFailure(
        draft.isRecovery
            ? ImportFailureKind.restoreFailed
            : ImportFailureKind.failed,
      );
    }
    ref.invalidate(dataSnapshotsProvider);
    ref.invalidate(photoIndexProvider);
  }

  ImportFailure _platformFailure(PlatformException error) {
    return switch (error.code) {
      'too_large' => const ImportFailure(ImportFailureKind.tooLarge),
      'unavailable' => const ImportFailure(ImportFailureKind.pickerUnavailable),
      _ => const ImportFailure(ImportFailureKind.unreadable),
    };
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

final Provider<BackupFlow> backupFlowProvider = Provider<BackupFlow>((Ref ref) {
  return BackupFlow(
    ref: ref,
    gateway: ref.watch(backupFileGatewayProvider),
    codec: ref.watch(backupCodecProvider),
    clock: ref.watch(appClockProvider),
  );
});
