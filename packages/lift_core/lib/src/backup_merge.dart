import 'dart:convert';

import 'app_data.dart';
import 'backup.dart';
import 'body_weight.dart';
import 'exercise.dart';
import 'program.dart';
import 'session.dart';

/// How a validated backup is committed (`IO-003`).
enum ImportMode { merge, replace }

/// Record counts used by the dry-run summary and commit verification.
class ImportCounts {
  const ImportCounts({
    this.exercises = 0,
    this.programs = 0,
    this.days = 0,
    this.planItems = 0,
    this.sessions = 0,
    this.sessionExercises = 0,
    this.sets = 0,
    this.bodyWeights = 0,
  });

  static const ImportCounts zero = ImportCounts();

  final int exercises;
  final int programs;
  final int days;
  final int planItems;
  final int sessions;
  final int sessionExercises;
  final int sets;
  final int bodyWeights;

  int get topLevelRecords => exercises + programs + sessions + bodyWeights;

  int get totalRecords =>
      exercises +
      programs +
      days +
      planItems +
      sessions +
      sessionExercises +
      sets +
      bodyWeights;

  ImportCounts operator +(ImportCounts other) {
    return ImportCounts(
      exercises: exercises + other.exercises,
      programs: programs + other.programs,
      days: days + other.days,
      planItems: planItems + other.planItems,
      sessions: sessions + other.sessions,
      sessionExercises: sessionExercises + other.sessionExercises,
      sets: sets + other.sets,
      bodyWeights: bodyWeights + other.bodyWeights,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ImportCounts &&
        other.exercises == exercises &&
        other.programs == programs &&
        other.days == days &&
        other.planItems == planItems &&
        other.sessions == sessions &&
        other.sessionExercises == sessionExercises &&
        other.sets == sets &&
        other.bodyWeights == bodyWeights;
  }

  @override
  int get hashCode => Object.hash(
    exercises,
    programs,
    days,
    planItems,
    sessions,
    sessionExercises,
    sets,
    bodyWeights,
  );

  @override
  String toString() =>
      'ImportCounts(exercises: $exercises, programs: $programs, '
      'days: $days, planItems: $planItems, sessions: $sessions, '
      'sessionExercises: $sessionExercises, sets: $sets, '
      'bodyWeights: $bodyWeights)';
}

/// Outcome counts for a Merge dry run.
class MergeSummary {
  const MergeSummary({
    required this.incoming,
    required this.added,
    required this.unchanged,
    required this.conflicts,
    this.settingsChanged = false,
  });

  final ImportCounts incoming;
  final ImportCounts added;

  /// Same-ID records whose content is identical; only top-level records are
  /// counted here.
  final ImportCounts unchanged;

  /// Same-ID/different-content records plus new records that could not be
  /// added without breaking identity or references. The local copy is kept.
  final int conflicts;

  /// Merge restores the file's settings only when no local training data
  /// exists. The dry run needs this signal so a settings-only backup can be
  /// applied.
  final bool settingsChanged;

  int get unchangedRecords =>
      unchanged.exercises + unchanged.programs + unchanged.sessions;

  @override
  bool operator ==(Object other) {
    return other is MergeSummary &&
        other.incoming == incoming &&
        other.added == added &&
        other.unchanged == unchanged &&
        other.conflicts == conflicts &&
        other.settingsChanged == settingsChanged;
  }

  @override
  int get hashCode =>
      Object.hash(incoming, added, unchanged, conflicts, settingsChanged);

  @override
  String toString() =>
      'MergeSummary(incoming: $incoming, added: $added, '
      'unchanged: $unchanged, conflicts: $conflicts, '
      'settingsChanged: $settingsChanged)';
}

class MergeResult {
  const MergeResult({required this.data, required this.summary});

  final AppData data;
  final MergeSummary summary;
}

/// One validated, previewed import. [data] is the exact planned result for the
/// selected mode; the controller re-plans Merge at commit time and refuses to
/// write if the counts changed.
class ImportPreview {
  const ImportPreview({
    required this.mode,
    required this.document,
    required this.summary,
    required this.data,
  });

  final ImportMode mode;
  final BackupDocument document;
  final MergeSummary summary;
  final AppData data;
}

/// Thrown when the current data changed between preview and commit.
class ImportPreviewMismatch implements Exception {
  const ImportPreviewMismatch();

