import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';

/// JSON encoding/decoding boundary. Production uses [IsolateBackupCodec] so a
/// 10,000-set document never blocks the UI thread (`IO-001`).
abstract interface class BackupCodec {
  Future<String> encode(
    AppData data, {
    required String appVersion,
    required DateTime exportedAt,
  });

  Future<BackupDocument> parse(String text);
}

class IsolateBackupCodec implements BackupCodec {
  const IsolateBackupCodec();

  @override
  Future<String> encode(
    AppData data, {
    required String appVersion,
    required DateTime exportedAt,
  }) {
    return Isolate.run(
      () =>
          buildBackupJson(data, appVersion: appVersion, exportedAt: exportedAt),
    );
  }

  @override
  Future<BackupDocument> parse(String text) async {
    final Object result = await Isolate.run<Object>(() {
      try {
        return parseBackup(text);
      } on BackupError catch (error) {
        return error;
      }
    });
    if (result is BackupError) {
      throw result;
    }
    return result as BackupDocument;
  }
}

final Provider<BackupCodec> backupCodecProvider = Provider<BackupCodec>(
  (Ref ref) => const IsolateBackupCodec(),
);
