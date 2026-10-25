import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('English LTR about golden', (WidgetTester tester) async {
    await _pumpAbout(tester, const Locale('en'), 'About');
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/about_en.png'),
    );
  });

  testWidgets('Persian RTL about golden', (WidgetTester tester) async {
    await _pumpAbout(tester, const Locale('fa'), 'درباره');
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/about_fa.png'),
    );
  });
}

Future<void> _pumpAbout(
  WidgetTester tester,
  Locale locale,
  String title,
) async {
  await pumpGymLogApp(
    tester,
    store: MemoryAppDataStore(),
    initialLocation: '/about',
    locale: locale,
  );
  expect(find.text(title), findsOneWidget);
}
