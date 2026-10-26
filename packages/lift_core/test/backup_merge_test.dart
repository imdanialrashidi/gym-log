import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

import 'backup_support.dart';

void main() {
  group('merge policy', () {
    test('adds everything to an empty database and matches the counts', () {
      final AppData incoming = sampleData();
      final MergeResult result = mergeAppData(AppData(), incoming);

      final ImportCounts incomingCounts = countAppData(incoming);
      expect(result.summary.incoming, incomingCounts);
      expect(result.summary.added, incomingCounts);
      expect(result.summary.conflicts, 0);
      expect(result.summary.unchangedRecords, 0);
      expect(countAppData(result.data), incomingCounts);
      expect(
        result.data.settings.weightUnit,
        WeightUnit.pounds,
        reason: 'Merge restores settings when no local training data exists.',
      );
      expect(result.data.exercises.first.name, incoming.exercises.first.name);
    });

    test('counts identical same-ID records as unchanged, not conflicts', () {
      final AppData incoming = sampleData();
      final AppData current = AppData(
        exercises: <Exercise>[incoming.exercises.first],
      );

      final MergeResult result = mergeAppData(current, incoming);

      expect(result.summary.unchanged.exercises, 1);
      expect(result.summary.conflicts, 0);
      expect(result.summary.added.exercises, 1);
      expect(result.summary.added.programs, 1);
      expect(result.summary.added.sessions, 1);
      expect(result.summary.added.sets, 1);
      expect(result.data.exercises, hasLength(2));
    });

    test('same ID with different content keeps the local record and reports a conflict', () {
      final AppData incoming = sampleData();
      final Exercise localExercise = Exercise(
        id: 'exercise-1',
        name: 'Local Press',
        createdAt: DateTime.utc(2026, 9, 1, 9),
      );
      final AppData current = AppData(exercises: <Exercise>[localExercise]);

      final MergeResult result = mergeAppData(current, incoming);

      expect(result.data.exerciseById('exercise-1')!.name, 'Local Press');
      expect(result.summary.conflicts, 1);
      expect(result.summary.added.exercises, 1);
      expect(result.summary.added.programs, 1);
      expect(result.summary.added.sessions, 1);
      expect(result.summary.settingsChanged, isFalse);
    });

    test('settings-only backup is a change only on an empty database', () {
      final AppData incoming = AppData(
        settings: const AppSettings(weightUnit: WeightUnit.pounds),
      );
      final MergeResult empty = mergeAppData(AppData(), incoming);
      expect(empty.summary.settingsChanged, isTrue);
      expect(empty.data.settings.weightUnit, WeightUnit.pounds);

      final AppData withData = AppData(
        exercises: <Exercise>[
          Exercise(
            id: 'exercise-1',
            name: 'Bench Press',
            createdAt: DateTime.utc(2026, 9, 1, 9),
          ),
        ],
      );
      final MergeResult nonEmpty = mergeAppData(withData, incoming);
      expect(nonEmpty.summary.settingsChanged, isFalse);
      expect(nonEmpty.data.settings.weightUnit, WeightUnit.kilograms);
    });

    test('local active session wins over an incoming active session', () {
      final Exercise localExercise = Exercise(
        id: 'exercise-1',
        name: 'Bench Press',
        createdAt: DateTime.utc(2026, 9, 1, 9),
      );
      final Session localActive = Session(
        id: 'local-active',
        startedAt: DateTime.utc(2026, 10, 20, 17),
        exercises: <SessionExercise>[
          SessionExercise(
            id: 'local-active-exercise',
            exerciseId: localExercise.id,
            sortOrder: 0,
          ),
        ],
      );
      final Session incomingActive = Session(
        id: 'incoming-active',
        startedAt: DateTime.utc(2026, 10, 21, 17),
        exercises: <SessionExercise>[
          SessionExercise(
            id: 'incoming-active-exercise',
            exerciseId: localExercise.id,
            sortOrder: 0,
          ),
        ],
      );
      final AppData current = AppData(
        exercises: <Exercise>[localExercise],
        sessions: <Session>[localActive],
      );

      final MergeResult result = mergeAppData(
        current,
        AppData(
          exercises: <Exercise>[localExercise],
          sessions: <Session>[incomingActive],
        ),
      );

      expect(result.data.sessions, hasLength(1));
      expect(result.data.sessions.single.id, 'local-active');
      expect(result.summary.conflicts, 1);
      expect(result.summary.added.sessions, 0);
    });

    test(
      'cross-type ID collisions skip the record and unresolvable dependents',
      () {
        final AppData current = AppData(
          programs: <Program>[
            Program(
              id: 'collision',
              name: 'Existing',
              createdAt: DateTime.utc(2026, 9, 1, 9),
            ),
          ],
        );
        final Exercise incomingExercise = Exercise(
          id: 'collision',
          name: 'Incoming',
          createdAt: DateTime.utc(2026, 9, 1, 9),
        );
        final Session incomingSession = Session(
          id: 'incoming-session',
          startedAt: DateTime.utc(2026, 10, 20, 17),
          exercises: <SessionExercise>[
            SessionExercise(
              id: 'incoming-session-exercise',
              exerciseId: incomingExercise.id,
              sortOrder: 0,
            ),
          ],
        );

        final MergeResult result = mergeAppData(
          current,
          AppData(
            exercises: <Exercise>[incomingExercise],
            sessions: <Session>[incomingSession],
          ),
        );

        expect(result.data.exercises, isEmpty);
        expect(result.data.sessions, isEmpty);
        expect(result.summary.conflicts, 2);
        expect(result.summary.added, ImportCounts.zero);
      },
    );
  });

  group('preview', () {
    test('Merge preview exposes the planned result and summary', () {
      final BackupDocument document = parseBackup(
        buildBackupJson(
          sampleData(),
          appVersion: testAppVersion,
          exportedAt: testExportedAt,
        ),
      );

      final ImportPreview preview = previewImport(
        current: AppData(),
        document: document,
        mode: ImportMode.merge,
      );

      expect(preview.mode, ImportMode.merge);
      expect(preview.summary.added, countAppData(document.data));
      expect(preview.summary.conflicts, 0);
      expect(countAppData(preview.data), preview.summary.added);
    });

    test('merges body-weight check-ins by id and keeps local conflicts', () {
      final BodyWeightEntry shared = BodyWeightEntry(
        id: 'weight-1',
        weightGrams: 80000,
        recordedAt: DateTime.utc(2026, 10, 21, 7),
      );
      final BodyWeightEntry incomingOnly = BodyWeightEntry(
        id: 'weight-2',
        weightGrams: 79000,
        recordedAt: DateTime.utc(2026, 10, 28, 7),
      );
      final AppData incoming = AppData(
        bodyWeights: <BodyWeightEntry>[incomingOnly],
      );
      final MergeResult result = mergeAppData(
        AppData(bodyWeights: <BodyWeightEntry>[shared]),
        incoming,
      );

      expect(result.data.bodyWeights, hasLength(2));
      expect(result.summary.added.bodyWeights, 1);
      expect(result.summary.conflicts, 0);
      expect(result.data.settings.weightUnit, WeightUnit.kilograms);

      final BodyWeightEntry changed = BodyWeightEntry(
        id: 'weight-1',
        weightGrams: 81000,
        recordedAt: DateTime.utc(2026, 10, 21, 7),
      );
      final MergeResult conflict = mergeAppData(
        AppData(bodyWeights: <BodyWeightEntry>[shared]),
        AppData(bodyWeights: <BodyWeightEntry>[changed]),
      );
      expect(conflict.data.bodyWeights.single.weightGrams, 80000);
      expect(conflict.summary.conflicts, 1);
    });

    test('Replace preview uses the incoming document and settings', () {
      final AppData incoming = sampleData();
      final BackupDocument document = parseBackup(
        buildBackupJson(
          incoming,
          appVersion: testAppVersion,
          exportedAt: testExportedAt,
        ),
      );

      final ImportPreview preview = previewImport(
        current: AppData(),
        document: document,
        mode: ImportMode.replace,
      );

      expect(preview.summary.added, countAppData(incoming));
      expect(preview.data.settings.weightUnit, WeightUnit.pounds);
      expect(preview.data.exercises.first.name, 'Bench Press');
    });
  });
}
