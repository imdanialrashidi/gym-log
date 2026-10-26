/// Body-weight check-ins and their weekly series.
///
/// A check-in is deliberately a separate record from a workout set: it is a
/// scale reading, not a lift. Weights stay canonical integer grams like every
/// other weight in the app (ADR-0002). Weekly series use the *latest* check-in
/// inside each week, so logging twice in one week never skews the trend.
library;

import 'json_reader.dart';

/// Lower bound for a body-weight check-in: 20 kg.
const int minimumBodyWeightGrams = 20000;

/// Upper bound for a body-weight check-in: 500 kg.
const int maximumBodyWeightGrams = 500000;

/// Default first day of the week, as [DateTime.weekday] (6 = Saturday).
///
/// The UI passes the locale's own first day; this default keeps pure-domain
/// callers Persian-first and deterministic.
const int defaultWeekStartsOn = DateTime.saturday;

/// Whether [grams] is inside the accepted body-weight range.
bool isValidBodyWeightGrams(int grams) {
  return grams >= minimumBodyWeightGrams && grams <= maximumBodyWeightGrams;
}

/// One scale reading.
class BodyWeightEntry {
  factory BodyWeightEntry({
    required String id,
    required int weightGrams,
    required DateTime recordedAt,
  }) {
    if (!isValidBodyWeightGrams(weightGrams)) {
      throw ArgumentError.value(
        weightGrams,
        'weightGrams',
        'Body weight must be between $minimumBodyWeightGrams and '
            '$maximumBodyWeightGrams grams',
      );
    }
    return BodyWeightEntry._(
      id: id,
      weightGrams: weightGrams,
      recordedAt: recordedAt.toUtc(),
    );
  }

  const BodyWeightEntry._({
    required this.id,
    required this.weightGrams,
    required this.recordedAt,
  });

  final String id;
  final int weightGrams;

  /// When the user stepped on the scale, stored in UTC.
  final DateTime recordedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'weightGrams': weightGrams,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory BodyWeightEntry.fromJson(Map<String, Object?> json) {
    return BodyWeightEntry(
      id: readString(json, 'id'),
      weightGrams: readInt(json, 'weightGrams'),
      recordedAt: readDateTime(json, 'recordedAt'),
    );
  }
}

/// Local midnight that starts the week containing [value].
///
/// [weekStartsOn] follows [DateTime.weekday] (1 = Monday … 7 = Sunday).
/// Calendar arithmetic is done on date fields, not by subtracting a duration,
/// so daylight-saving transitions cannot move the boundary into the previous
/// day.
DateTime startOfWeek(DateTime value, int weekStartsOn) {
  if (weekStartsOn < DateTime.monday || weekStartsOn > DateTime.sunday) {
    throw ArgumentError.value(weekStartsOn, 'weekStartsOn');
  }
  final DateTime local = value.toLocal();
  final int offset = (local.weekday - weekStartsOn + 7) % 7;
  return DateTime(local.year, local.month, local.day - offset);
}

/// One week of the body-weight trend.
class BodyWeightWeek {
  const BodyWeightWeek({
    required this.weekStart,
    required this.entry,
    required this.changeGrams,
  });

  /// Local midnight of the first day of the week.
  final DateTime weekStart;

  /// Latest check-in inside the week, or `null` when the week has none.
  final BodyWeightEntry? entry;

  /// Change from the previous week that has a check-in, in canonical grams.
  ///
  /// `null` when this week or every earlier week in the series is empty.
  final int? changeGrams;

  bool get hasEntry => entry != null;

  int? get weightGrams => entry?.weightGrams;
}

/// Weekly check-ins, oldest first, ending with the week containing [now].
///
/// Empty weeks are included with a `null` [BodyWeightWeek.entry] so a chart
/// draws a gap instead of inventing a value. [changeGrams] compares each week
/// with the latest earlier week that has a check-in inside the returned range.
List<BodyWeightWeek> weeklyBodyWeight({
  required List<BodyWeightEntry> entries,
  required DateTime now,
  int weekStartsOn = defaultWeekStartsOn,
  int weeks = 12,
}) {
  if (weeks < 1) {
    throw ArgumentError.value(weeks, 'weeks');
  }
  final Map<DateTime, BodyWeightEntry> latestByWeek =
      <DateTime, BodyWeightEntry>{};
  for (final BodyWeightEntry entry in entries) {
    final DateTime week = startOfWeek(entry.recordedAt, weekStartsOn);
    final BodyWeightEntry? existing = latestByWeek[week];
    if (existing == null ||
        entry.recordedAt.isAfter(existing.recordedAt) ||
        (entry.recordedAt.isAtSameMomentAs(existing.recordedAt) &&
            entry.id.compareTo(existing.id) > 0)) {
      latestByWeek[week] = entry;
    }
  }

  final DateTime currentWeek = startOfWeek(now, weekStartsOn);
  final List<BodyWeightWeek> series = <BodyWeightWeek>[];
  int? previousWeight;
  for (int index = weeks - 1; index >= 0; index -= 1) {
    final DateTime weekStart = DateTime(
      currentWeek.year,
      currentWeek.month,
      currentWeek.day - index * 7,
    );
    final BodyWeightEntry? entry = latestByWeek[weekStart];
    final int? weight = entry?.weightGrams;
    final int? change = weight == null || previousWeight == null
        ? null
        : weight - previousWeight;
    series.add(
      BodyWeightWeek(weekStart: weekStart, entry: entry, changeGrams: change),
    );
    if (weight != null) {
      previousWeight = weight;
    }
  }
  return series;
}

/// The newest check-in, breaking timestamp ties by id.
BodyWeightEntry? latestBodyWeightEntry(List<BodyWeightEntry> entries) {
  BodyWeightEntry? latest;
  for (final BodyWeightEntry entry in entries) {
    if (latest == null ||
        entry.recordedAt.isAfter(latest.recordedAt) ||
        (entry.recordedAt.isAtSameMomentAs(latest.recordedAt) &&
            entry.id.compareTo(latest.id) > 0)) {
      latest = entry;
    }
  }
  return latest;
}

/// The newest check-in together with its change from the previous one.
///
/// [changeGrams] is `null` until there are at least two check-ins, so the UI
/// never shows a made-up zero change on the first reading.
({BodyWeightEntry? entry, int? changeGrams}) latestBodyWeightChange(
  List<BodyWeightEntry> entries,
) {
  final List<BodyWeightEntry> sorted = List<BodyWeightEntry>.of(entries)
    ..sort((BodyWeightEntry a, BodyWeightEntry b) {
      final int byDate = a.recordedAt.compareTo(b.recordedAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
  if (sorted.isEmpty) {
    return (entry: null, changeGrams: null);
  }
  final BodyWeightEntry latest = sorted.last;
  if (sorted.length < 2) {
    return (entry: latest, changeGrams: null);
  }
  return (
    entry: latest,
    changeGrams: latest.weightGrams - sorted[sorted.length - 2].weightGrams,
  );
}

/// Drops leading weeks before the first check-in.
///
/// A trend chart should start at the user's first reading, not at an arbitrary
/// empty margin. A series with no entries is returned unchanged.
List<BodyWeightWeek> trimLeadingEmptyWeeks(List<BodyWeightWeek> weeks) {
  final int first = weeks.indexWhere((BodyWeightWeek week) => week.hasEntry);
  return first <= 0 ? weeks : weeks.sublist(first);
}
