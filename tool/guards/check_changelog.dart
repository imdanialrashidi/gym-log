import 'dart:io';

/// Enforces release discipline (`DAT-008`): every release has a CHANGELOG
/// entry, an Android-visible build number that increases, and an explicit
/// schema note the release workflow uses to mark schema-changing builds as
/// pre-release.
///
/// Entry format (newest first):
///
///   ## [Unreleased]
///
///   ## [1.2.3] - 2026-10-25
///
///   Build: 7
///   Schema: none
///
/// Usage:
///   dart run tool/guards/check_changelog.dart
///   dart run tool/guards/check_changelog.dart --tag v1.2.3 --print-notes
///   dart run tool/guards/check_changelog.dart --print-schema
void main(List<String> arguments) {
  final List<String> errors = <String>[];
  final _Options options;
  try {
    options = _Options.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln('CHANGELOG guard failed: ${error.message}');
    exitCode = 64;
    return;
  }

  final _Version version = _readVersion(errors);
  final List<_Entry> entries = _readEntries(errors);

  _validate(entries: entries, version: version, errors: errors);

  _Entry? selected;
  if (version.value.isNotEmpty) {
    selected = _findEntry(entries, version.value);
  }
  if (options.tag != null) {
    final String tagVersion = options.tag!.startsWith('v')
        ? options.tag!.substring(1)
        : options.tag!;
    if (version.value.isNotEmpty && tagVersion != version.value) {
      errors.add(
        'tag ${options.tag} does not match pubspec version '
        '${version.value}',
      );
    }
    selected = _findEntry(entries, tagVersion);
    if (selected == null) {
      errors.add('tag ${options.tag} has no CHANGELOG entry');
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('CHANGELOG guard failed:');
    for (final String error in errors) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }

  final _Entry current = selected!;
  final String schema = _isNoSchemaChange(current.schema ?? '')
      ? 'none'
      : 'changed';

  switch (options.output) {
    case _Output.printVersion:
      stdout.writeln(version.value);
    case _Output.printBuild:
      stdout.writeln(version.build);
    case _Output.printSchema:
      stdout.writeln(schema);
    case _Output.printNotes:
      stdout.writeln(current.releaseNotes);
    case _Output.summary:
      stdout.writeln(
        'CHANGELOG guard passed: ${version.value} (build ${version.build}), '
        'schema $schema.',
      );
  }
}

_Entry? _findEntry(List<_Entry> entries, String label) {
  for (final _Entry entry in entries) {
    if (entry.label == label) {
      return entry;
    }
  }
  return null;
}

bool _isNoSchemaChange(String value) => value.trim().toLowerCase() == 'none';

void _validate({
  required List<_Entry> entries,
  required _Version version,
  required List<String> errors,
}) {
  if (version.value.isEmpty) {
    return;
  }
  if (entries.isEmpty) {
    errors.add('no release entries found in CHANGELOG.md');
    return;
  }
  if (entries.first.label != 'Unreleased') {
    errors.add('the first CHANGELOG heading must be "## [Unreleased]"');
  }
  final List<_Entry> releases = <_Entry>[
    for (final _Entry entry in entries)
      if (entry.label != 'Unreleased') entry,
  ];
  if (releases.isEmpty) {
    errors.add('CHANGELOG.md has no versioned release entry');
    return;
  }
  if (releases.first.label != version.value) {
    errors.add(
      'the newest release entry must be ${version.value} (pubspec version), '
      'found ${releases.first.label}',
    );
  }

  _Entry? current;
  int? previousBuild;
  for (final _Entry entry in releases) {
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(entry.label)) {
      errors.add('release heading "${entry.label}" is not a semantic version');
      continue;
    }
    if (entry.build == null) {
      errors.add('${entry.label} has no "Build: <number>" line');
    }
    if (entry.schema == null) {
      errors.add('${entry.label} has no "Schema: <note>" line');
    }
    final int? build = entry.build;
    if (build != null && build <= 0) {
      errors.add('${entry.label} Build must be positive');
    }
    if (build != null && previousBuild != null && build >= previousBuild) {
      errors.add(
        'build numbers must increase with each release: '
        '${entry.label} has $build after $previousBuild',
      );
    }
    if (build != null) {
      previousBuild = build;
    }
    if (entry.label == version.value) {
      current = entry;
    }
  }

  if (current == null) {
    errors.add('CHANGELOG.md has no entry for ${version.value}');
    return;
  }
  if (current.build != null && current.build != version.build) {
    errors.add(
      'pubspec version ${version.value}+${version.build} does not match '
      'CHANGELOG Build: ${current.build}',
    );
  }
}

