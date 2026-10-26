import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

BodyWeightEntry _entry(
  String id,
  int grams,
  DateTime localDate, {
  int hour = 8,
}) {
  return BodyWeightEntry(
    id: id,
    weightGrams: grams,
    recordedAt: DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      hour,
    ).toUtc(),
  );
}

void main() {
  group('BodyWeightEntry', () {
    test('stores UTC and round-trips JSON', () {
      final BodyWeightEntry entry = BodyWeightEntry(
        id: 'weight-1',
        weightGrams: 78400,
        recordedAt: DateTime(2026, 10, 21, 8, 30),
      );
      expect(entry.recordedAt.isUtc, isTrue);
      final BodyWeightEntry restored = BodyWeightEntry.fromJson(entry.toJson());
      expect(restored.id, 'weight-1');
      expect(restored.weightGrams, 78400);
      expect(restored.recordedAt, entry.recordedAt);
    });

    test('rejects values outside 20–500 kg', () {
      expect(
        () => BodyWeightEntry(
          id: 'weight-1',
          weightGrams: minimumBodyWeightGrams - 1,
          recordedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
      expect(
        () => BodyWeightEntry(
          id: 'weight-1',
          weightGrams: maximumBodyWeightGrams + 1,
          recordedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
    });
  });

  group('startOfWeek', () {
    test('Saturday weeks start on Saturday', () {
      // 2026-10-21 is a Wednesday.
      expect(
        startOfWeek(DateTime(2026, 10, 21, 15), DateTime.saturday),
        DateTime(2026, 10, 17),
      );
      expect(
        startOfWeek(DateTime(2026, 10, 17, 0, 1), DateTime.saturday),
        DateTime(2026, 10, 17),
      );
      expect(
        startOfWeek(DateTime(2026, 10, 16, 23, 59), DateTime.saturday),
        DateTime(2026, 10, 10),
      );
    });

    test('Sunday and Monday weeks use their own boundary', () {
      expect(
        startOfWeek(DateTime(2026, 10, 21), DateTime.sunday),
        DateTime(2026, 10, 18),
      );
      expect(
        startOfWeek(DateTime(2026, 10, 21), DateTime.monday),
        DateTime(2026, 10, 19),
      );
    });

    test('rejects an invalid weekday', () {
      expect(() => startOfWeek(DateTime(2026), 0), throwsArgumentError);
      expect(() => startOfWeek(DateTime(2026), 8), throwsArgumentError);
    });
  });

  group('weeklyBodyWeight', () {
    final DateTime now = DateTime(2026, 10, 21, 12);

    test('picks the latest check-in per week and fills gaps', () {
      final List<BodyWeightWeek> weeks = weeklyBodyWeight(
        entries: <BodyWeightEntry>[
          _entry('w-1', 80000, DateTime(2026, 10, 3)),
          _entry('w-2', 79500, DateTime(2026, 10, 7)),
          _entry('w-3', 79000, DateTime(2026, 10, 18)),
          _entry('w-4', 78700, DateTime(2026, 10, 21)),
        ],
        now: now,
        weeks: 4,
      );

      expect(weeks, hasLength(4));
      expect(weeks.first.weekStart, DateTime(2026, 9, 26));
      expect(weeks.first.weightGrams, isNull);
      expect(weeks[1].weekStart, DateTime(2026, 10, 3));
      expect(weeks[1].weightGrams, 79500);
      expect(weeks[1].changeGrams, isNull);
      expect(weeks[2].weightGrams, isNull);
      expect(weeks[2].changeGrams, isNull);
      expect(weeks[3].weekStart, DateTime(2026, 10, 17));
      expect(weeks[3].weightGrams, 78700);
      expect(weeks[3].changeGrams, -800);
    });

    test('change compares with the previous recorded week, not a gap', () {
      final List<BodyWeightWeek> weeks = weeklyBodyWeight(
        entries: <BodyWeightEntry>[
          _entry('w-1', 80000, DateTime(2026, 9, 26)),
          _entry('w-2', 81000, DateTime(2026, 10, 21)),
        ],
        now: now,
        weeks: 4,
      );
      expect(weeks[0].weekStart, DateTime(2026, 9, 26));
      expect(weeks[0].weightGrams, 80000);
      expect(weeks[3].weekStart, DateTime(2026, 10, 17));
      expect(weeks[3].weightGrams, 81000);
      expect(weeks[3].changeGrams, 1000);
    });

    test('ties on timestamp keep the higher id deterministically', () {
      final DateTime sameDay = DateTime(2026, 10, 21, 8);
      final List<BodyWeightWeek> weeks = weeklyBodyWeight(
        entries: <BodyWeightEntry>[
          _entry('w-a', 80000, sameDay),
          _entry('w-b', 81000, sameDay),
        ],
        now: now,
        weeks: 1,
      );
      expect(weeks.single.weightGrams, 81000);
    });
  });

  group('latestBodyWeightChange', () {
    test('is empty without entries', () {
      expect(latestBodyWeightEntry(const <BodyWeightEntry>[]), isNull);
      expect(latestBodyWeightChange(const <BodyWeightEntry>[]).entry, isNull);
    });

    test('has no change with one entry and signed change with two', () {
      final BodyWeightEntry first = _entry(
        'w-1',
        80000,
        DateTime(2026, 10, 14),
      );
      expect(
        latestBodyWeightChange(<BodyWeightEntry>[first]).changeGrams,
        null,
      );
      final BodyWeightEntry second = _entry(
        'w-2',
        79300,
        DateTime(2026, 10, 21),
      );
      final ({BodyWeightEntry? entry, int? changeGrams}) result =
          latestBodyWeightChange(<BodyWeightEntry>[second, first]);
      expect(result.entry?.id, 'w-2');
      expect(result.changeGrams, -700);
    });
  });

  group('body-weight edits', () {
    final DateTime now = DateTime.utc(2026, 10, 21, 12);

    test('adds and deletes an entry', () {
      final ({AppData data, BodyWeightEntry entry}) added = addBodyWeightEntry(
        AppData(),
        id: 'weight-1',
        weightGrams: 80000,
        recordedAt: now,
      );
      expect(added.data.bodyWeights.single.id, 'weight-1');
      final ({AppData data, BodyWeightEntry entry}) removed =
          deleteBodyWeightEntry(added.data, 'weight-1');
      expect(removed.entry.weightGrams, 80000);
      expect(removed.data.bodyWeights, isEmpty);
    });

    test('replaces a same-week reading without changing its id', () {
      final ({AppData data, BodyWeightEntry entry}) first = addBodyWeightEntry(
        AppData(),
        id: 'weight-1',
        weightGrams: 80000,
        recordedAt: now,
      );
      final ({AppData data, BodyWeightEntry entry}) updated =
          replaceBodyWeightEntry(
            first.data,
            id: 'weight-1',
            weightGrams: 79500,
            recordedAt: now.add(const Duration(days: 1)),
          );
      expect(updated.data.bodyWeights, hasLength(1));
      expect(updated.entry.id, 'weight-1');
      expect(updated.data.bodyWeights.single.weightGrams, 79500);
    });

    test('rejects duplicate ids across the document', () {
      expect(
        () => AppData(
          exercises: <Exercise>[
            Exercise(id: 'shared', name: 'Bench', createdAt: now),
          ],
          bodyWeights: <BodyWeightEntry>[
            BodyWeightEntry(id: 'shared', weightGrams: 80000, recordedAt: now),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('schema versions', () {
    test('reads a version 2 document with no check-ins', () {
      final AppData restored = AppData.fromJson(<String, Object?>{
        'schemaVersion': 2,
        'exercises': const <Object?>[],
        'programs': const <Object?>[],
        'sessions': const <Object?>[],
        'settings': const <String, Object?>{'weightUnit': 'kilograms'},
      });
      expect(restored.bodyWeights, isEmpty);
    });

    test('round-trips check-ins in the current schema', () {
      final AppData original = AppData(
        bodyWeights: <BodyWeightEntry>[
          BodyWeightEntry(
            id: 'weight-1',
            weightGrams: 80000,
            recordedAt: DateTime.utc(2026, 10, 21, 8),
          ),
        ],
      );
      final Map<String, Object?> json = original.toJson();
      expect(json['schemaVersion'], appDataSchemaVersion);
      final AppData restored = AppData.fromJson(json);
      expect(restored.bodyWeights.single.weightGrams, 80000);
      expect(
        restored.bodyWeights.single.recordedAt,
        DateTime.utc(2026, 10, 21, 8),
      );
    });

    test('a version 3 document reads with no goals and writes version 4', () {
      final AppData restored = AppData.fromJson(<String, Object?>{
        'schemaVersion': 3,
        'exercises': const <Object?>[],
        'programs': const <Object?>[],
        'sessions': const <Object?>[],
        'bodyWeights': const <Object?>[],
        'settings': const <String, Object?>{'weightUnit': 'kilograms'},
      });
      expect(restored.settings.hasWeeklyGoal, isFalse);
      expect(restored.toJson()['schemaVersion'], 4);
    });

    test('rejects an invalid check-in on the read path', () {
      expect(
        () => AppData.fromJson(<String, Object?>{
          'schemaVersion': 3,
          'exercises': const <Object?>[],
          'programs': const <Object?>[],
          'sessions': const <Object?>[],
          'bodyWeights': <Object?>[
            <String, Object?>{
              'id': 'weight-1',
              'weightGrams': minimumBodyWeightGrams - 1,
              'recordedAt': '2026-10-21T08:00:00.000Z',
            },
          ],
          'settings': const <String, Object?>{'weightUnit': 'kilograms'},
        }),
        throwsArgumentError,
      );
    });
  });
}
