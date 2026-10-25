import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('Vazirmatn', <String>[
    'assets/fonts/Vazirmatn-Regular.ttf',
    'assets/fonts/Vazirmatn-Medium.ttf',
    'assets/fonts/Vazirmatn-Bold.ttf',
  ]);
  await _loadFont('MaterialIcons', <String>[_materialIconsPath()]);
  await testMain();
}

Future<void> _loadFont(String family, List<String> paths) async {
  final FontLoader loader = FontLoader(family);
  for (final String path in paths) {
    final File file = File(path);
    if (!file.existsSync()) {
      throw StateError('Test font is missing: $path');
    }
    final Uint8List bytes = await file.readAsBytes();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

String _materialIconsPath() {
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    final String path =
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf';
    if (File(path).existsSync()) {
      return path;
    }
  }

  final Directory cacheDirectory = File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent;
  final String fallback =
      '${cacheDirectory.path}/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf';
  if (File(fallback).existsSync()) {
    return fallback;
  }

  throw StateError(
    'MaterialIcons-Regular.otf was not found. Set FLUTTER_ROOT to the '
    'pinned Flutter SDK before running tests.',
  );
}
