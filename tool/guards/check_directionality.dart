import 'dart:io';

/// Fails when app source hard-codes a physical left/right layout direction
/// instead of using direction-aware APIs (`L10N-001`, `L10N-004`).
///
/// The progress chart is the only file allowed to pin its time axis LTR:
/// time deliberately runs left to right in both text directions (ADR-0005).
/// Physical spacing/alignment checks still apply there.
const Set<String> _allowedLtrFiles = <String>{
  'lib/features/progress/presentation/progress_chart.dart',
};

final List<_Rule> _rules = <_Rule>[
  _Rule(
    'physical EdgeInsets left/right',
    RegExp(
      r'EdgeInsets(?:Directional)?\.only\([^)]*\b(?:left|right)\s*:',
      dotAll: true,
    ),
  ),
  _Rule('physical EdgeInsets.fromLTRB', RegExp(r'EdgeInsets\.fromLTRB\(')),
  _Rule(
    'physical Positioned left/right',
    RegExp(r'Positioned\(\s*(?:left|right)\s*:', dotAll: true),
  ),
  _Rule(
    'physical Alignment',
    RegExp(
      r'Alignment\.(?:center|top|bottom)?(?:Left|Right)|Alignment\.(?:top|bottom)(?:Left|Right)',
    ),
  ),
  _Rule('physical TextAlign', RegExp(r'TextAlign\.(?:left|right)')),
  _Rule(
    'physical corner radius',
    RegExp(
      r'BorderRadius\.only\([^)]*\b(?:topLeft|topRight|bottomLeft|bottomRight)\s*:',
      dotAll: true,
    ),
  ),
  _Rule(
    'hard-coded LTR direction',
    RegExp(r'textDirection:\s*TextDirection\.ltr'),
    allowLtrFile: true,
  ),
];

void main() {
  final Directory lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('direction guard failed: lib/ is missing');
    exitCode = 1;
    return;
  }

  final List<String> errors = <String>[];
  final List<File> files =
      lib
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => file.path.endsWith('.dart'))
          .where((File file) => !file.path.contains('/generated/'))
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));

  for (final File file in files) {
    final String path = file.path.replaceAll('\\', '/');
    final List<String> lines = file.readAsLinesSync();
    for (final _Rule rule in _rules) {
      if (rule.allowLtrFile && _allowedLtrFiles.contains(path)) {
        continue;
      }
      for (final RegExpMatch match in rule.pattern.allMatches(
        lines.join('\n'),
      )) {
        final int line =
            '\n'.allMatches(lines.join('\n').substring(0, match.start)).length +
            1;
        errors.add('$path:$line: ${rule.name}: ${match.group(0)!.trim()}');
      }
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('direction guard failed:');
    for (final String error in errors) {
      stderr.writeln('  - $error');
    }
    stderr.writeln(
      'Use EdgeInsetsDirectional, AlignmentDirectional, TextAlign.start/end, '
      'BorderRadiusDirectional, and locale-driven direction instead.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'direction guard passed: ${files.length} Dart files use no physical '
    'left/right layout constants.',
  );
}

class _Rule {
  const _Rule(this.name, this.pattern, {this.allowLtrFile = false});

  final String name;
  final RegExp pattern;
  final bool allowLtrFile;
}
