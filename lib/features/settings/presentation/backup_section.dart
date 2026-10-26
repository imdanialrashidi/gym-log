import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/app_data_controller.dart';
import '../../../data/app_data_store.dart';
import '../../../data/backup_flow.dart';
import '../../../data/photo_index_controller.dart';
import '../../backup/presentation/backup_error_text.dart';
import '../../backup/presentation/backup_feedback.dart';

/// Export and import controls in Settings (`IO-001`–`IO-003`, `IO-006`).
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({required this.data, super.key, this.showHeading = true});

  final AppData data;
  final bool showHeading;

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final bool saved = await ref.read(backupFlowProvider).export(widget.data);
      if (!mounted) {
        return;
      }
      if (saved) {
        showBackupSnack(context, context.l10n.exportSaved);
      }
    } on PlatformException {
      if (mounted) {
        showBackupSnack(context, context.l10n.exportFailed);
      }
    } catch (_) {
      if (mounted) {
        showBackupSnack(context, context.l10n.exportFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _import() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final BackupFlow flow = ref.read(backupFlowProvider);
      final ImportDraft? draft = await flow.pickImport();
      if (draft == null || !mounted) {
        return;
      }
      setState(() => _busy = false);
      final ImportMode? mode = await showDialog<ImportMode>(
        context: context,
        builder: (BuildContext dialogContext) =>
            _ImportPreviewDialog(draft: draft),
      );
      if (mode == null || !mounted) {
        return;
      }
      setState(() => _busy = true);
      await flow.commit(draft, mode);
      if (mounted) {
        showBackupSnack(context, context.l10n.importCompleted);
      }
    } on ImportFailure catch (failure) {
      if (mounted) {
        // Stop the inline spinner before the modal error, or pumpAndSettle
        // never settles behind an animating indicator.
        setState(() => _busy = false);
        await showImportFailureDialog(
          context,
          importFailureText(context.l10n, failure),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _restoreSnapshot(DataSnapshotInfo info) async {
    if (_busy) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _RestoreSnapshotDialog(info: info),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .restoreSnapshot(info.fileName);
      ref.invalidate(dataSnapshotsProvider);
      ref.invalidate(photoIndexProvider);
      if (mounted) {
        showBackupSnack(context, context.l10n.importCompleted);
      }
    } catch (_) {
      if (mounted) {
        await showImportFailureDialog(
          context,
          context.l10n.restoreBackupFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<DataSnapshotInfo> snapshots =
        ref.watch(dataSnapshotsProvider).value ?? const <DataSnapshotInfo>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.showHeading)
          Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space1),
            child: Text(
              l10n.backupSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        // DAT-007/ADR-0007: Android Auto Backup is a manifest/build-time
        // policy. This build enforces it off, so the control communicates the
        // effective state instead of pretending a runtime switch can change it.
        SwitchListTile(
          key: const Key('android-backup-toggle'),
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppTokens.space1,
          ),
          title: Text(l10n.androidBackupTitle),
          subtitle: Text(l10n.androidBackupHint),
          value: false,
          onChanged: null,
        ),
        ListTile(
          key: const Key('export-data'),
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppTokens.space1,
          ),
          enabled: !_busy,
          leading: const Icon(Icons.upload_file_outlined),
          title: Text(l10n.exportData),
          subtitle: Text(l10n.exportDataHint),
          trailing: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _export,
        ),
        ListTile(
          key: const Key('import-data'),
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppTokens.space1,
          ),
          enabled: !_busy,
          leading: const Icon(Icons.download_outlined),
          title: Text(l10n.importData),
          subtitle: Text(l10n.importDataHint),
          onTap: _import,
        ),
        if (snapshots.isNotEmpty) ...<Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTokens.space1,
              AppTokens.space2,
              AppTokens.space1,
              AppTokens.space1,
            ),
            child: Text(
              l10n.previousDataVersions,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final DataSnapshotInfo info in snapshots)
            ListTile(
              key: Key('data-snapshot-${info.fileName}'),
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppTokens.space1,
              ),
              enabled: !_busy,
              leading: const Icon(Icons.history),
              title: Text(
                context.digits(
                  context.formatDate(
                    info.savedAt,
                    style: AppDateStyle.dateTime,
                  ),
                ),
              ),
              subtitle: Text(l10n.restoreSnapshotBody),
              onTap: () => _restoreSnapshot(info),
            ),
        ],
      ],
    );
  }
}

