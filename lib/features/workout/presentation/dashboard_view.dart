import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_clock.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/action_runner.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/muscle_balance_card.dart';
import '../../../core/widgets/training_formats.dart';
import '../../../data/app_data_controller.dart';
import '../../../data/training_overview.dart';
import '../../body_weight/presentation/body_weight_summary_card.dart';
import '../../body_weight/presentation/log_weight_dialog.dart';
import '../../goals/presentation/weekly_goal_sheet.dart';

/// The pre-session dashboard: this week at a glance, quick start, body weight,
/// and the muscle split.
///
/// Every number comes from the shared, memoized [trainingOverviewProvider], so
/// the dashboard never rescans the document per card or per frame.
class WorkoutDashboard extends ConsumerWidget {
  const WorkoutDashboard({
    required this.busy,
    required this.onStartDay,
    required this.onStartEmpty,
    super.key,
  });

  final bool busy;
  final ValueChanged<String> onStartDay;
  final VoidCallback onStartEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppData? document = ref.watch(
      appDataControllerProvider.select(
        (AsyncValue<AppData> value) => value.value,
      ),
    );
    if (document == null) {
      return const SizedBox.shrink();
    }
    final AppData data = document;
    final DateTime now = ref.watch(appClockProvider)();
    final DateTime day = DateTime(now.year, now.month, now.day);
    final TrainingOverview? overview = ref.watch(
      trainingOverviewProvider((weekStartsOn: context.weekStartsOn, day: day)),
    );
    final WeightUnit unit = data.settings.weightUnit;
    final WeekStats? current = overview?.currentWeek;
    final List<ProgramDay> days = <ProgramDay>[
      for (final Program program in data.programs)
        for (final ProgramDay day in program.days) day,
    ];
    final List<ProgramDay> visibleDays = days.take(4).toList();
    final double padding = AppTokens.pagePadding(
      MediaQuery.sizeOf(context).width,
    );
    final ValueChanged<String> startDay = busy ? (_) {} : onStartDay;

