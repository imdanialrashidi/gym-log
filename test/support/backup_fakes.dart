import 'package:flutter/services.dart';
import 'package:gym_log/data/backup_codec.dart';
import 'package:gym_log/data/backup_gateway.dart';
import 'package:lift_core/lift_core.dart';

/// Runs the pure codec inline so widget tests do not wait on a real isolate.
class InlineBackupCodec implements BackupCodec {
  const InlineBackupCodec();

  @override
  Future<String> encode(
    AppData data, {
    required String appVersion,
    required DateTime exportedAt,
  }) async {
    return buildBackupJson(
      data,
      appVersion: appVersion,
      exportedAt: exportedAt,
    );
  }

  @override
  Future<BackupDocument> parse(String text) async => parseBackup(text);
}

/// Fakes the Android save/open UI for widget tests.
class FakeBackupFileGateway implements BackupFileGateway {
  FakeBackupFileGateway({
    this.importText,
    this.saveResult = true,
    this.pickError,
  });

  String? importText;
  bool saveResult;
  PlatformException? pickError;
  int saveCalls = 0;
  int pickCalls = 0;
  String? savedFileName;
  String? savedContents;

  @override
  Future<bool> saveExport({
    required String fileName,
    required String contents,
  }) async {
    saveCalls += 1;
    savedFileName = fileName;
    savedContents = contents;
    return saveResult;
  }

  @override
  Future<String?> pickImport() async {
    pickCalls += 1;
    final PlatformException? error = pickError;
    if (error != null) {
      throw error;
    }
    return importText;
  }
}
