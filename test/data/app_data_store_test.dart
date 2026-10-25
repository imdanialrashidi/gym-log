import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/app_data_store.dart';
import 'package:lift_core/lift_core.dart';

Future<File> _tempFile() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'gym_log_store_test_',
  );
  addTearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });
  return File('${directory.path}${Platform.pathSeparator}data.json');
}

Exercise _exercise(String id, String name, {bool archived = false}) {
  return Exercise(
    id: id,
    name: name,
    archivedAt: archived ? DateTime.utc(2026, 10, 21, 12) : null,
    createdAt: DateTime.utc(2026, 10, 20, 10),
  );
}

void main() {
  test('fresh install loads an empty document', () async {
    final File file = await _tempFile();
    final JsonAppDataStore store = JsonAppDataStore(Future<File>.value(file));

    final AppData data = await store.load();

    expect(data.exercises, isEmpty);
    expect(data.programs, isEmpty);
    expect(file.existsSync(), isFalse);
  });

  test('saves and reloads exercises and archived state', () async {
    final File file = await _tempFile();
    final JsonAppDataStore store = JsonAppDataStore(Future<File>.value(file));
    final AppData original = AppData(
      exercises: <Exercise>[
        _exercise('exercise-1', 'Bench Press'),
        _exercise('exercise-2', 'Squat', archived: true),
      ],
    );

    await store.save(original);

    final JsonAppDataStore restarted = JsonAppDataStore(
      Future<File>.value(file),
    );
    final AppData reloaded = await restarted.load();

    expect(reloaded.exercises, hasLength(2));
    expect(reloaded.activeExercises.single.name, 'Bench Press');
    expect(reloaded.exerciseById('exercise-2'), isNotNull);
    expect(reloaded.exerciseById('exercise-2')!.isArchived, isTrue);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('serializes concurrent saves and keeps the last snapshot', () async {
    final File file = await _tempFile();
    final JsonAppDataStore store = JsonAppDataStore(Future<File>.value(file));

    await Future.wait(<Future<void>>[
      store.save(
        AppData(exercises: <Exercise>[_exercise('exercise-1', 'Bench Press')]),
      ),
      store.save(
        AppData(
          exercises: <Exercise>[_exercise('exercise-1', 'Bench Press')],
          programs: <Program>[
            Program(
              id: 'program-1',
              name: 'Upper/Lower',
              createdAt: DateTime.utc(2026, 10, 20, 11),
            ),
          ],
        ),
      ),
    ]);

    final AppData reloaded = await JsonAppDataStore(Future<File>.value(file))
        .load();
    expect(reloaded.programs.single.name, 'Upper/Lower');
  });

  test(
    'keeps the newest three snapshots and never prunes the new target',
    () async {
      final File file = await _tempFile();
      DateTime now = DateTime.utc(2026, 10, 22, 12);
      final JsonAppDataStore store = JsonAppDataStore(
        Future<File>.value(file),
        snapshotClock: () => now,
      );

      await store.save(AppData(exercises: <Exercise>[_exercise('a', 'Alpha')]));
      await store.snapshot();
      now = now.add(const Duration(minutes: 1));
      await store.save(AppData(exercises: <Exercise>[_exercise('b', 'Bravo')]));
      await store.snapshot();
      now = now.add(const Duration(minutes: 1));
      await store.save(
        AppData(exercises: <Exercise>[_exercise('c', 'Charlie')]),
      );
      await store.snapshot();

      // A backwards wall clock makes the next name sort before all earlier
      // snapshots; it must still be retained as the pre-Replace recovery point.
      now = DateTime.utc(2026, 10, 22, 11);
      await store.snapshot();
      await store.save(AppData(exercises: <Exercise>[_exercise('d', 'Delta')]));

      final List<File> backups = Directory(
        '${file.parent.path}${Platform.pathSeparator}backups',
      ).listSync().whereType<File>().toList();
      expect(backups, hasLength(3));
      final File recovery = backups.firstWhere(
        (File snapshot) => snapshot.path.contains('T11-00-00'),
      );
      final AppData recoveryData = AppData.fromJson(
        (jsonDecode(await recovery.readAsString()) as Map)
            .cast<String, Object?>(),
      );
      expect(recoveryData.exerciseById('c')!.name, 'Charlie');
      expect(
        backups.where((File snapshot) => snapshot.path.contains('T12-00-00')),
        isEmpty,
        reason: 'The oldest older snapshot is pruned, not the new one.',
      );
      expect(
        backups.where((File snapshot) => snapshot.path.contains('T12-01-00')),
        hasLength(1),
      );
      expect(
        backups.where((File snapshot) => snapshot.path.contains('T12-02-00')),
        hasLength(1),
      );
    },
  );

  test('rejects truncated data without overwriting it', () async {
    final File file = await _tempFile();
    await file.writeAsString('{"schemaVersion": 1, "exercises": [');
    final JsonAppDataStore store = JsonAppDataStore(Future<File>.value(file));

    await expectLater(store.load(), throwsA(isA<DataStoreException>()));
    expect(await file.readAsString(), '{"schemaVersion": 1, "exercises": [');
  });

  test(
    'upgrades a version 1 document to version 2 without data loss',
    () async {
      final File file = await _tempFile();
      await file.writeAsString(
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'exercises': <Object?>[
            _exercise('exercise-1', 'Bench Press').toJson(),
          ],
          'programs': const <Object?>[],
        }),
      );
      final JsonAppDataStore store = JsonAppDataStore(Future<File>.value(file));

      final AppData loaded = await store.load();
      expect(loaded.exercises.single.name, 'Bench Press');
      expect(loaded.sessions, isEmpty);
      expect(loaded.settings.weightUnit, WeightUnit.kilograms);

      await store.save(loaded);
      final Map<String, Object?> written = (jsonDecode(
        await file.readAsString(),
      ) as Map<Object?, Object?>).cast<String, Object?>();
      expect(written['schemaVersion'], 2);
      expect(written['sessions'], isEmpty);
      expect(
        (written['settings']! as Map<Object?, Object?>)['weightUnit'],
        'kilograms',
      );
      expect((written['exercises']! as List<Object?>), hasLength(1));
    },
  );

  test('rejects a newer data schema instead of guessing', () async {
    final File file = await _tempFile();
    await file.writeAsString(
      '{"schemaVersion": 99, "exercises": [], "programs": []}',
    );
    final JsonAppDataStore store = JsonAppDataStore(Future<File>.value(file));

    await expectLater(
      store.load(),
      throwsA(
        isA<DataStoreException>().having(
          (DataStoreException error) => error.cause,
          'cause',
          isA<FormatException>(),
        ),
      ),
    );
  });
}
