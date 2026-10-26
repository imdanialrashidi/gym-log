import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// The one app-private support directory lookup for the whole process.
///
/// Startup used to resolve this directory separately for the data document,
/// the export reminder, photos, and the pending-photo marker. Each lookup is a
/// platform-channel round trip, so one shared future lets the app overlap a
/// single lookup with engine startup and reuse its result everywhere.
final Provider<Future<Directory>> appSupportDirectoryProvider =
    Provider<Future<Directory>>((Ref ref) => getApplicationSupportDirectory());

/// Resolves a file directly inside the app-private support directory.
Future<File> appSupportFile(Ref ref, String fileName) async {
  final Directory directory = await ref.watch(appSupportDirectoryProvider);
  return File('${directory.path}${Platform.pathSeparator}$fileName');
}

/// Resolves the canonical data document from an already-running lookup.
///
/// `main` starts this before `runApp` so path resolution overlaps engine
/// startup; tests and other callers can use the provider-backed default.
Future<File> resolveAppDataFile(Future<Directory> supportDirectory) async {
  final Directory directory = await supportDirectory;
  return File('${directory.path}${Platform.pathSeparator}gym_log_data.json');
}
