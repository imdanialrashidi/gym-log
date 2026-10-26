import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';

/// Shows a one-line import/export outcome. Kept next to the backup flow so the
/// success and failure surfaces stay consistent across screens.
void showBackupSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Shows the localized reason an import was refused. The caller supplies the
/// message so validation details never render raw.
Future<void> showImportFailureDialog(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.importErrorTitle),
      content: SingleChildScrollView(child: Text(message)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dialogContext.l10n.close),
        ),
      ],
    ),
  );
}
