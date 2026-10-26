/// Weight handling shared by exercises, logging, and settings.
///
/// Canonical storage is integer grams (ADR-0002). Per-exercise increments are
/// grams too, so a display-unit change never mutates stored data.
///
/// Rounding rule: converting a display value to grams rounds half away from
/// zero at the gram boundary; formatting grams for display rounds half away
/// from zero to the nearest 0.01 display unit. Two displayed decimals are the
/// supported input precision, and half a gram is smaller than half of 0.01 kg
/// or 0.01 lb, so every supported input round-trips to the same displayed
/// value. Both boundaries accept only Latin, Persian (U+06F0–U+06F9), and
/// Arabic-Indic (U+0660–U+0669) digits, with `.` or the Persian/Arabic decimal
/// separator U+066B (٫). Other separators are rejected rather than guessed.
library;

import 'digits.dart';

enum WeightUnit { kilograms, pounds }

/// 2.5 kg in grams.
const int defaultKilogramIncrementGrams = 2500;

/// 5 lb in grams, rounded to the nearest gram.
const int defaultPoundIncrementGrams = 2268;

/// Upper bound for a logged weight: 1,000 kg (about 2,204.6 lb).
const int maximumSetWeightGrams = 1000000;

/// Upper bound for logged repetitions.
const int maximumSetRepetitions = 1000;

/// 1 lb = 453.59237 g, expressed as an exact integer fraction.
const int _poundGramNumerator = 45359237;
const int _poundGramDenominator = 100000;

/// 1 lb in hundredths of a pound expressed in grams, for display.
const int _poundHundredthNumerator = 10000000;
const int _poundHundredthDenominator = 45359237;

/// The default increment for [unit] (`EXR-007`).
int defaultIncrementGrams(WeightUnit unit) => switch (unit) {
  WeightUnit.kilograms => defaultKilogramIncrementGrams,
  WeightUnit.pounds => defaultPoundIncrementGrams,
};

/// Same value as [defaultIncrementGrams], for call sites where a settings
/// field named `defaultIncrementGrams` shadows the function.
int unitDefaultIncrementGrams(WeightUnit unit) => defaultIncrementGrams(unit);

/// Why a numeric input could not be accepted.
enum NumberProblem { empty, invalid, tooManyDecimals, negative, outOfRange }

/// Result of parsing a weight field.
class WeightParseResult {
  const WeightParseResult.valid(this.grams) : problem = null;

  const WeightParseResult.invalid(this.problem) : grams = null;

  final int? grams;
  final NumberProblem? problem;

  bool get isValid => grams != null;
}

/// Result of parsing a repetition field.
class RepsParseResult {
  const RepsParseResult.valid(this.reps) : problem = null;

  const RepsParseResult.invalid(this.problem) : reps = null;

  final int? reps;
  final NumberProblem? problem;

  bool get isValid => reps != null;
}

/// Parses a weight typed in [unit] into canonical grams.
///
/// Up to two decimal places are accepted. The parser never throws for user
/// input; every failure is reported through [WeightParseResult.problem].
WeightParseResult parseWeightInput(String input, WeightUnit unit) {
  final String normalized = normalizeDigits(input).trim();
  if (normalized.isEmpty) {
    return const WeightParseResult.invalid(NumberProblem.empty);
  }
  if (normalized.startsWith('-')) {
    return const WeightParseResult.invalid(NumberProblem.negative);
  }
  if (normalized.startsWith('+')) {
    return const WeightParseResult.invalid(NumberProblem.invalid);
  }

  final String decimal = normalized.replaceAll('\u066B', '.');
  final List<String> parts = decimal.split('.');
  if (parts.length > 2) {
    return const WeightParseResult.invalid(NumberProblem.invalid);
  }
  final String whole = parts.first;
  final String fraction = parts.length == 2 ? parts.last : '';
  if (fraction.isNotEmpty && !_isAsciiDigits(fraction)) {
    return const WeightParseResult.invalid(NumberProblem.invalid);
  }
  if (whole.isNotEmpty && !_isAsciiDigits(whole)) {
    return const WeightParseResult.invalid(NumberProblem.invalid);
  }
  if (whole.isEmpty && fraction.isEmpty) {
    return const WeightParseResult.invalid(NumberProblem.empty);
  }
  if (parts.length == 2 && fraction.isEmpty) {
    return const WeightParseResult.invalid(NumberProblem.invalid);
  }
  if (fraction.length > 2) {
    return const WeightParseResult.invalid(NumberProblem.tooManyDecimals);
  }

  final String coefficientText = '${whole.isEmpty ? '0' : whole}$fraction';
  final int? coefficient = int.tryParse(coefficientText);
  if (coefficient == null || coefficient > maximumSetWeightGrams) {
    return const WeightParseResult.invalid(NumberProblem.outOfRange);
  }
  final int scale = switch (fraction.length) {
    0 => 1,
    1 => 10,
    _ => 100,
  };
  final int grams = switch (unit) {
    WeightUnit.kilograms => _roundHalfUp(coefficient * 1000, scale),
    WeightUnit.pounds => _roundHalfUp(
      coefficient * _poundGramNumerator,
      scale * _poundGramDenominator,
    ),
  };
  if (grams > maximumSetWeightGrams) {
    return const WeightParseResult.invalid(NumberProblem.outOfRange);
  }
  return WeightParseResult.valid(grams);
}

