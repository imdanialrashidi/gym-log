/// Optional weekly goals and the current week's adherence (`GOAL-001`).
///
/// Goals are a display/coaching layer: nothing here is persisted on its own.
/// The configured targets live in [AppSettings] and the counts come from the
/// same one-pass [WeekStats] used by the weekly summary.
library;

import 'settings.dart';
import 'workout_stats.dart';

/// Progress against the two optional weekly targets.
class WeeklyGoalProgress {
  const WeeklyGoalProgress({
    required this.sessionGoal,
    required this.setGoal,
    required this.sessionCount,
    required this.workingSetCount,
    required this.streakWeeks,
  });

  final int? sessionGoal;
  final int? setGoal;
  final int sessionCount;
  final int workingSetCount;

  /// Consecutive weeks that met every configured target, ending with the
  /// current week when it is already met.
  final int streakWeeks;

  bool get hasGoal => sessionGoal != null || setGoal != null;

  bool get sessionMet => sessionGoal != null && sessionCount >= sessionGoal!;

  bool get setMet => setGoal != null && workingSetCount >= setGoal!;

  bool get allMet =>
      hasGoal &&
      (sessionGoal == null || sessionMet) &&
      (setGoal == null || setMet);

  int? get remainingSessions => sessionGoal == null
      ? null
      : (sessionGoal! - sessionCount).clamp(0, sessionGoal!);

  int? get remainingSets =>
      setGoal == null ? null : (setGoal! - workingSetCount).clamp(0, setGoal!);

  double? get sessionFraction => sessionGoal == null || sessionGoal! <= 0
      ? null
      : (sessionCount / sessionGoal!).clamp(0.0, 1.0);

  double? get setFraction => setGoal == null || setGoal! <= 0
      ? null
      : (workingSetCount / setGoal!).clamp(0.0, 1.0);
}

/// Derives goal progress from the current week and the previous weeks.
///
/// The current in-progress week never breaks a streak: a streak is the run of
/// completed weeks meeting the target, extended by one if this week has already
/// met it. This avoids a discouraging reset every Monday morning.
WeeklyGoalProgress weeklyGoalProgress({
  required List<WeekStats> weeks,
  required AppSettings settings,
}) {
  if (weeks.isEmpty) {
    return WeeklyGoalProgress(
      sessionGoal: settings.weeklySessionGoal,
      setGoal: settings.weeklySetGoal,
      sessionCount: 0,
      workingSetCount: 0,
      streakWeeks: 0,
    );
  }
  final WeekStats current = weeks.last;
  bool met(WeekStats week) {
    final bool sessionsOk =
        settings.weeklySessionGoal == null ||
        week.sessionCount >= settings.weeklySessionGoal!;
    final bool setsOk =
        settings.weeklySetGoal == null ||
        week.workingSetCount >= settings.weeklySetGoal!;
    return sessionsOk && setsOk;
  }

  int streak = 0;
  if (settings.hasWeeklyGoal) {
    final bool currentMet = met(current);
    if (currentMet) {
      streak = 1;
    }
    for (int index = weeks.length - 2; index >= 0; index -= 1) {
      if (!met(weeks[index])) {
        break;
      }
      streak += 1;
    }
  }

  return WeeklyGoalProgress(
    sessionGoal: settings.weeklySessionGoal,
    setGoal: settings.weeklySetGoal,
    sessionCount: current.sessionCount,
    workingSetCount: current.workingSetCount,
    streakWeeks: streak,
  );
}
