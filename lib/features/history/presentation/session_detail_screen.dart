import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/document_gate.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/muscle_labels.dart';
import '../../../core/widgets/action_runner.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/note_dialog.dart';
import '../../../core/widgets/pr_badge.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../core/widgets/training_formats.dart';
import '../../../core/widgets/undo_snack_bar.dart';
import '../../../data/app_data_controller.dart';
import '../../../data/photo_index_controller.dart';
import '../../photos/presentation/session_photos_section.dart';
import '../../workout/presentation/set_edit_dialog.dart';

/// Read-only session detail with notes and set/session editing (`HIS-002`,
/// `LOG-006`, `LOG-007`).
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessionDetailTitle),
        actions: <Widget>[_DeleteSessionAction(sessionId: sessionId)],
      ),
      body: DocumentGate(
        builder: (BuildContext context, AppData data) {
          final Session? session = data.sessionById(sessionId);
          if (session == null) {
            return Center(
              child: Text(
                l10n.sessionNotFound,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          final SessionStats stats = sessionStatsFor(
            session,
            exercises: data.exercises,
          );
          final Map<String, SessionExerciseStats> statsByExercise =
              <String, SessionExerciseStats>{
                for (final SessionExerciseStats exercise in stats.exercises)
                  exercise.sessionExerciseId: exercise,
              };
          // One session pass for this screen's exercises, not one scan per
          // exercise section.
          final Map<String, PersonalRecordsBySet> personalRecords =
              personalRecordsForExercises(
                sessions: data.sessions,
                exerciseIds: <String>{
                  for (final SessionExercise exercise in session.exercises)
                    exercise.exerciseId,
                },
              );

          return ListView(
            padding: const EdgeInsetsDirectional.all(AppTokens.space2),
            children: <Widget>[
              _SessionSummaryCard(
                session: session,
                stats: stats,
                unit: data.settings.weightUnit,
              ),
              const SizedBox(height: AppTokens.space2),
              _NoteSection(
                label: l10n.sessionNoteLabel,
                note: session.note,
                textKey: const Key('session-note-text'),
                addKey: const Key('add-session-note'),
                editKey: const Key('edit-session-note'),
                onEdit: () => _editSessionNote(context, ref, session),
              ),
              SessionPhotosSection(sessionId: session.id),
              for (final SessionExercise exercise in session.exercises)
                _ExerciseSection(
                  sessionExercise: exercise,
                  exercise: data.exerciseById(exercise.exerciseId),
                  stats: statsByExercise[exercise.id],
                  unit: data.settings.weightUnit,
                  personalRecords:
                      personalRecords[exercise.exerciseId] ??
                      const <String, Set<PersonalRecordType>>{},
                  onEditNote: () =>
                      _editExerciseNote(context, ref, session, exercise),
                  onEditSet: (SetLog set) =>
                      _editSet(context, ref, session, exercise, set),
                  onDeleteSet: (SetLog set) =>
                      _deleteSet(context, ref, session, exercise, set),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editSessionNote(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final String? note = await showNoteDialog(
      context,
      title: context.l10n.sessionNoteLabel,
      initialValue: session.note,
    );
    if (note == null || !context.mounted) {
      return;
    }
    await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .setSessionNote(session.id, note),
    );
  }

  Future<void> _editExerciseNote(
    BuildContext context,
    WidgetRef ref,
    Session session,
    SessionExercise exercise,
  ) async {
    final String? note = await showNoteDialog(
      context,
      title: context.l10n.exerciseNoteLabel,
      initialValue: exercise.note,
    );
    if (note == null || !context.mounted) {
      return;
    }
    await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .setSessionExerciseNote(
            sessionId: session.id,
            sessionExerciseId: exercise.id,
            note: note,
          ),
    );
  }

  Future<void> _editSet(
    BuildContext context,
    WidgetRef ref,
    Session session,
    SessionExercise exercise,
    SetLog set,
  ) async {
    final WeightUnit unit = ref
        .read(appDataControllerProvider)
        .requireValue
        .settings
        .weightUnit;
    final SetEntry? entry = await showSetEditDialog(
      context,
      set: set,
      unit: unit,
    );
    if (entry == null || !context.mounted) {
      return;
    }
    await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .updateSet(
            sessionId: session.id,
            sessionExerciseId: exercise.id,
            setId: set.id,
            entry: entry,
          ),
    );
  }

  Future<void> _deleteSet(
    BuildContext context,
    WidgetRef ref,
    Session session,
    SessionExercise exercise,
    SetLog set,
  ) async {
    final AppDataController controller = ref.read(
      appDataControllerProvider.notifier,
    );
    SetLog? removed;
    final bool saved = await runDataAction(context, () async {
      removed = await controller.deleteSet(
        sessionId: session.id,
        sessionExerciseId: exercise.id,
        setId: set.id,
      );
    });
    if (!saved || removed == null || !context.mounted) {
      return;
    }
    showUndoSnackBar(
      context,
      message: context.l10n.setDeleted,
      onUndo: () async {
        await controller.restoreSet(
          sessionId: session.id,
          sessionExerciseId: exercise.id,
          set: removed!,
        );
      },
    );
  }
}

class _DeleteSessionAction extends ConsumerWidget {
  const _DeleteSessionAction({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session? session = ref
        .watch(appDataControllerProvider)
        .value
        ?.sessionById(sessionId);
    if (session == null) {
      return const SizedBox.shrink();
    }
    return IconButton(
      key: const Key('delete-session'),
      tooltip: context.l10n.deleteSession,
      onPressed: () => _deleteSession(context, ref, session),
      icon: const Icon(Icons.delete_outline),
    );
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await confirmDestructive(
      context,
      title: l10n.deleteSessionTitle,
      message: l10n.deleteSessionBody,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool saved = await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .deleteSession(session.id),
    );
    if (!saved || !context.mounted) {
      return;
    }
    ref.invalidate(photoIndexProvider);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/history');
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.sessionDeleted)));
  }
}

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({
    required this.session,
    required this.stats,
    required this.unit,
  });

  final Session session;
  final SessionStats stats;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return AppCard(
      key: const Key('session-summary-card'),
      borderColor: AppTokens.outlineStrong,
      padding: const EdgeInsetsDirectional.all(AppTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.formatDate(session.startedAt, style: AppDateStyle.dateTime),
            key: const Key('session-detail-date'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.space1),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double half = (constraints.maxWidth - AppTokens.space1) / 2;
              return Wrap(
                spacing: AppTokens.space1,
                runSpacing: AppTokens.space1,
                children: <Widget>[
                  SizedBox(
                    width: half,
                    child: StatTile(
                      label: l10n.sessionTime,
                      value: formatTrainingDuration(context, stats.duration),
                      compact: true,
                    ),
                  ),
                  SizedBox(
                    width: half,
                    child: StatTile(
                      label: l10n.volumeLabel,
                      value: context.digits(
                        formatWeight(stats.volumeGrams, unit),
                      ),
                      unit: weightUnitLabel(context, unit),
                      compact: true,
                    ),
                  ),
                  SizedBox(
                    width: half,
                    child: StatTile(
                      label: l10n.workingSets,
                      value: context.digits('${stats.workingSetCount}'),
                      compact: true,
                    ),
                  ),
                  SizedBox(
                    width: half,
                    child: StatTile(
                      label: l10n.exerciseCount(session.exercises.length),
                      value: context.digits('${session.exercises.length}'),
                      compact: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppTokens.space1,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: AppTokens.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: AppTokens.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSection extends StatelessWidget {
  const _ExerciseSection({
    required this.sessionExercise,
    required this.exercise,
    required this.stats,
    required this.unit,
    required this.personalRecords,
    required this.onEditNote,
    required this.onEditSet,
    required this.onDeleteSet,
  });

  final SessionExercise sessionExercise;
  final Exercise? exercise;
  final SessionExerciseStats? stats;
  final WeightUnit unit;
  final PersonalRecordsBySet personalRecords;
  final VoidCallback onEditNote;
  final void Function(SetLog set) onEditSet;
  final void Function(SetLog set) onDeleteSet;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String noteKeySuffix = sessionExercise.id;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      exercise?.name ?? l10n.exerciseNotFound,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (exercise?.muscleGroup != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        muscleGroupLabel(l10n, exercise!.muscleGroup!),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppTokens.accent),
                      ),
                    ],
                  ],
                ),
              ),
              if (sessionExercise.repMin != null &&
                  sessionExercise.repMax != null)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppTokens.space1,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.surface2,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                  child: Text(
                    context.digits(
                      sessionExercise.targetSets == null
                          ? l10n.repRangeSummary(
                              sessionExercise.repMin!,
                              sessionExercise.repMax!,
                            )
                          : l10n.planItemSummary(
                              sessionExercise.targetSets!,
                              sessionExercise.repMin!,
                              sessionExercise.repMax!,
                            ),
                    ),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppTokens.textSecondary),
                  ),
                ),
            ],
          ),
          if (stats != null) ...<Widget>[
            const SizedBox(height: AppTokens.space1),
            Wrap(
              spacing: AppTokens.space1,
              runSpacing: AppTokens.space1,
              children: <Widget>[
                _MetaPill(
                  icon: Icons.layers_outlined,
                  label: context.digits(l10n.setsLabel(stats!.workingSetCount)),
                ),
                _MetaPill(
                  icon: Icons.scale_outlined,
                  label: context.digits(
                    '${formatWeight(stats!.volumeGrams, unit)} '
                    '${weightUnitLabel(context, unit)}',
                  ),
                ),
                if (stats!.setSpan != null && stats!.setSpan! > Duration.zero)
                  Tooltip(
                    message: l10n.exerciseTimeHint,
                    triggerMode: TooltipTriggerMode.tap,
                    child: _MetaPill(
                      icon: Icons.timer_outlined,
                      label: formatTrainingDuration(context, stats!.setSpan),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppTokens.space1),
          _NoteSection(
            label: l10n.exerciseNoteLabel,
            note: sessionExercise.note,
            textKey: ValueKey<String>('exercise-note-text-$noteKeySuffix'),
            addKey: ValueKey<String>('add-exercise-note-$noteKeySuffix'),
            editKey: ValueKey<String>('edit-exercise-note-$noteKeySuffix'),
            onEdit: onEditNote,
          ),
          const SizedBox(height: AppTokens.space1),
          if (sessionExercise.sets.isEmpty)
            Text(
              l10n.noSetsLogged,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTokens.textSecondary),
            )
          else
            for (final SetLog set in sessionExercise.sets)
              _SetTile(
                set: set,
                unit: unit,
                personalRecords:
                    personalRecords[set.id] ?? const <PersonalRecordType>{},
                onEdit: () => onEditSet(set),
                onDelete: () => onDeleteSet(set),
              ),
        ],
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  const _SetTile({
    required this.set,
    required this.unit,
    required this.personalRecords,
    required this.onEdit,
    required this.onDelete,
  });

  final SetLog set;
  final WeightUnit unit;
  final Set<PersonalRecordType> personalRecords;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String unitLabel = switch (unit) {
      WeightUnit.kilograms => l10n.unitKilograms,
      WeightUnit.pounds => l10n.unitPounds,
    };

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space1),
      child: Material(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: ListTile(
          key: ValueKey<String>('history-set-${set.id}'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          leading: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: set.isWarmup
                  ? AppTokens.surface3
                  : AppTokens.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Text(
              context.digits('${set.setIndex + 1}'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: set.isWarmup
                    ? AppTokens.textSecondary
                    : AppTokens.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(context.digits(formatWeight(set.weightGrams, unit))),
              Text(unitLabel),
              const Text('×'),
              Text(context.digits(set.reps)),
              if (personalRecords.isNotEmpty)
                PrBadge(
                  key: ValueKey<String>('history-set-${set.id}-pr'),
                  types: personalRecords,
                ),
            ],
          ),
          subtitle: Text(
            <String>[
              if (set.rir != null) context.digits(l10n.rirSummary(set.rir!)),
              if (set.isWarmup) l10n.warmupLabel,
            ].join(' · '),
          ),
          trailing: PopupMenuButton<String>(
            key: ValueKey<String>('history-set-actions-${set.id}'),
            tooltip: l10n.setActions,
            onSelected: (String action) {
              if (action == 'edit') {
                onEdit();
              } else {
                onDelete();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                key: ValueKey<String>('history-set-edit-${set.id}'),
                value: 'edit',
                child: Text(l10n.editSet),
              ),
              PopupMenuItem<String>(
                key: ValueKey<String>('history-set-delete-${set.id}'),
                value: 'delete',
                child: Text(l10n.deleteSet),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picks a paragraph direction from the first strong letter so English notes
/// in a Persian UI and Persian notes in an English UI both render correctly.
TextDirection _textDirectionFor(String text) {
  for (final int rune in text.runes) {
    if ((rune >= 0x0590 && rune <= 0x08FF) ||
        (rune >= 0xFB1D && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF)) {
      return TextDirection.rtl;
    }
    if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A)) {
      return TextDirection.ltr;
    }
  }
  return TextDirection.ltr;
}

class _NoteSection extends StatelessWidget {
  const _NoteSection({
    required this.label,
    required this.note,
    required this.textKey,
    required this.addKey,
    required this.editKey,
    required this.onEdit,
  });

  final String label;
  final String? note;
  final Key textKey;
  final Key addKey;
  final Key editKey;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    if (note == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          key: addKey,
          onPressed: onEdit,
          icon: const Icon(Icons.note_add_outlined),
          label: Text(l10n.addNote),
        ),
      );
    }

    return Container(
      padding: const EdgeInsetsDirectional.all(AppTokens.space1),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppTokens.textSecondary),
                ),
                const SizedBox(height: AppTokens.space1),
                Text(
                  note!,
                  key: textKey,
                  textDirection: _textDirectionFor(note!),
                ),
              ],
            ),
          ),
          IconButton(
            key: editKey,
            tooltip: l10n.editNote,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}
