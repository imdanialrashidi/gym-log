import 'dart:convert';
import 'dart:io';

/// Regenerates `docs/l10n/fa-review-sheet.md` from the ARB resources.
///
/// The sheet gives a native speaker every Persian string with its English
/// reference and the screen/context that uses it (`L10N-010`). The guard in
/// `tool/guards/check_fa_review_sheet.dart` fails when a key is missing.
void main() {
  final Map<String, String> fa = _messages('lib/core/l10n/app_fa.arb');
  final Map<String, String> en = _messages('lib/core/l10n/app_en.arb');
  final List<String> keys = fa.keys.toList()..sort();

  final StringBuffer output = StringBuffer()
    ..writeln('# Persian copy review sheet')
    ..writeln()
    ..writeln(
      'Native-speaker review aid for `L10N-010`. Every Persian string in '
      '`lib/core/l10n/app_fa.arb` appears exactly once. The English column is '
      'the source message, not a translation; the context column names the '
      'screen or shared surface. Review tone, clarity, and natural button '
      'wording; do not translate marketing claims.',
    )
    ..writeln()
    ..writeln('Regenerate with `dart run tool/fa_review_sheet.dart`.')
    ..writeln()
    ..writeln(
      '| Key | Screen / context | Persian (fa) | English reference | Notes |',
    )
    ..writeln('|---|---|---|---|---|');

  for (final String key in keys) {
    final String faValue = fa[key]!;
    final String enValue = en[key] ?? '';
    output.writeln(
      '| `$key` | ${_screenFor(key)} | ${_cell(faValue)} | '
      '${_cell(enValue)} | ${_notes(faValue, enValue)} |',
    );
  }

  final File file = File('docs/l10n/fa-review-sheet.md');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(output.toString());
  stdout.writeln('Wrote ${file.path} with ${keys.length} strings.');
}

Map<String, String> _messages(String path) {
  final Object? decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw StateError('$path is not a JSON object');
  }
  return <String, String>{
    for (final MapEntry<String, dynamic> entry in decoded.entries)
      if (!entry.key.startsWith('@') && entry.value is String)
        entry.key: entry.value as String,
  };
}

String _screenFor(String key) {
  final String lower = key.toLowerCase();
  const Set<String> shellKeys = <String>{
    'apptitle',
    'workouttab',
    'programstab',
    'historytab',
    'progresstab',
    'settingstitle',
  };
  if (shellKeys.contains(lower)) {
    return 'App shell / navigation';
  }
  if (lower.startsWith('progression')) {
    return 'Workout';
  }
  if (lower.startsWith('prbadge') ||
      lower.startsWith('prweight') ||
      lower.startsWith('prreps') ||
      lower.startsWith('pre1rm')) {
    return 'Workout / history';
  }
  if (lower == 'reprangesummary') {
    return 'Workout / history';
  }
  if (lower == 'planitemsummary') {
    return 'Programs / workout / history';
  }
  if (lower == 'errorreprange') {
    return 'Exercises / programs';
  }
  if (lower == 'errorsetsrange') {
    return 'Programs';
  }
  if (lower == 'noexercisesinsession' ||
      lower == 'noexercisesavailableforsession') {
    return 'Workout';
  }
  if (lower == 'nosetslogged') {
    return 'History / session';
  }
  if (lower == 'errorminexceedsmax') {
    return 'Exercises';
  }

  const List<(String, List<String>)> groups = <(String, List<String>)>[
    (
      'Settings / backup',
      <String>[
        'language',
        'digit',
        'defaultincrement',
        'resttimer',
        'backup',
        'export',
        'import',
        'unitkilograms',
        'unitpounds',
        'weightunit',
      ],
    ),
    (
      'Progress',
      <String>['progress', 'progresschart', 'progressrange', 'e1rm'],
    ),
    (
      'History / session',
      <String>[
        'history',
        'session',
        'calendar',
        'trained',
        'note',
        'undo',
        'editset',
        'deleteset',
        'setactions',
        'setdeleted',
      ],
    ),
    (
      'Programs',
      <String>[
        'program',
        'planitem',
        'targetsets',
        'setsrange',
        'addday',
        'newday',
        'editday',
        'dayname',
        'deleteday',
        'daynotfound',
        'nodays',
        'noplan',
      ],
    ),
    (
      'Exercises',
      <String>[
        'exercise',
        'muscle',
        'search',
        'increment',
        'lookup',
        'repm',
        'duplicate',
        'archive',
        'repmin',
        'repmax',
        'defaultrep',
        'errorname',
        'errorenter',
        'errorrep',
        'errorincrement',
      ],
    ),
    (
      'Workout',
      <String>[
        'workout',
        'start',
        'active',
        'finish',
        'addset',
        'setnumber',
        'setsaved',
        'rir',
        'warmup',
        'logset',
        'weight',
        'reps',
        'noexercises',
        'progression',
        'decrease',
        'increase',
      ],
    ),
    (
      'Shared controls',
      <String>[
        'cancel',
        'save',
        'delete',
        'close',
        'retry',
        'rename',
        'reorder',
        'edit',
        'moreactions',
        'error',
        'clearsearch',
      ],
    ),
  ];

  for (final (String screen, List<String> needles) in groups) {
    for (final String needle in needles) {
      if (lower.contains(needle)) {
        return screen;
      }
    }
  }
  return 'General';
}

String _cell(String value) {
  return value.replaceAll('|', r'\|').replaceAll('\n', ' ');
}

String _notes(String fa, String en) {
  final Set<String> placeholders = _placeholders(en);
  final List<String> notes = <String>[];
  if (placeholders.isNotEmpty) {
    notes.add(
      'Placeholders: ${placeholders.map((String p) => '{$p}').join(', ')}',
    );
  }
  if (en.contains('plural,')) {
    notes.add('Plural');
  }
  if (notes.isEmpty) {
    return 'Review tone and clarity.';
  }
  return notes.join('; ');
}

Set<String> _placeholders(String message) {
  return RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}')
      .allMatches(message)
      .map((RegExpMatch match) => match.group(1)!)
      .toSet();
}
