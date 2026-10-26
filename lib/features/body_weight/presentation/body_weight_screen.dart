import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_clock.dart';
import '../../../app/document_gate.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/action_runner.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/training_formats.dart';
import '../../../core/widgets/undo_snack_bar.dart';
import '../../../data/app_data_controller.dart';
import '../../progress/presentation/progress_chart.dart';
import 'log_weight_dialog.dart';

/// Body-weight check-ins with the weekly trend (`BODY-001`, `BODY-002`).
class BodyWeightScreen extends ConsumerWidget {
  const BodyWeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.bodyWeightTitle)),
      body: DocumentGate(
        builder: (BuildContext context, AppData data) {
          final AppLocalizations l10n = context.l10n;
          final DateTime now = ref.watch(appClockProvider)();
          final int weekStartsOn = context.weekStartsOn;
          final WeightUnit unit = data.settings.weightUnit;
          final List<BodyWeightWeek> allWeeks = weeklyBodyWeight(
            entries: data.bodyWeights,
            now: now,
            weekStartsOn: weekStartsOn,
          );
          final List<BodyWeightWeek> weeks = trimLeadingEmptyWeeks(allWeeks);
          final ({BodyWeightEntry? entry, int? changeGrams}) latest =
              latestBodyWeightChange(data.bodyWeights);
          final List<BodyWeightEntry> ordered =
              List<BodyWeightEntry>.of(data.bodyWeights)..sort(
                (BodyWeightEntry a, BodyWeightEntry b) =>
                    b.recordedAt.compareTo(a.recordedAt),
              );
          final bool loggedThisWeek = allWeeks.last.hasEntry;

          return ListView(
            key: const Key('body-weight-list'),
            padding: EdgeInsetsDirectional.fromSTEB(
              AppTokens.pagePadding(MediaQuery.sizeOf(context).width),
              AppTokens.space2,
              AppTokens.pagePadding(MediaQuery.sizeOf(context).width),
              AppTokens.space4,
            ),
            children: <Widget>[
              _WeightHero(
                entry: latest.entry,
                changeGrams: latest.changeGrams,
                unit: unit,
                loggedThisWeek: loggedThisWeek,
                onLog: () => unawaited(
                  _logWeight(
                    context,
                    ref,
                    unit,
                    latest.entry?.weightGrams,
                    allWeeks.last.entry?.id,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 19,
                      color: AppTokens.highlight,
                    ),
                    const SizedBox(width: AppTokens.space1),
                    Expanded(
                      child: Text(
                        l10n.bodyWeightHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space3),
              SectionHeader(
                title: l10n.bodyWeightChartTitle,
                subtitle: l10n.bodyWeightChartSubtitle,
              ),
              AppCard(
                child: ProgressChart(
                  key: const Key('body-weight-chart'),
                  points: <ProgressPoint>[
                    for (final BodyWeightWeek week in weeks)
                      ProgressPoint(
                        date: week.weekStart,
                        value: week.weightGrams?.toDouble(),
                      ),
                  ],
                  color: AppTokens.weight,
                  formatValue: (double value) => context.digits(
                    '${formatWeight(value.round(), unit)} '
                    '${weightUnitLabel(context, unit)}',
                  ),
                  emptyMessage: l10n.bodyWeightEmpty,
                  semanticsLabel: context.digits(
                    '${l10n.bodyWeightChartTitle}. '
                    '${l10n.checkInCount(data.bodyWeights.length)}',
                  ),
                  axisKeyPrefix: 'body-weight',
                ),
              ),
              const SizedBox(height: AppTokens.space3),
              SectionHeader(
                title: l10n.bodyWeightHistory,
                subtitle: context.digits(
                  l10n.checkInCount(data.bodyWeights.length),
                ),
              ),
              if (ordered.isEmpty)
                AppCard(
                  child: Text(
                    l10n.bodyWeightEmpty,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppTokens.textSecondary),
                  ),
                )
              else
                for (final BodyWeightEntry entry in ordered)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppTokens.space1,
                    ),
                    child: AppCard(
                      key: ValueKey<String>('body-weight-entry-${entry.id}'),
                      padding: const EdgeInsetsDirectional.only(
                        start: AppTokens.space2,
                        end: AppTokens.space1,
                        top: AppTokens.spaceHalf,
                        bottom: AppTokens.spaceHalf,
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTokens.weight.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusSmall,
                              ),
                            ),
                            child: const Icon(
                              Icons.monitor_weight_outlined,
                              size: 19,
                              color: AppTokens.weight,
                            ),
                          ),
                          const SizedBox(width: AppTokens.space2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  context.digits(
                                    '${formatWeight(entry.weightGrams, unit)} '
                                    '${weightUnitLabel(context, unit)}',
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  context.formatDate(
                                    entry.recordedAt,
                                    style: AppDateStyle.dateTime,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: ValueKey<String>(
                              'delete-body-weight-${entry.id}',
                            ),
                            tooltip: l10n.delete,
                            onPressed: () =>
                                unawaited(_deleteWeight(context, ref, entry)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (ordered.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppTokens.space2),
                OutlinedButton.icon(
                  key: const Key('body-weight-log-secondary'),
                  onPressed: () => unawaited(
                    _logWeight(
                      context,
                      ref,
                      unit,
                      latest.entry?.weightGrams,
                      allWeeks.last.entry?.id,
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.logWeight),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _logWeight(
    BuildContext context,
    WidgetRef ref,
    WeightUnit unit,
    int? initialGrams,
    String? replaceId,
  ) async {
    final int? grams = await showLogWeightDialog(
      context,
      unit: unit,
      initialGrams: initialGrams,
    );
    if (grams == null || !context.mounted) {
      return;
    }
    final bool saved = await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .logBodyWeight(weightGrams: grams, replaceId: replaceId),
    );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.bodyWeightSaved)));
    }
  }

  Future<void> _deleteWeight(
    BuildContext context,
    WidgetRef ref,
    BodyWeightEntry entry,
  ) async {
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await confirmDestructive(
      context,
      title: l10n.deleteWeightTitle,
      message: l10n.deleteWeightBody,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final AppDataController controller = ref.read(
      appDataControllerProvider.notifier,
    );
    BodyWeightEntry? removed;
    final bool saved = await runDataAction(context, () async {
      removed = await controller.deleteBodyWeight(entry.id);
    });
    if (!saved || removed == null || !context.mounted) {
      return;
    }
    showUndoSnackBar(
      context,
      message: l10n.bodyWeightDeleted,
      onUndo: () => controller.restoreBodyWeight(removed!),
    );
  }
}

class _WeightHero extends StatelessWidget {
  const _WeightHero({
    required this.entry,
    required this.changeGrams,
    required this.unit,
    required this.loggedThisWeek,
    required this.onLog,
  });

  final BodyWeightEntry? entry;
  final int? changeGrams;
  final WeightUnit unit;
  final bool loggedThisWeek;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final BodyWeightEntry? latest = entry;
    return AppCard(
      gradient: AppGradients.hero,
      borderColor: AppTokens.accentDeep.withValues(alpha: 0.45),
      padding: const EdgeInsetsDirectional.all(AppTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.bodyWeightTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space1),
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
                Text(
                  context.digits(formatWeight(latest.weightGrams, unit)),
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 42),
                ),
                const SizedBox(width: AppTokens.space1),
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 6),
                  child: Text(
                    weightUnitLabel(context, unit),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                if (changeGrams != null)
                  _ChangeChip(changeGrams: changeGrams, unit: unit),
              ],
            ),
          if (changeGrams != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 4),
              child: Text(
                l10n.sinceLastCheckIn,
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: AppTokens.space2),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('body-weight-log'),
              onPressed: onLog,
              icon: const Icon(Icons.add),
              label: Text(
                loggedThisWeek
                    ? l10n.updateWeightThisWeek
                    : l10n.logWeightThisWeek,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip({required this.changeGrams, required this.unit});

  final int? changeGrams;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final int? change = changeGrams;
    if (change == null) {
      return const SizedBox.shrink();
    }
    final bool up = change > 0;
    final bool flat = change == 0;
    final Color tone = flat ? AppTokens.textSecondary : AppTokens.weight;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppTokens.space1,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppTokens.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: tone.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            flat
                ? Icons.remove
                : up
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            size: 14,
            color: tone,
          ),
          const SizedBox(width: 4),
          Text(
            formatWeightChange(context, change, unit),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: tone, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