    return ListView(
      key: const Key('workout-dashboard'),
      padding: EdgeInsetsDirectional.fromSTEB(
        padding,
        AppTokens.space2,
        padding,
        AppTokens.space4,
      ),
      children: <Widget>[
        _Masthead(day: day),
        const SizedBox(height: AppTokens.space3),
        if (overview != null)
          _WeekInstrument(
            overview: overview,
            unit: unit,
            today: day,
            onOpen: () => context.push(AppRoutes.weeklySummary),
            onEditGoal: () => unawaited(_openGoal(context, ref, data.settings)),
          ),
        const SizedBox(height: AppTokens.space4),
        _SectionHeading(
          title: l10n.quickStartTitle,
          actionLabel: days.isEmpty ? null : l10n.programsTab,
          actionKey: const Key('dashboard-open-programs'),
          onAction: () => context.go('/programs'),
        ),
        if (days.isEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.noProgramDays,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTokens.textSecondary),
                ),
                const SizedBox(height: AppTokens.space2),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('start-empty-workout'),
                    onPressed: busy ? null : onStartEmpty,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.startEmptyWorkout),
                  ),
                ),
              ],
            ),
          )
        else ...<Widget>[
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                for (int index = 0; index < visibleDays.length; index += 1)
                  _DayRow(
                    key: ValueKey<String>('start-day-${visibleDays[index].id}'),
                    day: visibleDays[index],
                    programName: data
                        .programForDay(visibleDays[index].id)
                        ?.name,
                    enabled: !busy,
                    showDivider: index < visibleDays.length - 1,
                    onTap: () => startDay(visibleDays[index].id),
                  ),
              ],
            ),
          ),
          if (days.length > 4)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => context.go('/programs'),
                child: Text(l10n.viewAll),
              ),
            ),
          const SizedBox(height: AppTokens.space1),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('start-empty-workout'),
              onPressed: busy ? null : onStartEmpty,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.startEmptyWorkout),
            ),
          ),
        ],
        const SizedBox(height: AppTokens.space4),
        _SectionHeading(
          title: l10n.bodyWeightTitle,
          actionLabel: l10n.viewAll,
          actionKey: const Key('dashboard-open-body-weight'),
          onAction: () => context.push(AppRoutes.bodyWeight),
        ),
        BodyWeightSummaryCard(
          overview: overview,
          unit: unit,
          cardKey: const Key('dashboard-body-weight'),
          onOpen: () => context.push(AppRoutes.bodyWeight),
          onLog: () => unawaited(_logWeight(context, ref, overview, unit)),
        ),
        const SizedBox(height: AppTokens.space4),
        _SectionHeading(
          title: l10n.muscleSetsTitle,
          subtitle: l10n.muscleSetsHint,
        ),
        MuscleBalanceCard(
          workingSetsByMuscle:
              current?.workingSetsByMuscle ?? const <MuscleGroup?, int>{},
        ),
        const SizedBox(height: AppTokens.space4),
        _SectionHeading(
          title: l10n.lastWorkout,
          actionLabel: l10n.viewAll,
          actionKey: const Key('dashboard-open-history'),
          onAction: () => context.go('/history'),
        ),
        _RecentWorkoutCard(
          stats: overview?.latestSession,
          unit: unit,
          onOpen: (SessionStats stats) =>
              context.push(AppRoutes.session(stats.sessionId)),
        ),
      ],
    );
  }

  Future<void> _openGoal(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final WeeklyGoalDraft? draft = await showWeeklyGoalSheet(
      context,
      settings: settings,
    );
    if (draft == null || !context.mounted) {
      return;
    }
    final AppDataController controller = ref.read(
      appDataControllerProvider.notifier,
    );
    final bool saved = await runDataAction(context, () {
      if (draft.isEmpty) {
        return controller.clearWeeklyGoals();
      }
      return controller.setWeeklyGoals(
        sessionGoal: draft.sessionGoal,
        setGoal: draft.setGoal,
      );
    });
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.goalSaved)));
    }
  }

  Future<void> _logWeight(
    BuildContext context,
    WidgetRef ref,
    TrainingOverview? overview,
    WeightUnit unit,
  ) async {
    final int? grams = await showLogWeightDialog(
      context,
      unit: unit,
      initialGrams: overview?.latestWeightEntry?.weightGrams,
    );
    if (grams == null || !context.mounted) {
      return;
    }
    final bool saved = await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .logBodyWeight(
            weightGrams: grams,
            replaceId: overview?.currentWeek.bodyWeight?.entry?.id,
          ),
    );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.bodyWeightSaved)));
    }
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: AppTokens.space1,
          runSpacing: AppTokens.space1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              context.digits(
                '${l10n.dashboardToday} · ${context.formatDate(day)}',
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppTokens.space1 + AppTokens.spaceHalf,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppTokens.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(
                  color: AppTokens.accent.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTokens.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.dashboardReady,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTokens.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space1),
        Text(l10n.dashboardTitle, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 2),
        Text(l10n.workoutEmpty, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _WeekInstrument extends StatelessWidget {
  const _WeekInstrument({
    required this.overview,
    required this.unit,
    required this.today,
    required this.onOpen,
    required this.onEditGoal,
  });

  final TrainingOverview overview;
  final WeightUnit unit;
  final DateTime today;
  final VoidCallback onOpen;
  final VoidCallback onEditGoal;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final WeekStats week = overview.currentWeek;
    final int? sessionGoal = overview.goalProgress.sessionGoal;
    final double fraction = sessionGoal == null
        ? (overview.currentWeekDays.length / 7).clamp(0.0, 1.0)
        : (week.sessionCount / sessionGoal).clamp(0.0, 1.0);
    return AppCard(
      key: const Key('dashboard-week-hero'),
      gradient: AppGradients.hero,
      borderColor: AppTokens.accent.withValues(alpha: 0.32),
      padding: const EdgeInsetsDirectional.all(AppTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(l10n.thisWeek, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      formatWeekRange(context, week),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('dashboard-open-week'),
                onPressed: onOpen,
                tooltip: l10n.viewWeeklySummary,
                style: IconButton.styleFrom(
                  backgroundColor: AppTokens.accent.withValues(alpha: 0.12),
                  foregroundColor: AppTokens.accent,
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.arrow_outward, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: <Widget>[
              _WeekRing(
                fraction: fraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.digits('${week.sessionCount}'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 30,
                        ),
                      ),
                    ),
                    Text(
                      l10n.workoutsStatLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.dashboardWeekVolume,
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              context.digits(
                                formatWeight(week.volumeGrams, unit),
                              ),
                              maxLines: 1,
                              style: theme.textTheme.headlineMedium,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          weightUnitLabel(context, unit),
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space1),
                    Wrap(
                      spacing: AppTokens.space1 + AppTokens.spaceHalf,
                      runSpacing: 2,
                      children: <Widget>[
                        _WeekMeta(
                          icon: Icons.timer_outlined,
                          label: formatTrainingDurationShort(
                            context,
                            week.duration,
                          ),
                        ),
                        _WeekMeta(
                          icon: Icons.layers_outlined,
                          label: l10n.programSetsCount(week.workingSetCount),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          _WeekRail(
            week: week,
            trainedDays: overview.currentWeekDays,
            today: today,
          ),
          const SizedBox(height: AppTokens.space3),
          Container(
            padding: const EdgeInsetsDirectional.only(top: AppTokens.space2),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTokens.outline)),
            ),
            child: _GoalBlock(
              progress: overview.goalProgress,
              onEdit: onEditGoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekMeta extends StatelessWidget {
  const _WeekMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: AppTokens.textSecondary),
        const SizedBox(width: 5),
        Text(
          context.digits(label),
          maxLines: 1,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// A soft blue progress ring, with the week's session count in the middle.
class _WeekRing extends StatelessWidget {
  const _WeekRing({required this.fraction, required this.child});

  final double fraction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 108,
      child: CustomPaint(
        painter: _WeekRingPainter(fraction: fraction),
        child: Center(child: child),
      ),
    );
  }
}

class _WeekRingPainter extends CustomPainter {
  const _WeekRingPainter({required this.fraction});

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 9;
    final Rect rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawCircle(
      rect.center,
      rect.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppTokens.surface3,
    );
    final double sweep = (fraction.clamp(0.0, 1.0)) * math.pi * 2;
    if (sweep <= 0) {
      return;
    }
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        transform: GradientRotation(-math.pi / 2),
        colors: <Color>[
          AppTokens.accentDeep,
          AppTokens.accent,
          AppTokens.info,
          AppTokens.accentDeep,
        ],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
    final double end = -math.pi / 2 + sweep;
    canvas.drawCircle(
      Offset(
        rect.center.dx + rect.width / 2 * math.cos(end),
        rect.center.dy + rect.width / 2 * math.sin(end),
      ),
      3.2,
      Paint()..color = AppTokens.textPrimary,
    );
  }

  @override
  bool shouldRepaint(_WeekRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}

class _WeekRail extends StatelessWidget {
  const _WeekRail({
    required this.week,
    required this.trainedDays,
    required this.today,
  });

  final WeekStats week;
  final Set<DateTime> trainedDays;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final DateTime localToday = DateTime(today.year, today.month, today.day);
    final Map<DateTime, int> setsByDay = <DateTime, int>{};
    for (final SessionStats session in week.sessions) {
      final DateTime local = session.startedAt.toLocal();
      final DateTime day = DateTime(local.year, local.month, local.day);
      setsByDay.update(
        day,
        (int value) => value + session.workingSetCount,
        ifAbsent: () => session.workingSetCount,
      );
    }
    final int maxSets = setsByDay.values.fold<int>(
      1,
      (int max, int value) => value > max ? value : max,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (int index = 0; index < 7; index += 1)
          Expanded(
            child: Builder(
              builder: (BuildContext context) {
                final DateTime date = DateTime(
                  week.weekStart.year,
                  week.weekStart.month,
                  week.weekStart.day + index,
                );
                final bool trained = trainedDays.contains(date);
                final bool isToday = date == localToday;
                final bool future = date.isAfter(localToday);
                final int sets = setsByDay[date] ?? 0;
                final double barHeight =
                    6 + (sets / maxSets).clamp(0.0, 1.0) * 26;
                return Semantics(
                  label: trained
                      ? context.digits(
                          l10n.historyTrainedDay(context.formatDate(date)),
                        )
                      : context.formatDate(date),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 2,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          context.formatDate(
                            date,
                            style: AppDateStyle.weekdayNarrow,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isToday
                                ? AppTokens.accent
                                : trained
                                ? AppTokens.textPrimary
                                : AppTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          height: 34,
                          alignment: AlignmentDirectional.bottomCenter,
                          child: Container(
                            width: 12,
                            height: trained ? barHeight : 6,
                            decoration: BoxDecoration(
                              color: trained
                                  ? AppTokens.accent
                                  : future
                                  ? AppTokens.outline.withValues(alpha: 0.45)
                                  : AppTokens.surface3,
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusPill,
                              ),
                              border: isToday
                                  ? Border.all(
                                      color: AppTokens.accent,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.formatDate(date, style: AppDateStyle.day),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isToday
                                  ? AppTokens.accent
                                  : trained
                                  ? AppTokens.textPrimary
                                  : AppTokens.textSecondary,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _GoalBlock extends StatelessWidget {
  const _GoalBlock({required this.progress, required this.onEdit});

  final WeeklyGoalProgress progress;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    if (!progress.hasGoal) {
      return InkWell(
        key: const Key('dashboard-set-goal'),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppTokens.space1,
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.flag_outlined,
                size: 18,
                color: AppTokens.accent,
              ),
              const SizedBox(width: AppTokens.space1),
              Expanded(
                child: Text(
                  l10n.goalSetCta,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTokens.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppTokens.accent,
              ),
            ],
          ),
        ),
      );
    }
    return InkWell(
      key: const Key('dashboard-goal-block'),
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.goalWeeklyTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTokens.accent,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (progress.streakWeeks > 1) ...<Widget>[
                Text(
                  context.digits(l10n.goalStreak(progress.streakWeeks)),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTokens.highlight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppTokens.space1),
              ],
              const Icon(
                Icons.edit_outlined,
                size: 15,
                color: AppTokens.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space1),
          if (progress.sessionGoal != null)
            _GoalMeter(
              label: l10n.goalSessionsLabel,
              value: context.digits(
                l10n.goalProgressValue(
                  progress.sessionCount,
                  progress.sessionGoal!,
                ),
              ),
              count: progress.sessionCount,
              goal: progress.sessionGoal!,
            ),
          if (progress.sessionGoal != null && progress.setGoal != null)
            const SizedBox(height: 6),
          if (progress.setGoal != null)
            _GoalMeter(
              label: l10n.goalSetsLabel,
              value: context.digits(
                l10n.goalProgressValue(
                  progress.workingSetCount,
                  progress.setGoal!,
                ),
              ),
              count: progress.workingSetCount,
              goal: progress.setGoal!,
              color: AppTokens.highlight,
            ),
        ],
      ),
    );
  }
}

class _GoalMeter extends StatelessWidget {
  const _GoalMeter({
    required this.label,
    required this.value,
    required this.count,
    required this.goal,
    this.color = AppTokens.accent,
  });

  final String label;
  final String value;
  final int count;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int segments = goal.clamp(1, 10);
    final int filled = ((count / goal) * segments).ceil().clamp(0, segments);
    return Row(
      children: <Widget>[
        SizedBox(
          width: 76,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              for (int index = 0; index < segments; index += 1) ...<Widget>[
                Expanded(
                  child: Container(
                    height: 5,
                    color: index < filled ? color : AppTokens.surface3,
                  ),
                ),
                if (index < segments - 1) const SizedBox(width: 3),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppTokens.space1),
        SizedBox(
          width: 52,
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              color: count >= goal ? color : AppTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        bottom: AppTokens.space1,
        top: AppTokens.spaceHalf,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  key: actionKey,
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppTokens.space1,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(actionLabel!),
                ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Text(subtitle!, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.programName,
    required this.enabled,
    required this.showDivider,
    required this.onTap,
    super.key,
  });

  final ProgramDay day;
  final String? programName;
  final bool enabled;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final int exerciseCount = day.items.length;
    final int? targetSets = day.items.isEmpty
        ? null
        : day.items
              .map((PlanItem item) => item.targetSets)
              .fold<int?>(
                0,
                (int? total, int? sets) =>
                    total == null || sets == null ? null : total + sets,
              );
    // Keep the row compact: the day's own name already says what it is; show
    // exercise count and target sets instead of a redundant day count.
    final String detail = targetSets == null
        ? context.digits(l10n.programExercisesCount(exerciseCount))
        : context.digits(
            '${l10n.programExercisesCount(exerciseCount)} · '
            '${l10n.programSetsCount(targetSets)}',
          );
    return Column(
      children: <Widget>[
        InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTokens.space2,
              AppTokens.space1 + AppTokens.spaceHalf,
              AppTokens.space2,
              AppTokens.space1 + AppTokens.spaceHalf,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppTokens.accent.withValues(alpha: 0.14)
                        : AppTokens.surface2,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: enabled ? AppTokens.accent : AppTokens.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTokens.space1 + AppTokens.spaceHalf),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (programName != null && programName!.isNotEmpty)
                        Text(
                          programName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      Text(
                        day.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(detail, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.space1),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppTokens.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 72,
            endIndent: AppTokens.space2,
          ),
      ],
    );
  }
}

class _RecentWorkoutCard extends StatelessWidget {
  const _RecentWorkoutCard({
    required this.stats,
    required this.unit,
    required this.onOpen,
  });

  final SessionStats? stats;
  final WeightUnit unit;
  final ValueChanged<SessionStats> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final SessionStats? session = stats;
    if (session == null) {
      return AppCard(
        child: Text(
          l10n.historyEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTokens.textSecondary,
          ),
        ),
      );
    }
    return AppCard(
      key: const Key('dashboard-recent-workout'),
      onTap: () => onOpen(session),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.formatDate(session.startedAt, style: AppDateStyle.day),
                style: theme.textTheme.headlineSmall,
              ),
              Text(
                context.formatDate(
                  session.startedAt,
                  style: AppDateStyle.monthYear,
                ),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          Container(
            width: 1,
            height: 46,
            margin: const EdgeInsetsDirectional.symmetric(
              horizontal: AppTokens.space2,
            ),
            color: AppTokens.outline,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  context.digits(
                    '${l10n.workingSets}: ${session.workingSetCount}',
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.digits(
                    '${formatWeight(session.volumeGrams, unit)} '
                    '${weightUnitLabel(context, unit)} · '
                    '${formatTrainingDuration(context, session.duration)}',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}
