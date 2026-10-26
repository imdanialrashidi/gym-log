import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

WeekStats _week({
  required int sessionCount,
  required int workingSetCount,
  required bool current,
}) {
  final DateTime weekStart = DateTime(2026, 10, current ? 24 : 17);
  return WeekStats(
    weekStart: weekStart,
    weekEndExclusive: DateTime(2026, 10, weekStart.day + 7),
    isCurrentWeek: current,
    sessions: <SessionStats>[
      for (int index = 0; index < sessionCount; index += 1)
        SessionStats(
          sessionId: 'session-${weekStart.day}-$index',
          startedAt: weekStart.add(Duration(days: index)),
          endedAt: weekStart.add(Duration(days: index, hours: 1)),
          duration: const Duration(hours: 1),
          setCount: 0,
          workingSetCount: 0,
          volumeGrams: 0,
          exercises: const <SessionExerciseStats>[],
          workingSetsByMuscle: const <MuscleGroup?, int>{},
        ),
    ],
    duration: Duration.zero,
    setCount: workingSetCount,
    workingSetCount: workingSetCount,
    volumeGrams: 0,
    workingSetsByMuscle: const <MuscleGroup?, int>{},
    bodyWeight: null,
  );
}

void main() {
  group('weekly goals', () {
    test('no configured goal reports no goal and no streak', () {
      final WeeklyGoalProgress progress = weeklyGoalProgress(
        weeks: <WeekStats>[
          _week(sessionCount: 2, workingSetCount: 8, current: false),
          _week(sessionCount: 3, workingSetCount: 12, current: true),
        ],
        settings: const AppSettings(),
      );
      expect(progress.hasGoal, isFalse);
      expect(progress.streakWeeks, 0);
      expect(progress.sessionFraction, isNull);
      expect(progress.setFraction, isNull);
      expect(progress.allMet, isFalse);
    });

    test('counts the current week and consecutive completed weeks', () {
      final WeeklyGoalProgress progress = weeklyGoalProgress(
        weeks: <WeekStats>[
          _week(sessionCount: 1, workingSetCount: 6, current: false),
          _week(sessionCount: 3, workingSetCount: 12, current: false),
          _week(sessionCount: 4, workingSetCount: 14, current: false),
          _week(sessionCount: 3, workingSetCount: 12, current: true),
        ],
        settings: const AppSettings(weeklySessionGoal: 3, weeklySetGoal: 12),
      );
      expect(progress.hasGoal, isTrue);
      expect(progress.allMet, isTrue);
      expect(progress.streakWeeks, 3);
      expect(progress.remainingSessions, 0);
      expect(progress.remainingSets, 0);
      expect(progress.sessionFraction, 1);
      expect(progress.setFraction, 1);
    });

    test('an in-progress week does not break the previous streak', () {
      final WeeklyGoalProgress progress = weeklyGoalProgress(
        weeks: <WeekStats>[
          _week(sessionCount: 3, workingSetCount: 12, current: false),
          _week(sessionCount: 3, workingSetCount: 12, current: false),
          _week(sessionCount: 1, workingSetCount: 4, current: true),
        ],
        settings: const AppSettings(weeklySessionGoal: 3),
      );
      expect(progress.allMet, isFalse);
      expect(progress.streakWeeks, 2);
      expect(progress.remainingSessions, 2);
    });

    test('a miss outside the current week ends the streak', () {
      final WeeklyGoalProgress progress = weeklyGoalProgress(
        weeks: <WeekStats>[
          _week(sessionCount: 3, workingSetCount: 12, current: false),
          _week(sessionCount: 1, workingSetCount: 4, current: false),
          _week(sessionCount: 3, workingSetCount: 12, current: true),
        ],
        settings: const AppSettings(weeklySessionGoal: 3),
      );
      expect(progress.streakWeeks, 1);
    });

    test('set-only goal is supported', () {
      final WeeklyGoalProgress progress = weeklyGoalProgress(
        weeks: <WeekStats>[
          _week(sessionCount: 0, workingSetCount: 6, current: true),
        ],
        settings: const AppSettings(weeklySetGoal: 20),
      );
      expect(progress.hasGoal, isTrue);
      expect(progress.sessionGoal, isNull);
      expect(progress.setMet, isFalse);
      expect(progress.remainingSets, 14);
      expect(progress.setFraction, 0.3);
      expect(progress.sessionFraction, isNull);
    });

    test('settings round-trip goals and permit clearing them', () {
      const AppSettings settings = AppSettings(
        weeklySessionGoal: 4,
        weeklySetGoal: 18,
      );
      final AppSettings restored = AppSettings.fromJson(settings.toJson());
      expect(restored.weeklySessionGoal, 4);
      expect(restored.weeklySetGoal, 18);
      final AppSettings cleared = restored.withWeeklyGoals(
        sessionGoal: null,
        setGoal: null,
      );
      expect(cleared.hasWeeklyGoal, isFalse);
      expect(cleared.weeklySetGoal, isNull);
    });

    test('rejects out-of-range goals on both read and construction', () {
      expect(
        () => AppSettings.fromJson(<String, Object?>{
          'weightUnit': 'kilograms',
          'restTimerEnabled': false,
          'restTimerDurationSeconds': 90,
          'weeklySessionGoal': 0,
        }),
        throwsFormatException,
      );
      expect(
        () => const AppSettings().withWeeklyGoals(sessionGoal: 1, setGoal: 500),
        throwsArgumentError,
      );
    });
  });
}
