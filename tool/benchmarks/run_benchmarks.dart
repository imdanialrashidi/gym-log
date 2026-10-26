import 'dart:convert';
import 'dart:io';

import 'package:gym_log/app/app_info.dart';
import 'package:lift_core/lift_core.dart';

import 'benchmark_fixture.dart';

/// Benchmark IDs the gate must always run. A missing entry in
/// `thresholds.json` is a failure, not a silently skipped check.
const Map<String, String> expectedBenchmarks = <String, String>{
  'NFR-PERF-003': 'prefill_query',
  'NFR-PERF-005': 'chart_aggregation',
  'NFR-PERF-006': 'export_json',
  'CI-PR-001': 'single_set_pr',
  'CI-PR-002': 'full_pr_map',
  'CI-MUT-001': 'document_validation',
  'CI-STATS-001': 'weekly_stats',
};

/// Runs the CI micro-benchmarks and fails when a median exceeds its budget.
///
/// Usage (from the repository root):
///   dart run tool/benchmarks/run_benchmarks.dart [--output <path>]
///
/// These are algorithmic budgets on the pinned Dart VM. They are not device
/// measurements: `NFR-PERF-001`, `002`, `004`, and the device portion of
/// `005`/`006` stay `UNPROVEN` until the reference-device run in
/// `docs/perf/`.
Future<void> main(List<String> arguments) async {
  final String? outputPath = _option(arguments, '--output');
  final File thresholdsFile = File(
    _option(arguments, '--thresholds') ?? 'tool/benchmarks/thresholds.json',
  );
  final Map<String, Object?> thresholds =
      jsonDecode(await thresholdsFile.readAsString()) as Map<String, Object?>;
  final int warmupIterations = thresholds['warmupIterations']! as int;
  final int measuredIterations = thresholds['measuredIterations']! as int;
  final List<Map<String, Object?>> specs = (thresholds['benchmarks']! as List)
      .cast<Map<String, Object?>>();

  final Stopwatch fixtureTimer = Stopwatch()..start();
  final AppData fixture = buildTenThousandSetFixture();
  fixtureTimer.stop();
  _verifyFixture(fixture);

  final List<BodyWeightEntry> weights = <BodyWeightEntry>[
    for (int index = 0; index < 60; index++)
      BodyWeightEntry(
        id: 'benchmark-weight-$index',
        weightGrams: 80000 + (index % 5) * 250,
        recordedAt: benchmarkFirstSession.add(Duration(days: index * 7)),
      ),
  ];
  final Map<String, _Benchmark> benchmarks = <String, _Benchmark>{
    'prefill_query': _Benchmark(
      run: () => prefillForExercise(
        sessions: fixture.sessions,
        exerciseId: benchmarkExerciseId,
        setIndex: benchmarkSetsPerSession - 1,
      ),
    ),
    'chart_aggregation': _Benchmark(
      run: () => prepareExerciseProgress(
        sessions: fixture.sessions,
        exerciseId: benchmarkExerciseId,
        now: benchmarkLastSession.add(const Duration(days: 1)),
      ),
    ),
    'export_json': _Benchmark(
      run: () => buildBackupJson(
        fixture,
        appVersion: appVersion,
        exportedAt: benchmarkLastSession,
      ),
    ),
    'single_set_pr': _Benchmark(
      run: () => personalRecordTypesForSet(
        sessions: fixture.sessions,
        exerciseId: benchmarkExerciseId,
        setId:
            'benchmark-set-${benchmarkSessionCount - 1}-'
            '${benchmarkSetsPerSession - 1}',
      ),
    ),
    'full_pr_map': _Benchmark(
      run: () => personalRecordsForExercise(
        sessions: fixture.sessions,
        exerciseId: benchmarkExerciseId,
      ),
    ),
    'document_validation': _Benchmark(run: () => fixture.copyWith()),
    'weekly_stats': _Benchmark(
      run: () => (
        recentWeekStats(
          sessions: fixture.sessions,
          exercises: fixture.exercises,
          bodyWeights: weights,
          now: benchmarkLastSession.add(const Duration(days: 1)),
        ),
        latestFinishedSessionStats(
          fixture.sessions,
          exercises: fixture.exercises,
          now: benchmarkLastSession.add(const Duration(days: 1)),
        ),
      ),
    ),
  };

  for (final MapEntry<String, String> expected in expectedBenchmarks.entries) {
    final List<Map<String, Object?>> matches = specs
        .where((Map<String, Object?> spec) => spec['id'] == expected.key)
        .toList();
    if (matches.length != 1) {
      stderr.writeln(
        'FAIL: expected benchmark missing or duplicated: ${expected.key}',
      );
      exitCode = 1;
      return;
    }
    if (matches.single['metric'] != expected.value) {
      stderr.writeln(
        'FAIL: ${expected.key} must measure ${expected.value}, '
        'found ${matches.single['metric']}',
      );
      exitCode = 1;
      return;
    }
    if (!benchmarks.containsKey(expected.value)) {
      stderr.writeln('FAIL: expected benchmark missing: ${expected.value}');
      exitCode = 1;
      return;
    }
  }

  final List<Map<String, Object?>> results = <Map<String, Object?>>[];
  bool failed = false;

  stdout.writeln(
    'Performance micro-benchmarks: ${fixture.sessions.length} sessions, '
    '$benchmarkSetCount sets, $measuredIterations measured iterations.',
  );
  stdout.writeln(
    '${'ID'.padRight(14)}${'metric'.padRight(20)}'
    '${'median'.padLeft(11)}${'p90'.padLeft(11)}'
    '${'budget'.padLeft(11)}${'floor'.padLeft(9)}  result',
  );

  for (final Map<String, Object?> spec in specs) {
    final String id = spec['id']! as String;
    final String metric = spec['metric']! as String;
    final num budgetMs = spec['budgetMs']! as num;
    final num? regressionBudgetMs = spec['regressionBudgetMs'] as num?;
    final _Benchmark benchmark = benchmarks[metric]!;

    for (int i = 0; i < warmupIterations; i++) {
      benchmark.run();
    }
    final List<double> samplesMs = <double>[];
    Object? lastResult;
    for (int i = 0; i < measuredIterations; i++) {
      final Stopwatch stopwatch = Stopwatch()..start();
      lastResult = benchmark.run();
      stopwatch.stop();
      samplesMs.add(stopwatch.elapsedMicroseconds / 1000);
    }
    if (lastResult == null) {
      throw StateError('Benchmark $metric produced no result');
    }

    samplesMs.sort();
    final double medianMs = _median(samplesMs);
    final double p90Ms = samplesMs[(samplesMs.length * 9 / 10).ceil() - 1];
    final bool withinSpecBudget = medianMs <= budgetMs;
    final bool withinRegressionFloor =
        regressionBudgetMs == null || medianMs <= regressionBudgetMs;
    final bool passed = withinSpecBudget && withinRegressionFloor;
    failed = failed || !passed;

    stdout.writeln(
      '${id.padRight(14)}${metric.padRight(20)}'
      '${'${medianMs.toStringAsFixed(3)} ms'.padLeft(11)}'
      '${'${p90Ms.toStringAsFixed(3)} ms'.padLeft(11)}'
      '${'$budgetMs ms'.padLeft(11)}'
      '${'${regressionBudgetMs ?? '-'} ms'.padLeft(9)}'
      '  ${passed ? 'PASS' : 'FAIL'}',
    );

    results.add(<String, Object?>{
      'id': id,
      'metric': metric,
      'description': spec['description'],
      'budgetMs': budgetMs,
      'regressionBudgetMs': regressionBudgetMs,
      'medianMs': double.parse(medianMs.toStringAsFixed(3)),
      'p90Ms': double.parse(p90Ms.toStringAsFixed(3)),
      'minMs': double.parse(samplesMs.first.toStringAsFixed(3)),
      'maxMs': double.parse(samplesMs.last.toStringAsFixed(3)),
      'result': passed ? 'PASS' : 'FAIL',
    });
  }

  if (outputPath != null) {
    final File output = File(outputPath);
    await output.parent.create(recursive: true);
    await output.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'dartVersion': Platform.version,
        'fixture': <String, Object?>{'sessions': fixture.sessions.length, 'sets': benchmarkSetCount, 'exerciseId': benchmarkExerciseId, 'fixtureBuildMs': double.parse((fixtureTimer.elapsedMicroseconds / 1000).toStringAsFixed(1))},
        'warmupIterations': warmupIterations,
        'measuredIterations': measuredIterations,
        'benchmarks': results,
      })}\n',
    );
    stdout.writeln('Wrote $outputPath');
  }

  if (failed) {
    stderr.writeln(
      'Performance micro-benchmark budget exceeded. See docs/perf/.',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('All performance micro-benchmark budgets passed.');
}

void _verifyFixture(AppData fixture) {
  int setCount = 0;
  for (final Session session in fixture.sessions) {
    for (final SessionExercise exercise in session.exercises) {
      setCount += exercise.sets.length;
    }
  }
  if (setCount != benchmarkSetCount) {
    throw StateError('Benchmark fixture has $setCount sets');
  }
  final ExerciseProgress progress = prepareExerciseProgress(
    sessions: fixture.sessions,
    exerciseId: benchmarkExerciseId,
    now: benchmarkLastSession.add(const Duration(days: 1)),
  );
  if (progress.sessionCount != benchmarkSessionCount ||
      progress.bestWeightSeries.length != benchmarkSessionCount) {
    throw StateError('Benchmark fixture does not produce 1,000 chart points');
  }
  if (prefillForExercise(
    sessions: fixture.sessions,
    exerciseId: benchmarkExerciseId,
    setIndex: 0,
  ).isEmpty) {
    throw StateError('Benchmark fixture has no prefill history');
  }
}

double _median(List<double> sortedSamples) {
  final int middle = sortedSamples.length ~/ 2;
  if (sortedSamples.length.isOdd) {
    return sortedSamples[middle];
  }
  return (sortedSamples[middle - 1] + sortedSamples[middle]) / 2;
}

String? _option(List<String> arguments, String name) {
  for (int i = 0; i < arguments.length; i++) {
    if (arguments[i] == name) {
      if (i + 1 >= arguments.length) {
        throw ArgumentError('$name needs a path');
      }
      return arguments[i + 1];
    }
  }
  return null;
}

class _Benchmark {
  const _Benchmark({required this.run});

  final Object Function() run;
}