/// Parses a weight field, but returns [originalGrams] exactly when the text
/// still equals the canonical value's two-decimal display.
///
/// This preserves integer-gram identity across a no-op editor confirmation.
/// Display rounding is not an input: only a changed string is reparsed.
WeightParseResult parseWeightField(
  String input, {
  required WeightUnit unit,
  int? originalGrams,
}) {
  if (originalGrams != null) {
    final String normalized = normalizeDigits(input).trim();
    if (normalized == formatWeight(originalGrams, unit)) {
      return WeightParseResult.valid(originalGrams);
    }
  }
  return parseWeightInput(input, unit);
}

/// Parses a repetition count. Only whole numbers from 1 to
/// [maximumSetRepetitions] are accepted.
RepsParseResult parseRepsInput(String input) {
  final String normalized = normalizeDigits(input).trim();
  if (normalized.isEmpty) {
    return const RepsParseResult.invalid(NumberProblem.empty);
  }
  if (normalized.startsWith('-')) {
    return const RepsParseResult.invalid(NumberProblem.negative);
  }
  if (!_isAsciiDigits(normalized)) {
    return const RepsParseResult.invalid(NumberProblem.invalid);
  }
  final int? reps = int.tryParse(normalized);
  if (reps == null) {
    return const RepsParseResult.invalid(NumberProblem.outOfRange);
  }
  if (reps < 1 || reps > maximumSetRepetitions) {
    return const RepsParseResult.invalid(NumberProblem.outOfRange);
  }
  return RepsParseResult.valid(reps);
}

/// Formats canonical [grams] in [unit] with zero, one, or two decimals.
///
/// The output is ASCII and has no thousands grouping, so it can be placed
/// directly in an editable field and parsed back to the same displayed value
/// for every two-decimal input.
String formatWeight(int grams, WeightUnit unit) {
  if (grams < 0) {
    throw ArgumentError.value(grams, 'grams', 'Weight cannot be negative');
  }
  final int hundredths = switch (unit) {
    WeightUnit.kilograms => _roundHalfUp(grams, 10),
    WeightUnit.pounds => _roundHalfUp(
      grams * _poundHundredthNumerator,
      _poundHundredthDenominator,
    ),
  };
  return _formatHundredths(hundredths);
}

String _formatHundredths(int hundredths) {
  final int whole = hundredths ~/ 100;
  final int fraction = hundredths % 100;
  if (fraction == 0) {
    return '$whole';
  }
  if (fraction % 10 == 0) {
    return '$whole.${fraction ~/ 10}';
  }
  return '$whole.${fraction.toString().padLeft(2, '0')}';
}

/// Round a non-negative rational number half away from zero.
int _roundHalfUp(int numerator, int denominator) {
  return (numerator * 2 + denominator) ~/ (denominator * 2);
}

bool _isAsciiDigits(String value) {
  for (final int rune in value.runes) {
    if (rune < 0x30 || rune > 0x39) {
      return false;
    }
  }
  return true;
}
