import 'package:flutter_test/flutter_test.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_app_data_store.dart';
import '../support/test_app.dart';

Exercise _exercise(
  String id,
  String name, {
  bool archived = false,
  MuscleGroup? muscleGroup,
}) {
  return Exercise(
    id: id,
    name: name,
    muscleGroup: muscleGroup,
    archivedAt: archived ? DateTime.utc(2026, 10, 21, 12) : null,
    createdAt: DateTime.utc(2026, 10, 20, 10),
  );
}

void main() {
  testWidgets('fresh install shows the empty prompt and opens create', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore();

    await pumpGymLogApp(tester, store: store, initialLocation: '/exercises');

    expect(find.text('No exercises yet.'), findsOneWidget);
    expect(find.byKey(const Key('add-first-exercise')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-first-exercise')));
    await tester.pumpAndSettle();

    expect(find.text('New exercise'), findsOneWidget);
    expect(find.byKey(const Key('exercise-name-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('exercise-name-field')),
      'Bench Press',
    );
    await tester.tap(find.byKey(const Key('save-exercise')));
    await tester.pumpAndSettle();

    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('No exercises yet.'), findsNothing);
    expect(store.data.exercises.single.name, 'Bench Press');
  });

  testWidgets('archive hides the exercise but preserves its record', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      AppData(
        exercises: <Exercise>[
          _exercise(
            'exercise-1',
            'Bench Press',
            muscleGroup: MuscleGroup.chest,
          ),
        ],
      ),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/exercises');
    expect(find.text('Bench Press'), findsOneWidget);

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsNothing);
    expect(
      find.text('No active exercises. Show archived to see them.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('show-archived-chip')));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Archived · Chest'), findsOneWidget);
    expect(store.data.exerciseById('exercise-1'), isNotNull);
    expect(store.data.exerciseById('exercise-1')!.isArchived, isTrue);
    expect(store.data.activeExercises, isEmpty);
  });

  testWidgets('picker hides archived exercises and applies Persian search', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      AppData(
        exercises: <Exercise>[
          _exercise('exercise-1', 'Bench Press'),
          _exercise('exercise-2', 'Squat', archived: true),
          _exercise('exercise-3', 'پرس سینه'),
        ],
      ),
    );

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/exercise-picker',
    );

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Squat'), findsNothing);
    expect(find.text('پرس سینه'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('exercise-picker-search')),
      'BEN',
    );
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('پرس سینه'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('exercise-picker-search')),
      'پرس سينه',
    );
    await tester.pumpAndSettle();

    expect(find.text('پرس سینه'), findsOneWidget);
    expect(find.text('Bench Press'), findsNothing);
  });

  testWidgets('picker explains when every exercise is archived', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      AppData(
        exercises: <Exercise>[_exercise('exercise-1', 'Squat', archived: true)],
      ),
    );

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/exercise-picker',
    );

    expect(find.text('Squat'), findsNothing);
    expect(
      find.text('No active exercises. Add a new exercise.'),
      findsOneWidget,
    );
    expect(find.text('No exercises yet.'), findsNothing);
    expect(find.text('Add exercise'), findsOneWidget);
  });

  testWidgets('lookup launches the encoded image-search URL', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      AppData(exercises: <Exercise>[_exercise('exercise-1', 'AT&T #1')]),
    );
    final List<Uri> launched = <Uri>[];

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/exercises',
      externalLinkLauncher: (Uri uri) async {
        launched.add(uri);
        return true;
      },
    );

    await tester.tap(find.byTooltip('Look up images'));
    await tester.pumpAndSettle();

    expect(launched, hasLength(1));
    expect(launched.single.host, 'www.google.com');
    expect(launched.single.queryParameters['tbm'], 'isch');
    expect(launched.single.queryParameters['q'], 'AT&T #1');
    expect(launched.single.toString(), contains('%26'));
    expect(launched.single.toString(), contains('%23'));
    expect(find.textContaining('Could not open a browser'), findsNothing);
  });

  testWidgets('failed lookup shows a non-blocking message', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      AppData(
        exercises: <Exercise>[
          _exercise(
            'exercise-1',
            'Bench Press',
            muscleGroup: MuscleGroup.chest,
          ),
        ],
      ),
    );

    await pumpGymLogApp(
      tester,
      store: store,
      initialLocation: '/exercises',
      externalLinkLauncher: (Uri uri) async {
        throw StateError('no browser');
      },
    );

    await tester.tap(find.byTooltip('Look up images'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Could not open a browser. Search for the exercise manually.'),
      findsOneWidget,
    );
    expect(find.text('Bench Press'), findsOneWidget);
  });

  testWidgets('duplicate names warn but can still be saved', (
    WidgetTester tester,
  ) async {
    final MemoryAppDataStore store = MemoryAppDataStore(
      AppData(exercises: <Exercise>[_exercise('exercise-1', 'Bench Press')]),
    );

    await pumpGymLogApp(tester, store: store, initialLocation: '/exercises');

    await tester.tap(find.byKey(const Key('add-exercise-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('exercise-name-field')),
      'bench press',
    );
    await tester.tap(find.byKey(const Key('save-exercise')));
    await tester.pumpAndSettle();

    expect(find.text('Duplicate name'), findsOneWidget);
    expect(
      find.text('An exercise named "bench press" already exists. Save anyway?'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('save-duplicate-exercise')));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('bench press'), findsOneWidget);
  });
}
