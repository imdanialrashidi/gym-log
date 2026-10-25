import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_clock.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/text_empty_state.dart';
import '../../../data/app_data_controller.dart';

/// Progress overview: exercises with finished training, best weight and best
/// estimated 1RM (`PRG-001`–`PRG-003`).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AppData> asyncData = ref.watch(appDataControllerProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => Center(
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
      data: (AppData data) {
        final DateTime now = ref.watch(appClockProvider)();
        final List<_ExerciseSummary> summaries = _summaries(
          data,
          now,
          l10n.exerciseNotFound,
        );
        if (summaries.isEmpty) {
          return TextEmptyState(message: l10n.progressEmpty);
        }

        return ListView.builder(
          key: const Key('progress-list'),
          padding: const EdgeInsetsDirectional.all(AppTokens.space2),
          itemCount: summaries.length,
          itemBuilder: (BuildContext context, int index) {
            final _ExerciseSummary summary = summaries[index];
            return _ProgressCard(
              summary: summary,
              unit: data.settings.weightUnit,
              onTap: () =>
                  context.push(AppRoutes.exerciseProgress(summary.exerciseId)),
            );
          },
        );
      },
    );
  }
}

class _ExerciseSummary {
  const _ExerciseSummary({
    required this.exerciseId,
    required this.name,
    required this.progress,
  });

  final String exerciseId;
  final String name;
  final ExerciseProgress progress;
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

  final List<_ExerciseSummary> summaries = <_ExerciseSummary>[];
  for (final String exerciseId in exerciseIds) {
    final ExerciseProgress progress = prepareExerciseProgress(
      sessions: data.sessions,
      exerciseId: exerciseId,
      now: now,
    );
    if (!progress.hasData) {
      continue;
    }
    summaries.add(
      _ExerciseSummary(
        exerciseId: exerciseId,
        name: data.exerciseById(exerciseId)?.name ?? missingName,
        progress: progress,
      ),
    );
  }
  summaries.sort((_ExerciseSummary a, _ExerciseSummary b) {
    final int byDate = b.progress.bestWeightSeries.last.date.compareTo(
      a.progress.bestWeightSeries.last.date,
    );
    if (byDate != 0) {
      return byDate;
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
    final ExerciseProgress progress = summary.progress;
    final String unitLabel = switch (unit) {
      WeightUnit.kilograms => l10n.unitKilograms,
      WeightUnit.pounds => l10n.unitPounds,
    };
    final DateTime lastTrained = progress.bestWeightSeries.last.date;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space1),
      child: Material(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: InkWell(
          key: ValueKey<String>('progress-exercise-${summary.exerciseId}'),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        summary.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: AppTokens.space1),
                Wrap(
                  spacing: AppTokens.space3,
                  runSpacing: AppTokens.space1,
                  children: <Widget>[
                    _Stat(
                      label: l10n.progressBestWeight,
                      value: context.digits(
                        '${formatWeight(progress.bestWeightGrams!.round(), unit)} '
                        '$unitLabel',
                      ),
                    ),
                    _Stat(
                      label: l10n.progressBestE1rm,
                      value: progress.bestOneRepMaxGrams == null
                          ? l10n.progressValueMissing
                          : context.digits(
                              '${formatWeight(progress.bestOneRepMaxGrams!.round(), unit)} '
                              '$unitLabel',
                            ),
                      note: progress.bestOneRepMaxGrams == null
                          ? null
                          : progress.bestOneRepMaxLessReliable
                          ? '${l10n.progressEstimatedLabel} · '
                                '${l10n.progressLessReliableLabel}'
                          : l10n.progressEstimatedLabel,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space1),
                Text(
                  context.digits(
                    '${l10n.progressSessions(progress.sessionCount)} · '
                    '${l10n.progressLastTrained(context.formatDate(lastTrained))}',
                  ),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTokens.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.digits(label),
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppTokens.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (note != null)
          Text(
            note!,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppTokens.textSecondary),
          ),
      ],
    );
  }
}
