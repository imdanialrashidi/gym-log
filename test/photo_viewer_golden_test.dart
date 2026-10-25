import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app/theme/app_theme.dart';
import 'package:gym_log/core/l10n/l10n.dart';
import 'package:gym_log/features/photos/presentation/photo_viewer_screen.dart';
import 'package:image/image.dart' as image;
import 'package:material_ui/material_ui.dart';

File _samplePhoto() {
  final Directory directory = Directory.systemTemp.createTempSync(
    'gym_log_photo_viewer_golden_',
  );
  addTearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });
  final image.Image source = image.Image(width: 640, height: 480);
  for (int y = 0; y < source.height; y++) {
    for (int x = 0; x < source.width; x++) {
      source.setPixelRgb(
        x,
        y,
        30 + (x * 120) ~/ source.width,
        60 + (y * 100) ~/ source.height,
        90,
      );
    }
  }
  final File file = File('${directory.path}/sample.png')
    ..writeAsBytesSync(image.encodePng(source));
  return file;
}

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required File file,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: PhotoViewerScreen(file: file, onRemove: () async => true),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pump();
}

void main() {
  testWidgets('English LTR photo viewer golden', (WidgetTester tester) async {
    final File file = _samplePhoto();
    await _pump(tester, locale: const Locale('en'), file: file);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/photo_viewer_en.png'),
    );
  });

  testWidgets('Persian RTL photo viewer golden', (WidgetTester tester) async {
    final File file = _samplePhoto();
    await _pump(tester, locale: const Locale('fa'), file: file);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/photo_viewer_fa.png'),
    );
  });

  testWidgets('a missing photo file shows a plain message', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: PhotoViewerScreen(file: File('/definitely/not/a/photo.jpg')),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.text('This photo is no longer available.'), findsOneWidget);
  });
}
