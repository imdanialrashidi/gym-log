import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_app_data_store.dart';
import 'support/test_app.dart';

AppData _data() {
  return AppData(
    exercises: <Exercise>[
      Exercise(
        id: 'bench',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        createdAt: DateTime.utc(2026, 9, 1, 9),
      ),
    ],
    bodyWeights: <BodyWeightEntry>[
      BodyWeightEntry(
        id: 'weight-1',
        weightGrams: 81200,
        recordedAt: DateTime(2026, 9, 23, 8).toUtc(),
      ),
      BodyWeightEntry(
        id: 'weight-2',
        weightGrams: 80500,
        recordedAt: DateTime(2026, 9, 30, 8).toUtc(),
      ),
      BodyWeightEntry(
        id: 'weight-3',
        weightGrams: 79900,
        recordedAt: DateTime(2026, 10, 7, 8).toUtc(),
      ),
      BodyWeightEntry(
        id: 'weight-4',
        weightGrams: 79500,
        recordedAt: DateTime(2026, 10, 14, 8).toUtc(),
      ),
      BodyWeightEntry(
        id: 'weight-5',
        weightGrams: 79200,
        recordedAt: DateTime(2026, 10, 19, 8).toUtc(),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, Locale locale) async {
  await pumpGymLogApp(
    tester,
    store: MemoryAppDataStore(_data()),
    initialLocation: '/body-weight',
    locale: locale,
    clock: () => DateTime.utc(2026, 10, 21, 12),
  );
}

Finder get _screen => find.byType(Scaffold).first;

void main() {
  testWidgets('English LTR body weight golden', (WidgetTester tester) async {
    await _pump(tester, const Locale('en'));
    expect(Directionality.of(tester.element(_screen)), TextDirection.ltr);
    expect(tester.takeException(), isNull);
    await expectLater(_screen, matchesGoldenFile('goldens/body_weight_en.png'));
  });

  testWidgets('Persian RTL body weight golden', (WidgetTester tester) async {
    await _pump(tester, const Locale('fa'));
    expect(Directionality.of(tester.element(_screen)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
    await expectLater(_screen, matchesGoldenFile('goldens/body_weight_fa.png'));
  });
}
