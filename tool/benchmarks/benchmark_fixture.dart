import 'package:lift_core/lift_core.dart';

/// Deterministic fixture for the performance budgets (`NFR-PERF-003`,
/// `NFR-PERF-005`, `NFR-PERF-006`).
///
/// One exercise receives every set so the prefill query scans the same
/// 10,000-set history the app would have after years of logging, the chart
/// aggregates 1,000 finished sessions, and JSON export serializes the full
/// fixture. No dates, IDs, or values are random: a rerun measures the same
/// document.
const String benchmarkExerciseId = 'benchmark-exercise';
const int benchmarkSessionCount = 1000;
const int benchmarkSetsPerSession = 10;
const int benchmarkSetCount = benchmarkSessionCount * benchmarkSetsPerSession;

final DateTime benchmarkFirstSession = DateTime.utc(2023, 1, 1, 18);

/// The newest session start. Chart ranges are measured relative to this.
final DateTime benchmarkLastSession = benchmarkFirstSession.add(
  const Duration(days: benchmarkSessionCount - 1),
);

AppData buildTenThousandSetFixture() {
  final Exercise exercise = Exercise(
    id: benchmarkExerciseId,
    name: 'Bench Press',
    createdAt: benchmarkFirstSession.subtract(const Duration(days: 1)),
  );

  final List<Session> sessions = <Session>[
    for (
      int sessionIndex = 0;
      sessionIndex < benchmarkSessionCount;
      sessionIndex++
    )
      _session(sessionIndex),
  ];

  return AppData(exercises: <Exercise>[exercise], sessions: sessions);
}

Session _session(int sessionIndex) {
  final DateTime startedAt = benchmarkFirstSession.add(
    Duration(days: sessionIndex),
  );
  final int weightGrams = 60000 + (sessionIndex % 60) * 1000;
  final int reps = 5 + (sessionIndex % 6);

  return Session(
    id: 'benchmark-session-$sessionIndex',
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(hours: 1)),
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'benchmark-session-exercise-$sessionIndex',
        exerciseId: benchmarkExerciseId,
        sortOrder: 0,
        targetSets: benchmarkSetsPerSession,
        repMin: 5,
        repMax: 10,
        sets: <SetLog>[
          for (int setIndex = 0; setIndex < benchmarkSetsPerSession; setIndex++)
            SetLog(
              id: 'benchmark-set-$sessionIndex-$setIndex',
              setIndex: setIndex,
              weightGrams: weightGrams,
              reps: reps,
              rir: (sessionIndex + setIndex) % 4,
              loggedAt: startedAt.add(Duration(minutes: 5 * setIndex)),
            ),
        ],
      ),
    ],
  );
}
