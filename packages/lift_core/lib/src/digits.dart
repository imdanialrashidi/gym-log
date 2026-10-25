/// Persian/Latin digit display preference (`L10N-004`, `SET-002`).
///
/// Digits are a display concern. Stored training data never contains localized
/// digits; parsers normalize every supported digit style on input.
enum DigitStyle { persian, latin }

const int _asciiZero = 0x30;
const int _asciiNine = 0x39;
const int _persianZero = 0x06F0;
const int _persianNine = 0x06F9;
const int _arabicIndicZero = 0x0660;
const int _arabicIndicNine = 0x0669;

/// Converts Persian (U+06F0–U+06F9) and Arabic-Indic (U+0660–U+0669) digits
/// to ASCII digits. Other characters are preserved.
String normalizeDigits(String value) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in value.runes) {
    if (rune >= _persianZero && rune <= _persianNine) {
      buffer.writeCharCode(rune - _persianZero + _asciiZero);
    } else if (rune >= _arabicIndicZero && rune <= _arabicIndicNine) {
      buffer.writeCharCode(rune - _arabicIndicZero + _asciiZero);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// Renders [value] with the selected digit style.
///
/// Every digit in the input is first normalized, so switching between Persian
/// and Latin cannot leave a mixed string. Callers apply this at the display
/// boundary only; persisted values stay ASCII/ISO.
String applyDigitStyle(String value, DigitStyle style) {
  final String normalized = normalizeDigits(value);
  if (style == DigitStyle.latin) {
    return normalized;
  }
  final StringBuffer buffer = StringBuffer();
  for (final int rune in normalized.runes) {
    if (rune >= _asciiZero && rune <= _asciiNine) {
      buffer.writeCharCode(rune - _asciiZero + _persianZero);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