class _RestoreSnapshotDialog extends StatelessWidget {
  const _RestoreSnapshotDialog({required this.info});

  final DataSnapshotInfo info;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return AlertDialog(
      key: const Key('restore-snapshot-dialog'),
      title: Text(l10n.restoreSnapshotTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              context.digits(
                context.formatDate(info.savedAt, style: AppDateStyle.dateTime),
              ),
            ),
            const SizedBox(height: AppTokens.space1),
            Text(l10n.restoreSnapshotBody),
            const SizedBox(height: AppTokens.space1),
            Text(
              l10n.restoreSnapshotPhotosWarning,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('restore-snapshot-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('restore-snapshot-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.importConfirm),
        ),
      ],
    );
  }
}

class _ImportPreviewDialog extends StatefulWidget {
  const _ImportPreviewDialog({required this.draft});

  final ImportDraft draft;

  @override
  State<_ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<_ImportPreviewDialog> {
  ImportMode _mode = ImportMode.merge;

  ImportPreview get _preview => widget.draft.previewFor(_mode);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ImportPreview preview = _preview;
    final MergeSummary summary = preview.summary;
    final bool hasAdditions =
        summary.added.exercises > 0 ||
        summary.added.programs > 0 ||
        summary.added.sessions > 0;
    final bool showCounts =
        _mode == ImportMode.replace ||
        summary.added.topLevelRecords > 0 ||
        summary.added.sets > 0;
    final bool canImport =
        _mode == ImportMode.replace ||
        hasAdditions ||
        summary.added.sets > 0 ||
        summary.settingsChanged;

    return AlertDialog(
      key: const Key('import-preview-dialog'),
      title: Text(l10n.importPreviewTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              context.digits(
                l10n.importSource(
                  preview.document.appVersion,
                  context.formatDate(
                    preview.document.exportedAt,
                    style: AppDateStyle.dateTime,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              l10n.importModeLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTokens.space1),
            SegmentedButton<ImportMode>(
              key: const Key('import-mode'),
              segments: <ButtonSegment<ImportMode>>[
                ButtonSegment<ImportMode>(
                  value: ImportMode.merge,
                  label: Text(l10n.importModeMerge),
                ),
                ButtonSegment<ImportMode>(
                  value: ImportMode.replace,
                  label: Text(l10n.importModeReplace),
                ),
              ],
              selected: <ImportMode>{_mode},
              onSelectionChanged: (Set<ImportMode> selection) {
                setState(() => _mode = selection.single);
              },
            ),
            const SizedBox(height: AppTokens.space1),
            Text(
              _mode == ImportMode.merge
                  ? l10n.importMergeHint
                  : l10n.importReplaceHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppTokens.space2),
            if (showCounts)
              Text(
                context.digits(
                  _mode == ImportMode.merge
                      ? l10n.importSummaryAdd(
                          summary.added.exercises,
                          summary.added.programs,
                          summary.added.sessions,
                          summary.added.sets,
                          summary.added.bodyWeights,
                        )
                      : l10n.importSummaryReplace(
                          summary.added.exercises,
                          summary.added.programs,
                          summary.added.sessions,
                          summary.added.sets,
                          summary.added.bodyWeights,
                        ),
                ),
                key: const Key('import-summary'),
              ),
            if (_mode == ImportMode.merge && summary.conflicts > 0) ...<Widget>[
              const SizedBox(height: AppTokens.space1),
              Text(
                context.digits(l10n.importSummaryConflicts(summary.conflicts)),
              ),
            ],
            if (_mode == ImportMode.merge &&
                summary.unchangedRecords > 0) ...<Widget>[
              const SizedBox(height: AppTokens.space1),
              Text(
                context.digits(
                  l10n.importSummaryUnchanged(summary.unchangedRecords),
                ),
              ),
            ],
            if (_mode == ImportMode.merge && summary.settingsChanged) ...[
              const SizedBox(height: AppTokens.space1),
              Text(l10n.importSettingsRestored),
            ],
            if (!canImport) ...<Widget>[
              const SizedBox(height: AppTokens.space1),
              Text(l10n.importNothingToAdd),
            ],
            const SizedBox(height: AppTokens.space2),
            Text(
              l10n.importPhotosExcluded,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('import-confirm'),
          onPressed: canImport ? () => Navigator.of(context).pop(_mode) : null,
          child: Text(l10n.importConfirm),
        ),
      ],
    );
  }
}
