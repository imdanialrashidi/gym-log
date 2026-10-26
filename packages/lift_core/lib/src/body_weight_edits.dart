import 'app_data.dart';
import 'body_weight.dart';

/// Adds one body-weight check-in (`BODY-001`).
///
/// The caller owns id generation and the clock, matching the other edits.
({AppData data, BodyWeightEntry entry}) addBodyWeightEntry(
  AppData data, {
  required String id,
  required int weightGrams,
  required DateTime recordedAt,
}) {
  final BodyWeightEntry entry = BodyWeightEntry(
    id: id,
    weightGrams: weightGrams,
    recordedAt: recordedAt,
  );
  return (
    data: data.copyWith(
      bodyWeights: <BodyWeightEntry>[...data.bodyWeights, entry],
    ),
    entry: entry,
  );
}

/// Replaces one check-in's value, keeping its id, for a same-week update.
({AppData data, BodyWeightEntry entry}) replaceBodyWeightEntry(
  AppData data, {
  required String id,
  required int weightGrams,
  required DateTime recordedAt,
}) {
  final BodyWeightEntry existing = _requireEntry(data, id);
  final BodyWeightEntry updated = BodyWeightEntry(
    id: existing.id,
    weightGrams: weightGrams,
    recordedAt: recordedAt,
  );
  return (
    data: data.copyWith(
      bodyWeights: <BodyWeightEntry>[
        for (final BodyWeightEntry entry in data.bodyWeights)
          if (entry.id == id) updated else entry,
      ],
    ),
    entry: updated,
  );
}

/// Removes one check-in and returns it so the caller can offer Undo.
({AppData data, BodyWeightEntry entry}) deleteBodyWeightEntry(
  AppData data,
  String id,
) {
  final BodyWeightEntry removed = _requireEntry(data, id);
  return (
    data: data.copyWith(
      bodyWeights: <BodyWeightEntry>[
        for (final BodyWeightEntry entry in data.bodyWeights)
          if (entry.id != removed.id) entry,
      ],
    ),
    entry: removed,
  );
}

BodyWeightEntry _requireEntry(AppData data, String id) {
  for (final BodyWeightEntry entry in data.bodyWeights) {
    if (entry.id == id) {
      return entry;
    }
  }
  throw StateError('Body-weight entry $id does not exist');
}
