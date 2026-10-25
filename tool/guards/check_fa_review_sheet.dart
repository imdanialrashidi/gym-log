import 'dart:convert';
import 'dart:io';

/// CI coverage check for the native-speaker review sheet (`L10N-010`).
///
/// Every non-metadata key in `app_fa.arb` must appear in
/// `docs/l10n/fa-review-sheet.md` with its current Persian text, and the sheet
/// may not contain stale keys.
void main() {
  final Map<String, String> faMessages = _arbMessages(
    'lib/core/l10n/app_fa.arb',
  );
  final Set<String> faKeys = faMessages.keys.toSet();
  final File sheet = File('docs/l10n/fa-review-sheet.md');
  if (!sheet.existsSync()) {
    stderr.writeln('fa review sheet guard failed: ${sheet.path} is missing');
    exitCode = 1;
    return;
  }

  final Map<String, String> reviewed = <String, String>{};
  for (final String line in sheet.readAsLinesSync()) {
    final RegExpMatch? match = RegExp(
      r'^\| `([^`]+)` \| [^|]* \| (.*?) \| [^|]* \|',
    ).firstMatch(line);
    if (match == null) {
      continue;
    }
    reviewed[match.group(1)!] = match.group(2)!.replaceAll(r'\|', '|');
  }

  final List<String> errors = <String>[];
  for (final String key in faKeys.difference(reviewed.keys.toSet())) {
    errors.add('missing from review sheet: $key');
  }
  for (final String key in reviewed.keys.toSet().difference(faKeys)) {
    errors.add('stale review-sheet key: $key');
  }
  for (final String key in faKeys.intersection(reviewed.keys.toSet())) {
    if (reviewed[key] != faMessages[key]) {
      errors.add('stale fa text for "$key"; regenerate the sheet');
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('fa review sheet guard failed:');
    for (final String error in errors) {
      stderr.writeln('  - $error');
    }
    stderr.writeln(
      'Run `dart run tool/fa_review_sheet.dart` and review the diff.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'fa review sheet guard passed: ${faKeys.length} Persian strings covered.',
  );
}

Map<String, String> _arbMessages(String path) {
  final File file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('fa review sheet guard failed: $path is missing');
    exitCode = 1;
    return <String, String>{};
  }
  final Object? decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    stderr.writeln('fa review sheet guard failed: $path is not a JSON object');
    exitCode = 1;
    return <String, String>{};
  }
  return <String, String>{
    for (final MapEntry<String, dynamic> entry in decoded.entries)
      if (!entry.key.startsWith('@') && entry.value is String)
        entry.key: entry.value as String,
  };
}
