import 'dart:io';

final Map<RegExp, String> _forbidden = <RegExp, String>{
  RegExp(r'deleteDatabase\s*\(', caseSensitive: false): 'database deletion',
  RegExp(r'DROP\s+(TABLE|DATABASE)', caseSensitive: false): 'destructive SQL',
  RegExp(r'PRAGMA\s+writable_schema', caseSensitive: false): 'schema overwrite',
};

void main() {
  final List<Directory> roots = <Directory>[
    Directory('lib'),
    Directory('packages/lift_core/lib'),
  ];
  final List<String> violations = <String>[];

  for (final Directory root in roots) {
    if (!root.existsSync()) {
      // A missing root means the guard cannot prove the invariant; fail
      // closed instead of scanning nothing and reporting success.
      violations.add('required scan root is missing: ${root.path}');
      continue;
    }
    for (final File file
        in root
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.dart'))) {
      final List<String> lines = file.readAsLinesSync();
      for (int index = 0; index < lines.length; index++) {
        for (final MapEntry<RegExp, String> rule in _forbidden.entries) {
          if (rule.key.hasMatch(lines[index])) {
            violations.add(
              '${file.path}:${index + 1}: ${rule.value} '
              '("${lines[index].trim()}")',
            );
          }
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Destructive-reset guard failed (DAT-002 forbids deleting and recreating '
      'the database). A missing scan root also fails: the guard cannot prove '
      'the invariant without the source:',
    );
    for (final String violation in violations) {
      stderr.writeln('  - $violation');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Destructive-reset guard passed: no reset pattern in lib/ or '
    'packages/lift_core/lib/.',
  );
}
