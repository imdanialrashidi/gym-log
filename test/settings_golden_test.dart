import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app/app.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/export_reminder.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/memory_export_reminder_store.dart';

void main() {
  testWidgets('English LTR settings golden', (WidgetTester tester) async {
    await _pumpSettings(tester, const Locale('en'), 'Settings');
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/settings_en.png'),
    );
  });

  testWidgets('Persian RTL settings golden', (WidgetTester tester) async {
    await _pumpSettings(tester, const Locale('fa'), 'تنظیمات');
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/settings_fa.png'),
    );
  });
}

Future<void> _pumpSettings(
  WidgetTester tester,
  Locale locale,
  String settingsTooltip,
) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.localesTestValue = <Locale>[locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

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
  await tester.tap(find.byTooltip(settingsTooltip));
  await tester.pumpAndSettle();
}
