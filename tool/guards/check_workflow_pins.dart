import 'dart:io';

/// Fails when a GitHub workflow uses a movable action tag or when a
/// Flutter-based workflow's toolchain variables drift from
/// `tool/toolchain.env`.
///
/// A tag such as `@v4` can be moved after review; a full 40-hex commit SHA
/// cannot. This guard makes the pinning rule in `docs/QUALITY.md` executable.
/// Non-Flutter workflows (for example the static Pages deploy) do not need
/// Flutter pins, but every workflow still needs full-SHA action pins.
void main() {
  final List<String> violations = <String>[];
  final Map<String, String> env = _readEnv(File('tool/toolchain.env'));

  for (final String key in <String>[
    'FLUTTER_VERSION',
    'FLUTTER_ARCHIVE',
    'FLUTTER_SHA256',
  ]) {
    if (!env.containsKey(key) || env[key]!.trim().isEmpty) {
      violations.add('tool/toolchain.env is missing $key');
    }
  }

  final File versionFile = File('.flutter-version');
  if (!versionFile.existsSync()) {
    violations.add('.flutter-version is missing');
  } else if (env['FLUTTER_VERSION'] != null &&
      versionFile.readAsStringSync().trim() != env['FLUTTER_VERSION']) {
    violations.add(
      '.flutter-version does not match FLUTTER_VERSION in tool/toolchain.env',
    );
  }

  final Directory workflows = Directory('.github/workflows');
  if (!workflows.existsSync()) {
    violations.add('.github/workflows is missing');
  } else {
    final List<File> files =
        workflows
            .listSync()
            .whereType<File>()
            .where((File file) => file.path.endsWith('.yml'))
            .toList()
          ..sort((File a, File b) => a.path.compareTo(b.path));
    if (files.isEmpty) {
      violations.add('.github/workflows has no .yml files');
    }
    for (final File file in files) {
      final String name = file.uri.pathSegments.last;
      final String text = file.readAsStringSync();
      _checkPins(text, name, violations);
      if (_isFlutterWorkflow(text)) {
        _checkToolchain(text, name, env, violations);
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('Workflow pin guard failed:');
    for (final String violation in violations) {
      stderr.writeln('FAIL: $violation');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Workflow pin guard passed: every action uses a full SHA and every '
    'Flutter workflow matches tool/toolchain.env.',
  );
}

/// A workflow is Flutter-based when it mentions Flutter anywhere. This is
/// intentionally conservative: a false positive requires the pins, while a
/// false negative would let an unpinned toolchain ship.
bool _isFlutterWorkflow(String text) {
  return RegExp(r'flutter', caseSensitive: false).hasMatch(text);
}

void _checkPins(String text, String name, List<String> violations) {
  final RegExp usesLine = RegExp(
    r'^\s*(?:-\s*)?uses:\s*(\S+)',
    multiLine: true,
  );
  for (final RegExpMatch match in usesLine.allMatches(text)) {
    final String target = match.group(1)!;
    if (target.startsWith('./')) {
      continue;
    }
    final RegExp pinned = RegExp(r'^[^@\s]+@[0-9a-f]{40}$');
    if (!pinned.hasMatch(target)) {
      violations.add('$name: $target is not pinned to a 40-hex commit SHA');
    }
  }
}

void _checkToolchain(
  String text,
  String name,
  Map<String, String> env,
  List<String> violations,
) {
  for (final String key in <String>[
    'FLUTTER_VERSION',
    'FLUTTER_ARCHIVE',
    'FLUTTER_SHA256',
  ]) {
    final String? expected = env[key];
    if (expected == null) {
      continue;
    }
    final RegExpMatch? match = RegExp(
      '^\\s*$key:\\s*(\\S+)\\s*\$',
      multiLine: true,
    ).firstMatch(text);
    if (match == null) {
      violations.add('$name is missing $key');
      continue;
    }
    if (match.group(1) != expected) {
      violations.add('$name has $key that does not match tool/toolchain.env');
    }
  }
}

Map<String, String> _readEnv(File file) {
  if (!file.existsSync()) {
    return <String, String>{};
  }
  final Map<String, String> values = <String, String>{};
  for (final String line in file.readAsLinesSync()) {
    final String trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final int separator = trimmed.indexOf('=');
    if (separator <= 0) {
      continue;
    }
    values[trimmed.substring(0, separator)] = trimmed.substring(separator + 1);
  }
  return values;
}
