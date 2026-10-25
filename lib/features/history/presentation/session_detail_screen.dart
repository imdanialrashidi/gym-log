import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/note_dialog.dart';
import '../../../core/widgets/pr_badge.dart';
import '../../../core/widgets/undo_snack_bar.dart';
import '../../../data/app_data_controller.dart';
import '../../../data/photo_index_controller.dart';
import '../../photos/presentation/session_photos_section.dart';
import '../../workout/presentation/set_edit_dialog.dart';
import '../../workout/presentation/set_row.dart';

/// Read-only session detail with notes and set/session editing (`HIS-002`,
/// `LOG-006`, `LOG-007`).
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AppData> asyncData = ref.watch(appDataControllerProvider);

    return asyncData.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.sessionDetailTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => Scaffold(
        appBar: AppBar(title: Text(l10n.sessionDetailTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.loadFailed,
                  style: const TextStyle(color: AppTokens.danger),
                ),
                const SizedBox(height: AppTokens.space1),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(appDataControllerProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (AppData data) {
        final Session? session = data.sessionById(sessionId);
        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.sessionDetailTitle)),
            body: Center(
              child: Text(
                l10n.sessionNotFound,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.sessionDetailTitle),
            actions: <Widget>[
              IconButton(
                key: const Key('delete-session'),
                tooltip: l10n.deleteSession,
                onPressed: () => _deleteSession(context, ref, session),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsetsDirectional.all(AppTokens.space2),
            children: <Widget>[
              Text(
                context.formatDate(
                  session.startedAt,
                  style: AppDateStyle.dateTime,
                ),
                key: const Key('session-detail-date'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTokens.space1),
              Text(
                context.digits(
                  l10n.historySessionSummary(
                    session.exercises.fold<int>(
                      0,
                      (int total, SessionExercise exercise) =>
                          total + exercise.sets.length,
                    ),
                    session.exercises.length,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTokens.textSecondary),
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
                  unit: data.settings.weightUnit,
                  personalRecords: personalRecordsForExercise(
                    sessions: data.sessions,
                    exerciseId: exercise.exerciseId,
                  ),
                  onEditNote: () =>
                      _editExerciseNote(context, ref, session, exercise),
                  onEditSet: (SetLog set) =>
                      _editSet(context, ref, session, exercise, set),
                  onDeleteSet: (SetLog set) =>
                      _deleteSet(context, ref, session, exercise, set),
                ),
            ],
          ),
        );
      },
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
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .setSessionNote(session.id, note);
    } catch (_) {
      if (context.mounted) {
        _showFailure(context);
      }
    }
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
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .setSessionExerciseNote(
            sessionId: session.id,
            sessionExerciseId: exercise.id,
            note: note,
          );
    } catch (_) {
      if (context.mounted) {
        _showFailure(context);
      }
    }
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
    final SetDraft? draft = await showSetEditDialog(
      context,
      set: set,
      unit: unit,
    );
    if (draft == null || !context.mounted) {
      return;
    }
    final SetLog updated = SetLog(
      id: set.id,
      setIndex: set.setIndex,
      weightGrams: draft.weightGrams,
      reps: draft.reps,
      rir: draft.rir,
      isWarmup: draft.isWarmup,
      loggedAt: set.loggedAt,
    );
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .updateSet(
            sessionId: session.id,
            sessionExerciseId: exercise.id,
            set: updated,
          );
    } catch (_) {
      if (context.mounted) {
        _showFailure(context);
      }
    }
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
    try {
      final SetLog removed = await controller.deleteSet(
        sessionId: session.id,
        sessionExerciseId: exercise.id,
        setId: set.id,
      );
      if (!context.mounted) {
        return;
      }
      showUndoSnackBar(
        context,
        message: context.l10n.setDeleted,
        onUndo: () async {
          await controller.restoreSet(
            sessionId: session.id,
            sessionExerciseId: exercise.id,
            set: removed,
          );
        },
      );
    } catch (_) {
      if (context.mounted) {
        _showFailure(context);
      }
    }
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
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .deleteSession(session.id);
      ref.invalidate(photoIndexProvider);
      if (!context.mounted) {
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/history');
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.sessionDeleted)));
    } catch (_) {
      if (context.mounted) {
        _showFailure(context);
      }
    }
  }

  void _showFailure(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
  }
}

class _ExerciseSection extends StatelessWidget {
  const _ExerciseSection({
    required this.sessionExercise,
    required this.exercise,
    required this.unit,
    required this.personalRecords,
    required this.onEditNote,
    required this.onEditSet,
    required this.onDeleteSet,
  });

  final SessionExercise sessionExercise;
  final Exercise? exercise;
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
            children: <Widget>[
              Expanded(
                child: Text(
                  exercise?.name ?? l10n.exerciseNotFound,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (sessionExercise.repMin != null &&
                  sessionExercise.repMax != null)
                Text(
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
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTokens.textSecondary),
                ),
            ],
          ),
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
