/// Public app identity written into exports. Keep in sync with `pubspec.yaml`;
/// `test/data/export_reminder_test.dart` reads the pubspec version and compares
/// it with [appVersion].
const String appVersion = '0.2.1';

/// Top-level export generator marker.
const String appGenerator = 'gym-log';

/// Public project links shown on the About screen (`SET-005`). The donate
/// destination is owner-controlled and can change without affecting data.
const String appAuthorName = 'Danial Rashidi';
const String appWebsiteUrl = 'https://danialrashidi.ir';
const String appSourceUrl = 'https://github.com/imdanialrashidi/gym-log';
const String appDonateUrl = 'https://github.com/sponsors/imdanialrashidi';
