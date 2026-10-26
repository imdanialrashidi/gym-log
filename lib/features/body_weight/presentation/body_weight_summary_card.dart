import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/mini_trend.dart';
import '../../../core/widgets/training_formats.dart';
import '../../../data/training_overview.dart';

/// Compact body-weight trend: latest reading, change, sparkline, and one CTA.
///
/// Used by the dashboard and Progress so both surfaces show the same numbers
/// from the same memoized overview.
class BodyWeightSummaryCard extends StatelessWidget {
  const BodyWeightSummaryCard({
    required this.overview,
    required this.unit,
    required this.onOpen,
    required this.onLog,
    super.key,
    this.cardKey,
  });

  final TrainingOverview? overview;
  final WeightUnit unit;
  final VoidCallback onOpen;
  final VoidCallback onLog;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final BodyWeightEntry? latest = overview?.latestWeightEntry;
    final int? change = overview?.weightChangeGrams;
    final bool loggedThisWeek = overview?.loggedWeightThisWeek ?? false;
    return AppCard(
      key: cardKey,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (latest == null)
            Text(
              l10n.bodyWeightEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTokens.textSecondary,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              context.digits(
                                formatWeight(latest.weightGrams, unit),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              weightUnitLabel(context, unit),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        change == null
                            ? l10n.bodyWeightSubtitle
                            : context.digits(
                                '${formatWeightChange(context, change, unit)} '
                                '${l10n.sinceLastCheckIn}',
                              ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTokens.weight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                SizedBox(
                  width: 110,
                  child: MiniTrend(
                    points: <ProgressPoint>[
                      for (final BodyWeightWeek week in trimLeadingEmptyWeeks(
                        <BodyWeightWeek>[
                          for (final WeekStats statsWeek
                              in overview?.weeks ?? const <WeekStats>[])
                            BodyWeightWeek(
                              weekStart: statsWeek.weekStart,
                              entry: statsWeek.bodyWeight?.entry,
                              changeGrams: statsWeek.bodyWeight?.changeGrams,
                            ),
                        ],
                      ))
                        ProgressPoint(
                          date: week.weekStart,
                          value: week.weightGrams?.toDouble(),
                        ),
                    ],
                    color: AppTokens.weight,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppTokens.space2),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('dashboard-log-weight'),
                  onPressed: onLog,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    loggedThisWeek ? l10n.updateWeightThisWeek : l10n.logWeight,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space1),
              IconButton(
                tooltip: l10n.openBodyWeight,
                onPressed: onOpen,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
