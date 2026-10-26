import 'app_data.dart';
import 'exercise.dart';
import 'weight.dart';

/// Creates an exercise and appends it to the document.
({AppData data, Exercise exercise}) createExercise(
  AppData data, {
  required String id,
  required String name,
  required DateTime createdAt,
  String? searchTerm,
  MuscleGroup? muscleGroup,
  int? defaultRepMin,
  int? defaultRepMax,
  int incrementGrams = defaultKilogramIncrementGrams,
}) {
  final Exercise exercise = Exercise(
    id: id,
    name: name,
    searchTerm: searchTerm,
    muscleGroup: muscleGroup,
    defaultRepMin: defaultRepMin,
    defaultRepMax: defaultRepMax,
    incrementGrams: incrementGrams,
    createdAt: createdAt,
  );
  return (
    data: data.copyWith(exercises: <Exercise>[...data.exercises, exercise]),
    exercise: exercise,
  );
}

AppData updateExercise(AppData data, Exercise exercise) {
  _requireExercise(data, exercise.id);
  return data.copyWith(
    exercises: <Exercise>[
      for (final Exercise existing in data.exercises)
        if (existing.id == exercise.id) exercise else existing,
    ],
  );
}

/// Archives or restores an exercise. A missing id leaves the document
/// unchanged, matching the archive toggle's best-effort behavior.
AppData setExerciseArchived(
  AppData data,
  String exerciseId, {
  required bool archived,
  required DateTime changedAt,
}) {
  return data.copyWith(
    exercises: <Exercise>[
      for (final Exercise exercise in data.exercises)
        if (exercise.id == exerciseId)
          exercise.copyWith(archivedAt: archived ? changedAt.toUtc() : null)
        else
          exercise,
    ],
  );
}

Exercise _requireExercise(AppData data, String exerciseId) {
  final Exercise? exercise = data.exerciseById(exerciseId);
  if (exercise == null) {
    throw StateError('Exercise $exerciseId does not exist');
  }
  return exercise;
}
