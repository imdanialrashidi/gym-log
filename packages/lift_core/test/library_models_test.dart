import 'dart:convert';

import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

void main() {
  Exercise exercise({
    String id = 'exercise-1',
    String name = 'Bench Press',
    bool archived = false,
  }) {
    return Exercise(
      id: id,
      name: name,
      searchTerm: 'flat bench press',
      muscleGroup: MuscleGroup.chest,
      defaultRepMin: 8,
      defaultRepMax: 12,
      incrementGrams: 2500,
      archivedAt: archived ? DateTime.utc(2026, 10, 21, 12) : null,
      createdAt: DateTime.utc(2026, 10, 20, 10),
    );
  }

  Program program() {
    return Program(
      id: 'program-1',
      name: 'Upper/Lower',
      createdAt: DateTime.utc(2026, 10, 20, 11),
      days: <ProgramDay>[
        ProgramDay(
          id: 'day-1',
          name: 'Upper',
          sortOrder: 0,
          items: <PlanItem>[
            PlanItem(
              id: 'item-1',
              exerciseId: 'exercise-1',
              targetSets: 4,
              repMin: 6,
              repMax: 10,
              sortOrder: 0,
            ),
          ],
        ),
        ProgramDay(id: 'day-2', name: 'Lower', sortOrder: 1),
      ],
    );
  }

  group('limits', () {
    test('numeric bounds are positive and ordered', () {
      expect(maximumExerciseNameLength, 120);
      expect(maximumSearchTermLength, 200);
      expect(maximumProgramNameLength, 120);
      expect(maximumDayNameLength, 120);
      expect(maximumSortOrder, 1000000);
      expect(maximumSortOrder + 1, lessThan(9223372036854775807));
    });
  });

  group('Exercise', () {
    test('round-trips through JSON with explicit nullable fields', () {
      final Exercise original = exercise();
      final Map<String, Object?> json = original.toJson();
      final Exercise restored = Exercise.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.searchTerm, original.searchTerm);
      expect(restored.muscleGroup, MuscleGroup.chest);
      expect(restored.defaultRepMin, 8);
      expect(restored.defaultRepMax, 12);
      expect(restored.incrementGrams, 2500);
      expect(restored.isArchived, isFalse);
      expect(restored.createdAt.isUtc, isTrue);
      expect(json.containsKey('photoPath'), isFalse);
    });

    test('archiving preserves the record for history references', () {
      final Exercise archived = exercise(archived: true);

      expect(archived.isArchived, isTrue);
      expect(archived.archivedAt, DateTime.utc(2026, 10, 21, 12));
      expect(Exercise.fromJson(archived.toJson()).isArchived, isTrue);
    });

    test('rejects blank names, paired rep values, and bad increments', () {
      expect(
        () => Exercise(id: 'x', name: '  ', createdAt: DateTime.utc(2026)),
        throwsArgumentError,
      );
      expect(
        () => Exercise(
          id: 'x',
          name: 'Squat',
          createdAt: DateTime.utc(2026),
          defaultRepMin: 8,
        ),
        throwsArgumentError,
      );
      expect(
        () => Exercise(
          id: 'x',
          name: 'Squat',
          createdAt: DateTime.utc(2026),
          defaultRepMin: 12,
          defaultRepMax: 8,
        ),
        throwsArgumentError,
      );
      expect(
        () => Exercise(
          id: 'x',
          name: 'Squat',
          createdAt: DateTime.utc(2026),
          incrementGrams: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => Exercise(
          id: 'x',
          name: 'Squat',
          createdAt: DateTime.utc(2026),
          incrementGrams: maximumSetWeightGrams + 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('AppData', () {
    test('round-trips exercises and nested programs', () {
      final AppData original = AppData(
        exercises: <Exercise>[exercise()],
        programs: <Program>[program()],
      );
      final String encoded = jsonEncode(original.toJson());
      final AppData restored = AppData.fromJson(
        (jsonDecode(encoded) as Map<String, dynamic>).cast<String, Object?>(),
      );

      expect(restored.exercises.single.name, 'Bench Press');
      expect(restored.programs.single.name, 'Upper/Lower');
      expect(restored.programs.single.days, hasLength(2));
      expect(restored.dayById('day-1')?.items.single.targetSets, 4);
      expect(restored.dayById('day-2')?.name, 'Lower');
      expect(restored.exerciseById('exercise-1')?.incrementGrams, 2500);
    });

    test('activeExercises hides archived exercises but keeps lookup', () {
      final AppData data = AppData(
        exercises: <Exercise>[
          exercise(),
          exercise(id: 'exercise-2', name: 'Squat', archived: true),
        ],
      );

      expect(data.activeExercises.map((Exercise e) => e.id), <String>[
        'exercise-1',
      ]);
      expect(data.exerciseById('exercise-2'), isNotNull);
      expect(data.searchExercises('squat'), isEmpty);
    });

    test('searchExercises applies case and Persian normalization', () {
      final AppData data = AppData(
        exercises: <Exercise>[
          exercise(name: 'Bench Press'),
          exercise(id: 'exercise-2', name: 'پرس سینه'),
        ],
      );

      expect(data.searchExercises('BEN').single.name, 'Bench Press');
      expect(data.searchExercises('پرس سينه').single.name, 'پرس سینه');
      expect(data.searchExercises(''), hasLength(2));
    });

    test('rejects dangling plan item references', () {
      expect(
        () => AppData(programs: <Program>[program()]),
        throwsFormatException,
      );
    });

    test('rejects duplicate ids', () {
      expect(
        () => AppData(
          exercises: <Exercise>[
            exercise(),
            exercise(name: 'Another'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects newer schemas instead of guessing', () {
      final Map<String, Object?> json = exercise().toJson();
      expect(
        () => AppData.fromJson(<String, Object?>{
          'schemaVersion': appDataSchemaVersion + 1,
          'exercises': <Object?>[json],
          'programs': <Object?>[],
        }),
        throwsFormatException,
      );
    });
  });

  group('reorder helpers', () {
    test('moves days and renumbers sortOrder', () {
      final ProgramDay third = ProgramDay(
        id: 'day-3',
        name: 'Third',
        sortOrder: 2,
      );
      final List<ProgramDay> reordered = reorderProgramDays(
        <ProgramDay>[
          ProgramDay(id: 'day-1', name: 'First', sortOrder: 0),
          ProgramDay(id: 'day-2', name: 'Second', sortOrder: 1),
          third,
        ],
        0,
        2,
      );

      expect(reordered.map((ProgramDay day) => day.id), <String>[
        'day-2',
        'day-3',
        'day-1',
      ]);
      expect(reordered.map((ProgramDay day) => day.sortOrder), <int>[0, 1, 2]);
    });

    test('moves plan items and renumbers sortOrder', () {
      PlanItem item(String id, int order) => PlanItem(
        id: id,
        exerciseId: 'exercise-1',
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        sortOrder: order,
      );
      final List<PlanItem> reordered = reorderPlanItems(
        <PlanItem>[item('a', 0), item('b', 1), item('c', 2)],
        2,
        0,
      );

      expect(reordered.map((PlanItem item) => item.id), <String>[
        'c',
        'a',
        'b',
      ]);
      expect(reordered.map((PlanItem item) => item.sortOrder), <int>[0, 1, 2]);
    });

    test('rejects out-of-range indices', () {
      expect(() => reorderProgramDays(<ProgramDay>[], 0, 0), throwsRangeError);
    });
  });
}
