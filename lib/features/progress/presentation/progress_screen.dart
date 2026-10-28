import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_clock.dart';
import '../../../app/document_gate.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/action_runner.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/mini_trend.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../core/widgets/text_empty_state.dart';
import '../../../core/widgets/training_formats.dart';
import '../../../data/app_data_controller.dart';
import '../../../data/training_overview.dart';
import '../../body_weight/presentation/body_weight_summary_card.dart';
import '../../body_weight/presentation/log_weight_dialog.dart';

/// Progress overview: this week at a glance, the body-weight trend, and one
/// card per trained exercise with best-set numbers and total time (`PRG-001`–
/// `PRG-003`, `BODY-002`).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return DocumentGate(
      builder: (BuildContext context, AppData data) {
        final DateTime now = ref.watch(appClockProvider)();
        final DateTime day = DateTime(now.year, now.month, now.day);
        final TrainingOverview? overview = ref.watch(
          trainingOverviewProvider((
            weekStartsOn: context.weekStartsOn,
            day: day,
          )),
        );
        final List<_ExerciseSummary> summaries = _summaries(
          data,
          now,
          l10n.exerciseNotFound,
        );
        final double padding = AppTokens.pagePadding(
          MediaQuery.sizeOf(context).width,
        );

        return ListView(
          key: const Key('progress-list'),
          padding: EdgeInsetsDirectional.fromSTEB(
            padding,
            AppTokens.space2,
            padding,
            AppTokens.space4,
          ),
          children: <Widget>[
            if (summaries.isEmpty) ...<Widget>[
              TextEmptyState(message: l10n.progressEmpty),
              SectionHeader(
                title: l10n.bodyWeightTitle,
                actionLabel: l10n.viewAll,
                actionKey: const Key('progress-open-body-weight'),
                onAction: () => context.push(AppRoutes.bodyWeight),
              ),
              BodyWeightSummaryCard(
                overview: overview,
                unit: data.settings.weightUnit,
                cardKey: const Key('progress-body-weight'),
                onOpen: () => context.push(AppRoutes.bodyWeight),
                onLog: () => unawaited(
                  _logWeight(context, ref, overview, data.settings.weightUnit),
                ),
              ),
            ] else ...<Widget>[
              _WeekOverviewCard(
                overview: overview,
                unit: data.settings.weightUnit,
                onOpen: () => context.push(AppRoutes.weeklySummary),
              ),
              const SizedBox(height: AppTokens.space3),
            ],
            if (summaries.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppTokens.space3),
              SectionHeader(
                title: l10n.exercisesTitle,
                subtitle: l10n.progressSummaryHint,
              ),
              for (final _ExerciseSummary summary in summaries)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppTokens.space1,
                  ),
                  child: _ProgressCard(
                    summary: summary,
                    unit: data.settings.weightUnit,
                    onTap: () => context.push(
                      AppRoutes.exerciseProgress(summary.exerciseId),
                    ),
                  ),
                ),
            ],
            if (summaries.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppTokens.space3),
              SectionHeader(
                title: l10n.bodyWeightTitle,
                actionLabel: l10n.viewAll,
                actionKey: const Key('progress-open-body-weight'),
                onAction: () => context.push(AppRoutes.bodyWeight),
              ),
              BodyWeightSummaryCard(
                overview: overview,
                unit: data.settings.weightUnit,
                cardKey: const Key('progress-body-weight'),
                onOpen: () => context.push(AppRoutes.bodyWeight),
                onLog: () => unawaited(
                  _logWeight(context, ref, overview, data.settings.weightUnit),
                ),
              ),
            ],
          ],
        );
      },
    );
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

class _WeekOverviewCard extends StatelessWidget {
  const _WeekOverviewCard({
    required this.overview,
    required this.unit,
    required this.onOpen,
  });

