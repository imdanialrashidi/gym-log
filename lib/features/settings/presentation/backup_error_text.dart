import 'package:lift_core/lift_core.dart';

import '../../../core/l10n/l10n.dart';

/// Localized, user-facing copy for a rejected import. Field paths and IDs are
/// data identifiers, never note text.
String backupErrorText(AppLocalizations l10n, BackupError error) {
  return switch (error.code) {
    BackupErrorCode.empty => l10n.importErrorEmpty,
    BackupErrorCode.tooLarge => l10n.importErrorTooLarge,
    BackupErrorCode.tooDeep => l10n.importErrorTooDeep,
    BackupErrorCode.corrupt => l10n.importErrorCorrupt,
    BackupErrorCode.rootNotObject => l10n.importErrorRoot,
    BackupErrorCode.missingField => l10n.importErrorMissingField(
      error.field ?? '?',
    ),
    BackupErrorCode.invalidField => l10n.importErrorInvalidField(
      error.field ?? '?',
    ),
    BackupErrorCode.unsupportedVersion => l10n.importErrorUnsupportedVersion,
    BackupErrorCode.newerVersion => l10n.importErrorNewerVersion,
    BackupErrorCode.duplicateId => l10n.importErrorDuplicateId(
      error.value ?? '?',
    ),
    BackupErrorCode.orphanReference => l10n.importErrorOrphanReference(
      error.value ?? '?',
    ),
    BackupErrorCode.absurdValue => l10n.importErrorAbsurdValue(
      error.field ?? '?',
    ),
  };
}
