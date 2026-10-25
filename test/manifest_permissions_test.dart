import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no manifest requests notification permission (SET-004)', () {
    final List<String> manifests = <String>[
      'android/app/src/main/AndroidManifest.xml',
      'android/app/src/debug/AndroidManifest.xml',
      'android/app/src/profile/AndroidManifest.xml',
    ];
    for (final String path in manifests) {
      final String contents = File(path).readAsStringSync();
      expect(
        contents.contains('android.permission.POST_NOTIFICATIONS'),
        isFalse,
        reason: '$path must not request notification permission.',
      );
      expect(
        contents.contains('android.permission.ACCESS_NOTIFICATION_POLICY'),
        isFalse,
        reason: '$path must not request notification policy access.',
      );
      for (final String permission in <String>[
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.WRITE_EXTERNAL_STORAGE',
        'android.permission.MANAGE_EXTERNAL_STORAGE',
        'android.permission.READ_MEDIA_IMAGES',
        'android.permission.READ_MEDIA_VIDEO',
        'android.permission.READ_MEDIA_AUDIO',
        'android.permission.READ_MEDIA_VISUAL_USER_SELECTED',
        'android.permission.ACCESS_MEDIA_LOCATION',
        'android.permission.CAMERA',
      ]) {
        expect(
          contents.contains(permission),
          isFalse,
          reason:
              '$path must not request broad storage permission $permission.',
        );
      }
    }
  });

  test('release signing has no debug fallback and reads secrets only', () {
    final String build = File('android/app/build.gradle.kts')
        .readAsStringSync();

    expect(
      build.contains('signingConfigs.getByName("debug")'),
      isFalse,
      reason: 'A debug signing fallback would break updates for every user.',
    );
    for (final String variable in <String>[
      'GYM_LOG_KEYSTORE_PATH',
      'GYM_LOG_KEYSTORE_PASSWORD',
      'GYM_LOG_KEY_ALIAS',
      'GYM_LOG_KEY_PASSWORD',
    ]) {
      expect(
        build.contains('System.getenv("$variable")'),
        isTrue,
        reason: 'Signing value $variable must come from the environment.',
      );
    }
    expect(
      RegExp(r'signingConfig\s*=\s*signingConfigs\.findByName\("release"\)')
          .hasMatch(build),
      isTrue,
      reason: 'Release builds must use the secrets-backed signing config.',
    );
    expect(
      RegExp(
        r'tasks\.matching\s*\{\s*it\.name in releaseTaskNames\s*\}'
        r'\s*\.configureEach\s*\{[^}]*dependsOn\([^)]*'
        r'"verifyReleaseSigning"[^)]*\)',
        dotAll: true,
      ).hasMatch(build),
      isTrue,
      reason: 'assembleRelease and bundleRelease must depend on verifyReleaseSigning.',
    );
  });

  test('main manifest keeps the offline/local-only posture', () {
    final String main = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(main.contains('android.permission.INTERNET'), isFalse);
    expect(main.contains('android:allowBackup="false"'), isTrue);
    expect(main.contains('android:fullBackupContent="false"'), isTrue);
    expect(main.contains('android:dataExtractionRules='), isTrue);
    expect(
      RegExp(r'<uses-permission').hasMatch(main),
      isFalse,
      reason:
          'Photos must use the system picker/camera intent, so the main '
          'manifest needs no permission at all (PHO-001).',
    );
  });
}
