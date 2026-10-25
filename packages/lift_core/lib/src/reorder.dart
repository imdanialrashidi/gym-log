import 'program.dart';

/// Moves a day and renumbers every `sortOrder` from the resulting position.
///
/// [newIndex] follows Flutter's `onReorderItem` contract: it is already
/// adjusted for the removed item, so it is a valid index in the shortened list.
List<ProgramDay> reorderProgramDays(
  List<ProgramDay> days,
  int oldIndex,
  int newIndex,
) {
  RangeError.checkValidIndex(oldIndex, days, 'oldIndex');
  final List<ProgramDay> reordered = List<ProgramDay>.of(days);
  final ProgramDay moved = reordered.removeAt(oldIndex);
  RangeError.checkValueInInterval(newIndex, 0, reordered.length, 'newIndex');
  reordered.insert(newIndex, moved);
  return <ProgramDay>[
    for (int index = 0; index < reordered.length; index++)
      reordered[index].copyWith(sortOrder: index),
  ];
}

/// Moves a plan item and renumbers every `sortOrder`.
List<PlanItem> reorderPlanItems(
  List<PlanItem> items,
  int oldIndex,
  int newIndex,
) {
  RangeError.checkValidIndex(oldIndex, items, 'oldIndex');
  final List<PlanItem> reordered = List<PlanItem>.of(items);
  final PlanItem moved = reordered.removeAt(oldIndex);
  RangeError.checkValueInInterval(newIndex, 0, reordered.length, 'newIndex');
  reordered.insert(newIndex, moved);
  return <PlanItem>[
    for (int index = 0; index < reordered.length; index++)
      reordered[index].copyWith(sortOrder: index),
  ];
}
