import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// System save/open UI boundary (`IO-006`). No broad storage permission and no
/// file path is returned to Dart for import.
abstract interface class BackupFileGateway {
  /// Opens the Android create-document UI. Returns true only after the target
  /// file was written; false means the user cancelled.
  Future<bool> saveExport({required String fileName, required String contents});

  /// Opens the Android open-document UI. Returns the UTF-8 text, or null when
  /// the user cancelled.
  Future<String?> pickImport();
}

class PlatformBackupFileGateway implements BackupFileGateway {
  const PlatformBackupFileGateway();

  static const MethodChannel _channel = MethodChannel('gym_log/backup');

  @override
  Future<bool> saveExport({
    required String fileName,
    required String contents,
  }) async {
    final bool? saved = await _channel.invokeMethod<bool>(
      'saveExport',
      <String, Object?>{'fileName': fileName, 'contents': contents},
    );
    return saved ?? false;
  }

  @override
  Future<String?> pickImport() {
    return _channel.invokeMethod<String>('pickImport');
  }
}

final Provider<BackupFileGateway> backupFileGatewayProvider =
    Provider<BackupFileGateway>((Ref ref) => const PlatformBackupFileGateway());
