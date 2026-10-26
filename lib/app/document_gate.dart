import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../core/l10n/l10n.dart';
import '../core/widgets/app_loading_skeleton.dart';
import '../data/app_data_controller.dart';
import '../features/backup/presentation/backup_recovery_entry.dart';
import 'theme/app_tokens.dart';

/// Binds a screen body to the loaded document.
///
/// Owns loading, the failed-load presentation, retry, and the recovery entry
/// point, so screens only write the success builder. `retry: null` on the
/// provider means a corrupt document never retries itself; recovery replaces
/// it instead.
class DocumentGate extends ConsumerWidget {
  const DocumentGate({required this.builder, this.fallbackTitle, super.key});

  final Widget Function(BuildContext context, AppData data) builder;

  /// Chrome for the loading/failure states of a pushed screen whose success
  /// builder owns its own [Scaffold]. Without it the failure state would have
  /// no [Material] ancestor for the recovery entry.
  final String? fallbackTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppData> value = ref.watch(appDataControllerProvider);
    final Widget content = value.when(
      loading: () =>
          const AppLoadingSkeleton(key: Key('document-loading-skeleton')),
      error: (Object error, StackTrace stack) => const DocumentLoadFailure(),
      data: (AppData data) => builder(context, data),
    );
    final String? title = fallbackTitle;
    if (title == null || value.hasValue) {
      return content;
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: content,
    );
  }
}

/// The uniform failed-load surface: message, retry, and the backup recovery
/// entry. Also used by screens that must keep a custom watcher (Workout).
class DocumentLoadFailure extends ConsumerWidget {
  const DocumentLoadFailure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppTokens.space3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.loadFailed,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTokens.danger),
            ),
            const SizedBox(height: AppTokens.space2),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(appDataControllerProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
            const SizedBox(height: AppTokens.space3),
            const BackupRecoveryEntry(),
          ],
        ),
      ),
    );
  }
}
