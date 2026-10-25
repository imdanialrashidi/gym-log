import 'dart:convert';
import 'dart:io';

const List<String> _locales = <String>['en', 'fa'];

void main() {
  final Map<String, Map<String, String>> messages =
      <String, Map<String, String>>{
        for (final String locale in _locales)
          locale: _readMessages('lib/core/l10n/app_$locale.arb', locale),
      };
  if (exitCode != 0) {
    return;
  }

  final Set<String> templateKeys = messages['en']!.keys.toSet();
  final List<String> errors = <String>[];

  for (final String locale in _locales.skip(1)) {
    final Set<String> keys = messages[locale]!.keys.toSet();
    for (final String key in templateKeys.difference(keys)) {
      errors.add('$locale is missing key "$key"');
    }
    for (final String key in keys.difference(templateKeys)) {
      errors.add('$locale has extra key "$key"');
    }
  }

  for (final String key in templateKeys) {
    final String? en = messages['en']![key];
    final String? fa = messages['fa']![key];
    if (en == null || fa == null) {
      continue;
    }
    final Set<String> enPlaceholders = _placeholders(en);
    final Set<String> faPlaceholders = _placeholders(fa);
    for (final String placeholder in enPlaceholders.difference(
      faPlaceholders,
    )) {
      errors.add('fa "$key" is missing placeholder {$placeholder}');
    }
    for (final String placeholder in faPlaceholders.difference(
      enPlaceholders,
    )) {
      errors.add('en "$key" is missing placeholder {$placeholder}');
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('l10n guard failed:');
    for (final String error in errors) {
      stderr.writeln('  - $error');
    }
    stderr.writeln('Every user-facing key must exist in both fa and en.');
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'l10n guard passed: ${templateKeys.length} keys in both en and fa.',
  );
}

Map<String, String> _readMessages(String path, String locale) {
  final File file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('l10n guard failed: missing $path');
    exitCode = 1;
    return <String, String>{};
  }

  final Object? decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    stderr.writeln('l10n guard failed: $path is not a JSON object');
    exitCode = 1;
    return <String, String>{};
  }

  final String? declaredLocale = decoded['@@locale'] as String?;
  if (declaredLocale != locale) {
    stderr.writeln(
      'l10n guard failed: $path declares @@locale "$declaredLocale", expected "$locale"',
    );
    exitCode = 1;
  }

  final Map<String, String> messages = <String, String>{};
  for (final MapEntry<String, dynamic> entry in decoded.entries) {
    if (entry.key.startsWith('@')) {
      continue;
    }
    final Object? value = entry.value;
    if (value is! String || value.trim().isEmpty) {
      stderr.writeln(
        'l10n guard failed: $path key "${entry.key}" must be a non-empty string',
      );
      exitCode = 1;
      continue;
    }
    messages[entry.key] = value;
  }
  return messages;
}

Set<String> _placeholders(String message) {
  return RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}')
      .allMatches(message)
      .map((RegExpMatch match) => match.group(1)!)
      .toSet();
}
