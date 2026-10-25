import 'session.dart';
import 'session_history.dart';

/// Values copied into a new set row from history (`INT-001`).
///
/// Every field is nullable because a first session has no prefill. RIR is
/// carried over when it was logged; an untouched historical RIR stays null.
class SetPrefill {
  const SetPrefill({this.weightGrams, this.reps, this.rir});

  static const SetPrefill empty = SetPrefill();

  final int? weightGrams;
  final int? reps;
  final int? rir;

  bool get isEmpty => weightGrams == null && reps == null && rir == null;
}

/// Prefill for [setIndex] of [exerciseId] from the most recent previous
/// session that contains the exercise (`INT-001`).
///
/// Only working sets are indexed; warm-ups are ignored. If [setIndex] does not
/// exist in that session, its last working set is used. If the most recent
/// session has only warm-ups, the result is empty instead of falling back to an
/// older session. [excludeSessionId] keeps the active session out of its own
/// history.
SetPrefill prefillForExercise({
  required List<Session> sessions,
  required String exerciseId,
  required int setIndex,
  String? excludeSessionId,
}) {
  if (setIndex < 0) {
    throw ArgumentError.value(setIndex, 'setIndex');
  }

  final Session? latest = latestSessionForExercise(
    sessions: sessions,
    exerciseId: exerciseId,
    excludeSessionId: excludeSessionId,
  );
  if (latest == null) {
    return SetPrefill.empty;
  }

  final List<SetLog> workingSets = <SetLog>[
    for (final SessionExercise exercise in latest.exercises)
      if (exercise.exerciseId == exerciseId) ...exercise.workingSets,
  ];
  if (workingSets.isEmpty) {
    return SetPrefill.empty;
  }
  final SetLog chosen =
      workingSets[setIndex < workingSets.length
          ? setIndex
          : workingSets.length - 1];
  return SetPrefill(
    weightGrams: chosen.weightGrams,
    reps: chosen.reps,
    rir: chosen.rir,
  );
}
