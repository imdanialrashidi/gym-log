import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app/app.dart';
import 'package:gym_log/data/app_data_controller.dart';
import 'package:gym_log/data/export_reminder.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/memory_export_reminder_store.dart';

void main() {
  testWidgets('English LTR shell golden', (WidgetTester tester) async {
    await _pumpAt(tester, const Locale('en'));
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/app_shell_en.png'),
    );
  });

  testWidgets('Persian RTL shell golden', (WidgetTester tester) async {
    await _pumpAt(tester, const Locale('fa'));
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/app_shell_fa.png'),
    );
  });
}

Future<void> _pumpAt(WidgetTester tester, Locale locale) async {
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
}
