import 'dart:io';

import 'package:gym_log/app/app_info.dart';
import 'package:lift_core/lift_core.dart';

import 'benchmark_fixture.dart';

/// Writes the 10,000-set benchmark fixture as a valid JSON backup so the owner
/// can import it on the reference device for `NFR-PERF-004`–`006`.
///
/// Usage:
///   dart run tool/benchmarks/write_device_fixture.dart --output `<path>`
///
/// The file contains only synthetic training data: no account, photos, or
/// secrets. Import it through Settings, then run docs/perf/REFERENCE_DEVICE.md.
void main(List<String> arguments) {
  final int index = arguments.indexOf('--output');
  if (index == -1 || index + 1 >= arguments.length) {
    stderr.writeln(
      'Usage: dart run tool/benchmarks/write_device_fixture.dart '
      '--output <path>',
    );
    exitCode = 64;
    return;
  }

  final AppData fixture = buildTenThousandSetFixture();
  final String json = buildBackupJson(
    fixture,
    appVersion: appVersion,
    exportedAt: benchmarkLastSession.toUtc(),
  );

  final File output = File(arguments[index + 1]);
  output.parent.createSync(recursive: true);
  output.writeAsStringSync('$json\n');

  stdout.writeln(
    'Wrote ${output.path}: ${fixture.sessions.length} sessions, '
    '$benchmarkSetCount sets, ${json.length} bytes.',
  );
}
