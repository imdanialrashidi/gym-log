import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_clock.dart';
import '../../../app/document_gate.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/muscle_labels.dart';
import '../../../core/widgets/action_runner.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_skeleton.dart';
import '../../../core/widgets/progress_track.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../core/widgets/training_formats.dart';
import '../../../core/widgets/undo_snack_bar.dart';
import '../../../data/app_data_controller.dart';
import 'dashboard_view.dart';
import 'plate_calculator_sheet.dart';
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

  /// Watches only load status and the display unit. Committing a set must not
  /// rebuild the whole session: the tapped row and its card's stats listen to
  /// their own slice of the document.
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
    // Clear an older rest snapshot before the session mutation can expose the
    // live bar; otherwise an async restore could race the new session.
    ref.read(restTimerControllerProvider.notifier).dismiss();
    await _run(() async {
      await ref
          .read(appDataControllerProvider.notifier)
          .startSession(programDayId: programDayId);
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
    Session? finished;
    await _run(() async {
      finished = await ref
          .read(appDataControllerProvider.notifier)
          .finishSession(session.id);
      ref.read(restTimerControllerProvider.notifier).dismiss();
      _extraRows.clear();
    });
    if (finished == null || !mounted) {
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    await context.push(AppRoutes.sessionSummary(finished!.id));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    await runDataAction(context, action);
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<LoggedSet> _logSet(
    String sessionId,
    String sessionExerciseId,
    int setIndex,
    SetEntry entry,
  ) async {
    final LoggedSet logged = await ref
        .read(appDataControllerProvider.notifier)
        .logSet(
          sessionId: sessionId,
          sessionExerciseId: sessionExerciseId,
          setIndex: setIndex,
          entry: entry,
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
    return logged;
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
    final SetEntry? entry = await showSetEditDialog(
      context,
      set: set,
      unit: unit,
    );
    if (entry == null || !mounted) {
      return;
    }
    final bool saved = await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .updateSet(
            sessionId: session.id,
            sessionExerciseId: sessionExercise.id,
            setId: set.id,
            entry: entry,
          ),
    );
    if (saved && mounted) {
      setState(() {});
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
    SetLog? removed;
    final bool saved = await runDataAction(context, () async {
      removed = await controller.deleteSet(
        sessionId: session.id,
        sessionExerciseId: sessionExercise.id,
        setId: set.id,
      );
    });
    if (!saved || removed == null || !mounted) {
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
            await runDataAction(
              context,
              () => controller.restoreSet(
                sessionId: session.id,
                sessionExerciseId: sessionExercise.id,
                set: removed!,
              ),
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
      return const AppLoadingSkeleton(
        key: Key('workout-loading-skeleton'),
        rows: 2,
      );
    }
    if (load.error) {
      return const DocumentLoadFailure();
    }

    final AppData data = ref.read(appDataControllerProvider).requireValue;
    final Session? active = data.activeSession;
    if (active == null) {
      return WorkoutDashboard(
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
      onLog: (String sessionExerciseId, int setIndex, SetEntry entry) =>
          _logSet(active.id, sessionExerciseId, setIndex, entry),
      onEditSet: (SessionExercise sessionExercise, SetLog set) =>
          _editSet(active, sessionExercise, set),
      onDeleteSet: (SessionExercise sessionExercise, SetLog set) =>
          _deleteSet(active, sessionExercise, set),
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
  final Future<LoggedSet> Function(
    String sessionExerciseId,
    int setIndex,
    SetEntry entry,
  )
  onLog;
  final Future<void> Function(SessionExercise sessionExercise, SetLog set)
  onEditSet;
  final Future<void> Function(SessionExercise sessionExercise, SetLog set)
  onDeleteSet;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final double padding = AppTokens.pagePadding(
      MediaQuery.sizeOf(context).width,
    );
    // One scan for every exercise in this session instead of one full history
    // scan per exercise card.
    final Map<String, PersonalRecordsBySet> personalRecordsByExercise =
        personalRecordsForExercises(
          sessions: data.sessions,
          exerciseIds: <String>[
            for (final SessionExercise exercise in session.exercises)
              exercise.exerciseId,
          ],
        );

    final List<SessionExercise> exercises = session.exercises;
    final int itemCount = exercises.isEmpty ? 3 : exercises.length + 2;
    return ListView.builder(
      key: const Key('active-workout-list'),
      padding: EdgeInsetsDirectional.fromSTEB(
        padding,
        AppTokens.space2,
        padding,
        AppTokens.space4,
      ),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space3),
            child: _ActiveSessionHero(
              busy: busy,
              unit: unit,
              onFinish: onFinish,
            ),
          );
        }
        if (index == itemCount - 1) {
          return Padding(
            padding: EdgeInsetsDirectional.only(
              top: exercises.isEmpty ? 0 : AppTokens.space2,
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('session-add-exercise'),
                onPressed: busy ? null : onAddExercise,
                icon: const Icon(Icons.add),
                label: Text(l10n.addExercise),
              ),
            ),
          );
        }
        if (exercises.isEmpty) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space2),
            child: AppCard(
              child: Text(
                l10n.noExercisesInSession,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTokens.textSecondary),
              ),
            ),
          );
        }
        final int exerciseIndex = index - 1;
        final SessionExercise sessionExercise = exercises[exerciseIndex];
        return _SessionExerciseCard(
          key: ValueKey<String>(
            'exercise-card-${session.id}-${sessionExercise.id}',
          ),
          data: data,
          session: session,
          sessionExercise: sessionExercise,
          exerciseIndex: exerciseIndex,
          unit: unit,
          busy: busy,
          personalRecords:
              personalRecordsByExercise[sessionExercise.exerciseId] ??
              const <String, Set<PersonalRecordType>>{},
          extraRows: extraRows[sessionExercise.id] ?? 0,
          onAddSet: () => onAddSet(sessionExercise.id),
          onLog: onLog,
          onEditSet: onEditSet,
          onDeleteSet: onDeleteSet,
        );
      },
    );
  }
}

