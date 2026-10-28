import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';

/// The sample is a published contract for users and AI assistants; it must
/// keep importing as the format evolves.
void main() {
  test('the published import sample stays valid and program-only', () {
    final String text = File('docs/sample-import/program-sample.json')
        .readAsStringSync();
    final BackupDocument document = parseBackup(text);

    expect(document.data.exercises, hasLength(3));
    expect(document.data.programs, hasLength(1));
    expect(document.data.programs.single.days, hasLength(2));
    expect(document.data.sessions, isEmpty);
    expect(document.data.settings.weightUnit, WeightUnit.kilograms);
  });
}
