import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/text_empty_state.dart';
import '../../../core/widgets/undo_snack_bar.dart';
import '../../../data/app_data_controller.dart';
import 'rest_timer.dart';
import 'set_edit_dialog.dart';
import 'set_row.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

typedef _WorkoutLoad = ({bool ready, bool error, WeightUnit? unit});

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final Map<String, int> _extraRows = <String, int>{};
  ({String sessionExerciseId, int setIndex})? _pendingDeletedRow;
  bool _busy = false;

  /// Watches only load status and the display unit, so committing a set does
  /// not rebuild the screen or rows other than the one that was tapped.
  _WorkoutLoad get _load => ref.watch(
    appDataControllerProvider.select(
      (AsyncValue<AppData> value) => (
        ready: value.hasValue,
        error: value.hasError && !value.hasValue,
        unit: value.value?.settings.weightUnit,
      ),
    ),
  );

  Future<void> _start(String? programDayId) async {
    await _run(() async {
      await ref
          .read(appDataControllerProvider.notifier)
          .startSession(programDayId: programDayId);
      ref.read(restTimerControllerProvider.notifier).dismiss();
      _extraRows.clear();
    });
  }

  Future<void> _addExercise(Session session) async {
    if (_busy) {
      return;
    }
    final Set<String> existing = <String>{
      for (final SessionExercise exercise in session.exercises)
        exercise.exerciseId,
    };
    final Exercise? selected = await context.push<Exercise>(
      AppRoutes.exercisePicker,
      extra: existing,
    );
    if (selected == null || !mounted) {
      return;
    }
    await _run(() async {
      await ref
          .read(appDataControllerProvider.notifier)
          .addExerciseToSession(sessionId: session.id, exerciseId: selected.id);
    });
  }

  Future<void> _finish(Session session) async {
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.finishWorkoutTitle),
        content: Text(l10n.finishWorkoutBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm-finish-workout'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.finishWorkoutConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _run(() async {
      await ref
          .read(appDataControllerProvider.notifier)
          .finishSession(session.id);
      ref.read(restTimerControllerProvider.notifier).dismiss();
      _extraRows.clear();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<SetLogOutcome> _logSet(
    String sessionId,
    String sessionExerciseId,
    int setIndex,
    SetDraft draft,
  ) async {
    final SetLog logged = await ref
        .read(appDataControllerProvider.notifier)
        .logSet(
          sessionId: sessionId,
          sessionExerciseId: sessionExerciseId,
          setIndex: setIndex,
          weightGrams: draft.weightGrams,
          reps: draft.reps,
          rir: draft.rir,
          isWarmup: draft.isWarmup,
        );
    final ({String sessionExerciseId, int setIndex})? pending =
        _pendingDeletedRow;
    if (pending != null &&
        pending.sessionExerciseId == sessionExerciseId &&
        pending.setIndex == setIndex) {
      _pendingDeletedRow = null;
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    }
    if (mounted) {
      final AppSettings settings = ref
          .read(appDataControllerProvider)
          .requireValue
          .settings;
      if (settings.restTimerEnabled) {
        ref
            .read(restTimerControllerProvider.notifier)
            .start(Duration(seconds: settings.restTimerDurationSeconds));
      }
    }
    if (!mounted) {
      return SetLogOutcome(set: logged);
    }
    final AppData data = ref.read(appDataControllerProvider).requireValue;
    final SessionExercise? sessionExercise = data
        .sessionById(sessionId)
        ?.exerciseById(sessionExerciseId);
    final PersonalRecordsBySet records = sessionExercise == null
        ? <String, Set<PersonalRecordType>>{}
        : personalRecordsForExercise(
            sessions: data.sessions,
            exerciseId: sessionExercise.exerciseId,
          );
    return SetLogOutcome(
      set: logged,
      personalRecords: records[logged.id] ?? const <PersonalRecordType>{},
    );
  }

  Future<void> _editSet(
    Session session,
    SessionExercise sessionExercise,
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
    if (draft == null || !mounted) {
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
            sessionExerciseId: sessionExercise.id,
            set: updated,
          );
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
      }
    }
  }

  Future<void> _deleteSet(
    Session session,
    SessionExercise sessionExercise,
    SetLog set,
  ) async {
    final AppDataController controller = ref.read(
      appDataControllerProvider.notifier,
    );
    try {
      final SetLog removed = await controller.deleteSet(
        sessionId: session.id,
        sessionExerciseId: sessionExercise.id,
        setId: set.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {});
      final ({String sessionExerciseId, int setIndex}) deleted = (
        sessionExerciseId: sessionExercise.id,
        setIndex: set.setIndex,
      );
      _pendingDeletedRow = deleted;
      final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackBar =
          showUndoSnackBar(
            context,
            message: context.l10n.setDeleted,
            onUndo: () async {
              if (_pendingDeletedRow == deleted) {
                _pendingDeletedRow = null;
              }
              await controller.restoreSet(
                sessionId: session.id,
                sessionExerciseId: sessionExercise.id,
                set: removed,
              );
              if (mounted) {
                setState(() {});
              }
            },
          );
      unawaited(
        snackBar.closed.then((_) {
          if (_pendingDeletedRow == deleted) {
            _pendingDeletedRow = null;
          }
        }),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
      }
    }
  }

  void _addSet(String sessionExerciseId) {
    setState(() {
      _extraRows.update(
        sessionExerciseId,
        (int count) => count + 1,
        ifAbsent: () => 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final _WorkoutLoad load = _load;
    if (!load.ready && !load.error) {
      return const Center(child: CircularProgressIndicator());
    }
    if (load.error) {
      return TextEmptyState(
        message: context.l10n.loadFailed,
        action: OutlinedButton.icon(
          onPressed: () => ref.invalidate(appDataControllerProvider),
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.retry),
        ),
      );
    }

    final AppData data = ref.read(appDataControllerProvider).requireValue;
    final Session? active = data.activeSession;
    if (active == null) {
      return _StartWorkoutView(
        data: data,
        busy: _busy,
        onStartDay: (String dayId) => unawaited(_start(dayId)),
        onStartEmpty: () => unawaited(_start(null)),
      );
    }

    return _ActiveWorkoutView(
      data: data,
      session: active,
      unit: load.unit ?? data.settings.weightUnit,
      busy: _busy,
      extraRows: _extraRows,
      onAddExercise: () => unawaited(_addExercise(active)),
      onFinish: () => unawaited(_finish(active)),
      onAddSet: _addSet,
      onLog: (String sessionExerciseId, int setIndex, SetDraft draft) =>
          _logSet(active.id, sessionExerciseId, setIndex, draft),
      onEditSet: (SessionExercise sessionExercise, SetLog set) =>
          _editSet(active, sessionExercise, set),
      onDeleteSet: (SessionExercise sessionExercise, SetLog set) =>
          _deleteSet(active, sessionExercise, set),
    );
  }
}

class _StartWorkoutView extends StatelessWidget {
  const _StartWorkoutView({
    required this.data,
    required this.busy,
    required this.onStartDay,
    required this.onStartEmpty,
  });

  final AppData data;
  final bool busy;
  final void Function(String dayId) onStartDay;
  final VoidCallback onStartEmpty;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool hasDays = data.programs.any(
      (Program program) => program.days.isNotEmpty,
    );

    return ListView(
      padding: const EdgeInsetsDirectional.all(AppTokens.space2),
      children: <Widget>[
        Text(
          l10n.startWorkoutTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTokens.space1),
        Text(
          l10n.workoutEmpty,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: AppTokens.textSecondary),
        ),
        if (hasDays) ...<Widget>[
          const SizedBox(height: AppTokens.space3),
          for (final Program program in data.programs)
            if (program.days.isNotEmpty) ...<Widget>[
              Text(
                program.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTokens.space1),
              for (final ProgramDay day in program.days)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppTokens.space1,
                  ),
                  child: Material(
                    color: AppTokens.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                    child: ListTile(
                      key: ValueKey<String>('start-day-${day.id}'),
                      enabled: !busy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusSmall,
                        ),
                      ),
                      title: Text(day.name),
                      subtitle: _daySubtitle(day),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: busy ? null : () => onStartDay(day.id),
                    ),
                  ),
                ),
              const SizedBox(height: AppTokens.space1),
            ],
        ] else ...<Widget>[
          const SizedBox(height: AppTokens.space2),
          Text(
            l10n.noProgramDays,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTokens.textSecondary),
          ),
        ],
        const SizedBox(height: AppTokens.space2),
        FilledButton.icon(
          key: const Key('start-empty-workout'),
          onPressed: busy ? null : onStartEmpty,
          icon: const Icon(Icons.add),
          label: Text(l10n.startEmptyWorkout),
        ),
      ],
    );
  }

  Widget? _daySubtitle(ProgramDay day) {
    final List<String> names = <String>[];
    for (final PlanItem item in day.items) {
      final Exercise? exercise = data.exerciseById(item.exerciseId);
      if (exercise != null) {
        names.add(exercise.name);
      }
    }
    if (names.isEmpty) {
      return null;
    }
    return Text(
      names.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ActiveWorkoutView extends StatelessWidget {
  const _ActiveWorkoutView({
    required this.data,
    required this.session,
    required this.unit,
    required this.busy,
    required this.extraRows,
    required this.onAddExercise,
    required this.onFinish,
    required this.onAddSet,
    required this.onLog,
    required this.onEditSet,
    required this.onDeleteSet,
  });

  final AppData data;
  final Session session;
  final WeightUnit unit;
  final bool busy;
  final Map<String, int> extraRows;
  final VoidCallback onAddExercise;
  final VoidCallback onFinish;
  final void Function(String sessionExerciseId) onAddSet;
  final Future<SetLogOutcome> Function(
    String sessionExerciseId,
    int setIndex,
    SetDraft draft,
  )
  onLog;
  final Future<void> Function(SessionExercise sessionExercise, SetLog set)
  onEditSet;
  final Future<void> Function(SessionExercise sessionExercise, SetLog set)
  onDeleteSet;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return ListView(
      padding: const EdgeInsetsDirectional.all(AppTokens.space2),
      children: <Widget>[
        const RestTimerBanner(),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.activeWorkoutTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            OutlinedButton.icon(
              key: const Key('finish-workout'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTokens.textSecondary),
              ),
              onPressed: busy ? null : onFinish,
              icon: const Icon(Icons.flag_outlined),
              label: Text(l10n.finishWorkout),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space2),
        if (session.exercises.isEmpty) ...<Widget>[
          Text(
            l10n.noExercisesInSession,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppTokens.textSecondary),
          ),
          const SizedBox(height: AppTokens.space2),
        ] else
          for (int index = 0; index < session.exercises.length; index++)
            _SessionExerciseCard(
              key: ValueKey<String>(
                'exercise-card-${session.id}-${session.exercises[index].id}',
              ),
              data: data,
              session: session,
              sessionExercise: session.exercises[index],
              exerciseIndex: index,
              unit: unit,
              busy: busy,
              extraRows: extraRows[session.exercises[index].id] ?? 0,
              onAddSet: () => onAddSet(session.exercises[index].id),
              onLog: onLog,
              onEditSet: onEditSet,
              onDeleteSet: onDeleteSet,
            ),
        OutlinedButton.icon(
          key: const Key('session-add-exercise'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTokens.textSecondary),
          ),
          onPressed: busy ? null : onAddExercise,
          icon: const Icon(Icons.add),
          label: Text(l10n.addExercise),
        ),
      ],
    );
  }
}

