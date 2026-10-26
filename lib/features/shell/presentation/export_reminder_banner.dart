import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_clock.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/action_runner.dart';
import '../../../data/app_data_controller.dart';
import '../../../data/backup_flow.dart';
import '../../../data/export_reminder.dart';

/// In-app 30-day export reminder (`SET-004`). It never posts a notification
/// and is hidden until training data exists.
class ExportReminderBanner extends ConsumerStatefulWidget {
  const ExportReminderBanner({super.key});

  @override
  ConsumerState<ExportReminderBanner> createState() =>
      _ExportReminderBannerState();
}

class _ExportReminderBannerState extends ConsumerState<ExportReminderBanner> {
  bool _busy = false;

  Future<void> _export(AppData data) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final bool saved = await ref.read(backupFlowProvider).export(data);
      if (!mounted) {
        return;
      }
      if (saved) {
        _showSnack(context.l10n.exportSaved);
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

  Future<void> _snooze(DateTime now) async {
    await runDataAction(
      context,
      () => ref.read(exportReminderControllerProvider.notifier).snooze(now),
    );
  }

  Future<void> _dismiss(DateTime baseline) async {
    await runDataAction(
      context,
      () =>
          ref.read(exportReminderControllerProvider.notifier).dismiss(baseline),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AppData? data = ref.watch(appDataControllerProvider).asData?.value;
    final ExportReminderState? reminder = ref
        .watch(exportReminderControllerProvider)
        .asData
        ?.value;
    if (data == null || reminder == null) {
      return const SizedBox.shrink();
    }
    final DateTime now = ref.watch(appClockProvider)();
    if (!shouldShowExportReminder(data: data, state: reminder, now: now)) {
      return const SizedBox.shrink();
    }
    final DateTime? baseline =
        reminder.lastExportedAt ?? earliestDataTimestamp(data);
    if (baseline == null) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l10n = context.l10n;

    return Padding(
      key: const Key('export-reminder-banner'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTokens.space2,
        AppTokens.space1,
        AppTokens.space2,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTokens.surface2,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppTokens.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsetsDirectional.only(top: 2),
                    child: Icon(
                      Icons.backup_outlined,
                      color: AppTokens.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space1),
                  Expanded(
                    child: Text(
                      l10n.exportReminderTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    key: const Key('export-reminder-dismiss'),
                    tooltip: l10n.exportReminderDismiss,
                    onPressed: _busy ? null : () => _dismiss(baseline),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppTokens.space3,
                  end: AppTokens.space3,
                ),
                child: Text(
                  context.digits(l10n.exportReminderBody),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: AppTokens.space1),
              Wrap(
                spacing: AppTokens.space1,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  FilledButton(
                    key: const Key('export-reminder-export'),
                    onPressed: _busy ? null : () => _export(data),
                    child: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.exportReminderExport),
                  ),
                  TextButton(
                    key: const Key('export-reminder-later'),
                    onPressed: _busy ? null : () => _snooze(now),
                    child: Text(l10n.exportReminderLater),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
