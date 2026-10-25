import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

void main() {
  test('normalizeDigits converts Persian and Arabic-Indic digits', () {
    expect(normalizeDigits('۱۲۳۴۵۶۷۸۹۰'), '1234567890');
    expect(normalizeDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    expect(normalizeDigits('مهر ۱۴۰۵ / 10'), 'مهر 1405 / 10');
    expect(normalizeDigits('۱۲٫۵'), '12٫5');
  });

  test('applyDigitStyle keeps a single digit style', () {
    expect(applyDigitStyle('12.5', DigitStyle.persian), '۱۲.۵');
    expect(applyDigitStyle('۱۲٫۵', DigitStyle.persian), '۱۲٫۵');
    expect(applyDigitStyle('١٢٥', DigitStyle.persian), '۱۲۵');
    expect(applyDigitStyle('۱۲۳', DigitStyle.latin), '123');
    expect(applyDigitStyle('123', DigitStyle.latin), '123');
  });

  test('digit style never leaks into parsed weights', () {
    for (final String input in <String>['80.5', '۸۰٫۵', '٨٠.٥']) {
      final WeightParseResult parsed = parseWeightInput(
        input,
        WeightUnit.kilograms,
      );
      expect(parsed.grams, 80500, reason: input);
      expect(formatWeight(parsed.grams!, WeightUnit.kilograms), '80.5');
    }
  });

  test('settings keep optional digit style and increment out of old files', () {
    const AppSettings defaults = AppSettings();
    expect(defaults.digitStyle, isNull);
    expect(defaults.defaultIncrementGrams, isNull);
    expect(defaults.incrementFor(WeightUnit.kilograms), 2500);
    expect(defaults.incrementFor(WeightUnit.pounds), 2268);

    final AppSettings restored = AppSettings.fromJson(<String, Object?>{
      'weightUnit': 'pounds',
      'digitStyle': 'persian',
      'defaultIncrementGrams': 4536,
    });
    expect(restored.digitStyle, DigitStyle.persian);
    expect(restored.defaultIncrementGrams, 4536);
    expect(restored.incrementFor(WeightUnit.kilograms), 4536);
    expect(restored.toJson()['digitStyle'], 'persian');
    expect(restored.toJson()['defaultIncrementGrams'], 4536);
  });

  test('settings reject unknown digit styles and invalid increments', () {
    expect(
      () => AppSettings.fromJson(<String, Object?>{
        'weightUnit': 'kilograms',
        'digitStyle': 'roman',
      }),
      throwsFormatException,
    );
    expect(
      () => AppSettings.fromJson(<String, Object?>{
        'weightUnit': 'kilograms',
        'defaultIncrementGrams': 0,
      }),
      throwsFormatException,
    );
  });
}
