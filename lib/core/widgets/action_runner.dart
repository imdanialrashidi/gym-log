import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';

/// Runs one document mutation and presents the single failure mode every write
/// shares: a localized "could not save" message.
///
/// Returns false when the mutation failed, so a caller can skip the success
/// side effects (undo affordance, navigation, invalidation). The controller has
/// already rolled its in-memory state back by then.
Future<bool> runDataAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
    }
    return false;
  }
}
