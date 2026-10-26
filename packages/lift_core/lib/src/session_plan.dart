import 'prefill.dart';
import 'session.dart';

/// One row in a session-exercise card: either an already logged set or an
/// editable row seeded from history (`INT-001`).
class SessionRowPlan {
  const SessionRowPlan({required this.index, this.savedSet, this.prefill});

  /// Zero-based row position inside the session exercise.
  final int index;

  /// The logged set for this row, or null for an editable row.
  final SetLog? savedSet;

  /// Prefill for an editable row. Always null when [savedSet] is non-null.
  final SetPrefill? prefill;
}

/// Builds the rows for one session exercise.
///
/// The row count covers the planned target sets and any set logged past them,
/// plus [extraRows] opened by the user. Warm-ups do not consume a prefill
/// index, so editable rows are seeded by working-set position, not row number.
List<SessionRowPlan> planSessionRows({
  required SessionExercise sessionExercise,
  required List<SetLog> previousWorkingSets,
  int extraRows = 0,
}) {
  if (extraRows < 0) {
    throw ArgumentError.value(extraRows, 'extraRows');
  }
  final Map<int, SetLog> loggedByIndex = <int, SetLog>{
    for (final SetLog set in sessionExercise.sets) set.setIndex: set,
  };
  final int highestLoggedIndex = sessionExercise.sets.isEmpty
      ? -1
      : sessionExercise.sets.last.setIndex;
  final int plannedRows = sessionExercise.targetSets ?? 1;
  final int rowCount =
      (plannedRows > highestLoggedIndex + 1
          ? plannedRows
          : highestLoggedIndex + 1) +
      extraRows;

  final List<SessionRowPlan> rows = <SessionRowPlan>[];
  int workingIndex = 0;
  for (int index = 0; index < rowCount; index++) {
    final SetLog? saved = loggedByIndex[index];
    if (saved == null) {
      rows.add(
        SessionRowPlan(
          index: index,
          prefill: prefillFromWorkingSets(
            workingSets: previousWorkingSets,
            setIndex: workingIndex,
          ),
        ),
      );
      workingIndex += 1;
      continue;
    }
    rows.add(SessionRowPlan(index: index, savedSet: saved));
    if (!saved.isWarmup) {
      workingIndex += 1;
    }
  }
  return rows;
}
