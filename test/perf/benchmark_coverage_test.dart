import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/benchmarks/run_benchmarks.dart';

/// The gate must not be able to skip a metric by deleting its threshold entry.
void main() {
  test('thresholds cover every expected benchmark exactly once', () {
    final Map<String, Object?> json = (jsonDecode(
      File('tool/benchmarks/thresholds.json').readAsStringSync(),
    ) as Map).cast<String, Object?>();
    final List<Map<String, Object?>> specs = (json['benchmarks']! as List)
        .cast<Map<String, Object?>>();

    for (final MapEntry<String, String> expected
        in expectedBenchmarks.entries) {
      final List<Map<String, Object?>> matches = specs
          .where((Map<String, Object?> spec) => spec['id'] == expected.key)
          .toList();
      expect(matches, hasLength(1), reason: 'ID ${expected.key}');
      expect(matches.single['metric'], expected.value);
      final Object? floor = matches.single['regressionBudgetMs'];
      expect(floor, isA<num>(), reason: 'floor for ${expected.key}');
      expect(floor! as num, greaterThan(0));
    }
    for (final Map<String, Object?> spec in specs) {
      expect(
        specs.where((Map<String, Object?> other) {
          return other['metric'] == spec['metric'];
        }),
        hasLength(1),
        reason: 'metric ${spec['metric']} must be measured once',
      );
    }
  });
}
