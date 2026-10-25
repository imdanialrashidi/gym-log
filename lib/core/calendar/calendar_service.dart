import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../l10n/digit_style_scope.dart';

/// How a date or time is rendered. Every user-visible date goes through
/// [CalendarService] (`L10N-005`).
enum AppDateStyle { day, monthYear, date, dateTime, weekdayNarrow }

/// A display-calendar month used by the history grid.
class CalendarMonth {
  const CalendarMonth({required this.start, required this.length});

  /// Local midnight of display day 1, expressed as a Gregorian [DateTime].
  final DateTime start;

  /// Number of days in the display month (29–31).
  final int length;

  /// First weekday as `DateTime.weekday % 7` (0 = Sunday).
  int get firstWeekdayIndex => start.weekday % 7;
}

/// Display-calendar boundary.
///
/// Dates are stored in UTC and shown in local time. The Persian UI uses the
/// Jalali (Shamsi) calendar with Persian month names; the English UI uses
/// Gregorian. `shamsi_date` is an implementation detail of
/// [JalaliCalendarService] and must not be imported by features or data code,
/// so the library can be replaced without touching them (Section 26).
abstract interface class CalendarService {
  /// Formats a local [value] for [languageCode].
  ///
  /// [digitStyle] is applied to every numeric part; [narrowWeekdays] is the
  /// active [MaterialLocalizations.narrowWeekdays] list indexed by
  /// `DateTime.weekday % 7` (0 = Sunday).
  String formatDate(
    DateTime value, {
    required AppDateStyle style,
    required String languageCode,
    required DigitStyle digitStyle,
    required List<String> narrowWeekdays,
  });

  /// First day of the week as `DateTime.weekday % 7` (0 = Sunday).
  ///
  /// Persian weeks start on Saturday (`L10N-006`); English keeps Sunday.
  int weekStartIndex(String languageCode);

  /// The display-calendar month containing [value].
  CalendarMonth month(DateTime value, {required String languageCode});

  /// The display-calendar month [months] away from [value].
  DateTime shiftMonth(
    DateTime value,
    int months, {
    required String languageCode,
  });
}

/// Jalali for Persian, Gregorian for other locales.
class JalaliCalendarService implements CalendarService {
  const JalaliCalendarService();

  @override
  String formatDate(
    DateTime value, {
    required AppDateStyle style,
    required String languageCode,
    required DigitStyle digitStyle,
    required List<String> narrowWeekdays,
  }) {
    final DateTime local = value.toLocal();
    if (style == AppDateStyle.weekdayNarrow) {
      return narrowWeekdays[local.weekday % 7];
    }
    if (languageCode != 'fa') {
      return _formatGregorian(
        local,
        style: style,
        digitStyle: digitStyle,
        narrowWeekdays: narrowWeekdays,
      );
    }
    return _formatJalali(
      local,
      style: style,
      digitStyle: digitStyle,
      narrowWeekdays: narrowWeekdays,
    );
  }

  @override
  int weekStartIndex(String languageCode) => languageCode == 'fa' ? 6 : 0;

  @override
  CalendarMonth month(DateTime value, {required String languageCode}) {
    final DateTime local = value.toLocal();
    if (languageCode != 'fa') {
      return CalendarMonth(
        start: DateTime(local.year, local.month),
        length: DateTime(local.year, local.month + 1, 0).day,
      );
    }
    final Jalali jalali = Jalali.fromDateTime(local);
    final Jalali first = Jalali(jalali.year, jalali.month);
    return CalendarMonth(start: first.toDateTime(), length: first.monthLength);
  }

  @override
  DateTime shiftMonth(
    DateTime value,
    int months, {
    required String languageCode,
  }) {
    if (languageCode != 'fa') {
      final DateTime local = value.toLocal();
      return DateTime(local.year, local.month + months);
    }
    final Jalali jalali = Jalali.fromDateTime(value.toLocal());
    return Jalali(jalali.year, jalali.month).addMonths(months).toDateTime();
  }

  String _formatGregorian(
    DateTime local, {
    required AppDateStyle style,
    required DigitStyle digitStyle,
    required List<String> narrowWeekdays,
  }) {
    final String day = applyDigitStyle(
      local.day.toString().padLeft(2, '0'),
      digitStyle,
    );
    final String month = applyDigitStyle(
      local.month.toString().padLeft(2, '0'),
      digitStyle,
    );
    final String year = applyDigitStyle(
      local.year.toString().padLeft(4, '0'),
      digitStyle,
    );
    final String rawDate = '$year/$month/$day';
    final String rawTime = applyDigitStyle(
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}',
      digitStyle,
    );

    return switch (style) {
      AppDateStyle.day => _isolated(
        applyDigitStyle('${local.day}', digitStyle),
      ),
      AppDateStyle.monthYear => _isolated('$year/$month'),
      AppDateStyle.date => _isolated(rawDate),
      AppDateStyle.dateTime => _isolated('$rawDate $rawTime'),
      AppDateStyle.weekdayNarrow => narrowWeekdays[local.weekday % 7],
    };
  }

  String _formatJalali(
    DateTime local, {
    required AppDateStyle style,
    required DigitStyle digitStyle,
    required List<String> narrowWeekdays,
  }) {
    final Jalali jalali = Jalali.fromDateTime(local);
    final String day = applyDigitStyle('${jalali.day}', digitStyle);
    final String year = applyDigitStyle('${jalali.year}', digitStyle);
    final String monthName = jalali.formatter.mN;
    final String rawTime = _isolated(
      applyDigitStyle(
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}',
        digitStyle,
      ),
    );

    return switch (style) {
      AppDateStyle.day => day,
      AppDateStyle.monthYear => '$monthName $year',
      AppDateStyle.date => '$day $monthName $year',
      AppDateStyle.dateTime => '$day $monthName $year، $rawTime',
      AppDateStyle.weekdayNarrow => narrowWeekdays[local.weekday % 7],
    };
  }

  String _isolated(String value) => '\u2066$value\u2069';
}

/// Formats a date through the single [CalendarService] implementation.
extension AppCalendarContext on BuildContext {
  static const CalendarService _calendar = JalaliCalendarService();

  String formatDate(DateTime value, {AppDateStyle style = AppDateStyle.date}) {
    return _calendar.formatDate(
      value,
      style: style,
      languageCode: Localizations.localeOf(this).languageCode,
      digitStyle: DigitStyleScope.of(this),
      narrowWeekdays: MaterialLocalizations.of(this).narrowWeekdays,
    );
  }

  /// First day of the week for the active locale (`L10N-006`).
  int get weekStartIndex =>
      _calendar.weekStartIndex(Localizations.localeOf(this).languageCode);

  /// Display-calendar month containing [value].
  CalendarMonth calendarMonth(DateTime value) => _calendar.month(
    value,
    languageCode: Localizations.localeOf(this).languageCode,
  );

  /// Display-calendar month shift for the history pager.
  DateTime shiftCalendarMonth(DateTime value, int months) =>
      _calendar.shiftMonth(
        value,
        months,
        languageCode: Localizations.localeOf(this).languageCode,
      );
}
