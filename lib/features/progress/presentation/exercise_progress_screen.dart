import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_clock.dart';
import '../../../app/document_gate.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/rir_info.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../core/widgets/text_empty_state.dart';
import '../../../core/widgets/training_formats.dart';
import '../../../data/app_data_controller.dart';
import '../../../data/photo_index_controller.dart';
import '../../../data/photo_storage.dart';
import '../../photos/presentation/photo_thumbnail.dart';
import '../../photos/presentation/photo_viewer_screen.dart';
import 'progress_chart.dart';

/// Per-exercise progress detail with range filter and four charts
/// (`PRG-001`–`PRG-003`, `PRG-005`).
class ExerciseProgressScreen extends ConsumerStatefulWidget {
  const ExerciseProgressScreen({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  ConsumerState<ExerciseProgressScreen> createState() =>
      _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState
    extends ConsumerState<ExerciseProgressScreen> {
  ProgressRange _range = ProgressRange.all;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: _ExerciseProgressTitle(exerciseId: widget.exerciseId),
      ),
      body: DocumentGate(
        builder: (BuildContext context, AppData data) {
          final DateTime now = ref.watch(appClockProvider)();
          final ExerciseProgress progress = prepareExerciseProgress(
            sessions: data.sessions,
            exerciseId: widget.exerciseId,
            range: _range,
            now: now,
          );
          final ExerciseTrainingStats training = exerciseTrainingStats(
            sessions: data.sessions,
            exerciseId: widget.exerciseId,
          );
          return !progress.hasHistory
              ? TextEmptyState(message: l10n.progressNoDataForExercise)
              : ListView(
                  key: const Key('exercise-progress-list'),
                  padding: const EdgeInsetsDirectional.all(AppTokens.space2),
                  children: <Widget>[
                    _RangeFilter(
                      selected: _range,
                      onChanged: (ProgressRange range) {
                        setState(() => _range = range);
                      },
                    ),
                    const SizedBox(height: AppTokens.space2),
                    if (!progress.hasData)
                      TextEmptyState(message: l10n.progressNoDataInRange)
                    else
                      ..._charts(
                        context,
                        progress,
                        training,
                        data.settings.weightUnit,
                      ),
                  ],
                );
        },
      ),
    );
  }

  List<Widget> _charts(
    BuildContext context,
    ExerciseProgress progress,
    ExerciseTrainingStats training,
    WeightUnit unit,
  ) {
    final AppLocalizations l10n = context.l10n;
    final String unitLabel = switch (unit) {
      WeightUnit.kilograms => l10n.unitKilograms,
      WeightUnit.pounds => l10n.unitPounds,
    };
    String weightValue(double value) =>
        context.digits('${formatWeight(value.round(), unit)} $unitLabel');

    return <Widget>[
      _SummaryRow(progress: progress, unit: unit),
      const SizedBox(height: AppTokens.space2),
      _TrainingTotalsCard(training: training, unit: unit),
      const SizedBox(height: AppTokens.space2),
      ProgressChartSection(
        key: const Key('progress-chart-weight'),
        title: l10n.progressChartWeightTitle,
        points: progress.bestWeightSeries,
        formatValue: weightValue,
        emptyMessage: l10n.progressChartEmptyValues,
        axisKeyPrefix: 'progress-chart-weight',
      ),
      ProgressChartSection(
        key: const Key('progress-chart-e1rm'),
        title: l10n.progressChartE1rmTitle,
        subtitle: l10n.progressChartE1rmHint,
        points: progress.estimatedOneRepMaxSeries,
        formatValue: weightValue,
        emptyMessage: l10n.progressChartEmptyValues,
        axisKeyPrefix: 'progress-chart-e1rm',
      ),
      ProgressChartSection(
        key: const Key('progress-chart-reps'),
        title: l10n.progressChartRepsTitle,
        points: progress.repsSeries,
        formatValue: (double value) => value.round().toString(),
        emptyMessage: l10n.progressChartEmptyValues,
        axisKeyPrefix: 'progress-chart-reps',
      ),
      ProgressChartSection(
        key: const Key('progress-chart-rir'),
        title: l10n.progressChartRirTitle,
        subtitle: l10n.progressChartRirHint,
        points: progress.rirSeries,
        formatValue: (double value) => value.round().toString(),
        emptyMessage: l10n.progressChartEmptyValues,
        axisKeyPrefix: 'progress-chart-rir',
      ),
      const Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: AppTokens.space2,
          top: AppTokens.spaceHalf,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: RirInfoButton(key: Key('progress-rir-info')),
        ),
      ),
    ];
  }
}

