import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app/app.dart';
import 'package:gym_log/app/theme/app_tokens.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/export_reminder.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/memory_export_reminder_store.dart';

void main() {
  testWidgets('first launch is dark on a light-theme device', (
    WidgetTester tester,
  ) async {
    await _pumpApp(
      tester,
      locale: const Locale('en'),
      brightness: Brightness.light,
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).scaffoldBackgroundColor, AppTokens.background);
  });

  testWidgets('Persian device starts in Persian RTL', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, locale: const Locale('fa', 'IR'));

    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(find.text('تمرین'), findsWidgets);
    expect(find.text('برنامه‌ها'), findsOneWidget);
    expect(find.text('No active workout.'), findsNothing);
  });

  testWidgets('unsupported device locale falls back to English LTR', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, locale: const Locale('de'));

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );
    expect(find.text('Workout'), findsWidgets);
    expect(find.text('No active workout.'), findsOneWidget);
  });

  testWidgets('language switches without restart and mirrors layout', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, locale: const Locale('fa', 'IR'));
    final Element appElement = tester.element(find.byType(GymLogApp));
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );

    await tester.tap(find.byTooltip('تنظیمات'));
    await tester.pumpAndSettle();
    expect(find.text('زبان'), findsOneWidget);

    await tester.tap(find.text('انگلیسی'));
    await tester.pumpAndSettle();

    final BuildContext settingsContext = tester.element(find.byType(Scaffold));
    expect(Directionality.of(settingsContext), TextDirection.ltr);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(tester.element(find.byType(GymLogApp)), same(appElement));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Workout'), findsWidgets);
    expect(find.text('No active workout.'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );
  });

  testWidgets('four tabs show their text-only empty states', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, locale: const Locale('en'));
    expect(find.text('No active workout.'), findsOneWidget);

    const Map<String, String> tabs = <String, String>{
      'Programs': 'No programs yet.',
      'History': 'No history yet.',
      'Progress': 'Finish a workout to see progress here.',
    };
    for (final MapEntry<String, String> tab in tabs.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab.key),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(tab.value), findsOneWidget);
    }
  });

  testWidgets('settings icon opens the language control', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, locale: const Locale('en'));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required Locale locale,
  Brightness brightness = Brightness.dark,
}) async {
  tester.platformDispatcher.localesTestValue = <Locale>[locale];
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDataStoreProvider.overrideWithValue(MemoryAppDataStore()),
        exportReminderStoreProvider.overrideWithValue(
          MemoryExportReminderStore(
            ExportReminderState(lastExportedAt: DateTime.now()),
          ),
        ),
      ],
      child: const GymLogApp(),
    ),
  );
  await tester.pumpAndSettle();
}
