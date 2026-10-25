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
import '../../../data/backup_coordinator.dart';
import '../../../data/photo_index_controller.dart';
import 'backup_error_text.dart';

/// Export and import controls in Settings (`IO-001`–`IO-003`, `IO-006`).
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({required this.data, super.key});

  final AppData data;

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
      final bool saved = await ref
          .read(backupCoordinatorProvider)
          .export(widget.data);
      if (!mounted) {
        return;
      }
      if (saved) {
        _showSnack(context.l10n.exportSaved);
      }
    } on PlatformException {
      if (mounted) {
        _showSnack(context.l10n.exportFailed);
      }
    } catch (_) {
      if (mounted) {
        _showSnack(context.l10n.exportFailed);
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
      final BackupCoordinator coordinator = ref.read(backupCoordinatorProvider);
      final BackupDocument? document = await coordinator.pickImport();
      if (document == null || !mounted) {
        return;
      }
      final AppData current = ref.read(appDataControllerProvider).requireValue;
      final ImportPreview mergePreview = previewImport(
        current: current,
        document: document,
        mode: ImportMode.merge,
      );
      final ImportPreview replacePreview = previewImport(
        current: current,
        document: document,
        mode: ImportMode.replace,
      );
      setState(() => _busy = false);
      final ImportPreview? preview = await showDialog<ImportPreview>(
        context: context,
        builder: (BuildContext dialogContext) => _ImportPreviewDialog(
          mergePreview: mergePreview,
          replacePreview: replacePreview,
        ),
      );
      if (preview == null || !mounted) {
        return;
      }
      setState(() => _busy = true);
      await coordinator.apply(preview);
      ref.invalidate(photoIndexProvider);
      if (mounted) {
        _showSnack(context.l10n.importCompleted);
      }
    } on BackupError catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        await _showError(backupErrorText(context.l10n, error));
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        await _showError(switch (error.code) {
          'too_large' => context.l10n.importErrorTooLarge,
          'unavailable' => context.l10n.importErrorPickerUnavailable,
          _ => context.l10n.importErrorUnreadable,
        });
      }
    } on ImportPreviewMismatch {
      if (mounted) {
        setState(() => _busy = false);
        await _showError(context.l10n.importDataChanged);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        await _showError(context.l10n.importFailed);
      }
    } finally {
      if (mounted && _busy) {
        setState(() => _busy = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showError(String message) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.importErrorTitle),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
      ],
    );
  }
}

class _ImportPreviewDialog extends StatefulWidget {
  const _ImportPreviewDialog({
    required this.mergePreview,
    required this.replacePreview,
  });

  final ImportPreview mergePreview;
  final ImportPreview replacePreview;

  @override
  State<_ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<_ImportPreviewDialog> {
  ImportMode _mode = ImportMode.merge;

  ImportPreview get _preview =>
      _mode == ImportMode.merge ? widget.mergePreview : widget.replacePreview;

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
                        )
                      : l10n.importSummaryReplace(
                          summary.added.exercises,
                          summary.added.programs,
                          summary.added.sessions,
                          summary.added.sets,
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
          onPressed: canImport
              ? () => Navigator.of(context).pop(preview)
              : null,
          child: Text(l10n.importConfirm),
        ),
      ],
    );
  }
}
