import 'package:flutter/services.dart';

/// Input formatters that accept Latin, Persian (U+06F0–U+06F9), and
/// Arabic-Indic (U+0660–U+0669) digits (`LOG-010`, `L10N-004`).
///
/// Values are normalized with `normalizeDigits` before parsing; the field
/// keeps whatever style the user typed.
final TextInputFormatter wholeNumberInput = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9\u06F0-\u06F9\u0660-\u0669]'),
);

/// Whole or decimal digits with `.` or the Persian/Arabic decimal separator
/// `٫`; commas are rejected because the parser never guesses a separator.
final TextInputFormatter decimalNumberInput = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9\u06F0-\u06F9\u0660-\u0669.٫]'),
);