_Version _readVersion(List<String> errors) {
  final File pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    errors.add('pubspec.yaml is missing');
    return const _Version(value: '', build: 0);
  }
  final RegExpMatch? match = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)(?:\+(\d+))?\s*$',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());
  if (match == null) {
    errors.add('pubspec.yaml version must be X.Y.Z+N');
    return const _Version(value: '', build: 0);
  }
  return _Version(
    value: match.group(1)!,
    build: int.parse(match.group(2) ?? '0'),
  );
}

List<_Entry> _readEntries(List<String> errors) {
  final File changelog = File('CHANGELOG.md');
  if (!changelog.existsSync()) {
    errors.add('CHANGELOG.md is missing');
    return const <_Entry>[];
  }

  final List<_Entry> entries = <_Entry>[];
  String? label;
  List<String> body = <String>[];
  final RegExp heading = RegExp(r'^## \[([^\]]+)\]');
  for (final String line in changelog.readAsLinesSync()) {
    final RegExpMatch? match = heading.firstMatch(line);
    if (match != null) {
      if (label != null) {
        entries.add(_Entry.parse(label, body));
      }
      label = match.group(1)!;
      body = <String>[];
      continue;
    }
    if (label != null) {
      body.add(line);
    }
  }
  if (label != null) {
    entries.add(_Entry.parse(label, body));
  }
  return entries;
}

class _Entry {
  _Entry({
    required this.label,
    required this.build,
    required this.schema,
    required this.releaseNotes,
  });

  factory _Entry.parse(String label, List<String> body) {
    int? build;
    String? schema;
    final List<String> notes = <String>[];
    for (final String line in body) {
      final String trimmed = line.trim();
      final RegExpMatch? buildMatch = RegExp(r'^Build:\s*(\d+)$')
          .firstMatch(trimmed);
      if (buildMatch != null) {
        build = build ?? int.tryParse(buildMatch.group(1)!);
        continue;
      }
      final RegExpMatch? schemaMatch = RegExp(r'^Schema:\s*(\S.*)$')
          .firstMatch(trimmed);
      if (schemaMatch != null) {
        schema = schema ?? schemaMatch.group(1)!.trim();
        continue;
      }
      notes.add(line);
    }
    while (notes.isNotEmpty && notes.first.trim().isEmpty) {
      notes.removeAt(0);
    }
    while (notes.isNotEmpty && notes.last.trim().isEmpty) {
      notes.removeLast();
    }
    return _Entry(
      label: label,
      build: build,
      schema: schema,
      releaseNotes: notes.join('\n'),
    );
  }

  final String label;
  final int? build;
  final String? schema;
  final String releaseNotes;
}

class _Version {
  const _Version({required this.value, required this.build});

  final String value;
  final int build;
}

enum _Output { summary, printVersion, printBuild, printSchema, printNotes }

class _Options {
  const _Options({required this.tag, required this.output});

  factory _Options.parse(List<String> arguments) {
    String? tag;
    _Output output = _Output.summary;
    int outputs = 0;

    for (int i = 0; i < arguments.length; i++) {
      final String argument = arguments[i];
      switch (argument) {
        case '--tag':
          if (i + 1 >= arguments.length) {
            throw const FormatException('--tag needs a value');
          }
          tag = arguments[++i];
        case '--print-version':
          output = _Output.printVersion;
          outputs++;
        case '--print-build':
          output = _Output.printBuild;
          outputs++;
        case '--print-schema':
          output = _Output.printSchema;
          outputs++;
        case '--print-notes':
          output = _Output.printNotes;
          outputs++;
        default:
          throw FormatException('unknown argument "$argument"');
      }
    }
    if (outputs > 1) {
      throw const FormatException('choose only one --print option');
    }
    if (tag != null && !RegExp(r'^v\d+\.\d+\.\d+$').hasMatch(tag)) {
      throw const FormatException('--tag must look like v1.2.3');
    }
    return _Options(tag: tag, output: output);
  }

  final String? tag;
  final _Output output;
}
