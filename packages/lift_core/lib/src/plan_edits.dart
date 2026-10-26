import 'app_data.dart';
import 'limits.dart';
import 'program.dart';
import 'reorder.dart' as reorder;

/// Creates a program and appends it to the document.
({AppData data, Program program}) createProgram(
  AppData data, {
  required String id,
  required String name,
  required DateTime createdAt,
}) {
  final Program program = Program(id: id, name: name, createdAt: createdAt);
  return (
    data: data.copyWith(programs: <Program>[...data.programs, program]),
    program: program,
  );
}

AppData renameProgram(AppData data, String programId, String name) {
  _requireProgram(data, programId);
  return data.copyWith(
    programs: <Program>[
      for (final Program program in data.programs)
        if (program.id == programId) program.copyWith(name: name) else program,
    ],
  );
}

AppData deleteProgram(AppData data, String programId) {
  _requireProgram(data, programId);
  return data.copyWith(
    programs: <Program>[
      for (final Program program in data.programs)
        if (program.id != programId) program,
    ],
  );
}

({AppData data, ProgramDay day}) addDay(
  AppData data, {
  required String id,
  required String programId,
  required String name,
}) {
  final Program program = _requireProgram(data, programId);
  final ProgramDay day = ProgramDay(
    id: id,
    name: name,
    sortOrder: _nextSortOrder(
      program.days.isEmpty ? null : program.days.last.sortOrder,
    ),
  );
  return (
    data: data.copyWith(
      programs: <Program>[
        for (final Program existing in data.programs)
          if (existing.id == programId)
            existing.copyWith(days: <ProgramDay>[...existing.days, day])
          else
            existing,
      ],
    ),
    day: day,
  );
}

AppData renameDay(AppData data, String programId, String dayId, String name) {
  final Program program = _requireProgram(data, programId);
  _requireDayInProgram(program, dayId);
  return data.copyWith(
    programs: <Program>[
      for (final Program existing in data.programs)
        if (existing.id == programId)
          existing.copyWith(
            days: <ProgramDay>[
              for (final ProgramDay day in existing.days)
                if (day.id == dayId) day.copyWith(name: name) else day,
            ],
          )
        else
          existing,
    ],
  );
}

AppData deleteDay(AppData data, String programId, String dayId) {
  final Program program = _requireProgram(data, programId);
  _requireDayInProgram(program, dayId);
  return data.copyWith(
    programs: <Program>[
      for (final Program existing in data.programs)
        if (existing.id == programId)
          existing.copyWith(
            days: <ProgramDay>[
              for (final ProgramDay day in existing.days)
                if (day.id != dayId) day,
            ],
          )
        else
          existing,
    ],
  );
}

AppData reorderDays(
  AppData data,
  String programId,
  int oldIndex,
  int newIndex,
) {
  return data.copyWith(
    programs: <Program>[
      for (final Program program in data.programs)
        if (program.id == programId)
          program.copyWith(
            days: reorder.reorderProgramDays(program.days, oldIndex, newIndex),
          )
        else
          program,
    ],
  );
}

({AppData data, PlanItem item}) addPlanItem(
  AppData data, {
  required String id,
  required String dayId,
  required String exerciseId,
  required int targetSets,
  required int repMin,
  required int repMax,
}) {
  final ProgramDay day = _requireDay(data, dayId);
  final PlanItem item = PlanItem(
    id: id,
    exerciseId: exerciseId,
    targetSets: targetSets,
    repMin: repMin,
    repMax: repMax,
    sortOrder: _nextSortOrder(
      day.items.isEmpty ? null : day.items.last.sortOrder,
    ),
  );
  return (
    data: _replaceDay(
      data,
      dayId,
      (ProgramDay existing) =>
          existing.copyWith(items: <PlanItem>[...existing.items, item]),
    ),
    item: item,
  );
}

AppData updatePlanItem(AppData data, PlanItem item) {
  return _replaceDay(
    data,
    _dayIdForItem(data, item.id),
    (ProgramDay day) => day.copyWith(
      items: <PlanItem>[
        for (final PlanItem existing in day.items)
          if (existing.id == item.id) item else existing,
      ],
    ),
  );
}

AppData deletePlanItem(AppData data, String dayId, String itemId) {
  final ProgramDay day = _requireDay(data, dayId);
  _requirePlanItem(day, itemId);
  return _replaceDay(
    data,
    dayId,
    (ProgramDay existing) => existing.copyWith(
      items: <PlanItem>[
        for (final PlanItem item in existing.items)
          if (item.id != itemId) item,
      ],
    ),
  );
}

AppData reorderItemsInDay(
  AppData data,
  String dayId,
  int oldIndex,
  int newIndex,
) {
  return _replaceDay(
    data,
    dayId,
    (ProgramDay day) => day.copyWith(
      items: reorder.reorderPlanItems(day.items, oldIndex, newIndex),
    ),
  );
}

int _nextSortOrder(int? last) {
  if (last == null) {
    return 0;
  }
  final int next = last + 1;
  if (next > maximumSortOrder) {
    throw StateError('Sort order is exhausted at $maximumSortOrder');
  }
  return next;
}

Program _requireProgram(AppData data, String programId) {
  final Program? program = data.programById(programId);
  if (program == null) {
    throw StateError('Program $programId does not exist');
  }
  return program;
}

ProgramDay _requireDay(AppData data, String dayId) {
  final ProgramDay? day = data.dayById(dayId);
  if (day == null) {
    throw StateError('Day $dayId does not exist');
  }
  return day;
}

ProgramDay _requireDayInProgram(Program program, String dayId) {
  final ProgramDay? day = program.days
      .where((ProgramDay candidate) => candidate.id == dayId)
      .firstOrNull;
  if (day == null) {
    throw StateError('Day $dayId does not exist');
  }
  return day;
}

void _requirePlanItem(ProgramDay day, String itemId) {
  if (!day.items.any((PlanItem item) => item.id == itemId)) {
    throw StateError('Plan item $itemId does not exist');
  }
}

String _dayIdForItem(AppData data, String itemId) {
  for (final Program program in data.programs) {
    for (final ProgramDay day in program.days) {
      if (day.items.any((PlanItem item) => item.id == itemId)) {
        return day.id;
      }
    }
  }
  throw StateError('Plan item $itemId does not exist');
}

AppData _replaceDay(
  AppData data,
  String dayId,
  ProgramDay Function(ProgramDay day) update,
) {
  _requireDay(data, dayId);
  return data.copyWith(
    programs: <Program>[
      for (final Program program in data.programs)
        program.copyWith(
          days: <ProgramDay>[
            for (final ProgramDay day in program.days)
              if (day.id == dayId) update(day) else day,
          ],
        ),
    ],
  );
}
