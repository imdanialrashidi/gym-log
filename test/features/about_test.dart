import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app/app_info.dart';
import 'package:gym_log/core/widgets/square_switch.dart';
import 'package:gym_log/features/settings/presentation/about_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

void main() {
  testWidgets('About shows version, license, links, privacy, and notice', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(),
      initialLocation: '/about',
    );

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Version $appVersion'), findsOneWidget);
    expect(find.text('App license'), findsOneWidget);
    expect(find.text('MIT'), findsOneWidget);
    expect(find.text('Developer'), findsOneWidget);
    expect(find.textContaining('Danial Rashidi'), findsOneWidget);
    expect(find.textContaining('danialrashidi.ir'), findsOneWidget);
    expect(find.text('Open-source licenses'), findsOneWidget);
    expect(find.text('Source code'), findsOneWidget);
    expect(find.text('Donate'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(
      find.textContaining('Your training data stays on this device'),
      findsOneWidget,
    );
    expect(find.textContaining('not medical advice'), findsOneWidget);
  });

  testWidgets('source and donate links open externally', (
    WidgetTester tester,
  ) async {
    final List<Uri> launched = <Uri>[];
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(),
      initialLocation: '/about',
      externalLinkLauncher: (Uri uri) async {
        launched.add(uri);
        return true;
      },
    );

    await tester.tap(find.byKey(const Key('about-developer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-source')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-donate')));
    await tester.pumpAndSettle();

    expect(launched, <Uri>[
      Uri.parse(appWebsiteUrl),
      Uri.parse(appSourceUrl),
      Uri.parse(appDonateUrl),
    ]);
    expect(launched[0].scheme, 'https');
    expect(launched[1].scheme, 'https');
    expect(launched[2].scheme, 'https');
  });

  testWidgets('failed link launch shows a non-blocking message', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(),
      initialLocation: '/about',
      externalLinkLauncher: (Uri uri) async => false,
    );

    await tester.tap(find.byKey(const Key('about-source')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Could not open a browser.'), findsOneWidget);
    expect(find.byType(AboutScreen), findsOneWidget);
  });

  testWidgets('open-source licenses open from About', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(),
      initialLocation: '/about',
    );

    await tester.tap(find.byKey(const Key('about-open-source-licenses')));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('Settings exposes About and an enforced-off backup control', (
    WidgetTester tester,
  ) async {
    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(),
      initialLocation: '/settings',
    );

    final Finder backup = find.byKey(const Key('android-backup-toggle'));
    await tester.scrollUntilVisible(
      backup,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final SquareSwitch toggle = tester.widget<SquareSwitch>(backup);
    expect(toggle.value, isFalse);
    expect(toggle.onChanged, isNull);
    expect(find.text('Allow Android backup'), findsOneWidget);

    final Finder about = find.byKey(const Key('open-about'));
    await tester.scrollUntilVisible(
      about,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(about);
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
  });
}
