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

  group('data snapshots', () {
    Future<JsonAppDataStore> seedStore(File file) async {
      final JsonAppDataStore store = JsonAppDataStore(
        Future<File>.value(file),
        snapshotClock: () => DateTime.utc(2026, 10, 22, 12),
      );
      await store.save(AppData(exercises: <Exercise>[_exercise('a', 'Alpha')]));
      await store.snapshot();
      return store;
    }

    test('a fresh install has no snapshots', () async {
      final File file = await _tempFile();
      final JsonAppDataStore store = JsonAppDataStore(Future<File>.value(file));

      expect(await store.listSnapshots(), isEmpty);
      expect(
        Directory('${file.parent.path}${Platform.pathSeparator}backups')
            .existsSync(),
        isFalse,
      );
    });

    test('lists snapshots newest first using file times, not names', () async {
      final File file = await _tempFile();
      final JsonAppDataStore store = await seedStore(file);
      final Directory backups = Directory(
        '${file.parent.path}${Platform.pathSeparator}backups',
      );
      // Names sort backwards; the file mtime is the authority.
      final File newer = File(
        '${backups.path}${Platform.pathSeparator}gym_log_data-2026-01-01T00-00-00.json',
      );
      await newer.writeAsBytes(
        await backups.listSync().whereType<File>().single.readAsBytes(),
      );
      newer.setLastModifiedSync(DateTime.utc(2030, 10, 22, 13));
      final File older = File(
        '${backups.path}${Platform.pathSeparator}gym_log_data-2026-12-31T00-00-00.json',
      );
      await older.writeAsBytes(await newer.readAsBytes());
      older.setLastModifiedSync(DateTime.utc(2030, 10, 22, 11));

      final List<DataSnapshotInfo> listed = await store.listSnapshots();

      expect(listed, hasLength(3));
      expect(listed.first.fileName, contains('2026-01-01'));
      expect(listed[1].fileName, contains('2026-12-31'));
    });

    test('loads a snapshot document', () async {
      final File file = await _tempFile();
      final JsonAppDataStore store = await seedStore(file);
      final DataSnapshotInfo info = (await store.listSnapshots()).single;

      final AppData loaded = await store.loadSnapshot(info.fileName);

      expect(loaded.exercises.single.name, 'Alpha');
    });

    test('rejects traversal and non-snapshot names', () async {
      final File file = await _tempFile();
      final JsonAppDataStore store = await seedStore(file);

      for (final String name in <String>[
        '../gym_log_data-x.json',
        r'..\gym_log_data-x.json',
        'gym_log_data-x.json/../x',
        'other.json',
        'gym_log_data-x.txt',
        'sub/gym_log_data-x.json',
      ]) {
        await expectLater(
          store.loadSnapshot(name),
          throwsA(isA<DataStoreException>()),
          reason: 'Accepted unsafe snapshot name "$name"',
        );
      }
    });

    test('a corrupt snapshot throws without touching the document', () async {
      final File file = await _tempFile();
      final JsonAppDataStore store = await seedStore(file);
      final DataSnapshotInfo info = (await store.listSnapshots()).single;
      final File corrupt = File(
        '${file.parent.path}${Platform.pathSeparator}backups'
        '${Platform.pathSeparator}${info.fileName}',
      );
      await corrupt.writeAsString('{"schemaVersion": 1, "exercises": [');

      await expectLater(
        store.loadSnapshot(info.fileName),
        throwsA(isA<DataStoreException>()),
      );
      expect((await store.load()).exercises.single.name, 'Alpha');
    });

    test('retention leaves exactly three listed snapshots', () async {
      final File file = await _tempFile();
      DateTime now = DateTime.utc(2026, 10, 22, 12);
      final JsonAppDataStore store = JsonAppDataStore(
        Future<File>.value(file),
        snapshotClock: () => now,
      );
      await store.save(AppData(exercises: <Exercise>[_exercise('a', 'Alpha')]));
      for (int index = 0; index < 5; index++) {
        now = now.add(const Duration(minutes: 1));
        await store.snapshot();
      }

      expect(await store.listSnapshots(), hasLength(3));
    });
  });

  test('rejects truncated data without overwriting it', () async {
    final File file = await _tempFile();
    await file.writeAsString('{"schemaVersion": 1, "exercises": [');
    final JsonAppDataStore store = JsonAppDataStore(Future<File>.value(file));

    await expectLater(store.load(), throwsA(isA<DataStoreException>()));
    expect(await file.readAsString(), '{"schemaVersion": 1, "exercises": [');
  });

  test(
    'upgrades a version 1 document to the current version without data loss',
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
      expect(written['schemaVersion'], appDataSchemaVersion);
      expect(written['sessions'], isEmpty);
      expect(written['bodyWeights'], isEmpty);
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
