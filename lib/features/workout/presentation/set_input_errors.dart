import 'package:lift_core/lift_core.dart';

import '../../../core/l10n/l10n.dart';

String weightErrorText(AppLocalizations l10n, NumberProblem problem) {
  return switch (problem) {
    NumberProblem.empty => l10n.errorWeightRequired,
    NumberProblem.invalid => l10n.errorInvalidNumber,
    NumberProblem.tooManyDecimals => l10n.errorWeightDecimals,
    NumberProblem.negative => l10n.errorWeightNegative,
    NumberProblem.outOfRange => l10n.errorWeightRange,
  };
}

String repsErrorText(AppLocalizations l10n, NumberProblem problem) {
  return switch (problem) {
    NumberProblem.empty => l10n.errorRepsRequired,
    NumberProblem.invalid => l10n.errorInvalidNumber,
    NumberProblem.tooManyDecimals => l10n.errorInvalidNumber,
    NumberProblem.negative => l10n.errorRepsNegative,
    NumberProblem.outOfRange => l10n.errorRepsRange,
  };
}
