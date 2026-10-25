import 'json_reader.dart';
import 'rep_range.dart';
import 'weight.dart';

/// Fixed muscle-group list (`EXR-006`). Optional on an exercise.
enum MuscleGroup {
  chest('chest'),
  back('back'),
  shoulders('shoulders'),
  biceps('biceps'),
  triceps('triceps'),
  forearms('forearms'),
  quadriceps('quadriceps'),
  hamstrings('hamstrings'),
  glutes('glutes'),
  calves('calves'),
  abdominals('abdominals'),
  fullBody('full_body');

  const MuscleGroup(this.jsonValue);

  final String jsonValue;

  static MuscleGroup? fromJson(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw const FormatException('"muscleGroup" must be a string or null');
    }
    for (final MuscleGroup group in MuscleGroup.values) {
      if (group.jsonValue == value) {
        return group;
      }
    }
    throw FormatException('Unknown muscle group "$value"');
  }
}

const Object _absent = Object();

/// A user-created exercise (`EXR-001`, `EXR-006`, `EXR-007`).
///
/// Archived exercises are retained so history references keep resolving; the
/// picker filters on [archivedAt].
class Exercise {
  factory Exercise({
    required String id,
    required String name,
    required DateTime createdAt,
    String? searchTerm,
    MuscleGroup? muscleGroup,
    int? defaultRepMin,
    int? defaultRepMax,
    int incrementGrams = defaultKilogramIncrementGrams,
    DateTime? archivedAt,
  }) {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Exercise name is required');
    }
    if (incrementGrams <= 0 || incrementGrams > maximumSetWeightGrams) {
      throw ArgumentError.value(
        incrementGrams,
        'incrementGrams',
        'Increment must be positive and no more than '
            '$maximumSetWeightGrams grams',
      );
    }
    if ((defaultRepMin == null) != (defaultRepMax == null)) {
      throw ArgumentError(
        'Default rep minimum and maximum must be provided together',
      );
    }
    if (defaultRepMin != null && defaultRepMax != null) {
      if (validateRepRange(defaultRepMin, defaultRepMax) != null) {
        throw ArgumentError(
          'Default rep range must satisfy 1 <= min <= max <= 100',
        );
      }
    }
    final String? trimmedSearchTerm = searchTerm?.trim();

    return Exercise._(
      id: id,
      name: trimmedName,
      searchTerm: (trimmedSearchTerm == null || trimmedSearchTerm.isEmpty)
          ? null
          : trimmedSearchTerm,
      muscleGroup: muscleGroup,
      defaultRepMin: defaultRepMin,
      defaultRepMax: defaultRepMax,
      incrementGrams: incrementGrams,
      archivedAt: archivedAt?.toUtc(),
      createdAt: createdAt.toUtc(),
    );
  }

  const Exercise._({
    required this.id,
    required this.name,
    required this.searchTerm,
    required this.muscleGroup,
    required this.defaultRepMin,
    required this.defaultRepMax,
    required this.incrementGrams,
    required this.archivedAt,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? searchTerm;
  final MuscleGroup? muscleGroup;
  final int? defaultRepMin;
  final int? defaultRepMax;
  final int incrementGrams;
  final DateTime? archivedAt;
  final DateTime createdAt;

  bool get isArchived => archivedAt != null;

  Exercise copyWith({
    String? name,
    Object? searchTerm = _absent,
    Object? muscleGroup = _absent,
    Object? defaultRepMin = _absent,
    Object? defaultRepMax = _absent,
    int? incrementGrams,
    Object? archivedAt = _absent,
  }) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      searchTerm: identical(searchTerm, _absent)
          ? this.searchTerm
          : searchTerm as String?,
      muscleGroup: identical(muscleGroup, _absent)
          ? this.muscleGroup
          : muscleGroup as MuscleGroup?,
      defaultRepMin: identical(defaultRepMin, _absent)
          ? this.defaultRepMin
          : defaultRepMin as int?,
      defaultRepMax: identical(defaultRepMax, _absent)
          ? this.defaultRepMax
          : defaultRepMax as int?,
      incrementGrams: incrementGrams ?? this.incrementGrams,
      archivedAt: identical(archivedAt, _absent)
          ? this.archivedAt
          : archivedAt as DateTime?,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'searchTerm': searchTerm,
    'muscleGroup': muscleGroup?.jsonValue,
    'defaultRepMin': defaultRepMin,
    'defaultRepMax': defaultRepMax,
    'incrementGrams': incrementGrams,
    'archivedAt': archivedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Exercise.fromJson(Map<String, Object?> json) {
    return Exercise(
      id: readString(json, 'id'),
      name: readString(json, 'name'),
      searchTerm: readOptionalString(json, 'searchTerm'),
      muscleGroup: MuscleGroup.fromJson(json['muscleGroup']),
      defaultRepMin: readOptionalInt(json, 'defaultRepMin'),
      defaultRepMax: readOptionalInt(json, 'defaultRepMax'),
      incrementGrams: readInt(json, 'incrementGrams'),
      archivedAt: readOptionalDateTime(json, 'archivedAt'),
      createdAt: readDateTime(json, 'createdAt'),
    );
  }
}
