import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_backdrop.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/muscle_balance_card.dart';
import '../../../core/widgets/pr_badge.dart';
import '../../../core/widgets/training_formats.dart';
import '../../../data/app_data_controller.dart';
import 'workout_done_cat.dart';

/// The post-workout close: what was done, what changed, and the way out.
class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AppData> asyncData = ref.watch(appDataControllerProvider);
    if (asyncData.hasError && !asyncData.hasValue) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sessionSummaryTitle)),
        body: Center(child: Text(l10n.loadFailed)),
      );
    }
    if (!asyncData.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final AppData data = asyncData.requireValue;
    final Session? session = data.sessionById(sessionId);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sessionSummaryTitle)),
        body: Center(child: Text(l10n.sessionNotFound)),
      );
    }
    final SessionStats stats = sessionStatsFor(
      session,
      exercises: data.exercises,
    );
    final List<SessionRecord> records = personalRecordsInSession(
      sessions: data.sessions,
      sessionId: sessionId,
    );
    final Map<String, List<SessionRecord>> recordsByExercise =
        <String, List<SessionRecord>>{};
    for (final SessionRecord record in records) {
      recordsByExercise
          .putIfAbsent(record.exerciseId, () => <SessionRecord>[])
          .add(record);
    }
    final List<MapEntry<String, List<SessionRecord>>> recordGroups =
        recordsByExercise.entries.toList();
    final SessionStats? previous = _previousSession(
      data.sessions,
      before: session.startedAt,
      exerciseList: data.exercises,
    );
    final WeightUnit unit = data.settings.weightUnit;
    final int? volumeDelta = previous == null
        ? null
        : stats.volumeGrams - previous.volumeGrams;
    final double padding = AppTokens.pagePadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessionSummaryTitle),
        actions: <Widget>[
          IconButton(
            key: const Key('summary-open-session'),
            tooltip: l10n.summaryViewSession,
            onPressed: () =>
                unawaited(context.push(AppRoutes.session(sessionId))),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: AppBackdrop(
        child: ListView(
          key: const Key('session-summary-screen'),
          padding: EdgeInsetsDirectional.fromSTEB(
            padding,
            AppTokens.space2,
            padding,
            AppTokens.space4,
          ),
          children: <Widget>[
            const WorkoutDoneCat(key: Key('workout-done-cat')),
            const SizedBox(height: AppTokens.space3),
            _SummaryHero(
              session: session,
              stats: stats,
              unit: unit,
              volumeDelta: volumeDelta,
              previousExists: previous != null,
              recordCount: records.length,
            ),
            const SizedBox(height: AppTokens.space4),
            _SummarySectionTitle(title: l10n.summaryRecordsTitle),
            if (records.isEmpty)
              AppCard(
                child: Text(
                  l10n.summaryNoRecords,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTokens.textSecondary),
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    for (int index = 0; index < recordGroups.length; index += 1)
                      _RecordRow(
                        records: recordGroups[index].value,
                        exerciseName:
                            data.exerciseById(recordGroups[index].key)?.name ??
                            l10n.exerciseNotFound,
                        unit: unit,
                        showDivider: index < recordGroups.length - 1,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppTokens.space4),
            _SummarySectionTitle(title: l10n.muscleSetsTitle),
            MuscleBalanceCard(workingSetsByMuscle: stats.workingSetsByMuscle),
            const SizedBox(height: AppTokens.space4),
            _SummarySectionTitle(title: l10n.summaryBreakdownTitle),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (
                    int index = 0;
                    index < stats.exercises.length;
                    index += 1
                  )
                    _ExerciseRow(
                      index: index,
                      stats: stats.exercises[index],
                      exerciseName:
                          data
                              .exerciseById(stats.exercises[index].exerciseId)
                              ?.name ??
                          l10n.exerciseNotFound,
                      unit: unit,
                      showDivider: index < stats.exercises.length - 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('summary-back-home'),
                onPressed: () => context.go('/workout'),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: Text(l10n.summaryBackHome),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SessionStats? _previousSession(
    List<Session> sessions, {
    required DateTime before,
    required List<Exercise> exerciseList,
  }) {
    Session? previous;
    for (final Session session in sessions) {
      if (session.isActive || !session.startedAt.isBefore(before)) {
        continue;
      }
      if (previous == null || session.startedAt.isAfter(previous.startedAt)) {
        previous = session;
      }
    }
    return previous == null
        ? null
        : sessionStatsFor(previous, exercises: exerciseList);
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.session,
    required this.stats,
    required this.unit,
    required this.volumeDelta,
    required this.previousExists,
    required this.recordCount,
  });

  final Session session;
  final SessionStats stats;
  final WeightUnit unit;
  final int? volumeDelta;
  final bool previousExists;
  final int recordCount;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return AppCard(
      key: const Key('session-summary-hero'),
      gradient: AppGradients.hero,
      borderColor: AppTokens.accentDeep.withValues(alpha: 0.55),
      padding: const EdgeInsetsDirectional.all(AppTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SessionSeal(size: 92, records: recordCount),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.summaryKicker.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTokens.accent,
                        letterSpacing: 1.7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.summaryHeadline,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.digits(
                        context.formatDate(
                          session.endedAt ?? session.startedAt,
                          style: AppDateStyle.dateTime,
                        ),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Flexible(
                child: Text(
                  context.digits(formatWeight(stats.volumeGrams, unit)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 44),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                weightUnitLabel(context, unit),
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          Text(l10n.volumeLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppTokens.space2),
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.only(top: AppTokens.space2),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTokens.outline)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _HeroStat(
                    label: l10n.summaryWorkingSetsLabel,
                    value: context.digits('${stats.workingSetCount}'),
                  ),
                ),
                const _HeroRule(),
                Expanded(
                  child: _HeroStat(
                    label: l10n.summaryDurationLabel,
                    value: formatTrainingDurationShort(context, stats.duration),
                  ),
                ),
                const _HeroRule(),
                Expanded(
                  child: _HeroStat(
                    label: l10n.summaryExercisesLabel,
                    value: context.digits('${stats.exercises.length}'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Wrap(
            spacing: AppTokens.space1,
            runSpacing: AppTokens.space1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (recordCount > 0)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppTokens.space1,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.highlight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    border: Border.all(
                      color: AppTokens.highlight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    context.digits(l10n.summaryPrCountLabel(recordCount)),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTokens.highlight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (volumeDelta == null && !previousExists)
                Text(l10n.summaryNoPrevious, style: theme.textTheme.bodySmall)
              else if (volumeDelta != null)
                Text(
                  context.digits(
                    l10n.summaryVolumeDelta(
                      _signedWeight(context, volumeDelta!, unit),
                    ),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: volumeDelta! >= 0
                        ? AppTokens.accent
                        : AppTokens.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _signedWeight(BuildContext context, int grams, WeightUnit unit) {
    final String magnitude = formatWeight(grams.abs(), unit);
    final String sign = grams >= 0 ? '+' : '−';
    return '$sign$magnitude ${weightUnitLabel(context, unit)}';
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeroRule extends StatelessWidget {
  const _HeroRule();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: AppTokens.outline);
  }
}

class _SessionSeal extends StatelessWidget {
  const _SessionSeal({required this.size, required this.records});

  final double size;
  final int records;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final Widget seal = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SealPainter(
          ring: AppTokens.accent,
          marker: records > 0 ? AppTokens.highlight : AppTokens.accentDeep,
        ),
      ),
    );
    if (reduceMotion) {
      return seal;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.88, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: seal,
    );
  }
}

class _SealPainter extends CustomPainter {
  const _SealPainter({required this.ring, required this.marker});

  final Color ring;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2 - 2;
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = ring.withValues(alpha: 0.55);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.2,
      5.2,
      false,
      ringPaint,
    );
    final Paint inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ring.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius - 9, inner);
    final Paint markerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = marker;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      2.7,
      0.9,
      false,
      markerPaint,
    );
    final Path check = Path()
      ..moveTo(center.dx - radius * 0.3, center.dy)
      ..lineTo(center.dx - radius * 0.06, center.dy + radius * 0.24)
      ..lineTo(center.dx + radius * 0.38, center.dy - radius * 0.26);
    canvas.drawPath(
      check,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppTokens.textPrimary,
    );
    final Paint tick = Paint()..color = marker;
    for (int index = 0; index < 4; index += 1) {
      final double angle = -0.6 + index * 0.35;
      final Offset tickCenter = Offset(
        center.dx + radius * 0.8 * _cos(angle),
        center.dy + radius * 0.8 * _sin(angle),
      );
      canvas.drawCircle(tickCenter, 1.4, tick);
    }
  }

  static double _cos(double value) => math.cos(value);
  static double _sin(double value) => math.sin(value);

  @override
  bool shouldRepaint(_SealPainter oldDelegate) =>
      oldDelegate.ring != ring || oldDelegate.marker != marker;
}

class _SummarySectionTitle extends StatelessWidget {
  const _SummarySectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        bottom: AppTokens.space1,
        top: AppTokens.spaceHalf,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.records,
    required this.exerciseName,
    required this.unit,
    required this.showDivider,
  });

  final List<SessionRecord> records;
  final String exerciseName;
  final WeightUnit unit;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final SessionRecord best = records.reduce((
      SessionRecord a,
      SessionRecord b,
    ) {
      if (a.weightGrams != b.weightGrams) {
        return a.weightGrams > b.weightGrams ? a : b;
      }
      return a.reps >= b.reps ? a : b;
    });
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppTokens.space2,
            AppTokens.space1,
            AppTokens.space2,
            AppTokens.space1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.workspace_premium_outlined,
                color: AppTokens.highlight,
                size: 20,
              ),
              const SizedBox(width: AppTokens.space1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      exerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      context.digits(
                        '${formatWeight(best.weightGrams, unit)} '
                        '${weightUnitLabel(context, unit)} × ${best.reps}',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTokens.highlight,
                      ),
                    ),
                    if (records.length > 1)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 2),
                        child: Text(
                          context.digits(
                            l10n.summaryPrSetCount(records.length),
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTokens.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PrBadge(types: best.types),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: AppTokens.space2,
            endIndent: AppTokens.space2,
          ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.index,
    required this.stats,
    required this.exerciseName,
    required this.unit,
    required this.showDivider,
  });

  final int index;
  final SessionExerciseStats stats;
  final String exerciseName;
  final WeightUnit unit;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.all(AppTokens.space2),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 26,
                child: Text(
                  context.digits((index + 1).toString().padLeft(2, '0')),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTokens.accent,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(width: 1, height: 38, color: AppTokens.outline),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      exerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.digits(
                        '${l10n.programSetsCount(stats.workingSetCount)} · '
                        '${formatWeight(stats.volumeGrams, unit)} '
                        '${weightUnitLabel(context, unit)}',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (stats.setSpan != null)
                Text(
                  formatTrainingDurationShort(context, stats.setSpan),
                  style: theme.textTheme.labelSmall,
                ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: AppTokens.space2,
            endIndent: AppTokens.space2,
          ),
      ],
    );
  }
}
