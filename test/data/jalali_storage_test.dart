import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/core/calendar/calendar_service.dart';
import 'package:gym_log/data/app_data_store.dart';
import 'package:lift_core/lift_core.dart';

Exercise _exercise() {
  return Exercise(
    id: 'exercise-1',
    name: 'Bench Press',
    createdAt: DateTime.utc(2026, 9, 1, 9),
  );
}

Session _session() {
  return Session(
    id: 'session-1',
    startedAt: DateTime.utc(2026, 10, 20, 10),
    endedAt: DateTime.utc(2026, 10, 20, 11),
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'session-1-exercise',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        sets: <SetLog>[
          SetLog(
            id: 'set-1',
            setIndex: 0,
            weightGrams: 100000,
            reps: 8,
            rir: 2,
            loggedAt: DateTime.utc(2026, 10, 20, 10, 5),
          ),
        ],
      ),
    ],
  );
}

void main() {
  test('stored document and export never contain Jalali strings', () async {
    final AppData data = AppData(
      exercises: <Exercise>[_exercise()],
      sessions: <Session>[_session()],
      settings: const AppSettings(
        digitStyle: DigitStyle.persian,
        defaultIncrementGrams: 5000,
      ),
    );

    final String stored = jsonEncode(data.toJson());
    final String exported = buildBackupJson(
      data,
      appVersion: '0.1.0',
      exportedAt: DateTime.utc(2026, 10, 22, 12),
    );

    for (final String json in <String>[stored, exported]) {
      expect(json, isNot(contains('فروردین')));
      expect(json, isNot(contains('شهریور')));
      expect(json, isNot(contains(RegExp(r'[\u06F0-\u06F9\u0660-\u0669]'))));
      expect(json, contains('2026-10-20T10:00:00.000Z'));
    }

    // Display digits can be chosen without rewriting the stored values.
    final AppData restored = AppData.fromJson(data.toJson());
    expect(
      restored.sessions.single.exercises.single.sets.single.weightGrams,
      100000,
    );
    expect(restored.settings.digitStyle, DigitStyle.persian);
  });

  test('stored document file keeps UTC and no Jalali strings', () async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'gym_log_jalali_storage_',
    );
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final File file = File('${directory.path}/data.json');
    final JsonAppDataStore store = JsonAppDataStore(Future<File>.value(file));
    final AppData data = AppData(
      exercises: <Exercise>[_exercise()],
      sessions: <Session>[_session()],
      settings: const AppSettings(digitStyle: DigitStyle.persian),
    );

    await store.save(data);
    final String stored = await file.readAsString();
    expect(stored, contains('2026-10-20T10:00:00.000Z'));
    expect(stored, isNot(contains('مهر')));
    expect(stored, isNot(contains(RegExp(r'[\u06F0-\u06F9]'))));

    final AppData reloaded = await store.load();
    expect(
      reloaded.sessions.single.exercises.single.sets.single.weightGrams,
      100000,
    );
    expect(reloaded.settings.digitStyle, DigitStyle.persian);
  });

  test('Persian display formats the same UTC instant as Jalali', () {
    const List<String> weekdays = <String>['ی', 'د', 'س', 'چ', 'پ', 'ج', 'ش'];
    final String shown = const JalaliCalendarService().formatDate(
      DateTime(2026, 10, 22, 12),
      style: AppDateStyle.date,
      languageCode: 'fa',
      digitStyle: DigitStyle.persian,
      narrowWeekdays: weekdays,
    );
    expect(shown, '۳۰ مهر ۱۴۰۵');
    expect(shown, isNot(contains('2026')));
  });
}
