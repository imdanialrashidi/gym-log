import 'dart:convert';

import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

import 'backup_support.dart';

Map<String, Object?> _decode(String text) {
  return (jsonDecode(text) as Map).cast<String, Object?>();
}

List<Object?> _listAt(Map<String, Object?> json, String key) {
  return (json[key] as List).cast<Object?>();
}

Map<String, Object?> _mapAt(Object? value) {
  return (value as Map).cast<String, Object?>();
}

Matcher _backupError(BackupErrorCode code, {String? field}) {
  return isA<BackupError>()
      .having((BackupError error) => error.code, 'code', code)
      .having((BackupError error) => error.field, 'field', field ?? anything);
}

void main() {
  group('export format', () {
    test('writes required fields, stable ids, explicit nulls, no photos', () {
      final AppData data = sampleData();
      final String encoded = buildBackupJson(
        data,
        appVersion: testAppVersion,
        exportedAt: testExportedAt,
      );
      final Map<String, Object?> json = _decode(encoded);

      expect(json.keys.toList(), <String>[
        'schemaVersion',
        'appVersion',
        'exportedAt',
        'generator',
        'exercises',
        'programs',
        'sessions',
        'settings',
      ]);
      expect(json['schemaVersion'], backupSchemaVersion);
      expect(json['appVersion'], testAppVersion);
      expect(json['exportedAt'], '2026-10-22T12:00:00.000Z');
      expect(json['generator'], backupGenerator);

      final Map<String, Object?> exercise = _mapAt(
        _listAt(json, 'exercises')[1],
      );
      expect(exercise['id'], 'exercise-2');
      expect(exercise['searchTerm'], isNull);
      expect(exercise['muscleGroup'], isNull);
      expect(exercise['defaultRepMin'], isNull);
      expect(exercise['defaultRepMax'], isNull);
      expect(exercise['archivedAt'], isNull);

      final Map<String, Object?> program = _mapAt(_listAt(json, 'programs')[0]);
      expect(program['archivedAt'], isNull);

      final Map<String, Object?> session = _mapAt(_listAt(json, 'sessions')[0]);
      expect(session['endedAt'], '2026-09-04T18:30:00.000Z');
      expect(session['programDayId'], 'day-1');
      expect(session['note'], 'Good day');
      final Map<String, Object?> sessionExercise = _mapAt(
        (session['exercises'] as List).single,
      );
      expect(sessionExercise['targetSets'], 3);
      expect(sessionExercise['repMin'], 8);
      expect(sessionExercise['repMax'], 12);
      expect(sessionExercise['note'], 'Felt strong');
      final Map<String, Object?> set = _mapAt(
        (sessionExercise['sets'] as List).single,
      );
      expect(set['id'], 'set-1');
      expect(set['rir'], 2);

      expect(encoded.contains('photo'), isFalse);
      expect(encoded.contains('data:image'), isFalse);
      expect(encoded.contains('base64'), isFalse);
    });

    test('parses its own export back to equivalent data', () {
      final String encoded = buildBackupJson(
        sampleData(),
        appVersion: testAppVersion,
        exportedAt: testExportedAt,
      );

      final BackupDocument document = parseBackup(encoded);

      expect(document.schemaVersion, backupSchemaVersion);
      expect(document.appVersion, testAppVersion);
      expect(document.exportedAt, testExportedAt);
      expect(document.generator, backupGenerator);
      expect(
        buildBackupJson(
          document.data,
          appVersion: document.appVersion,
          exportedAt: document.exportedAt,
          generator: document.generator,
        ),
        encoded,
      );
    });

    test('ignores unknown top-level and entity fields', () {
      final Map<String, Object?> json = sampleBackupMap();
      json['future'] = <String, Object?>{'anything': true};
      final Map<String, Object?> exercise = _mapAt(
        _listAt(json, 'exercises')[0],
      );
      exercise['futureExerciseField'] = 'ignored';

      final BackupDocument document = parseBackup(jsonEncode(json));

      expect(document.data.exercises.first.id, 'exercise-1');
    });

    test('10,000-set export and import stay below size and time bounds', () {
      final AppData data = tenThousandSetData();
      final Stopwatch stopwatch = Stopwatch()..start();
      final String encoded = buildBackupJson(
        data,
        appVersion: testAppVersion,
        exportedAt: testExportedAt,
      );
      final BackupDocument parsed = parseBackup(encoded);
      stopwatch.stop();

      expect(encoded.length, lessThan(maxBackupBytes));
      expect(
        parsed.data.sessions.single.exercises.fold<int>(
          0,
          (int sum, SessionExercise exercise) => sum + exercise.sets.length,
        ),
        10000,
      );
      // Pure codec evidence only; device UI responsiveness stays UNPROVEN.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 8)));
    });
  });

  group('import rejection', () {
    test('rejects an empty file', () {
      expect(
        () => parseBackup('   '),
        throwsA(_backupError(BackupErrorCode.empty)),
      );
    });

    test('rejects an oversized file before decoding', () {
      final String text = 'a' * (maxBackupBytes + 1);
      expect(
        () => parseBackup(text),
        throwsA(_backupError(BackupErrorCode.tooLarge)),
      );
    });

    test('rejects deeply nested JSON', () {
      final String open = '[' * (maxBackupNestingDepth + 1);
      final String close = ']' * (maxBackupNestingDepth + 1);
      expect(
        () => parseBackup('{"schemaVersion": 1, "nested": $open$close}'),
        throwsA(_backupError(BackupErrorCode.tooDeep)),
      );
    });

    test('rejects dense JSON before it can amplify into decoded objects', () {
      final String dense =
          '{"schemaVersion": 1, "dense": ['
          '${'{}' * (maxBackupContainers + 1)}]}';
      expect(
        () => parseBackup(dense),
        throwsA(_backupError(BackupErrorCode.tooLarge)),
      );
    });

    test('rejects truncated JSON', () {
      final String encoded = buildBackupJson(
        sampleData(),
        appVersion: testAppVersion,
        exportedAt: testExportedAt,
      );
      expect(
        () => parseBackup(encoded.substring(0, encoded.length - 20)),
        throwsA(_backupError(BackupErrorCode.corrupt)),
      );
    });

    test('rejects corrupt JSON', () {
      expect(
        () => parseBackup('definitely not json'),
        throwsA(_backupError(BackupErrorCode.corrupt)),
      );
    });

    test('rejects a non-object root', () {
      expect(
        () => parseBackup('[1, 2, 3]'),
        throwsA(_backupError(BackupErrorCode.rootNotObject)),
      );
    });

    test('rejects a mistyped schemaVersion', () {
      final Map<String, Object?> json = sampleBackupMap();
      json['schemaVersion'] = '1';
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          _backupError(BackupErrorCode.invalidField, field: 'schemaVersion'),
        ),
      );
    });

    test('rejects a mistyped entity field', () {
      final Map<String, Object?> json = sampleBackupMap();
      final Map<String, Object?> exercise = _mapAt(
        _listAt(json, 'exercises')[0],
      );
      exercise['incrementGrams'] = 'heavy';
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          _backupError(BackupErrorCode.invalidField, field: 'exercises[0]'),
        ),
      );
    });

    test('rejects a duplicate id across entity types', () {
      final Map<String, Object?> json = sampleBackupMap();
      final List<Object?> programs = _listAt(json, 'programs');
      final Map<String, Object?> program = _mapAt(programs.single);
      program['id'] = 'exercise-1';
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          _backupError(BackupErrorCode.duplicateId, field: 'programs[0].id'),
        ),
      );
    });

    test('rejects a plan item referencing a missing exercise', () {
      final Map<String, Object?> json = sampleBackupMap();
      final Map<String, Object?> program = _mapAt(_listAt(json, 'programs')[0]);
      final Map<String, Object?> day = _mapAt((program['days'] as List).single);
      final Map<String, Object?> item = _mapAt((day['items'] as List).single);
      item['exerciseId'] = 'missing-exercise';
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          _backupError(
            BackupErrorCode.orphanReference,
            field: 'programs[0].days[0].items[0].exerciseId',
          ),
        ),
      );
    });

    test('rejects a session exercise referencing a missing exercise', () {
      final Map<String, Object?> json = sampleBackupMap();
      final Map<String, Object?> session = _mapAt(_listAt(json, 'sessions')[0]);
      final Map<String, Object?> exercise = _mapAt(
        (session['exercises'] as List).single,
      );
      exercise['exerciseId'] = 'missing-exercise';
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(_backupError(BackupErrorCode.orphanReference)),
      );
    });

    test('rejects absurd set values', () {
      final Map<String, Object?> json = sampleBackupMap();
      final Map<String, Object?> session = _mapAt(_listAt(json, 'sessions')[0]);
      final Map<String, Object?> exercise = _mapAt(
        (session['exercises'] as List).single,
      );
      final Map<String, Object?> set = _mapAt(
        (exercise['sets'] as List).single,
      );
      set['weightGrams'] = -1;
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(_backupError(BackupErrorCode.absurdValue)),
      );
    });

    test('rejects an absurd RIR value', () {
      final Map<String, Object?> json = sampleBackupMap();
      final Map<String, Object?> session = _mapAt(_listAt(json, 'sessions')[0]);
      final Map<String, Object?> exercise = _mapAt(
        (session['exercises'] as List).single,
      );
      final Map<String, Object?> set = _mapAt(
        (exercise['sets'] as List).single,
      );
      set['rir'] = 99;
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(_backupError(BackupErrorCode.absurdValue)),
      );
    });

    test('rejects an out-of-range timestamp', () {
      final Map<String, Object?> json = sampleBackupMap();
      final Map<String, Object?> session = _mapAt(_listAt(json, 'sessions')[0]);
      session['startedAt'] = '9999-01-01T00:00:00.000Z';
      session['endedAt'] = '9999-01-01T01:00:00.000Z';
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          _backupError(
            BackupErrorCode.absurdValue,
            field: 'sessions[0].startedAt',
          ),
        ),
      );
    });

    test('rejects a non-UTC exportedAt', () {
      final Map<String, Object?> json = sampleBackupMap();
      json['exportedAt'] = '2026-10-22T12:00:00';
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          _backupError(BackupErrorCode.invalidField, field: 'exportedAt'),
        ),
      );
    });

    test('accepts a zero offset and rejects a nonzero offset', () {
      final Map<String, Object?> json = sampleBackupMap();
      json['exportedAt'] = '2026-10-22T12:00:00.000+00:00';
      expect(parseBackup(jsonEncode(json)).exportedAt, testExportedAt);

      json['exportedAt'] = '2026-10-22T12:00:00.000+03:30';
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          _backupError(BackupErrorCode.invalidField, field: 'exportedAt'),
        ),
      );
    });

    test('rejects an absurd exercise increment', () {
      final Map<String, Object?> json = sampleBackupMap();
      final Map<String, Object?> exercise = _mapAt(
        _listAt(json, 'exercises')[0],
      );
      exercise['incrementGrams'] = 9223372036854775807;
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          _backupError(BackupErrorCode.absurdValue, field: 'exercises[0]'),
        ),
      );
    });

    test('rejects control characters in the app version header', () {
      final Map<String, Object?> json = sampleBackupMap();
      json['appVersion'] = '0.1.0\n\u202Eevil';
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          _backupError(BackupErrorCode.invalidField, field: 'appVersion'),
        ),
      );
    });

    test('rejects an ID outside the stable-ID character set', () {
      final Map<String, Object?> json = sampleBackupMap();
      final Map<String, Object?> exercise = _mapAt(
        _listAt(json, 'exercises')[0],
      );
      exercise['id'] = 'exercise\n\u202E';
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          _backupError(BackupErrorCode.invalidField, field: 'exercises[0].id'),
        ),
      );
    });

    test('rejects control characters in a reference ID', () {
      final Map<String, Object?> json = sampleBackupMap();
      final Map<String, Object?> session = _mapAt(_listAt(json, 'sessions')[0]);
      final Map<String, Object?> exercise = _mapAt(
        (session['exercises'] as List).single,
      );
      exercise['exerciseId'] = 'exercise\n\u202E';
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          _backupError(
            BackupErrorCode.invalidField,
            field: 'sessions[0].exercises[0].exerciseId',
          ),
        ),
      );
    });

    test('rejects a newer schemaVersion with the update-app signal', () {
      final Map<String, Object?> json = sampleBackupMap();
      json['schemaVersion'] = backupSchemaVersion + 1;
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(
          allOf(
            _backupError(BackupErrorCode.newerVersion, field: 'schemaVersion'),
            isA<BackupError>().having(
              (BackupError error) => error.supportedVersion,
              'supportedVersion',
              backupSchemaVersion,
            ),
          ),
        ),
      );
    });

    test('rejects an unsupported older schemaVersion', () {
      final Map<String, Object?> json = sampleBackupMap();
      json['schemaVersion'] = 0;
      expect(
        () => parseBackup(jsonEncode(json)),
        throwsA(_backupError(BackupErrorCode.unsupportedVersion)),
      );
    });
  });
}
