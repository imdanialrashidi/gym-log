import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';

/// Undo window required by `LOG-006`: at least five seconds. Six seconds leaves
/// room for the snackbar animation without shrinking the usable window.
const Duration undoWindow = Duration(seconds: 6);

/// Shows a snackbar with Undo. [onUndo] runs when the action is tapped; a
/// failure is surfaced instead of being silently swallowed.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showUndoSnackBar(
  BuildContext context, {
  required String message,
  required Future<void> Function() onUndo,
}) {
  final AppLocalizations l10n = context.l10n;
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String failure = l10n.saveFailed;
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      duration: undoWindow,
      content: Text(message),
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: () => unawaited(
          onUndo().catchError((Object _) {
            messenger.showSnackBar(SnackBar(content: Text(failure)));
          }),
        ),
      ),
    ),
  );
}
