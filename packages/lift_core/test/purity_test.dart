import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

const Set<String> _allowedDartLibraries = <String>{
  'dart:async',
  'dart:collection',
  'dart:convert',
  'dart:core',
  'dart:math',
  'dart:typed_data',
};

void main() {
  test('lift_core imports only pure Dart and its own package', () async {
    final Uri? libraryUri = await Isolate.resolvePackageUri(
      Uri.parse('package:lift_core/lift_core.dart'),
    );
    expect(libraryUri, isNotNull, reason: 'Could not resolve lift_core.');

    final Directory libDirectory = File.fromUri(libraryUri!).parent;
    final RegExp directive = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );
    final List<String> violations = <String>[];

    for (final File file
        in libDirectory
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.dart'))) {
      for (final RegExpMatch match in directive.allMatches(
        file.readAsStringSync(),
      )) {
        final String uri = match.group(1)!;
        if (uri.startsWith('dart:')) {
          if (!_allowedDartLibraries.contains(uri)) {
            violations.add('${file.path}: forbidden $uri');
          }
        } else if (uri.startsWith('package:') &&
            !uri.startsWith('package:lift_core/')) {
          violations.add('${file.path}: forbidden $uri');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'lift_core must remain pure Dart. Forbidden imports found:\n'
          '${violations.join('\n')}',
    );
  });
}