class _ActiveSessionHero extends ConsumerWidget {
  const _ActiveSessionHero({
    required this.busy,
    required this.unit,
    required this.onFinish,
  });

  final bool busy;
  final WeightUnit unit;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ({Session? session, String? dayName}) hero = ref.watch(
      appDataControllerProvider.select((AsyncValue<AppData> value) {
        final AppData? data = value.value;
        final Session? active = data?.activeSession;
        final String? programDayId = active?.programDayId;
        return (
          session: active,
          dayName: programDayId == null
              ? null
              : data?.dayById(programDayId)?.name,
        );
      }),
    );
    final Session? session = hero.session;
    if (session == null) {
      return const SizedBox.shrink();
    }
    final int workingSets = session.exercises.fold<int>(
      0,
      (int total, SessionExercise exercise) =>
          total + exercise.workingSets.length,
    );
    final int volume = session.exercises.fold<int>(
      0,
      (int total, SessionExercise exercise) =>
          total +
          exercise.workingSets.fold<int>(
            0,
            (int sum, SetLog set) => sum + set.weightGrams * set.reps,
          ),
    );
    return AppCard(
      key: const Key('active-session-hero'),
      borderColor: AppTokens.outlineStrong,
      padding: const EdgeInsetsDirectional.all(AppTokens.space3),
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Container(width: 6, height: 6, color: AppTokens.accent),
                        Text(
                          l10n.inProgress,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTokens.accent,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hero.dayName ?? l10n.activeWorkoutTitle,
                      key: const Key('active-session-title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.digits(
                        l10n.programExercisesCount(session.exercises.length),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    l10n.elapsedTime,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  _ElapsedClock(startedAt: session.startedAt),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.only(top: AppTokens.space2),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTokens.outline)),
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double half =
                    (constraints.maxWidth - AppTokens.space2) / 2;
                return Wrap(
                  spacing: AppTokens.space2,
                  runSpacing: AppTokens.space1,
                  children: <Widget>[
                    SizedBox(
                      width: half,
                      child: StatTile(
                        label: l10n.workingSets,
                        value: context.digits('$workingSets'),
                        compact: true,
                      ),
                    ),
                    SizedBox(
                      width: half,
                      child: StatTile(
                        label: l10n.volumeLabel,
                        value: context.digits(formatWeight(volume, unit)),
                        unit: weightUnitLabel(context, unit),
                        compact: true,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('finish-workout'),
              onPressed: busy ? null : onFinish,
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: Text(l10n.finishWorkout),
            ),
          ),
        ],
      ),
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
    required this.personalRecords,
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
  final PersonalRecordsBySet personalRecords;
  final int extraRows;
  final VoidCallback onAddSet;
  final Future<LoggedSet> Function(
    String sessionExerciseId,
    int setIndex,
    SetEntry entry,
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

  /// Working sets of the previous session, scanned once per card, not per row.
  late final List<SetLog> _lastWorkingSets;

  @override
  void initState() {
    super.initState();
    _lastWorkingSets = lastWorkingSetsForExercise(
      sessions: widget.data.sessions,
      exerciseId: widget.sessionExercise.exerciseId,
      excludeSessionId: widget.session.id,
    );
    _suggestion = progressionSuggestion(
      targetSets: widget.sessionExercise.targetSets,
      repMin: widget.sessionExercise.repMin,
      repMax: widget.sessionExercise.repMax,
      incrementGrams:
          widget.data
              .exerciseById(widget.sessionExercise.exerciseId)
              ?.incrementGrams ??
          defaultIncrementGrams(widget.unit),
      lastWorkingSets: _lastWorkingSets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppData data = widget.data;
    final SessionExercise sessionExercise = widget.sessionExercise;
    final int exerciseIndex = widget.exerciseIndex;
    final WeightUnit unit = widget.unit;
    final bool busy = widget.busy;
    final int extraRows = widget.extraRows;
    final VoidCallback onAddSet = widget.onAddSet;
    final Future<LoggedSet> Function(
      String sessionExerciseId,
      int setIndex,
      SetEntry entry,
    )
    onLog = widget.onLog;
    final Future<void> Function(SessionExercise sessionExercise, SetLog set)
    onEditSet = widget.onEditSet;
    final Future<void> Function(SessionExercise sessionExercise, SetLog set)
    onDeleteSet = widget.onDeleteSet;

    final AppLocalizations l10n = context.l10n;
    final Exercise? exercise = data.exerciseById(sessionExercise.exerciseId);
    final int incrementGrams =
        exercise?.incrementGrams ?? defaultIncrementGrams(unit);
    final ProgressionSuggestion? suggestion = _suggestion;
    final PersonalRecordsBySet personalRecords = widget.personalRecords;
    final int? plateWeightGrams = sessionExercise.workingSets.isNotEmpty
        ? sessionExercise.workingSets.last.weightGrams
        : (_lastWorkingSets.isNotEmpty
              ? _lastWorkingSets.first.weightGrams
              : null);
    final List<SessionRowPlan> plan = planSessionRows(
      sessionExercise: sessionExercise,
      previousWorkingSets: _lastWorkingSets,
      extraRows: extraRows,
    );
    final List<Widget> rows = <Widget>[];
    for (final SessionRowPlan row in plan) {
      final int index = row.index;
      final String rowKey = 'set-$exerciseIndex-$index';
      final SetLog? saved = row.savedSet;
      if (saved == null) {
        final SetPrefill prefill = row.prefill!;
        rows.add(
          RepaintBoundary(
            child: SetRow(
              key: ValueKey<String>(rowKey),
              rowKey: rowKey,
              setNumber: index + 1,
              unit: unit,
              incrementGrams: incrementGrams,
              initialWeightGrams: prefill.weightGrams,
              initialReps: prefill.reps,
              initialRir: prefill.rir,
              suggestion: suggestion,
              onLog: (SetEntry entry) =>
                  onLog(sessionExercise.id, index, entry),
              onEdit: (SetLog savedSet) => onEditSet(sessionExercise, savedSet),
              onDelete: (SetLog savedSet) =>
                  onDeleteSet(sessionExercise, savedSet),
            ),
          ),
        );
        continue;
      }
      rows.add(
        RepaintBoundary(
          child: SetRow(
            key: ValueKey<String>(rowKey),
            rowKey: rowKey,
            setNumber: index + 1,
            unit: unit,
            incrementGrams: incrementGrams,
            savedSet: saved,
            personalRecords:
                personalRecords[saved.id] ?? const <PersonalRecordType>{},
            onLog: (SetEntry entry) => onLog(sessionExercise.id, index, entry),
            onEdit: (SetLog savedSet) => onEditSet(sessionExercise, savedSet),
            onDelete: (SetLog savedSet) =>
                onDeleteSet(sessionExercise, savedSet),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space2),
      child: RepaintBoundary(
        child: AppCard(
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
                          const SizedBox(height: 3),
                          Text(
                            muscleGroupLabel(l10n, exercise!.muscleGroup!),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTokens.accent),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (exercise != null)
                    IconButton(
                      key: ValueKey<String>('plate-calc-$exerciseIndex'),
                      tooltip: l10n.plateCalculatorAction,
                      onPressed: busy
                          ? null
                          : () => unawaited(
                              showPlateCalculatorSheet(
                                context,
                                unit: unit,
                                initialGrams: plateWeightGrams,
                              ),
                            ),
                      icon: const Icon(Icons.calculate_outlined, size: 20),
                    ),
                  if (sessionExercise.repMin != null &&
                      sessionExercise.repMax != null)
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppTokens.space1,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: AppTokens.surface2,
                        border: Border(
                          bottom: BorderSide(color: AppTokens.outline),
                        ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppTokens.textSecondary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTokens.space1),
              RepaintBoundary(
                child: _ExerciseStats(
                  sessionId: widget.session.id,
                  sessionExerciseId: sessionExercise.id,
                  unit: unit,
                  targetSets: sessionExercise.targetSets,
                ),
              ),
              const SizedBox(height: AppTokens.space1),
              ...rows,
              const SizedBox(height: AppTokens.spaceHalf),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  key: ValueKey<String>('add-set-$exerciseIndex'),
                  onPressed: busy || plan.length >= maximumTargetSets
                      ? null
                      : onAddSet,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addSet),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseStats extends ConsumerWidget {
  const _ExerciseStats({
    required this.sessionId,
    required this.sessionExerciseId,
    required this.unit,
    required this.targetSets,
  });

  final String sessionId;
  final String sessionExerciseId;
  final WeightUnit unit;
  final int? targetSets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionExercise? exercise = ref.watch(
      appDataControllerProvider.select((AsyncValue<AppData> value) {
        return value.value
            ?.sessionById(sessionId)
            ?.exerciseById(sessionExerciseId);
      }),
    );
    if (exercise == null) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l10n = context.l10n;
    final int workingSetCount = exercise.workingSets.length;
    final int volumeGrams = exercise.workingSets.fold<int>(
      0,
      (int total, SetLog set) => total + set.weightGrams * set.reps,
    );
    final Duration? setSpan = exercise.sets.length < 2
        ? null
        : _loggedSpan(exercise.sets);
    final int? target = targetSets;
    final double progress = target == null || target <= 0
        ? 0
        : (workingSetCount / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: AppTokens.space1,
          runSpacing: AppTokens.space1,
          children: <Widget>[
            _MetaPill(
              icon: Icons.layers_outlined,
              label: target == null
                  ? context.digits(l10n.setsLabel(workingSetCount))
                  : context.digits(l10n.setProgress(workingSetCount, target)),
            ),
            _MetaPill(
              icon: Icons.scale_outlined,
              label: context.digits(
                '${formatWeight(volumeGrams, unit)} '
                '${weightUnitLabel(context, unit)}',
              ),
            ),
            if (setSpan != null)
              _MetaPill(
                icon: Icons.timer_outlined,
                label: formatTrainingDuration(context, setSpan),
              ),
          ],
        ),
        if (target != null) ...<Widget>[
          const SizedBox(height: 6),
          Semantics(
            label: context.digits(l10n.setProgress(workingSetCount, target)),
            child: ProgressTrack(
              key: ValueKey<String>('exercise-progress-$sessionExerciseId'),
              value: progress,
              color: workingSetCount >= target
                  ? AppTokens.accent
                  : AppTokens.info,
            ),
          ),
        ],
      ],
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

/// First-to-last logged span, independent of row order.
Duration _loggedSpan(List<SetLog> sets) {
  DateTime first = sets.first.loggedAt;
  DateTime last = sets.first.loggedAt;
  for (final SetLog set in sets) {
    if (set.loggedAt.isBefore(first)) {
      first = set.loggedAt;
    }
    if (set.loggedAt.isAfter(last)) {
      last = set.loggedAt;
    }
  }
  return last.difference(first);
}

/// The live session clock.
///
/// Only this label rebuilds once per second. The surrounding hero, stats, and
/// set rows stay untouched, so a running clock does not scroll or repaint the
/// logging surface.
class _ElapsedClock extends ConsumerStatefulWidget {
  const _ElapsedClock({required this.startedAt});

  final DateTime startedAt;

  @override
  ConsumerState<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends ConsumerState<_ElapsedClock> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = ref.watch(appClockProvider)();
    final Duration elapsed = now.toUtc().difference(widget.startedAt);
    return Text(
      formatElapsedClock(context, elapsed),
      key: const Key('active-session-elapsed'),
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        color: AppTokens.accent,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}
