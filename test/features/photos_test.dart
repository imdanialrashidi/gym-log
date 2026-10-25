import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/photo_pending_store.dart';
import 'package:gym_log/data/photo_picker.dart';
import 'package:gym_log/data/photo_storage.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/photo_fakes.dart';
import '../support/test_app.dart';

const String _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
    '+A8AAQUBAScY42YAAAAASUVORK5CYII=';

Exercise _exercise(String id, String name) {
  return Exercise(id: id, name: name, createdAt: DateTime.utc(2026, 10));
}

Session _session() {
  return Session(
    id: 'session-1',
    startedAt: DateTime.utc(2026, 10, 20, 10),
    endedAt: DateTime.utc(2026, 10, 20, 11),
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'session-exercise-1',
        exerciseId: 'exercise-1',
        sortOrder: 0,
        targetSets: 3,
        repMin: 8,
        repMax: 12,
        sets: <SetLog>[
          SetLog(
            id: 'set-1',
            weightGrams: 100000,
            reps: 8,
            rir: 2,
            setIndex: 0,
            loggedAt: DateTime.utc(2026, 10, 20, 10, 5),
          ),
        ],
      ),
    ],
  );
}

AppData _data() {
  return AppData(
    exercises: <Exercise>[
      _exercise('exercise-1', 'Bench Press'),
      _exercise('exercise-2', 'Squat'),
    ],
    sessions: <Session>[_session()],
  );
}

Directory _photoDirectory() {
  final Directory directory = Directory.systemTemp.createTempSync(
    'gym_log_photo_widget_',
  );
  addTearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });
  return directory;
}

File _writePhoto(Directory directory, String name) {
  final File file = File('${directory.path}${Platform.pathSeparator}$name');
  file.writeAsBytesSync(base64Decode(_onePixelPng));
  return file;
}

File _sourcePhoto(Directory directory) {
  return _writePhoto(directory, 'source.png');
}

MemoryPhotoStorage _storage(
  Directory directory, {
  Set<String>? fileNames,
  PhotoFailure? importFailure,
}) {
  return MemoryPhotoStorage(
    directory: directory,
    fileNames: fileNames,
    importFailure: importFailure,
  );
}

