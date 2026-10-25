import 'dart:convert';
import 'dart:io';

import 'package:gym_log/app/app_info.dart';
import 'package:lift_core/lift_core.dart';

import 'benchmark_fixture.dart';

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
  final String? outputPath = _outputPath(arguments);
  final File thresholdsFile = File('tool/benchmarks/thresholds.json');
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
  };

  final List<Map<String, Object?>> results = <Map<String, Object?>>[];
  bool failed = false;

  stdout.writeln(
    'Performance micro-benchmarks: ${fixture.sessions.length} sessions, '
    '$benchmarkSetCount sets, $measuredIterations measured iterations.',
  );
  stdout.writeln(
    '${'ID'.padRight(14)}${'metric'.padRight(20)}'
    '${'median'.padLeft(11)}${'p90'.padLeft(11)}'
    '${'budget'.padLeft(11)}  result',
  );

  for (final Map<String, Object?> spec in specs) {
    final String id = spec['id']! as String;
    final String metric = spec['metric']! as String;
    final num budgetMs = spec['budgetMs']! as num;
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
    final bool passed = medianMs <= budgetMs;
    failed = failed || !passed;

    stdout.writeln(
      '${id.padRight(14)}${metric.padRight(20)}'
      '${'${medianMs.toStringAsFixed(3)} ms'.padLeft(11)}'
      '${'${p90Ms.toStringAsFixed(3)} ms'.padLeft(11)}'
      '${'$budgetMs ms'.padLeft(11)}  ${passed ? 'PASS' : 'FAIL'}',
    );

    results.add(<String, Object?>{
      'id': id,
      'metric': metric,
      'description': spec['description'],
      'budgetMs': budgetMs,
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

String? _outputPath(List<String> arguments) {
  for (int i = 0; i < arguments.length; i++) {
    if (arguments[i] == '--output') {
      if (i + 1 >= arguments.length) {
        throw ArgumentError('--output needs a path');
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
