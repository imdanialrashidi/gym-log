import 'json_reader.dart';
import 'rep_range.dart';

const Object _absent = Object();

/// One exercise inside a program day (`PLAN-002`).
///
/// The constructor enforces `1 <= repMin <= repMax <= 100`; the editors run
/// the same rule first so users see inline messages instead of exceptions.
class PlanItem {
  factory PlanItem({
    required String id,
    required String exerciseId,
    required int targetSets,
    required int repMin,
    required int repMax,
    required int sortOrder,
  }) {
    if (!isValidTargetSets(targetSets)) {
      throw ArgumentError.value(targetSets, 'targetSets');
    }
    final RepRangeProblem? problem = validateRepRange(repMin, repMax);
    if (problem != null) {
      throw ArgumentError('Invalid rep range: $problem');
    }
    if (sortOrder < 0) {
      throw ArgumentError.value(sortOrder, 'sortOrder');
    }
    return PlanItem._(
      id: id,
      exerciseId: exerciseId,
      targetSets: targetSets,
      repMin: repMin,
      repMax: repMax,
      sortOrder: sortOrder,
    );
  }

  const PlanItem._({
    required this.id,
    required this.exerciseId,
    required this.targetSets,
    required this.repMin,
    required this.repMax,
    required this.sortOrder,
  });

  final String id;
  final String exerciseId;
  final int targetSets;
  final int repMin;
  final int repMax;
  final int sortOrder;

  PlanItem copyWith({
    String? exerciseId,
    int? targetSets,
    int? repMin,
    int? repMax,
    int? sortOrder,
  }) {
    return PlanItem(
      id: id,
      exerciseId: exerciseId ?? this.exerciseId,
      targetSets: targetSets ?? this.targetSets,
      repMin: repMin ?? this.repMin,
      repMax: repMax ?? this.repMax,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'exerciseId': exerciseId,
    'targetSets': targetSets,
    'repMin': repMin,
    'repMax': repMax,
    'sortOrder': sortOrder,
  };

  factory PlanItem.fromJson(Map<String, Object?> json) {
    return PlanItem(
      id: readString(json, 'id'),
      exerciseId: readString(json, 'exerciseId'),
      targetSets: readInt(json, 'targetSets'),
      repMin: readInt(json, 'repMin'),
      repMax: readInt(json, 'repMax'),
      sortOrder: readInt(json, 'sortOrder'),
    );
  }
}

/// A named, ordered day inside a program (`PLAN-001`).
class ProgramDay {
  ProgramDay({
    required this.id,
    required String name,
    required this.sortOrder,
    List<PlanItem> items = const <PlanItem>[],
  }) : name = name.trim(),
       items = List<PlanItem>.unmodifiable(
         List<PlanItem>.of(items)..sort(
           (PlanItem a, PlanItem b) => a.sortOrder.compareTo(b.sortOrder),
         ),
       ) {
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Day name is required');
    }
    if (sortOrder < 0) {
      throw ArgumentError.value(sortOrder, 'sortOrder');
    }
  }

  final String id;
  final String name;
  final int sortOrder;
  final List<PlanItem> items;

  ProgramDay copyWith({String? name, int? sortOrder, List<PlanItem>? items}) {
    return ProgramDay(
      id: id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      items: items ?? this.items,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'sortOrder': sortOrder,
    'items': <Object?>[for (final PlanItem item in items) item.toJson()],
  };

  factory ProgramDay.fromJson(Map<String, Object?> json) {
    return ProgramDay(
      id: readString(json, 'id'),
      name: readString(json, 'name'),
      sortOrder: readInt(json, 'sortOrder'),
      items: <PlanItem>[
        for (final Object? item in readList(json, 'items'))
          PlanItem.fromJson(readMap(item, 'items')),
      ],
    );
  }
}

/// A program with ordered days (`PLAN-001`).
class Program {
  factory Program({
    required String id,
    required String name,
    required DateTime createdAt,
    List<ProgramDay> days = const <ProgramDay>[],
    DateTime? archivedAt,
  }) {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Program name is required');
    }
    return Program._(
      id: id,
      name: trimmedName,
      createdAt: createdAt.toUtc(),
      archivedAt: archivedAt?.toUtc(),
      days: List<ProgramDay>.unmodifiable(
        List<ProgramDay>.of(days)..sort(
          (ProgramDay a, ProgramDay b) => a.sortOrder.compareTo(b.sortOrder),
        ),
      ),
    );
  }

  const Program._({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.archivedAt,
    required this.days,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? archivedAt;
  final List<ProgramDay> days;

  Program copyWith({
    String? name,
    List<ProgramDay>? days,
    Object? archivedAt = _absent,
  }) {
    return Program(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      archivedAt: identical(archivedAt, _absent)
          ? this.archivedAt
          : archivedAt as DateTime?,
      days: days ?? this.days,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'archivedAt': archivedAt?.toIso8601String(),
    'days': <Object?>[for (final ProgramDay day in days) day.toJson()],
  };

  factory Program.fromJson(Map<String, Object?> json) {
    return Program(
      id: readString(json, 'id'),
      name: readString(json, 'name'),
      createdAt: readDateTime(json, 'createdAt'),
      archivedAt: readOptionalDateTime(json, 'archivedAt'),
      days: <ProgramDay>[
        for (final Object? day in readList(json, 'days'))
          ProgramDay.fromJson(readMap(day, 'days')),
      ],
    );
  }
}
