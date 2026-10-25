import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/photo_storage.dart';

/// Localized, path-free failure copy for photo operations.
String photoFailureMessage(BuildContext context, PhotoStorageException error) {
  final AppLocalizations l10n = context.l10n;
  final String message = switch (error.failure) {
    PhotoFailure.unreadable => l10n.photoPickFailed,
    PhotoFailure.outOfSpace => l10n.photoStorageFull,
    PhotoFailure.writeFailed => l10n.photoSaveFailed,
    PhotoFailure.deleteFailed => l10n.photoDeleteFailed,
    PhotoFailure.limitReached => l10n.photoLimitReached(maxSessionPhotos),
  };
  return context.digits(message);
}