class _SessionExerciseCard extends StatefulWidget {
  const _SessionExerciseCard({
    super.key,
    required this.data,
    required this.session,
    required this.sessionExercise,
    required this.exerciseIndex,
    required this.unit,
    required this.busy,
    required this.extraRows,
    required this.onAddSet,
    required this.onLog,
    required this.onEditSet,
    required this.onDeleteSet,
  });

  final AppData data;
  final Session session;
  final SessionExercise sessionExercise;
  final int exerciseIndex;
  final WeightUnit unit;
  final bool busy;
  final int extraRows;
  final VoidCallback onAddSet;
  final Future<SetLogOutcome> Function(
    String sessionExerciseId,
    int setIndex,
    SetDraft draft,
  )
  onLog;
  final Future<void> Function(SessionExercise sessionExercise, SetLog set)
  onEditSet;
  final Future<void> Function(SessionExercise sessionExercise, SetLog set)
  onDeleteSet;

  @override
  State<_SessionExerciseCard> createState() => _SessionExerciseCardState();
}

class _SessionExerciseCardState extends State<_SessionExerciseCard> {
  /// Snapshot taken when this exercise first appears in the card.
  ///
  /// History edits elsewhere must not silently change the values already in
  /// the editable drafts; the snapshot keeps the banner and the fields in
  /// sync for the life of the active card.
  late final ProgressionSuggestion? _suggestion;

