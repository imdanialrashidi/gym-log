import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/reorder_handle.dart';
import '../../../core/widgets/text_empty_state.dart';
import '../../../data/app_data_controller.dart';

enum _DayAction { rename, delete }

class DayEditorScreen extends ConsumerWidget {
  const DayEditorScreen({
    required this.programId,
    required this.dayId,
    super.key,
  });

  final String programId;
  final String dayId;

  Future<void> _addPlanItem(
    BuildContext context,
    WidgetRef ref,
    ProgramDay day,
  ) async {
    await context.push(AppRoutes.planItemEditor(day.id, 'new'));
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    Program program,
    ProgramDay day,
  ) async {
    final String? name = await showNameDialog(
      context,
      title: context.l10n.editDayTitle,
      label: context.l10n.dayNameLabel,
      initialValue: day.name,
    );
    if (name == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .renameDay(program.id, day.id, name);
    } catch (_) {
      if (context.mounted) {
        _showSaveError(context);
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Program program,
    ProgramDay day,
  ) async {
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await confirmDestructive(
      context,
      title: l10n.deleteDayTitle,
      message: l10n.deleteDayBody,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .deleteDay(program.id, day.id);
      if (context.mounted) {
        context.pop();
      }
    } catch (_) {
      if (context.mounted) {
        _showSaveError(context);
      }
    }
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    ProgramDay day,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .reorderPlanItems(day.id, oldIndex, newIndex);
    } catch (_) {
      if (context.mounted) {
        _showSaveError(context);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AppData> asyncData = ref.watch(appDataControllerProvider);

    return asyncData.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.programsTab)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => Scaffold(
        appBar: AppBar(title: Text(l10n.programsTab)),
        body: TextEmptyState(
          message: l10n.loadFailed,
          action: OutlinedButton.icon(
            onPressed: () => ref.invalidate(appDataControllerProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ),
      ),
      data: (AppData data) {
        final Program? program = data.programById(programId);
        ProgramDay? day;
        if (program != null) {
          for (final ProgramDay candidate in program.days) {
            if (candidate.id == dayId) {
              day = candidate;
            }
          }
        }
        if (program == null || day == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.programsTab)),
            body: TextEmptyState(message: l10n.dayNotFound),
          );
        }
        final ProgramDay resolvedDay = day;
        return Scaffold(
          appBar: AppBar(
            title: Text(resolvedDay.name),
            actions: <Widget>[
              PopupMenuButton<_DayAction>(
                tooltip: l10n.moreActions,
                onSelected: (_DayAction action) {
                  switch (action) {
                    case _DayAction.rename:
                      unawaited(_rename(context, ref, program, resolvedDay));
                    case _DayAction.delete:
                      unawaited(_delete(context, ref, program, resolvedDay));
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<_DayAction>>[
                      PopupMenuItem<_DayAction>(
                        value: _DayAction.rename,
                        child: Text(l10n.rename),
                      ),
                      PopupMenuItem<_DayAction>(
                        value: _DayAction.delete,
                        child: Text(l10n.delete),
                      ),
                    ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('add-plan-item-fab'),
            onPressed: () => _addPlanItem(context, ref, resolvedDay),
            icon: const Icon(Icons.add),
            label: Text(l10n.newPlanItemTitle),
          ),
          body: resolvedDay.items.isEmpty
              ? TextEmptyState(
                  message: l10n.noPlanItemsYet,
                  action: FilledButton.icon(
                    key: const Key('add-first-plan-item'),
                    onPressed: () => _addPlanItem(context, ref, resolvedDay),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newPlanItemTitle),
                  ),
                )
              : ReorderableListView.builder(
                  key: const Key('plan-item-reorder-list'),
                  padding: const EdgeInsets.only(bottom: 96),
                  buildDefaultDragHandles: false,
                  itemCount: resolvedDay.items.length,
                  onReorderItem: (int oldIndex, int newIndex) => unawaited(
                    _reorder(context, ref, resolvedDay, oldIndex, newIndex),
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final PlanItem item = resolvedDay.items[index];
                    final Exercise? exercise = data.exerciseById(
                      item.exerciseId,
                    );
                    return ListTile(
                      key: ValueKey<String>('plan-item-${item.id}'),
                      leading: const Icon(Icons.fitness_center),
                      title: Text(exercise?.name ?? ''),
                      subtitle: Text(
                        context.digits(
                          l10n.planItemSummary(
                            item.targetSets,
                            item.repMin,
                            item.repMax,
                          ),
                        ),
                      ),
                      trailing: ReorderHandle(
                        index: index,
                        label: l10n.reorder,
                      ),
                      onTap: () => context.push(
                        AppRoutes.planItemEditor(resolvedDay.id, item.id),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

void _showSaveError(BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
}
