import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../calendar/calendar_service.dart';
import '../l10n/digit_style_scope.dart';
import '../l10n/l10n.dart';

/// Human duration for session and exercise cards.
///
/// Rounds down to whole minutes: a 10:59 block reads as 10 minutes, which is
/// the honest "time trained" rather than an inflated minute. A missing value
/// says so instead of pretending the time was zero.
String formatTrainingDuration(BuildContext context, Duration? duration) {
  final AppLocalizations l10n = context.l10n;
  if (duration == null) {
    return l10n.durationUnknown;
  }
  final int totalMinutes = duration.inMinutes;
  if (totalMinutes <= 0) {
    return l10n.durationLessThanMinute;
  }
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  if (hours == 0) {
    return context.digits(l10n.durationMinutes(minutes));
  }
  if (minutes == 0) {
    return context.digits(l10n.durationHours(hours));
  }
  return context.digits(l10n.durationHoursMinutes(hours, minutes));
}

/// Compact duration for stat tiles where a half-width column is tight.
String formatTrainingDurationShort(BuildContext context, Duration? duration) {
  final AppLocalizations l10n = context.l10n;
  if (duration == null) {
    return l10n.durationUnknown;
  }
  final int totalMinutes = duration.inMinutes;
  if (totalMinutes <= 0) {
    return l10n.durationUnderMinuteShort;
  }
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  if (hours == 0) {
    return context.digits(l10n.durationMinutesShort(minutes));
  }
  if (minutes == 0) {
    return context.digits(l10n.durationHoursShort(hours));
  }
  return context.digits(l10n.durationHoursMinutesShort(hours, minutes));
}

/// Live `mm:ss` or `h:mm:ss` clock for the active session.
String formatElapsedClock(BuildContext context, Duration elapsed) {
  final int totalSeconds = elapsed.isNegative ? 0 : elapsed.inSeconds;
  final int hours = totalSeconds ~/ 3600;
  final int minutes = (totalSeconds % 3600) ~/ 60;
  final int seconds = totalSeconds % 60;
  final String mm = minutes.toString().padLeft(2, '0');
  final String ss = seconds.toString().padLeft(2, '0');
  final String raw = hours == 0 ? '$mm:$ss' : '$hours:$mm:$ss';
  return context.digits(raw);
}

/// Localized short unit for weight values.
String weightUnitLabel(BuildContext context, WeightUnit unit) {
  final AppLocalizations l10n = context.l10n;
  return switch (unit) {
    WeightUnit.kilograms => l10n.unitKilograms,
    WeightUnit.pounds => l10n.unitPounds,
  };
}

/// Signed body-weight change, including the unit, for the weight card.
String formatWeightChange(
  BuildContext context,
  int changeGrams,
  WeightUnit unit,
) {
  if (changeGrams == 0) {
    return '0 ${weightUnitLabel(context, unit)}';
  }
  final String magnitude = context.digits(
    '${formatWeight(changeGrams.abs(), unit)} '
    '${weightUnitLabel(context, unit)}',
  );
  return changeGrams > 0 ? '+$magnitude' : '−$magnitude';
}

/// Localized inclusive date range for one calendar week.
String formatWeekRange(BuildContext context, WeekStats week) {
  final DateTime end = DateTime(
    week.weekEndExclusive.year,
    week.weekEndExclusive.month,
    week.weekEndExclusive.day - 1,
  );
  return context.digits(
    context.l10n.weekRange(
      context.formatDate(week.weekStart),
      context.formatDate(end),
    ),
  );
}

/// Compact "weekday + day" label for the seven-day activity strip.
String formatWeekdayDay(BuildContext context, DateTime day) {
  return context.digits(
    '${context.formatDate(day, style: AppDateStyle.weekdayNarrow)} '
    '${context.formatDate(day, style: AppDateStyle.day)}',
  );
}
