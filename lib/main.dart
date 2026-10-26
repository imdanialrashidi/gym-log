import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'data/app_data_controller.dart';
import 'data/app_data_store.dart';
import 'data/app_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolve and read the document while the engine is still starting. The
  // controller consumes this load once; a failed load still exposes the normal
  // retry path, which reads the file again.
  final Future<Directory> supportDirectory = getApplicationSupportDirectory();
  supportDirectory.ignore();
  final Future<File> dataFile = resolveAppDataFile(supportDirectory);
  dataFile.ignore();
  final JsonAppDataStore store = JsonAppDataStore(dataFile);
  final Future<AppData> preloadedDocument = store.load();
  preloadedDocument.ignore();

  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const <String>['Vazirmatn'], license);
  });
  runApp(
    ProviderScope(
      overrides: [
        appSupportDirectoryProvider.overrideWithValue(supportDirectory),
        appDataStoreProvider.overrideWithValue(store),
        appDataPreloaderProvider.overrideWithValue(
          AppDataPreloader(preloadedDocument),
        ),
      ],
      child: const GymLogApp(),
    ),
  );
}
