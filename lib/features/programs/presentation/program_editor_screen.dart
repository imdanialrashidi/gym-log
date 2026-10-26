import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/document_gate.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/action_runner.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/reorder_handle.dart';
import '../../../core/widgets/text_empty_state.dart';
import '../../../data/app_data_controller.dart';

enum _ProgramAction { rename, delete }

class ProgramEditorScreen extends ConsumerWidget {
  const ProgramEditorScreen({required this.programId, super.key});

  final String programId;

  Future<void> _addDay(
    BuildContext context,
    WidgetRef ref,
    Program program,
  ) async {
    final AppLocalizations l10n = context.l10n;
    final String? name = await showNameDialog(
      context,
      title: l10n.newDayTitle,
      label: l10n.dayNameLabel,
      maxLength: maximumDayNameLength,
    );
    if (name == null || !context.mounted) {
      return;
    }
    ProgramDay? day;
    final bool saved = await runDataAction(context, () async {
      day = await ref
          .read(appDataControllerProvider.notifier)
          .addDay(program.id, name);
    });
    if (!saved || day == null || !context.mounted) {
      return;
    }
    await context.push(AppRoutes.dayEditor(program.id, day!.id));
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    Program program,
  ) async {
    final String? name = await showNameDialog(
      context,
      title: context.l10n.editProgramTitle,
      label: context.l10n.programNameLabel,
      maxLength: maximumProgramNameLength,
      initialValue: program.name,
    );
    if (name == null || !context.mounted) {
      return;
    }
    await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .renameProgram(program.id, name),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Program program,
  ) async {
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await confirmDestructive(
      context,
      title: l10n.deleteProgramTitle,
      message: l10n.deleteProgramBody,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final bool saved = await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .deleteProgram(program.id),
    );
    if (saved && context.mounted && context.canPop()) {
      context.pop();
    }
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    Program program,
    int oldIndex,
    int newIndex,
  ) async {
    await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .reorderDays(program.id, oldIndex, newIndex),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return DocumentGate(
      fallbackTitle: l10n.programsTab,
      builder: (BuildContext context, AppData data) {
        final Program? program = data.programById(programId);
        if (program == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.programsTab)),
            body: TextEmptyState(message: l10n.programNotFound),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(program.name),
            actions: <Widget>[
              PopupMenuButton<_ProgramAction>(
                tooltip: l10n.moreActions,
                onSelected: (_ProgramAction action) {
                  switch (action) {
                    case _ProgramAction.rename:
                      unawaited(_rename(context, ref, program));
                    case _ProgramAction.delete:
                      unawaited(_delete(context, ref, program));
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<_ProgramAction>>[
                      PopupMenuItem<_ProgramAction>(
                        value: _ProgramAction.rename,
                        child: Text(l10n.rename),
                      ),
                      PopupMenuItem<_ProgramAction>(
                        value: _ProgramAction.delete,
                        child: Text(l10n.delete),
                      ),
                    ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('add-day-fab'),
            onPressed: () => _addDay(context, ref, program),
            icon: const Icon(Icons.add),
            label: Text(l10n.addDay),
          ),
          body: program.days.isEmpty
              ? TextEmptyState(
                  message: l10n.noDaysYet,
                  action: FilledButton.icon(
                    key: const Key('add-first-day'),
                    onPressed: () => _addDay(context, ref, program),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addDay),
                  ),
                )
              : ReorderableListView.builder(
                  key: const Key('day-reorder-list'),
                  padding: const EdgeInsets.only(bottom: 96),
                  buildDefaultDragHandles: false,
                  itemCount: program.days.length,
                  onReorderItem: (int oldIndex, int newIndex) => unawaited(
                    _reorder(context, ref, program, oldIndex, newIndex),
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final ProgramDay day = program.days[index];
                    return ListTile(
                      key: ValueKey<String>('day-${day.id}'),
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(day.name),
                      trailing: ReorderHandle(
                        index: index,
                        label: l10n.reorder,
                      ),
                      onTap: () =>
                          context.push(AppRoutes.dayEditor(program.id, day.id)),
                    );
                  },
                ),
        );
      },
    );
  }
}
