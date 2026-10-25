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
import '../../../data/app_data_controller.dart';

/// History list plus a month calendar that marks trained days (`HIS-001`).
///
/// Sessions are rendered through a lazy [ListView.builder]; rows outside the
/// viewport and cache extent are never built.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late DateTime _visibleMonth;

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
        final List<Session> sessions = <Session>[
          for (final Session session in data.sessions)
            if (!session.isActive) session,
        ]..sort((Session a, Session b) => b.startedAt.compareTo(a.startedAt));
        final Map<DateTime, Session> trainedDays = <DateTime, Session>{};
        for (final Session session in sessions) {
          final DateTime local = session.startedAt.toLocal();
          final DateTime day = DateTime(local.year, local.month, local.day);
          final Session? existing = trainedDays[day];
          if (existing == null ||
              session.startedAt.isAfter(existing.startedAt)) {
            trainedDays[day] = session;
          }
        }

        final bool isEmpty = sessions.isEmpty;
        return ListView.builder(
          key: const Key('history-list'),
          padding: const EdgeInsetsDirectional.only(
            start: AppTokens.space1,
            end: AppTokens.space1,
            top: AppTokens.space2,
            bottom: AppTokens.space2,
          ),
          itemCount: 1 + (isEmpty ? 0 : sessions.length),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              final Widget calendar = _HistoryCalendar(
                visibleMonth: _visibleMonth,
                trainedDays: trainedDays,
                onPreviousMonth: () => _shiftMonth(-1),
                onNextMonth: () => _shiftMonth(1),
                onOpenDay: _openSession,
              );
              if (!isEmpty) {
                return calendar;
              }
              return Column(
                children: <Widget>[
                  calendar,
                  Padding(
                    padding: const EdgeInsetsDirectional.all(AppTokens.space3),
                    child: Text(
                      l10n.historyEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: AppTokens.textSecondary),
                    ),
                  ),
                ],
              );
            }
            final Session session = sessions[index - 1];
            return _SessionTile(
              session: session,
              onTap: () => _openSession(session),
            );
          },
        );
      },
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

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
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
          const SizedBox(height: AppTokens.space1),
          Row(
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
          const SizedBox(height: AppTokens.space1),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
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
                    decoration: trained == null
                        ? null
                        : BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSmall,
                            ),
                            border: Border.all(color: AppTokens.accent),
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
                            top: 0,
                            start: 0,
                            child: Icon(
                              Icons.check,
                              key: ValueKey<String>(
                                'calendar-trained-${_dayKey(date)}',
                              ),
                              size: 10,
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

  /// Maps a calendar column to a narrow weekday label through the single
  /// calendar service. 2024-01-07 was a Sunday, index 0 of
  /// [MaterialLocalizations.narrowWeekdays].
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
  const _SessionTile({required this.session, required this.onTap});

  final Session session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final int setCount = session.exercises.fold<int>(
      0,
      (int total, SessionExercise exercise) => total + exercise.sets.length,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppTokens.space1,
        end: AppTokens.space1,
        bottom: AppTokens.space1,
      ),
      child: Material(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: ListTile(
          key: ValueKey<String>('history-session-${session.id}'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          title: Text(
            context.formatDate(session.startedAt, style: AppDateStyle.dateTime),
          ),
          subtitle: Text(
            context.digits(
              l10n.historySessionSummary(setCount, session.exercises.length),
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

String _dayKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
