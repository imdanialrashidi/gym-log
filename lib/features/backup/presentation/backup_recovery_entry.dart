import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/backup_flow.dart';
import 'backup_error_text.dart';
import 'backup_feedback.dart';

/// Recovery entry point shown when the on-device document cannot be read.
///
/// The backup must parse before anything is written; the controller snapshots
/// the unreadable file before the replacement document is saved.
class BackupRecoveryEntry extends ConsumerStatefulWidget {
  const BackupRecoveryEntry({super.key});

  @override
  ConsumerState<BackupRecoveryEntry> createState() =>
      _BackupRecoveryEntryState();
}

class _BackupRecoveryEntryState extends ConsumerState<BackupRecoveryEntry> {
  bool _busy = false;

  Future<void> _restore() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final BackupFlow flow = ref.read(backupFlowProvider);
      final ImportDraft? draft = await flow.pickRecovery();
      if (draft == null || !mounted) {
        return;
      }
      // Match the normal import flow: no spinner behind the modal while the
      // user decides.
      setState(() => _busy = false);
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) =>
            _RestoreBackupDialog(preview: draft.replacePreview),
      );
      if (confirmed != true || !mounted) {
        return;
      }
      setState(() => _busy = true);
      await flow.commit(draft, ImportMode.replace);
      if (mounted) {
        showBackupSnack(context, context.l10n.importCompleted);
      }
    } on ImportFailure catch (failure) {
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return ListTile(
      key: const Key('restore-from-backup'),
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppTokens.space1,
      ),
      enabled: !_busy,
      leading: const Icon(Icons.restore_page_outlined),
      title: Text(l10n.restoreFromBackup),
      subtitle: Text(l10n.restoreBackupHint),
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _restore,
    );
  }
}

class _RestoreBackupDialog extends StatelessWidget {
  const _RestoreBackupDialog({required this.preview});

  final ImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final MergeSummary summary = preview.summary;
    return AlertDialog(
      key: const Key('restore-preview-dialog'),
      title: Text(l10n.restoreFromBackup),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.restoreBackupHint),
            const SizedBox(height: AppTokens.space2),
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
            const SizedBox(height: AppTokens.space1),
            Text(
              context.digits(
                l10n.importSummaryReplace(
                  summary.added.exercises,
                  summary.added.programs,
                  summary.added.sessions,
                  summary.added.sets,
                  summary.added.bodyWeights,
                ),
              ),
              key: const Key('restore-summary'),
            ),
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
          key: const Key('restore-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('restore-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.importConfirm),
        ),
      ],
    );
  }
}
