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
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/muscle_balance_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../core/widgets/training_formats.dart';
import '../../../data/training_overview.dart';

/// The week-at-a-glance report: workouts, volume, time, sets, weight change,
/// and muscle split (`WEEK-001`).
class WeeklySummaryScreen extends ConsumerWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.weeklySummaryTitle)),
      body: DocumentGate(
        builder: (BuildContext context, AppData data) {
          final DateTime now = ref.watch(appClockProvider)();
          final DateTime day = DateTime(now.year, now.month, now.day);
          final TrainingOverview? overview = ref.watch(
            trainingOverviewProvider((
              weekStartsOn: context.weekStartsOn,
              day: day,
            )),
          );
          if (overview == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final WeightUnit unit = data.settings.weightUnit;
          final WeekStats current = overview.currentWeek;
          final List<WeekStats> previous = overview.weeks
              .where(
                (WeekStats week) =>
                    !week.isCurrentWeek && week.sessionCount > 0,
              )
              .toList()
              .reversed
              .toList();

          return ListView(
            key: const Key('weekly-summary-list'),
            padding: EdgeInsetsDirectional.fromSTEB(
              AppTokens.pagePadding(MediaQuery.sizeOf(context).width),
              AppTokens.space2,
              AppTokens.pagePadding(MediaQuery.sizeOf(context).width),
              AppTokens.space4,
            ),
            children: <Widget>[
              _WeekHero(week: current, unit: unit),
              if (current.sessionCount == 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: AppTokens.space2,
                  ),
                  child: Text(
                    l10n.noTrainingThisWeek,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTokens.textSecondary),
                  ),
                ),
              if (current.sessionCount > 0) ...<Widget>[
                const SizedBox(height: AppTokens.space3),
                SectionHeader(
                  title: l10n.muscleSetsTitle,
                  subtitle: l10n.muscleSetsHint,
                ),
                MuscleBalanceCard(
                  workingSetsByMuscle: current.workingSetsByMuscle,
                ),
                const SizedBox(height: AppTokens.space3),
                SectionHeader(title: l10n.sessionsTitle),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      for (
                        int index = 0;
                        index < current.sessions.length;
                        index += 1
                      ) ...<Widget>[
                        if (index > 0)
                          const Divider(height: 1, indent: AppTokens.space2),
                        _WeekSessionRow(
                          stats: current.sessions[index],
                          unit: unit,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.space3),
              if (previous.isEmpty)
                Text(
                  l10n.weeklySummaryEmpty,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTokens.textSecondary),
                )
              else ...<Widget>[
                SectionHeader(title: l10n.previousWeeks),
                for (final WeekStats week in previous)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppTokens.space1,
                    ),
                    child: _PreviousWeekCard(week: week, unit: unit),
                  ),
              ],
              const SizedBox(height: AppTokens.space2),
              OutlinedButton.icon(
                key: const Key('weekly-summary-body-weight'),
                onPressed: () => context.push(AppRoutes.bodyWeight),
                icon: const Icon(Icons.monitor_weight_outlined),
                label: Text(l10n.bodyWeightTitle),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeekHero extends StatelessWidget {
  const _WeekHero({required this.week, required this.unit});

  final WeekStats week;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final BodyWeightWeek? weight = week.bodyWeight;
    return AppCard(
      borderColor: AppTokens.outlineStrong,
      padding: const EdgeInsetsDirectional.all(AppTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  week.isCurrentWeek ? l10n.thisWeek : l10n.previousWeeks,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                context.formatDate(
                  week.weekStart,
                  style: AppDateStyle.monthYear,
                ),
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space1),
          Text(_weekRange(context, week), style: theme.textTheme.bodySmall),
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
                  SizedBox(
                    width: half,
                    child: StatTile(
                      label: l10n.weightTrend,
                      value: weight?.weightGrams == null
                          ? l10n.bodyWeightMissingWeek
                          : context.digits(
                              '${formatWeight(weight!.weightGrams!, unit)} '
                              '${weightUnitLabel(context, unit)}',
                            ),
                      icon: Icons.monitor_weight_outlined,
                      tone: weight?.weightGrams == null
                          ? AppTokens.textSecondary
                          : AppTokens.weight,
                      compact: true,
                    ),
                  ),
                ],
              );
            },
          ),
          if (weight?.entry != null && weight?.changeGrams != null) ...<Widget>[
            const SizedBox(height: AppTokens.space1),
            Text(
              context.digits(
                '${formatWeightChange(context, weight!.changeGrams!, unit)} '
                '${l10n.sinceLastCheckIn}',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTokens.weight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekSessionRow extends StatelessWidget {
  const _WeekSessionRow({required this.stats, required this.unit});

  final SessionStats stats;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return InkWell(
      key: ValueKey<String>('weekly-session-${stats.sessionId}'),
      borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      onTap: () => context.push(AppRoutes.session(stats.sessionId)),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppTokens.space2),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTokens.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 19,
                color: AppTokens.accent,
              ),
            ),
            const SizedBox(width: AppTokens.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    context.formatDate(
                      stats.startedAt,
                      style: AppDateStyle.dateTime,
                    ),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.digits(
                      '${l10n.setsLabel(stats.workingSetCount)} · '
                      '${formatWeight(stats.volumeGrams, unit)} '
                      '${weightUnitLabel(context, unit)} · '
                      '${formatTrainingDuration(context, stats.duration)}',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PreviousWeekCard extends StatelessWidget {
  const _PreviousWeekCard({required this.week, required this.unit});

  final WeekStats week;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final BodyWeightWeek? weight = week.bodyWeight;
    return AppCard(
      key: ValueKey<String>(
        'weekly-summary-${week.weekStart.toIso8601String()}',
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _weekRange(context, week),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  context.digits(
                    '${l10n.workoutsLabel(week.sessionCount)} · '
                    '${formatWeight(week.volumeGrams, unit)} '
                    '${weightUnitLabel(context, unit)} · '
                    '${formatTrainingDuration(context, week.duration)}',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (weight?.weightGrams != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppTokens.space1,
              ),
              child: Text(
                context.digits(
                  '${formatWeight(weight!.weightGrams!, unit)} '
                  '${weightUnitLabel(context, unit)}',
                ),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTokens.weight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _weekRange(BuildContext context, WeekStats week) {
  final DateTime end = DateTime(
    week.weekEndExclusive.year,
    week.weekEndExclusive.month,
    week.weekEndExclusive.day - 1,
  );
  return context.digits(
    context.l10n.weekRange(
      context.formatDate(week.weekStart),
      context.formatDate(end),
    ),
  );
}