  @override
  void initState() {
    super.initState();
    _suggestion = progressionSuggestion(
      targetSets: widget.sessionExercise.targetSets,
      repMin: widget.sessionExercise.repMin,
      repMax: widget.sessionExercise.repMax,
      incrementGrams:
          widget.data
              .exerciseById(widget.sessionExercise.exerciseId)
              ?.incrementGrams ??
          defaultIncrementGrams(widget.unit),
      lastWorkingSets: lastWorkingSetsForExercise(
        sessions: widget.data.sessions,
        exerciseId: widget.sessionExercise.exerciseId,
        excludeSessionId: widget.session.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppData data = widget.data;
    final Session session = widget.session;
    final SessionExercise sessionExercise = widget.sessionExercise;
    final int exerciseIndex = widget.exerciseIndex;
    final WeightUnit unit = widget.unit;
    final bool busy = widget.busy;
    final int extraRows = widget.extraRows;
    final VoidCallback onAddSet = widget.onAddSet;
    final Future<SetLogOutcome> Function(
      String sessionExerciseId,
      int setIndex,
      SetDraft draft,
    )
    onLog = widget.onLog;
    final Future<void> Function(SessionExercise sessionExercise, SetLog set)
    onEditSet = widget.onEditSet;
    final Future<void> Function(SessionExercise sessionExercise, SetLog set)
    onDeleteSet = widget.onDeleteSet;

    final AppLocalizations l10n = context.l10n;
    final Exercise? exercise = data.exerciseById(sessionExercise.exerciseId);
    final List<SetLog> logged = sessionExercise.sets;
    final Map<int, SetLog> loggedByIndex = <int, SetLog>{
      for (final SetLog set in logged) set.setIndex: set,
    };
    final int highestLoggedIndex = logged.isEmpty ? -1 : logged.last.setIndex;
    final int plannedRows = sessionExercise.targetSets ?? 1;
    final int rowCount =
        (plannedRows > highestLoggedIndex + 1
            ? plannedRows
            : highestLoggedIndex + 1) +
        extraRows;
    final int incrementGrams =
        exercise?.incrementGrams ?? defaultIncrementGrams(unit);
    final ProgressionSuggestion? suggestion = _suggestion;
    final PersonalRecordsBySet personalRecords = personalRecordsForExercise(
      sessions: data.sessions,
      exerciseId: sessionExercise.exerciseId,
    );
    final List<Widget> rows = <Widget>[];
    int workingIndex = 0;
    for (int index = 0; index < rowCount; index++) {
      final SetLog? saved = loggedByIndex[index];
      final String rowKey = 'set-$exerciseIndex-$index';
      if (saved == null) {
        final SetPrefill prefill = prefillForExercise(
          sessions: data.sessions,
          exerciseId: sessionExercise.exerciseId,
          setIndex: workingIndex,
          excludeSessionId: session.id,
        );
        rows.add(
          SetRow(
            key: ValueKey<String>(rowKey),
            rowKey: rowKey,
            setNumber: index + 1,
            unit: unit,
            incrementGrams: incrementGrams,
            initialWeightGrams: prefill.weightGrams,
            initialReps: prefill.reps,
            initialRir: prefill.rir,
            suggestion: suggestion,
            onLog: (SetDraft draft) => onLog(sessionExercise.id, index, draft),
            onEdit: (SetLog savedSet) => onEditSet(sessionExercise, savedSet),
            onDelete: (SetLog savedSet) =>
                onDeleteSet(sessionExercise, savedSet),
          ),
        );
        workingIndex += 1;
      } else {
        rows.add(
          SetRow(
            key: ValueKey<String>(rowKey),
            rowKey: rowKey,
            setNumber: index + 1,
            unit: unit,
            incrementGrams: incrementGrams,
            savedSet: saved,
            personalRecords:
                personalRecords[saved.id] ?? const <PersonalRecordType>{},
            onLog: (SetDraft draft) => onLog(sessionExercise.id, index, draft),
            onEdit: (SetLog savedSet) => onEditSet(sessionExercise, savedSet),
            onDelete: (SetLog savedSet) =>
                onDeleteSet(sessionExercise, savedSet),
          ),
        );
        if (!saved.isWarmup) {
          workingIndex += 1;
        }
      }
    }

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
          ...rows,
          TextButton.icon(
            key: ValueKey<String>('add-set-$exerciseIndex'),
            onPressed: busy || rowCount >= maximumTargetSets ? null : onAddSet,
            icon: const Icon(Icons.add),
            label: Text(l10n.addSet),
          ),
        ],
      ),
    );
  }
}