class _ExerciseProgressTitle extends ConsumerWidget {
  const _ExerciseProgressTitle({required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppData? data = ref.watch(appDataControllerProvider).value;
    final PhotoIndex? index = ref.watch(photoIndexProvider).value;
    final String title =
        data?.exerciseById(exerciseId)?.name ?? context.l10n.exerciseNotFound;
    final String? photoName = index?.exerciseFileName(exerciseId);
    if (index == null || photoName == null) {
      return Text(title, overflow: TextOverflow.ellipsis);
    }
    final File file = index.file(photoName);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          button: true,
          label: context.l10n.exercisePhotoLabel,
          child: InkWell(
            key: const Key('exercise-detail-photo'),
            onTap: () => _openPhoto(context, ref, file),
            child: SizedBox(
              width: AppTokens.minTouchTarget,
              height: AppTokens.minTouchTarget,
              child: Center(
                child: PhotoThumbnail(
                  file: file,
                  label: context.l10n.exercisePhotoLabel,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.space1),
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Future<void> _openPhoto(
    BuildContext context,
    WidgetRef ref,
    File file,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext routeContext) => PhotoViewerScreen(
          file: file,
          onRemove: () async {
            await ref
                .read(photoIndexProvider.notifier)
                .removeExercisePhoto(exerciseId);
            return true;
          },
        ),
      ),
    );
  }
}

class _TrainingTotalsCard extends StatelessWidget {
  const _TrainingTotalsCard({required this.training, required this.unit});

  final ExerciseTrainingStats training;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool hasTime = training.totalSpan != Duration.zero;
    final bool hasAverage = training.averageSpan != null;
    return AppCard(
      key: const Key('progress-training-totals'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.trainingTotals, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTokens.space1),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: l10n.totalTime,
                  value: hasTime
                      ? formatTrainingDurationShort(context, training.totalSpan)
                      : '—',
                  icon: Icons.timer_outlined,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: l10n.averageTime,
                  value: hasAverage
                      ? formatTrainingDurationShort(
                          context,
                          training.averageSpan,
                        )
                      : '—',
                  icon: Icons.av_timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space1),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: l10n.workingSets,
                  value: context.digits('${training.workingSetCount}'),
                  icon: Icons.layers_outlined,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: l10n.volumeLabel,
                  value: context.digits(
                    formatWeight(training.volumeGrams, unit),
                  ),
                  unit: weightUnitLabel(context, unit),
                  icon: Icons.scale_outlined,
                ),
              ),
            ],
          ),
          if (!hasTime || !hasAverage) ...<Widget>[
            const SizedBox(height: AppTokens.space2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.info_outline,
                  size: 15,
                  color: AppTokens.textMuted,
                ),
                const SizedBox(width: AppTokens.space1),
                Expanded(
                  child: Text(
                    context.digits(l10n.notEnoughData),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTokens.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RangeFilter extends StatelessWidget {
  const _RangeFilter({required this.selected, required this.onChanged});

  final ProgressRange selected;
  final ValueChanged<ProgressRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<({ProgressRange range, String label, String key})> options =
        <({ProgressRange range, String label, String key})>[
          (
            range: ProgressRange.fourWeeks,
            label: context.digits(l10n.progressRangeFourWeeks),
            key: 'progress-range-four-weeks',
          ),
          (
            range: ProgressRange.twelveWeeks,
            label: context.digits(l10n.progressRangeTwelveWeeks),
            key: 'progress-range-twelve-weeks',
          ),
          (
            range: ProgressRange.oneYear,
            label: context.digits(l10n.progressRangeOneYear),
            key: 'progress-range-one-year',
          ),
          (
            range: ProgressRange.all,
            label: l10n.progressRangeAll,
            key: 'progress-range-all',
          ),
        ];

    return Semantics(
      label: l10n.progressRangeLabel,
      container: true,
      child: Wrap(
        spacing: AppTokens.space1,
        runSpacing: AppTokens.space1,
        children: <Widget>[
          for (final option in options)
            ChoiceChip(
              key: Key(option.key),
              label: Text(option.label),
              selected: selected == option.range,
              showCheckmark: false,
              selectedColor: AppTokens.accent,
              backgroundColor: AppTokens.surface2,
              labelStyle: TextStyle(
                color: selected == option.range
                    ? AppTokens.onAccent
                    : AppTokens.textPrimary,
              ),
              side: BorderSide(
                color: selected == option.range
                    ? AppTokens.accent
                    : AppTokens.textSecondary,
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => onChanged(option.range),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.progress, required this.unit});

  final ExerciseProgress progress;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String unitLabel = switch (unit) {
      WeightUnit.kilograms => l10n.unitKilograms,
      WeightUnit.pounds => l10n.unitPounds,
    };
    String weightText(double? grams) {
      if (grams == null) {
        return l10n.progressValueMissing;
      }
      return context.digits('${formatWeight(grams.round(), unit)} $unitLabel');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _SummaryCard(
            cardKey: const Key('progress-best-weight'),
            label: l10n.progressBestWeight,
            value: weightText(progress.bestWeightGrams),
            note: context.digits(l10n.progressSessions(progress.sessionCount)),
          ),
        ),
        const SizedBox(width: AppTokens.space1),
        Expanded(
          child: _SummaryCard(
            cardKey: const Key('progress-best-e1rm'),
            label: l10n.progressBestE1rm,
            value: weightText(progress.bestOneRepMaxGrams),
            note: progress.bestOneRepMaxLessReliable
                ? '${l10n.progressEstimatedLabel} · '
                      '${l10n.progressLessReliableLabel}'
                : l10n.progressEstimatedLabel,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.cardKey,
    required this.label,
    required this.value,
    required this.note,
  });

  final Key cardKey;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      padding: const EdgeInsetsDirectional.all(AppTokens.space2),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.digits(label),
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppTokens.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            context.digits(value),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            context.digits(note),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
