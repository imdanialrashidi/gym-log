import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/photo_storage.dart';
import 'package:lift_core/lift_core.dart';

void main() {
  test('JSON export contains no photo payload or file reference', () async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'gym_log_photo_export_',
    );
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final FilePhotoStorage storage = FilePhotoStorage(() async => directory);
    await storage.importExercisePhoto(
      exerciseId: 'exercise-1',
      source: File('test/fixtures/photos/geotagged.jpg'),
    );
    await storage.importSessionPhoto(
      sessionId: 'session-1',
      source: File('test/fixtures/photos/geotagged.jpg'),
    );

    final AppData data = AppData(
      exercises: <Exercise>[
        Exercise(
          id: 'exercise-1',
          name: 'Bench Press',
          createdAt: DateTime.utc(2026, 10),
        ),
      ],
      sessions: <Session>[
        Session(
          id: 'session-1',
          startedAt: DateTime.utc(2026, 10, 20, 10),
          endedAt: DateTime.utc(2026, 10, 20, 11),
        ),
      ],
    );

    final String export = buildBackupJson(
      data,
      appVersion: '0.1.0',
      exportedAt: DateTime.utc(2026, 10, 25),
    );
    final String lower = export.toLowerCase();

    expect(lower.contains('photo'), isFalse);
    expect(export.contains('exercise_exercise-1'), isFalse);
    expect(export.contains('session_session-1'), isFalse);
    expect(export.contains('data:image'), isFalse);
    final Map<String, Object?> decoded =
        jsonDecode(export) as Map<String, Object?>;
    expect(
      decoded.keys,
      unorderedEquals(<String>[
        'schemaVersion',
        'appVersion',
        'exportedAt',
        'generator',
        'exercises',
        'programs',
        'sessions',
        'settings',
      ]),
    );
  });

  test('backup and device-transfer rules exclude every app file domain', () {
    final String manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest.contains('android:allowBackup="false"'), isTrue);
    expect(manifest.contains('android:fullBackupContent="false"'), isTrue);
    expect(manifest.contains('android:dataExtractionRules='), isTrue);

    final String rules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();
    for (final String section in <String>['cloud-backup', 'device-transfer']) {
      final RegExp block = RegExp('<$section>(.*?)</$section>', dotAll: true);
      final RegExpMatch? match = block.firstMatch(rules);
      expect(match, isNotNull, reason: '$section rules are required');
      for (final String domain in <String>[
        'root',
        'file',
        'database',
        'sharedpref',
        'external',
      ]) {
        expect(
          RegExp('<exclude\\s+domain="$domain"\\s+path="\\."\\s*/>')
              .hasMatch(match!.group(1)!),
          isTrue,
          reason: '$section must exclude $domain',
        );
      }
    }
  });
}
