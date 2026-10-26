import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/app_data_store.dart';
import 'package:gym_log/data/backup_codec.dart';
import 'package:gym_log/data/backup_flow.dart';
import 'package:gym_log/data/backup_gateway.dart';
import 'package:gym_log/data/export_reminder.dart';
import 'package:lift_core/lift_core.dart';

import '../support/backup_data.dart';
import '../support/backup_fakes.dart';
import '../support/memory_export_reminder_store.dart';

Map<String, Object?> _sampleMap() {
  return buildBackupMap(
    backupSampleData(),
    appVersion: '0.1.0',
    exportedAt: backupTestExportedAt,
  );
}

Map<String, Object?> _mapAt(Object? value) {
  return (value as Map).cast<String, Object?>();
}

List<Object?> _listAt(Map<String, Object?> json, String key) {
  return (json[key] as List).cast<Object?>();
}

String _invalidTruncated() {
  final String valid = backupJson();
  return valid.substring(0, valid.length - 20);
}

String _invalidCorrupt() => 'not a json document';

String _invalidMistyped() {
  final Map<String, Object?> json = _sampleMap();
  final Map<String, Object?> exercise = _mapAt(_listAt(json, 'exercises')[0]);
  exercise['incrementGrams'] = 'heavy';
  return jsonEncode(json);
}

String _invalidDuplicate() {
  final Map<String, Object?> json = _sampleMap();
  _mapAt(_listAt(json, 'programs')[0])['id'] = 'exercise-1';
  return jsonEncode(json);
}

String _invalidOrphan() {
  final Map<String, Object?> json = _sampleMap();
  final Map<String, Object?> program = _mapAt(_listAt(json, 'programs')[0]);
  final Map<String, Object?> day = _mapAt((program['days'] as List).single);
  final Map<String, Object?> item = _mapAt((day['items'] as List).single);
  item['exerciseId'] = 'missing-exercise';
  return jsonEncode(json);
}

String _invalidAbsurd() {
  final Map<String, Object?> json = _sampleMap();
  final Map<String, Object?> session = _mapAt(_listAt(json, 'sessions')[0]);
  final Map<String, Object?> exercise = _mapAt(
    (session['exercises'] as List).single,
  );
  final Map<String, Object?> set = _mapAt((exercise['sets'] as List).single);
  set['weightGrams'] = -1;
  return jsonEncode(json);
}

String _invalidOverLimitName() {
  final Map<String, Object?> json = _sampleMap();
  _mapAt(_listAt(json, 'exercises')[0])['name'] =
      'x' * (maximumExerciseNameLength + 1);
  return jsonEncode(json);
}

String _invalidSortOrder() {
  final Map<String, Object?> json = _sampleMap();
  final Map<String, Object?> program = _mapAt(_listAt(json, 'programs')[0]);
  final Map<String, Object?> day = _mapAt((program['days'] as List).single);
  day['sortOrder'] = maximumSortOrder + 1;
  return jsonEncode(json);
}

String _invalidNewer() {
  final Map<String, Object?> json = _sampleMap();
  json['schemaVersion'] = backupSchemaVersion + 1;
  return jsonEncode(json);
}

String _invalidDeep() {
  final String open = '[' * (maxBackupNestingDepth + 1);
  final String close = ']' * (maxBackupNestingDepth + 1);
  return '{"schemaVersion": 1, "nested": $open$close}';
}

String _invalidOversized() => 'a' * (maxBackupBytes + 1);

Future<void> _expectRejected({
  required String text,
  required BackupErrorCode code,
}) async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'gym_log_import_reject_',
  );
  addTearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });
  final File file = File('${directory.path}${Platform.pathSeparator}data.json');
  await file.writeAsString(jsonEncode(backupSampleData().toJson()));
  final List<int> before = await file.readAsBytes();

  final ProviderContainer container = ProviderContainer.test(
    overrides: [
      appDataStoreProvider.overrideWithValue(
        JsonAppDataStore(Future<File>.value(file)),
      ),
      backupFileGatewayProvider.overrideWithValue(
        FakeBackupFileGateway(importText: text),
      ),
      backupCodecProvider.overrideWithValue(const InlineBackupCodec()),
      exportReminderStoreProvider.overrideWithValue(
        MemoryExportReminderStore(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(appDataControllerProvider.future);
  final BackupFlow flow = container.read(backupFlowProvider);

  await expectLater(
    flow.pickImport(),
    throwsA(
      isA<ImportFailure>().having(
        (ImportFailure failure) => failure.error?.code,
        'code',
        code,
      ),
    ),
  );

  expect(await file.readAsBytes(), before);
  expect(
    container.read(appDataControllerProvider).requireValue.exercises,
    hasLength(2),
  );
}

void main() {
  final List<(String, String Function(), BackupErrorCode)> cases =
      <(String, String Function(), BackupErrorCode)>[
        ('truncated', _invalidTruncated, BackupErrorCode.corrupt),
        ('corrupt', _invalidCorrupt, BackupErrorCode.corrupt),
        ('mistyped', _invalidMistyped, BackupErrorCode.invalidField),
        ('duplicate id', _invalidDuplicate, BackupErrorCode.duplicateId),
        ('orphan reference', _invalidOrphan, BackupErrorCode.orphanReference),
        ('absurd value', _invalidAbsurd, BackupErrorCode.absurdValue),
        ('over-limit name', _invalidOverLimitName, BackupErrorCode.absurdValue),
        (
          'over-limit sort order',
          _invalidSortOrder,
          BackupErrorCode.absurdValue,
        ),
        ('newer schemaVersion', _invalidNewer, BackupErrorCode.newerVersion),
        ('deeply nested', _invalidDeep, BackupErrorCode.tooDeep),
        ('oversized', _invalidOversized, BackupErrorCode.tooLarge),
      ];

  for (final (String name, String Function() build, BackupErrorCode code)
      in cases) {
    test('rejects a $name file without changing the database', () async {
      await _expectRejected(text: build(), code: code);
    });
  }
}