  final TrainingOverview? overview;
  final WeightUnit unit;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final WeekStats? week = overview?.currentWeek;
    if (week == null) {
      return const SizedBox.shrink();
    }
    return AppCard(
      key: const Key('progress-week-overview'),
      borderColor: AppTokens.outlineStrong,
      padding: const EdgeInsetsDirectional.all(AppTokens.space3),
      onTap: onOpen,
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
                    Text(l10n.thisWeek, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      formatWeekRange(context, week),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
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
                      label: l10n.workoutsStatLabel,
                      value: context.digits('${week.sessionCount}'),
                      compact: true,
                    ),
                  ),
                  SizedBox(
                    width: half,
                    child: StatTile(
                      label: l10n.volumeLabel,
                      value: context.digits(
                        formatWeight(week.volumeGrams, unit),
                      ),
                      unit: weightUnitLabel(context, unit),
                      compact: true,
                    ),
                  ),
                  SizedBox(
                    width: half,
                    child: StatTile(
                      label: l10n.setsStatLabel,
                      value: context.digits('${week.workingSetCount}'),
                      compact: true,
                    ),
                  ),
                  SizedBox(
                    width: half,
                    child: StatTile(
                      label: l10n.timeLabel,
                      value: formatTrainingDurationShort(
                        context,
                        week.duration,
                      ),
                      compact: true,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.space1),
          Row(
            children: <Widget>[
              Text(
                l10n.viewWeeklySummary,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTokens.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                size: 15,
                color: AppTokens.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseSummary {
  const _ExerciseSummary({
    required this.exerciseId,
    required this.name,
    required this.progress,
    required this.training,
  });

  final String exerciseId;
  final String name;
  final ExerciseProgress progress;
  final ExerciseTrainingStats training;
}

List<_ExerciseSummary> _summaries(
  AppData data,
  DateTime now,
  String missingName,
) {
  final Set<String> exerciseIds = <String>{};
  for (final Session session in data.sessions) {
    if (session.isActive) {
      continue;
    }
    for (final SessionExercise exercise in session.exercises) {
      if (exercise.workingSets.isNotEmpty) {
        exerciseIds.add(exercise.exerciseId);
      }
    }
  }

  // One session pass each, not one pass per exercise.
  final Map<String, ExerciseProgress> progressById = prepareExerciseProgressMap(
    sessions: data.sessions,
    exerciseIds: exerciseIds,
    now: now,
  );
  final Map<String, ExerciseTrainingStats> trainingById =
      exerciseTrainingStatsMap(
        sessions: data.sessions,
        exerciseIds: exerciseIds,
      );

  final List<_ExerciseSummary> summaries = <_ExerciseSummary>[];
  for (final String exerciseId in exerciseIds) {
    final ExerciseProgress progress = progressById[exerciseId]!;
    if (!progress.hasData) {
      continue;
    }
    summaries.add(
      _ExerciseSummary(
        exerciseId: exerciseId,
        name: data.exerciseById(exerciseId)?.name ?? missingName,
        progress: progress,
        training: trainingById[exerciseId]!,
      ),
    );
  }
  summaries.sort((_ExerciseSummary a, _ExerciseSummary b) {
    final DateTime? aLast = a.training.lastTrainedAt;
    final DateTime? bLast = b.training.lastTrainedAt;
    if (aLast != null && bLast != null) {
      final int byDate = bLast.compareTo(aLast);
      if (byDate != 0) {
        return byDate;
      }
    }
    return a.name.compareTo(b.name);
  });
  return summaries;
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.summary,
    required this.unit,
    required this.onTap,
  });

  final _ExerciseSummary summary;
  final WeightUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ExerciseProgress progress = summary.progress;
    final ExerciseTrainingStats training = summary.training;
    String weight(double? grams) {
      if (grams == null) {
        return l10n.progressValueMissing;
      }
      return context.digits(
        '${formatWeight(grams.round(), unit)} '
        '${weightUnitLabel(context, unit)}',
      );
    }

    return AppCard(
      key: ValueKey<String>('progress-exercise-${summary.exerciseId}'),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  summary.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
          const SizedBox(height: AppTokens.space1),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: l10n.progressBestWeight,
                  value: weight(progress.bestWeightGrams),
                  compact: true,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: l10n.progressBestE1rm,
                  value: weight(progress.bestOneRepMaxGrams),
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space1),
          MiniTrend(
            points: progress.bestWeightSeries.length > 12
                ? progress.bestWeightSeries.sublist(
                    progress.bestWeightSeries.length - 12,
                  )
                : progress.bestWeightSeries,
            height: 38,
          ),
          const SizedBox(height: AppTokens.space1),
          Text(
            context.digits(
              '${l10n.setsLabel(training.workingSetCount)} · '
              '${training.totalSpan == Duration.zero ? l10n.notEnoughData : formatTrainingDuration(context, training.totalSpan)} · '
              '${l10n.progressSessions(progress.sessionCount)}',
            ),
            maxLines: 2,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
