import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';

/// Localizes a structured `INT-002` reason for the active locale and digit
/// style.
String progressionReasonText(
  BuildContext context,
  ProgressionSuggestion suggestion,
  WeightUnit unit,
) {
  return progressionReasonTextFor(
    context.l10n,
    suggestion,
    unit,
    digitStyle: DigitStyleScope.of(context),
  );
}

/// Locale-level form used by unit tests; display code should prefer
/// [progressionReasonText] so the active digit style is applied.
String progressionReasonTextFor(
  AppLocalizations l10n,
  ProgressionSuggestion suggestion,
  WeightUnit unit, {
  DigitStyle digitStyle = DigitStyle.latin,
}) {
  final ProgressionReason reason = suggestion.reason;
  return applyDigitStyle(switch (reason) {
    ProgressionReasonAddWeight() => l10n.progressionAddWeightReason(
      reason.setCount,
      reason.maxReps,
      '${formatWeight(reason.incrementGrams, unit)} ${_unitLabel(l10n, unit)}',
    ),
    ProgressionReasonAddReps() => l10n.progressionAddRepsReason(
      reason.weakestReps,
      reason.targetReps,
    ),
    ProgressionReasonHold() => l10n.progressionHoldReason(reason.minReps),
  }, digitStyle);
}

String _unitLabel(AppLocalizations l10n, WeightUnit unit) {
  return switch (unit) {
    WeightUnit.kilograms => l10n.unitKilograms,
    WeightUnit.pounds => l10n.unitPounds,
  };
}
