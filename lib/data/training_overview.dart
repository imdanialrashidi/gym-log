import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';

import 'app_data_controller.dart';

/// Everything the dashboard and weekly summary need, derived once per
/// document revision and shared by both screens.
class TrainingOverview {
  const TrainingOverview({
    required this.weeks,
    required this.latestSession,
    required this.latestWeightEntry,
    required this.weightChangeGrams,
    required this.finishedSessionCount,
    required this.weekStartsOn,
    required this.goalProgress,
  });

  /// Oldest first, always eight weeks including empty ones.
  final List<WeekStats> weeks;

  final SessionStats? latestSession;
  final BodyWeightEntry? latestWeightEntry;

  /// Change from the previous check-in, all-time. `null` before two readings.
  final int? weightChangeGrams;

  final int finishedSessionCount;
  final int weekStartsOn;

  /// Adherence against the optional weekly goals (`GOAL-001`).
  final WeeklyGoalProgress goalProgress;

  WeekStats get currentWeek => weeks.last;

  /// Local dates in the current week with a finished session.
  Set<DateTime> get currentWeekDays => <DateTime>{
    for (final SessionStats session in currentWeek.sessions)
      _localDay(session.startedAt),
  };

  bool get hasTraining => finishedSessionCount > 0;

  bool get loggedWeightThisWeek => currentWeek.bodyWeight?.hasEntry ?? false;
}

DateTime _localDay(DateTime value) {
  final DateTime local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Cache key: one computation per week-start policy and calendar day.
typedef TrainingOverviewKey = ({int weekStartsOn, DateTime day});

/// `null` while the document is loading or failed.
final trainingOverviewProvider =
    Provider.family<TrainingOverview?, TrainingOverviewKey>((
      Ref ref,
      TrainingOverviewKey key,
    ) {
      final AppData? data = ref.watch(
        appDataControllerProvider.select(
          (AsyncValue<AppData> value) => value.value,
        ),
      );
      if (data == null) {
        return null;
      }
      final ({BodyWeightEntry? entry, int? changeGrams}) weight =
          latestBodyWeightChange(data.bodyWeights);
      final List<WeekStats> weeks = recentWeekStats(
        sessions: data.sessions,
        exercises: data.exercises,
        bodyWeights: data.bodyWeights,
        now: key.day,
        weekStartsOn: key.weekStartsOn,
      );
      return TrainingOverview(
        weeks: weeks,
        latestSession: latestFinishedSessionStats(
          data.sessions,
          exercises: data.exercises,
          now: key.day,
        ),
        latestWeightEntry: weight.entry,
        weightChangeGrams: weight.changeGrams,
        finishedSessionCount: data.sessions
            .where((Session session) => !session.isActive)
            .length,
        weekStartsOn: key.weekStartsOn,
        goalProgress: weeklyGoalProgress(weeks: weeks, settings: data.settings),
      );
    });
