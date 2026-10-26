/// Derived personal-record detection (`INT-003`, ADR-0004).
///
/// PRs are never stored. Every call recomputes them from the current sessions,
/// so editing or deleting the record set immediately recalculates which sets
/// hold records. Warm-ups are ignored, the first working set for an exercise is
/// a baseline rather than a PR, and equalling an existing record is not a PR.
library;

import 'e1rm.dart';
import 'session.dart';

/// The three PR kinds defined by `INT-003`.
enum PersonalRecordType {
  /// Heaviest weight for at least one rep.
  heaviestWeight,

  /// Most reps at a given exact weight.
  mostRepsAtWeight,

  /// Highest estimated one-rep maximum (Epley, reps 1–12 only).
  estimatedOneRepMax,
}

/// PR types keyed by [SetLog.id] for one exercise.
///
/// Sets that are not PRs (including warm-ups and the first working set) are
/// present with an empty set, so callers can distinguish "no PR" from "this
/// set does not belong to the exercise".
typedef PersonalRecordsBySet = Map<String, Set<PersonalRecordType>>;

/// Recomputes PR status for every working set of [exerciseId].
///
/// Sets are compared in logged order across all sessions. Only working sets
/// participate; a tie never counts as a PR. The first working set is the
/// exercise baseline. For [PersonalRecordType.mostRepsAtWeight], the first
/// working set at each exact weight is that weight's local baseline, so only a
/// later set with more reps at the same weight earns the PR.
PersonalRecordsBySet personalRecordsForExercise({
  required List<Session> sessions,
  required String exerciseId,
}) {
  return personalRecordsForExercises(
    sessions: sessions,
    exerciseIds: <String>[exerciseId],
  )[exerciseId]!;
}

/// Recomputes PR status for several exercises in one pass over [sessions].
///
/// Identical per-exercise results to [personalRecordsForExercise], but the
/// session/exercise scan happens once. Every wanted ID is present in the
/// result, including exercises with no entries (an empty map).
Map<String, PersonalRecordsBySet> personalRecordsForExercises({
  required List<Session> sessions,
  required Iterable<String> exerciseIds,
}) {
  final Set<String> wanted = exerciseIds.toSet();
  final Map<String, List<_LoggedEntry>> entriesByExercise =
      <String, List<_LoggedEntry>>{
        for (final String exerciseId in wanted) exerciseId: <_LoggedEntry>[],
      };
  for (final Session session in sessions) {
    for (final SessionExercise exercise in session.exercises) {
      final List<_LoggedEntry>? entries =
          entriesByExercise[exercise.exerciseId];
      if (entries == null) {
        continue;
      }
      for (final SetLog set in exercise.workingSets) {
        entries.add(_LoggedEntry(session: session, set: set));
      }
    }
  }

  return <String, PersonalRecordsBySet>{
    for (final String exerciseId in wanted)
      exerciseId: _recordsForEntries(entriesByExercise[exerciseId]!),
  };
}

PersonalRecordsBySet _recordsForEntries(List<_LoggedEntry> entries) {
  entries.sort(_compareEntries);

  final PersonalRecordsBySet records = <String, Set<PersonalRecordType>>{};
  int? bestWeight;
  int? bestE1rm;
  final Map<int, int> bestRepsAtWeight = <int, int>{};
  bool hasBaseline = false;

  for (final _LoggedEntry entry in entries) {
    final SetLog set = entry.set;
    final Set<PersonalRecordType> types = <PersonalRecordType>{};
    final E1rmEstimate? estimate = estimateOneRepMax(
      weightGrams: set.weightGrams,
      reps: set.reps,
    );

    if (!hasBaseline) {
      // The first working set establishes the baseline; it is never a PR.
      hasBaseline = true;
    } else {
      if (bestWeight != null && set.weightGrams > bestWeight) {
        types.add(PersonalRecordType.heaviestWeight);
      }
      // The first set at a weight seeds that weight's local baseline; only a
      // later, higher rep count at the exact weight is a PR.
      final int? previousReps = bestRepsAtWeight[set.weightGrams];
      if (previousReps != null && set.reps > previousReps) {
        types.add(PersonalRecordType.mostRepsAtWeight);
      }
      if (estimate != null && bestE1rm != null && estimate.grams > bestE1rm) {
        types.add(PersonalRecordType.estimatedOneRepMax);
      }
    }

    if (bestWeight == null || set.weightGrams > bestWeight) {
      bestWeight = set.weightGrams;
    }
    final int? previousReps = bestRepsAtWeight[set.weightGrams];
    if (previousReps == null || set.reps > previousReps) {
      bestRepsAtWeight[set.weightGrams] = set.reps;
    }
    if (estimate != null && (bestE1rm == null || estimate.grams > bestE1rm)) {
      bestE1rm = estimate.grams;
    }

    records[set.id] = Set<PersonalRecordType>.unmodifiable(types);
  }

  return records;
}

