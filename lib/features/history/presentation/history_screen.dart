import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_clock.dart';
import '../../../app/document_gate.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../core/widgets/training_formats.dart';

/// History list plus a month calendar that marks trained days (`HIS-001`).
///
/// Sessions are rendered through a lazy [ListView.builder]; rows outside the
/// viewport are never built. Derived stats are cached per document revision so
/// scrolling does not rescan the same session.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late DateTime _visibleMonth;
  AppData? _statsSource;
  Map<String, SessionStats> _statsCache = <String, SessionStats>{};

  @override
  void initState() {
    super.initState();
    final DateTime now = ref.read(appClockProvider)();
    _visibleMonth = DateTime(now.year, now.month, now.day);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = context.shiftCalendarMonth(_visibleMonth, delta);
    });
  }

  void _openSession(Session session) {
    context.push(AppRoutes.session(session.id));
  }

  @override
  Widget build(BuildContext context) {
    return DocumentGate(
      builder: (BuildContext context, AppData data) {
        final AppLocalizations l10n = context.l10n;
        if (!identical(_statsSource, data)) {
          _statsSource = data;
          _statsCache = <String, SessionStats>{};
        }
        final Map<String, Exercise> exercisesById = <String, Exercise>{
          for (final Exercise exercise in data.exercises) exercise.id: exercise,
        };
        final List<Session> sessions = <Session>[
          for (final Session session in data.sessions)
            if (!session.isActive) session,
        ]..sort((Session a, Session b) => b.startedAt.compareTo(a.startedAt));
        final Map<DateTime, Session> trainedDays = <DateTime, Session>{};
        for (final Session session in sessions) {
          final DateTime day = _localDay(session.startedAt);
          final Session? existing = trainedDays[day];
          if (existing == null ||
              session.startedAt.isAfter(existing.startedAt)) {
            trainedDays[day] = session;
          }
        }

        final CalendarMonth month = context.calendarMonth(_visibleMonth);
        final DateTime monthEnd = DateTime(
          month.start.year,
          month.start.month,
          month.start.day + month.length,
        );
        int monthVolume = 0;
        int monthSets = 0;
        Duration monthDuration = Duration.zero;
        int monthSessions = 0;
        for (final Session session in sessions) {
          final DateTime local = session.startedAt.toLocal();
          if (local.isBefore(month.start) || !local.isBefore(monthEnd)) {
            continue;
          }
          final SessionStats stats = _statsFor(session, exercisesById);
          monthSessions += 1;
          monthVolume += stats.volumeGrams;
          monthSets += stats.workingSetCount;
          monthDuration += stats.duration ?? Duration.zero;
        }

        final bool isEmpty = sessions.isEmpty;
        return ListView.builder(
          key: const Key('history-list'),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppTokens.space1,
            AppTokens.space2,
            AppTokens.space1,
            AppTokens.space4,
          ),
          itemCount: 1 + (isEmpty ? 0 : sessions.length),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _MonthSummary(
                    monthLabel: context.formatDate(
                      month.start,
                      style: AppDateStyle.monthYear,
                    ),
                    sessions: monthSessions,
                    volumeGrams: monthVolume,
                    workingSets: monthSets,
                    duration: monthDuration,
                    unit: data.settings.weightUnit,
                  ),
                  const SizedBox(height: AppTokens.space2),
                  _HistoryCalendar(
                    visibleMonth: _visibleMonth,
                    trainedDays: trainedDays,
                    onPreviousMonth: () => _shiftMonth(-1),
                    onNextMonth: () => _shiftMonth(1),
                    onOpenDay: _openSession,
                  ),
                  if (isEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.all(
                        AppTokens.space3,
                      ),
                      child: Text(
                        l10n.historyEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppTokens.textSecondary),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: AppTokens.space2,
                        bottom: AppTokens.space1,
                      ),
                      child: Text(
                        l10n.sessionsTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                ],
              );
            }
            final Session session = sessions[index - 1];
            return Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: AppTokens.space1,
              ),
              child: _SessionTile(
                session: session,
                stats: _statsFor(session, exercisesById),
                unit: data.settings.weightUnit,
                onTap: () => _openSession(session),
              ),
            );
          },
        );
      },
    );
  }

  SessionStats _statsFor(Session session, Map<String, Exercise> exercisesById) {
    return _statsCache.putIfAbsent(
      session.id,
      () => sessionStatsUsingMap(
        session,
        exerciseById: exercisesById,
        now: ref.read(appClockProvider)(),
      ),
    );
  }
}