  @override
  String toString() => 'ImportPreviewMismatch';
}

ImportCounts countAppData(AppData data) {
  int days = 0;
  int planItems = 0;
  for (final Program program in data.programs) {
    days += program.days.length;
    for (final ProgramDay day in program.days) {
      planItems += day.items.length;
    }
  }
  int sessionExercises = 0;
  int sets = 0;
  for (final Session session in data.sessions) {
    sessionExercises += session.exercises.length;
    for (final SessionExercise exercise in session.exercises) {
      sets += exercise.sets.length;
    }
  }
  return ImportCounts(
    exercises: data.exercises.length,
    programs: data.programs.length,
    days: days,
    planItems: planItems,
    sessions: data.sessions.length,
    sessionExercises: sessionExercises,
    sets: sets,
    bodyWeights: data.bodyWeights.length,
  );
}

ImportPreview previewImport({
  required AppData current,
  required BackupDocument document,
  required ImportMode mode,
}) {
  if (mode == ImportMode.replace) {
    final ImportCounts incoming = countAppData(document.data);
    return ImportPreview(
      mode: mode,
      document: document,
      summary: MergeSummary(
        incoming: incoming,
        added: incoming,
        unchanged: ImportCounts.zero,
        conflicts: 0,
      ),
      data: document.data,
    );
  }
  final MergeResult result = mergeAppData(current, document.data);
  return ImportPreview(
    mode: mode,
    document: document,
    summary: result.summary,
    data: result.data,
  );
}

/// Applies the accepted Merge policy without mutating either input.
///
/// Existing records are never overwritten or renamed. Same-ID/different-content
/// records keep the local copy; a new top-level record is skipped when any of
/// its IDs collides with existing data or when a referenced exercise cannot
/// exist after conflicts. Local settings win when training data already
/// exists; an empty database accepts the file's settings so export -> import ->
/// export is equivalent (`IO-004`).
MergeResult mergeAppData(AppData current, AppData incoming) {
  final Set<String> usedIds = <String>{};
  _collectIds(current, usedIds);

  final List<Exercise> exercises = <Exercise>[...current.exercises];
  final List<Program> programs = <Program>[...current.programs];
  final List<Session> sessions = <Session>[...current.sessions];
  final List<BodyWeightEntry> bodyWeights = <BodyWeightEntry>[
    ...current.bodyWeights,
  ];

  final Map<String, Exercise> currentExercises = <String, Exercise>{
    for (final Exercise exercise in current.exercises) exercise.id: exercise,
  };
  final Map<String, Program> currentPrograms = <String, Program>{
    for (final Program program in current.programs) program.id: program,
  };
  final Map<String, Session> currentSessions = <String, Session>{
    for (final Session session in current.sessions) session.id: session,
  };
  final Map<String, BodyWeightEntry> currentBodyWeights =
      <String, BodyWeightEntry>{
        for (final BodyWeightEntry entry in current.bodyWeights)
          entry.id: entry,
      };
  final Set<String> mergedExerciseIds = <String>{
    for (final Exercise exercise in current.exercises) exercise.id,
  };

  ImportCounts added = ImportCounts.zero;
  ImportCounts unchanged = ImportCounts.zero;
  int conflicts = 0;

  for (final Exercise exercise in incoming.exercises) {
    final Exercise? existing = currentExercises[exercise.id];
    if (existing != null) {
      if (_sameJson(existing.toJson(), exercise.toJson())) {
        unchanged = unchanged + const ImportCounts(exercises: 1);
      } else {
        conflicts += 1;
      }
      continue;
    }
    final Set<String> ids = <String>{exercise.id};
    if (ids.any(usedIds.contains)) {
      conflicts += 1;
      continue;
    }
    exercises.add(exercise);
    usedIds.addAll(ids);
    mergedExerciseIds.add(exercise.id);
    added = added + const ImportCounts(exercises: 1);
  }

  for (final Program program in incoming.programs) {
    final Program? existing = currentPrograms[program.id];
    if (existing != null) {
      if (_sameJson(existing.toJson(), program.toJson())) {
        unchanged = unchanged + const ImportCounts(programs: 1);
      } else {
        conflicts += 1;
      }
      continue;
    }
    if (!_programReferencesResolve(program, mergedExerciseIds) ||
        _programIds(program).any(usedIds.contains)) {
      conflicts += 1;
      continue;
    }
    programs.add(program);
    usedIds.addAll(_programIds(program));
    int planItems = 0;
    for (final ProgramDay day in program.days) {
      planItems += day.items.length;
    }
    added =
        added +
        ImportCounts(
          programs: 1,
          days: program.days.length,
          planItems: planItems,
        );
  }

  bool hasActiveSession = current.activeSession != null;

  for (final Session session in incoming.sessions) {
    final Session? existing = currentSessions[session.id];
    if (existing != null) {
      if (_sameJson(existing.toJson(), session.toJson())) {
        unchanged = unchanged + const ImportCounts(sessions: 1);
      } else {
        conflicts += 1;
      }
      continue;
    }
    if (!_sessionReferencesResolve(session, mergedExerciseIds) ||
        _sessionIds(session).any(usedIds.contains) ||
        (session.isActive && hasActiveSession)) {
      conflicts += 1;
      continue;
    }
    sessions.add(session);
    usedIds.addAll(_sessionIds(session));
    if (session.isActive) {
      hasActiveSession = true;
    }
    final int sessionExercises = session.exercises.length;
    int sets = 0;
    for (final SessionExercise exercise in session.exercises) {
      sets += exercise.sets.length;
    }
    added =
        added +
        ImportCounts(
          sessions: 1,
          sessionExercises: sessionExercises,
          sets: sets,
        );
  }

  for (final BodyWeightEntry entry in incoming.bodyWeights) {
    final BodyWeightEntry? existing = currentBodyWeights[entry.id];
    if (existing != null) {
      if (_sameJson(existing.toJson(), entry.toJson())) {
        unchanged = unchanged + const ImportCounts(bodyWeights: 1);
      } else {
        conflicts += 1;
      }
      continue;
    }
    if (usedIds.contains(entry.id)) {
      conflicts += 1;
      continue;
    }
    bodyWeights.add(entry);
    usedIds.add(entry.id);
    added = added + const ImportCounts(bodyWeights: 1);
  }

  final bool hasLocalData =
      current.exercises.isNotEmpty ||
      current.programs.isNotEmpty ||
      current.sessions.isNotEmpty ||
      current.bodyWeights.isNotEmpty;
  final bool settingsChanged =
      !hasLocalData &&
      !_sameJson(current.settings.toJson(), incoming.settings.toJson());
  final AppData data = AppData(
    exercises: exercises,
    programs: programs,
    sessions: sessions,
    bodyWeights: bodyWeights,
    settings: hasLocalData ? current.settings : incoming.settings,
  );

  return MergeResult(
    data: data,
    summary: MergeSummary(
      incoming: countAppData(incoming),
      added: added,
      unchanged: unchanged,
      conflicts: conflicts,
      settingsChanged: settingsChanged,
    ),
  );
}

bool _sameJson(Map<String, Object?> a, Map<String, Object?> b) {
  return jsonEncode(a) == jsonEncode(b);
}

bool _programReferencesResolve(Program program, Set<String> exerciseIds) {
  for (final ProgramDay day in program.days) {
    for (final PlanItem item in day.items) {
      if (!exerciseIds.contains(item.exerciseId)) {
        return false;
      }
    }
  }
  return true;
}

bool _sessionReferencesResolve(Session session, Set<String> exerciseIds) {
  for (final SessionExercise exercise in session.exercises) {
    if (!exerciseIds.contains(exercise.exerciseId)) {
      return false;
    }
  }
  return true;
}

void _collectIds(AppData data, Set<String> ids) {
  for (final Exercise exercise in data.exercises) {
    ids.add(exercise.id);
  }
  for (final Program program in data.programs) {
    ids.addAll(_programIds(program));
  }
  for (final Session session in data.sessions) {
    ids.addAll(_sessionIds(session));
  }
  for (final BodyWeightEntry entry in data.bodyWeights) {
    ids.add(entry.id);
  }
}

Set<String> _programIds(Program program) {
  final Set<String> ids = <String>{program.id};
  for (final ProgramDay day in program.days) {
    ids.add(day.id);
    for (final PlanItem item in day.items) {
      ids.add(item.id);
    }
  }
  return ids;
}

Set<String> _sessionIds(Session session) {
  final Set<String> ids = <String>{session.id};
  for (final SessionExercise exercise in session.exercises) {
    ids.add(exercise.id);
    for (final SetLog set in exercise.sets) {
      ids.add(set.id);
    }
  }
  return ids;
}
