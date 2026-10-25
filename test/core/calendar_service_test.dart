import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/core/calendar/calendar_service.dart';
import 'package:lift_core/lift_core.dart';

// Conversion vectors cross-checked against independent calendar references:
// - https://www.whatistheday.com/persian-date-converter
//   20 March 2024 = 1 Farvardin 1403; 20 March 2025 = 30 Esfand 1403;
//   21 March 2025 = 1 Farvardin 1404.
// - https://www.vercalendario.info/en/calendars/persian-calendar/compare-1403.html
//   31 Shahrivar 1403 = 21 September 2024; 1 Mehr 1403 = 22 September 2024.
// - https://www.whatistheday.com/persian-month/farvardin
//   1405 starts on 21 March 2026.
const List<String> _faWeekdays = <String>['ی', 'د', 'س', 'چ', 'پ', 'ج', 'ش'];

String _format(
  DateTime value, {
  AppDateStyle style = AppDateStyle.date,
  DigitStyle digits = DigitStyle.persian,
  String languageCode = 'fa',
}) {
  return const JalaliCalendarService().formatDate(
    value,
    style: style,
    languageCode: languageCode,
    digitStyle: digits,
    narrowWeekdays: _faWeekdays,
  );
}

void main() {
  test('Jalali conversion matches independent leap-year vectors', () {
    expect(_format(DateTime(2024, 3, 20)), '۱ فروردین ۱۴۰۳');
    expect(_format(DateTime(2025, 3, 20)), '۳۰ اسفند ۱۴۰۳');
    expect(_format(DateTime(2025, 3, 21)), '۱ فروردین ۱۴۰۴');
    expect(_format(DateTime(2026, 3, 20)), '۲۹ اسفند ۱۴۰۴');
    expect(_format(DateTime(2026, 3, 21)), '۱ فروردین ۱۴۰۵');
  });

  test('Jalali conversion matches month-boundary vectors', () {
    expect(_format(DateTime(2024, 9, 21)), '۳۱ شهریور ۱۴۰۳');
    expect(_format(DateTime(2024, 9, 22)), '۱ مهر ۱۴۰۳');
    expect(_format(DateTime(2024, 9, 21), style: AppDateStyle.day), '۳۱');
    expect(
      _format(DateTime(2024, 9, 21), style: AppDateStyle.monthYear),
      'شهریور ۱۴۰۳',
    );
  });

  test('digit style changes display only, including time', () {
    expect(
      _format(DateTime(2024, 3, 20), digits: DigitStyle.latin),
      '1 فروردین 1403',
    );
    expect(
      _format(
        DateTime(2024, 9, 21, 9, 5),
        style: AppDateStyle.dateTime,
        digits: DigitStyle.latin,
      ),
      contains('31 شهریور 1403'),
    );
    expect(
      _format(DateTime(2024, 9, 21, 9, 5), style: AppDateStyle.dateTime),
      contains('۰۹:۰۵'),
    );
  });

  test('English keeps Gregorian dates and Sunday week start', () {
    final String date = _format(
      DateTime(2024, 3, 20),
      languageCode: 'en',
      digits: DigitStyle.latin,
    );
    expect(date, contains('2024/03/20'));
    expect(const JalaliCalendarService().weekStartIndex('en'), 0);
  });

  test('display months follow the Persian calendar, not Gregorian', () {
    const JalaliCalendarService service = JalaliCalendarService();
    final CalendarMonth mehr = service.month(
      DateTime(2026, 10, 21),
      languageCode: 'fa',
    );
    expect(mehr.start, DateTime(2026, 9, 23));
    expect(mehr.length, 30);
    expect(mehr.firstWeekdayIndex, 3); // Wednesday

    final DateTime aban = service.shiftMonth(
      DateTime(2026, 10, 21),
      1,
      languageCode: 'fa',
    );
    expect(aban, DateTime(2026, 10, 23));
    expect(service.month(aban, languageCode: 'fa').length, 30);

    final CalendarMonth march = service.month(
      DateTime(2024, 3, 20),
      languageCode: 'en',
    );
    expect(march.start, DateTime(2024, 3));
    expect(march.length, 31);
  });

  test('Persian week starts on Saturday and weekday labels align', () {
    expect(const JalaliCalendarService().weekStartIndex('fa'), 6);
    expect(
      _format(DateTime(2024, 9, 21), style: AppDateStyle.weekdayNarrow),
      'ش',
    );
  });
}
