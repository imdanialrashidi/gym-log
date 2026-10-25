import 'session.dart';

/// The most recent session that contains [exerciseId] (`INT-001`, `INT-002`).
///
/// Recency is the latest [Session.startedAt]. [excludeSessionId] keeps the
/// active session out of its own history. Ties keep the later entry in
/// [sessions], matching the prefill contract.
Session? latestSessionForExercise({
  required List<Session> sessions,
  required String exerciseId,
  String? excludeSessionId,
}) {
  Session? latest;
  for (final Session session in sessions) {
    if (session.id == excludeSessionId) {
      continue;
    }
    if (!session.exercises.any(
      (SessionExercise exercise) => exercise.exerciseId == exerciseId,
    )) {
      continue;
    }
    if (latest == null || !session.startedAt.isBefore(latest.startedAt)) {
      latest = session;
    }
  }
  return latest;
}