DateTime _localDay(DateTime value) {
  final DateTime local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({
    required this.monthLabel,
    required this.sessions,
    required this.volumeGrams,
    required this.workingSets,
    required this.duration,
    required this.unit,
  });

  final String monthLabel;
  final int sessions;
  final int volumeGrams;
  final int workingSets;
  final Duration duration;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return AppCard(
      key: const Key('history-month-summary'),
      gradient: AppGradients.hero,
      borderColor: AppTokens.accentDeep.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.digits('${l10n.thisMonth} · $monthLabel'),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                context.digits(l10n.workoutsLabel(sessions)),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTokens.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space1),
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
                      label: l10n.volumeLabel,
                      value: context.digits(formatWeight(volumeGrams, unit)),
                      unit: weightUnitLabel(context, unit),
                      compact: true,
                    ),
                  ),
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
                      label: l10n.timeLabel,
                      value: formatTrainingDurationShort(context, duration),
                      compact: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryCalendar extends StatelessWidget {
  const _HistoryCalendar({
    required this.visibleMonth,
    required this.trainedDays,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onOpenDay,
  });

  final DateTime visibleMonth;
  final Map<DateTime, Session> trainedDays;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final void Function(Session session) onOpenDay;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final CalendarMonth month = context.calendarMonth(visibleMonth);
    final int leading =
        (month.firstWeekdayIndex - context.weekStartIndex + 7) % 7;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppTokens.space1,
            ),
            child: Row(
              children: <Widget>[
                IconButton(
                  key: const Key('history-previous-month'),
                  tooltip: l10n.historyCalendarPrevious,
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    context.formatDate(
                      month.start,
                      style: AppDateStyle.monthYear,
                    ),
                    key: const Key('history-month'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('history-next-month'),
                  tooltip: l10n.historyCalendarNext,
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.spaceHalf),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppTokens.space1,
            ),
            child: Row(
              children: <Widget>[
                for (int column = 0; column < 7; column++)
                  Expanded(
                    child: Text(
                      _weekdayLabel(context, column),
                      key: ValueKey<String>('calendar-weekday-$column'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AppTokens.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.spaceHalf),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 1,
            ),
            itemCount: leading + month.length,
            itemBuilder: (BuildContext context, int index) {
              if (index < leading) {
                return const SizedBox.shrink();
              }
              final int day = index - leading + 1;
              final DateTime date = DateTime(
                month.start.year,
                month.start.month,
                month.start.day + day - 1,
              );
              final Session? trained = trainedDays[date];
              final String label = context.formatDate(date);
              return Semantics(
                label: trained == null
                    ? label
                    : context.digits(l10n.historyTrainedDay(label)),
                button: trained != null,
                child: InkWell(
                  key: ValueKey<String>('calendar-day-${_dayKey(date)}'),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  onTap: trained == null ? null : () => onOpenDay(trained),
                  child: Container(
                    decoration: BoxDecoration(
                      color: trained == null
                          ? null
                          : AppTokens.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(
                        AppTokens.radiusSmall,
                      ),
                      border: Border.all(
                        color: trained == null
                            ? Colors.transparent
                            : AppTokens.accent,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Text(
                          context.formatDate(date, style: AppDateStyle.day),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: trained == null
                                ? AppTokens.textPrimary
                                : AppTokens.accent,
                            fontWeight: trained == null
                                ? FontWeight.w400
                                : FontWeight.w700,
                          ),
                        ),
                        if (trained != null)
                          PositionedDirectional(
                            bottom: 3,
                            start: 0,
                            end: 0,
                            child: Icon(
                              Icons.check,
                              key: ValueKey<String>(
                                'calendar-trained-${_dayKey(date)}',
                              ),
                              size: 9,
                              color: AppTokens.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(BuildContext context, int column) {
    final int firstDay = context.weekStartIndex;
    final DateTime anchor = DateTime(
      2024,
      1,
      7,
    ).add(Duration(days: (firstDay + column) % 7));
    return context.formatDate(anchor, style: AppDateStyle.weekdayNarrow);
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.stats,
    required this.unit,
    required this.onTap,
  });

  final Session session;
  final SessionStats stats;
  final WeightUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final DateTime local = session.startedAt.toLocal();
    return AppCard(
      key: ValueKey<String>('history-session-${session.id}'),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 52,
            decoration: BoxDecoration(
              color: AppTokens.surface2,
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
              border: Border.all(color: AppTokens.outline),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.formatDate(local, style: AppDateStyle.day),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.formatDate(
                      local,
                      style: AppDateStyle.weekdayNarrow,
                    ),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
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
                    session.startedAt,
                    style: AppDateStyle.dateTime,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space1),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}

String _dayKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
