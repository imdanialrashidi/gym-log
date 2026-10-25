import 'dart:io';

/// Keeps the Jalali library inside the CalendarService adapter (`L10N-005`,
/// Section 26). Features, data, and store code must never import it.
const String _allowedImportFile = 'lib/core/calendar/calendar_service.dart';

void main() {
  final List<String> errors = <String>[];
  final List<File> files =
      <File>[
          ...Directory('lib').listSync(recursive: true).whereType<File>(),
          ...Directory('packages/lift_core')
              .listSync(recursive: true)
              .whereType<File>(),
        ].where((File file) => file.path.endsWith('.dart')).toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));

  for (final File file in files) {
    final String path = file.path.replaceAll('\\', '/');
    final String contents = file.readAsStringSync();
    if (!contents.contains('package:shamsi_date/')) {
      continue;
    }
    if (path == _allowedImportFile) {
      continue;
    }
    errors.add('$path imports package:shamsi_date directly');
  }

  if (errors.isNotEmpty) {
    stderr.writeln('calendar boundary guard failed:');
    for (final String error in errors) {
      stderr.writeln('  - $error');
    }
    stderr.writeln(
      'Import the Jalali library only in $_allowedImportFile; features and '
      'data use CalendarService.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'calendar boundary guard passed: shamsi_date stays inside CalendarService.',
  );
}
