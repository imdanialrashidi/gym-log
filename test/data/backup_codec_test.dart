import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/backup_codec.dart';
import 'package:lift_core/lift_core.dart';

import '../support/backup_data.dart';

void main() {
  test('isolate codec returns typed rejection errors', () async {
    const BackupCodec codec = IsolateBackupCodec();
    await expectLater(
      codec.parse('not json'),
      throwsA(
        isA<BackupError>().having(
          (BackupError error) => error.code,
          'code',
          BackupErrorCode.corrupt,
        ),
      ),
    );
  });

  test('isolate codec round-trips a 10,000-set export', () async {
    const BackupCodec codec = IsolateBackupCodec();
    final Stopwatch stopwatch = Stopwatch()..start();
    final String text = await codec.encode(
      backupTenThousandSetData(),
      appVersion: '0.1.0',
      exportedAt: backupTestExportedAt,
    );
    final BackupDocument document = await codec.parse(text);
    stopwatch.stop();

    expect(document.data.sessions.single.exercises, hasLength(100));
    expect(
      document.data.sessions.single.exercises
          .expand((SessionExercise exercise) => exercise.sets)
          .length,
      10000,
    );
    expect(text.length, lessThan(maxBackupBytes));
    // Encoding and validation happen in an isolate. The bound below is a
    // pathological-regression signal, not a device UI measurement.
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
  });
}