/// Recomputes the PR types earned by exactly one logged set.
///
/// This is the single-set form of [personalRecordsForExercise]: it returns the
/// same set for [setId] without sorting or allocating the full map. Sets that
/// do not exist for [exerciseId], warm-ups, and the exercise baseline return an
/// empty set. Every comparison uses the same rules and [_compareEntries] order
/// as the full map; a tie is never a PR.
Set<PersonalRecordType> personalRecordTypesForSet({
  required List<Session> sessions,
  required String exerciseId,
  required String setId,
}) {
  _LoggedEntry? target;
  final List<_LoggedEntry> entries = <_LoggedEntry>[];
  for (final Session session in sessions) {
    for (final SessionExercise exercise in session.exercises) {
      if (exercise.exerciseId != exerciseId) {
        continue;
      }
      for (final SetLog set in exercise.workingSets) {
        final _LoggedEntry entry = _LoggedEntry(session: session, set: set);
        entries.add(entry);
        if (set.id == setId) {
          target = entry;
        }
      }
    }
  }
  if (target == null) {
    return const <PersonalRecordType>{};
  }

  int? bestWeight;
  int? bestE1rm;
  final Map<int, int> bestRepsAtWeight = <int, int>{};
  bool hasBaseline = false;
  for (final _LoggedEntry entry in entries) {
    // Strictly earlier entries establish the state the target is judged
    // against; this is the same order the full map sorts into.
    if (_compareEntries(entry, target) >= 0) {
      continue;
    }
    final SetLog set = entry.set;
    hasBaseline = true;
    if (bestWeight == null || set.weightGrams > bestWeight) {
      bestWeight = set.weightGrams;
    }
    final int? previousReps = bestRepsAtWeight[set.weightGrams];
    if (previousReps == null || set.reps > previousReps) {
      bestRepsAtWeight[set.weightGrams] = set.reps;
    }
    final E1rmEstimate? estimate = estimateOneRepMax(
      weightGrams: set.weightGrams,
      reps: set.reps,
    );
    if (estimate != null && (bestE1rm == null || estimate.grams > bestE1rm)) {
      bestE1rm = estimate.grams;
    }
  }
  if (!hasBaseline) {
    return const <PersonalRecordType>{};
  }

  final SetLog set = target.set;
  final Set<PersonalRecordType> types = <PersonalRecordType>{};
  final E1rmEstimate? estimate = estimateOneRepMax(
    weightGrams: set.weightGrams,
    reps: set.reps,
  );
  if (bestWeight != null && set.weightGrams > bestWeight) {
    types.add(PersonalRecordType.heaviestWeight);
  }
  final int? previousReps = bestRepsAtWeight[set.weightGrams];
  if (previousReps != null && set.reps > previousReps) {
    types.add(PersonalRecordType.mostRepsAtWeight);
  }
  if (estimate != null && bestE1rm != null && estimate.grams > bestE1rm) {
    types.add(PersonalRecordType.estimatedOneRepMax);
  }
  return Set<PersonalRecordType>.unmodifiable(types);
}

/// One record-holding set inside a single session.
class SessionRecord {
  const SessionRecord({
    required this.sessionExerciseId,
    required this.exerciseId,
    required this.setId,
    required this.weightGrams,
    required this.reps,
    required this.types,
  });

  final String sessionExerciseId;
  final String exerciseId;
  final String setId;
  final int weightGrams;
  final int reps;
  final Set<PersonalRecordType> types;
}

/// All record-holding sets inside [sessionId], in exercise/set order.
///
/// Uses the same all-time rules as [personalRecordsForExercise], so the
/// post-workout summary and the in-session badge can never disagree. Returns an
/// empty list for an unknown session.
List<SessionRecord> personalRecordsInSession({
  required List<Session> sessions,
  required String sessionId,
}) {
  Session? target;
  for (final Session session in sessions) {
    if (session.id == sessionId) {
      target = session;
      break;
    }
  }
  if (target == null) {
    return const <SessionRecord>[];
  }
  final Set<String> exerciseIds = <String>{
    for (final SessionExercise exercise in target.exercises)
      exercise.exerciseId,
  };
  final Map<String, PersonalRecordsBySet> records = personalRecordsForExercises(
    sessions: sessions,
    exerciseIds: exerciseIds,
  );
  final List<SessionRecord> result = <SessionRecord>[];
  for (final SessionExercise exercise in target.exercises) {
    final PersonalRecordsBySet bySet = records[exercise.exerciseId]!;
    for (final SetLog set in exercise.sets) {
      final Set<PersonalRecordType> types = bySet[set.id] ?? const {};
      if (types.isEmpty) {
        continue;
      }
      result.add(
        SessionRecord(
          sessionExerciseId: exercise.id,
          exerciseId: exercise.exerciseId,
          setId: set.id,
          weightGrams: set.weightGrams,
          reps: set.reps,
          types: types,
        ),
      );
    }
  }
  return List<SessionRecord>.unmodifiable(result);
}

class _LoggedEntry {
  const _LoggedEntry({required this.session, required this.set});

  final Session session;
  final SetLog set;
}

int _compareEntries(_LoggedEntry a, _LoggedEntry b) {
  int result = a.set.loggedAt.compareTo(b.set.loggedAt);
  if (result != 0) {
    return result;
  }
  result = a.session.startedAt.compareTo(b.session.startedAt);
  if (result != 0) {
    return result;
  }
  result = a.session.id.compareTo(b.session.id);
  if (result != 0) {
    return result;
  }
  result = a.set.setIndex.compareTo(b.set.setIndex);
  if (result != 0) {
    return result;
  }
  return a.set.id.compareTo(b.set.id);
}