void main() {
  testWidgets('session photos show, open, and remove with a visible count', (
    WidgetTester tester,
  ) async {
    final Directory directory = _photoDirectory();
    _writePhoto(directory, 'session_session-1_0.jpg');
    _writePhoto(directory, 'session_session-1_2.jpg');
    final MemoryPhotoStorage storage = _storage(
      directory,
      fileNames: <String>{'session_session-1_0.jpg', 'session_session-1_2.jpg'},
    );

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/session/session-1',
      photoStorage: storage,
    );

    expect(find.byKey(const Key('session-photos-section')), findsOneWidget);
    expect(find.text('2 of 3'), findsOneWidget);
    expect(find.byKey(const Key('session-photo-0')), findsOneWidget);
    expect(find.byKey(const Key('session-photo-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('session-photo-0')));
    await tester.pumpAndSettle();
    expect(find.text('Photo'), findsOneWidget);
    expect(find.byKey(const Key('remove-photo')), findsOneWidget);

    await tester.tap(find.byKey(const Key('remove-photo')));
    await tester.pumpAndSettle();
    expect(find.text('Remove photo?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session-photo-0')), findsNothing);
    expect(find.byKey(const Key('session-photo-2')), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(storage.removeCount, 1);
  });

  testWidgets('adding a session photo uses the gallery and updates the index', (
    WidgetTester tester,
  ) async {
    final Directory directory = _photoDirectory();
    final File source = _sourcePhoto(directory);
    final FakePhotoPicker picker = FakePhotoPicker(next: source);
    final MemoryPhotoStorage storage = _storage(directory);

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/session/session-1',
      photoStorage: storage,
      photoPicker: picker,
    );

    expect(find.text('0 of 3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-session-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo-source-gallery')));
    await tester.pumpAndSettle();

    expect(picker.lastSource, PhotoSource.gallery);
    expect(storage.importCount, 1);
    expect(find.byKey(const Key('session-photo-0')), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
  });

  testWidgets('a cancelled pick leaves the photo count unchanged', (
    WidgetTester tester,
  ) async {
    final Directory directory = _photoDirectory();
    final FakePhotoPicker picker = FakePhotoPicker();
    final MemoryPhotoStorage storage = _storage(directory);

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/session/session-1',
      photoStorage: storage,
      photoPicker: picker,
    );

    await tester.tap(find.byKey(const Key('add-session-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo-source-camera')));
    await tester.pumpAndSettle();

    expect(picker.lastSource, PhotoSource.camera);
    expect(storage.importCount, 0);
    expect(find.text('0 of 3'), findsOneWidget);
  });

  testWidgets('an unreadable pick is refused with a reason and no photo', (
    WidgetTester tester,
  ) async {
    final Directory directory = _photoDirectory();
    final FakePhotoPicker picker = FakePhotoPicker(
      next: _sourcePhoto(directory),
    );
    final MemoryPhotoStorage storage = _storage(
      directory,
      importFailure: PhotoFailure.unreadable,
    );

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/session/session-1',
      photoStorage: storage,
      photoPicker: picker,
    );

    await tester.tap(find.byKey(const Key('add-session-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo-source-gallery')));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not read this image. Try another one.'),
      findsOneWidget,
    );
    expect(find.text('0 of 3'), findsOneWidget);
    expect(find.byKey(const Key('session-photo-0')), findsNothing);
  });

  testWidgets('low storage is refused with a reason and no partial photo', (
    WidgetTester tester,
  ) async {
    final Directory directory = _photoDirectory();
    final FakePhotoPicker picker = FakePhotoPicker(
      next: _sourcePhoto(directory),
    );
    final MemoryPhotoStorage storage = _storage(
      directory,
      importFailure: PhotoFailure.outOfSpace,
    );

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/session/session-1',
      photoStorage: storage,
      photoPicker: picker,
    );

    await tester.tap(find.byKey(const Key('add-session-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo-source-gallery')));
    await tester.pumpAndSettle();

    expect(find.text('Not enough storage to save the photo.'), findsOneWidget);
    expect(find.text('0 of 3'), findsOneWidget);
    expect(find.byKey(const Key('session-photo-0')), findsNothing);
  });

  testWidgets('a picker failure is shown without changing photos', (
    WidgetTester tester,
  ) async {
    final Directory directory = _photoDirectory();
    final FakePhotoPicker picker = FakePhotoPicker(
      next: _sourcePhoto(directory),
    )..throwOnPick = true;
    final MemoryPhotoStorage storage = _storage(directory);

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/session/session-1',
      photoStorage: storage,
      photoPicker: picker,
    );

    await tester.tap(find.byKey(const Key('add-session-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo-source-camera')));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not read this image. Try another one.'),
      findsOneWidget,
    );
    expect(storage.importCount, 0);
    expect(find.text('0 of 3'), findsOneWidget);
  });

  testWidgets('three photos hide the add action and state the limit', (
    WidgetTester tester,
  ) async {
    final Directory directory = _photoDirectory();
    final Set<String> names = <String>{
      for (int slot = 0; slot < maxSessionPhotos; slot++)
        sessionPhotoFileName('session-1', slot),
    };
    for (final String name in names) {
      _writePhoto(directory, name);
    }

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/session/session-1',
      photoStorage: _storage(directory, fileNames: names),
    );

    expect(find.text('3 of 3'), findsOneWidget);
    expect(find.byKey(const Key('add-session-photo')), findsNothing);
    expect(
      find.text('You can add up to 3 photos per session.'),
      findsOneWidget,
    );
  });

  testWidgets('exercise photo is shown in editor, picker, and detail', (
    WidgetTester tester,
  ) async {
    final Directory directory = _photoDirectory();
    _writePhoto(directory, 'exercise_exercise-1.jpg');
    final MemoryPhotoStorage storage = _storage(
      directory,
      fileNames: <String>{'exercise_exercise-1.jpg'},
    );

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/exercise-editor/exercise-1',
      photoStorage: storage,
    );
    expect(find.byKey(const Key('exercise-photo-section')), findsOneWidget);
    expect(find.byKey(const Key('exercise-photo-thumbnail')), findsOneWidget);

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/exercise-picker',
      photoStorage: storage,
    );
    expect(find.byKey(const Key('picker-photo-exercise-1')), findsOneWidget);

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/progress/exercise-1',
      photoStorage: storage,
    );
    expect(find.byKey(const Key('exercise-detail-photo')), findsOneWidget);
  });

  testWidgets(
    'removing an exercise photo deletes it and restores the add action',
    (WidgetTester tester) async {
      final Directory directory = _photoDirectory();
      _writePhoto(directory, 'exercise_exercise-1.jpg');
      final MemoryPhotoStorage storage = _storage(
        directory,
        fileNames: <String>{'exercise_exercise-1.jpg'},
      );

      await pumpGymLogApp(
        tester,
        store: MemoryAppDataStore(_data()),
        initialLocation: '/exercise-editor/exercise-1',
        photoStorage: storage,
      );

      await tester.tap(find.byKey(const Key('remove-exercise-photo')));
      await tester.pumpAndSettle();
      expect(find.text('Remove photo?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exercise-photo-thumbnail')), findsNothing);
      expect(find.byKey(const Key('remove-exercise-photo')), findsNothing);
      expect(storage.removeCount, 1);
    },
  );

  testWidgets('deleting a session removes its photo files from the index', (
    WidgetTester tester,
  ) async {
    final Directory directory = _photoDirectory();
    final Set<String> names = <String>{
      'session_session-1_0.jpg',
      'session_session-1_1.jpg',
    };
    for (final String name in names) {
      _writePhoto(directory, name);
    }
    final MemoryPhotoStorage storage = _storage(directory, fileNames: names);

    await pumpGymLogApp(
      tester,
      store: MemoryAppDataStore(_data()),
      initialLocation: '/session/session-1',
      photoStorage: storage,
    );

    await tester.tap(find.byKey(const Key('delete-session')));
    await tester.pumpAndSettle();
    expect(find.text('Delete session?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(storage.index.sessionSlots('session-1'), isEmpty);
    expect(
      directory.listSync().whereType<File>().where((File file) {
        return file.path.contains('session_session-1');
      }),
      isEmpty,
    );
  });

  testWidgets(
    'lost activity recovery attaches the photo to its pending session',
    (WidgetTester tester) async {
      final Directory directory = _photoDirectory();
      final File lost = _writePhoto(directory, 'lost.png');
      final MemoryPhotoStorage storage = _storage(directory);
      final MemoryPhotoPendingStore pending = MemoryPhotoPendingStore()
        ..target = PhotoTarget.session('session-1');

      final FakePhotoPicker picker = FakePhotoPicker(lost: lost);
      await pumpGymLogApp(
        tester,
        store: MemoryAppDataStore(_data()),
        initialLocation: '/workout',
        photoStorage: storage,
        photoPicker: picker,
        photoPendingStore: pending,
      );
      expect(picker.retrieveCount, 1);
      expect(pending.target, isNull);
      expect(storage.index.sessionSlots('session-1'), <int>[0]);
    },
  );
}
