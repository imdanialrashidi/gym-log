import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app/app_info.dart';
import 'package:lift_core/lift_core.dart';

import '../../tool/benchmarks/benchmark_fixture.dart';

/// The performance budgets are only meaningful if the fixture keeps its
/// documented shape: 10,000 sets for one exercise and 1,000 chart points.
void main() {
  test('benchmark fixture has 10,000 sets and 1,000 chart points', () {
    final AppData fixture = buildTenThousandSetFixture();

    final int setCount = fixture.sessions
        .expand((Session session) => session.exercises)
        .expand((SessionExercise exercise) => exercise.sets)
        .length;
    expect(setCount, benchmarkSetCount);
    expect(setCount, 10000);

    final ExerciseProgress progress = prepareExerciseProgress(
      sessions: fixture.sessions,
      exerciseId: benchmarkExerciseId,
      now: benchmarkLastSession.add(const Duration(days: 1)),
    );
    expect(progress.sessionCount, 1000);
    expect(progress.bestWeightSeries, hasLength(1000));

    final SetPrefill prefill = prefillForExercise(
      sessions: fixture.sessions,
      exerciseId: benchmarkExerciseId,
      setIndex: benchmarkSetsPerSession - 1,
    );
    expect(prefill.isEmpty, isFalse);
    expect(prefill.reps, isNotNull);
  });

  test('benchmark fixture is a valid importable backup', () {
    final AppData fixture = buildTenThousandSetFixture();
    final String json = buildBackupJson(
      fixture,
      appVersion: appVersion,
      exportedAt: benchmarkLastSession,
    );

    final BackupDocument parsed = parseBackup(json);
    expect(parsed.data.sessions, hasLength(benchmarkSessionCount));
    expect(
      parsed.data.sessions
          .expand((Session session) => session.exercises)
          .expand((SessionExercise exercise) => exercise.sets)
          .length,
      benchmarkSetCount,
    );
  });
}
