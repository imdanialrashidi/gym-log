import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_formats.dart';
import '../../../core/widgets/progress_track.dart';
import '../../../data/app_data_controller.dart';
import 'rest_timer.dart';

/// The in-app live workout notification.
///
/// Sticky above every tab while a session is active. It names the exercise
/// being trained, shows set progress, and becomes the rest countdown while the
/// timer runs. This is intentionally in-app: the release build declares no
/// notification permission (`SET-004`), so the bar is the notification surface.
class WorkoutLiveBar extends ConsumerStatefulWidget {
  const WorkoutLiveBar({super.key});

  @override
  ConsumerState<WorkoutLiveBar> createState() => _WorkoutLiveBarState();
}

class _WorkoutLiveBarState extends ConsumerState<WorkoutLiveBar>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(restTimerControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppData? data = ref.watch(
      appDataControllerProvider.select(
        (AsyncValue<AppData> value) => value.value,
      ),
    );
    final Session? session = data?.activeSession;
    if (data == null || session == null) {
      return const SizedBox.shrink();
    }
    final _LiveExercise? live = _currentExercise(data, session);
    if (live == null) {
      return const SizedBox.shrink();
    }
    final RestTimerState timer = ref.watch(restTimerControllerProvider);
    final double padding = AppTokens.pagePadding(
      MediaQuery.sizeOf(context).width,
    );
    final String name = live.exercise?.name ?? l10n.exerciseNotFound;
    final String progress = live.target == null
        ? context.digits(l10n.setsLabel(live.done))
        : context.digits(l10n.setProgress(live.done, live.target!));
    final String next = context.digits(_nextLabel(l10n, data, session, live));
    final BorderRadius shape = BorderRadius.circular(AppTokens.radiusMedium);

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        padding,
        AppTokens.space1,
        padding,
        0,
      ),
      child: Semantics(
        container: true,
        label: l10n.liveSessionLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('workout-live-bar'),
            onTap: () => context.go('/workout'),
            borderRadius: shape,
            child: Ink(
              decoration: BoxDecoration(
                color: AppTokens.surface2,
                borderRadius: shape,
                border: Border.all(
                  color: AppTokens.accent.withValues(alpha: 0.38),
                ),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(AppTokens.space2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsetsDirectional.only(top: 5),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTokens.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.space1),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                l10n.inProgress,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppTokens.accent,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                name,
                                key: const Key('live-exercise-name'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                progress,
                                key: const Key('live-set-progress'),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.north_east,
                          size: 16,
                          color: AppTokens.textSecondary,
                        ),
                      ],
                    ),
                    if (timer.isVisible) ...<Widget>[
                      const SizedBox(height: AppTokens.space1),
                      _RestCountdown(timer: timer, next: next),
                    ] else if (next.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppTokens.spaceHalf),
                      Text(
                        next,
                        key: const Key('live-next-label'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _nextLabel(
    AppLocalizations l10n,
    AppData data,
    Session session,
    _LiveExercise live,
  ) {
    if (!live.complete) {
      return l10n.liveNextSet(
        live.exercise?.name ?? l10n.exerciseNotFound,
        live.nextSet,
      );
    }
    final int index = session.exercises.indexOf(live.sessionExercise);
    for (int next = index + 1; next < session.exercises.length; next++) {
      final SessionExercise candidate = session.exercises[next];
      if (!_isComplete(candidate)) {
        return l10n.liveNextExercise(
          data.exerciseById(candidate.exerciseId)?.name ??
              l10n.exerciseNotFound,
        );
      }
    }
    return l10n.liveAllSetsDone;
  }
}

class _RestCountdown extends ConsumerWidget {
  const _RestCountdown({required this.timer, required this.next});

  final RestTimerState timer;
  final String next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool finished = timer.finished;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTokens.outline)),
          ),
          child: Semantics(
            container: true,
            liveRegion: finished,
            label: finished
                ? l10n.restTimerComplete
                : l10n.restTimerBannerLabel,
            child: Container(
              key: const Key('rest-timer-banner'),
              padding: const EdgeInsetsDirectional.only(top: AppTokens.space1),
              child: Row(
                children: <Widget>[
                  Icon(
                    finished
                        ? Icons.notifications_active
                        : Icons.timer_outlined,
                    color: finished
                        ? AppTokens.accent
                        : AppTokens.textSecondary,
                  ),
                  const SizedBox(width: AppTokens.space1),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        finished
                            ? l10n.restTimerComplete
                            : context.digits(
                                l10n.restTimerRunning(
                                  formatRestDuration(timer.remaining),
                                ),
                              ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: finished
                                  ? AppTokens.accent
                                  : AppTokens.textPrimary,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('rest-timer-stop'),
                    tooltip: l10n.restTimerStop,
                    onPressed: () => ref
                        .read(restTimerControllerProvider.notifier)
                        .dismiss(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spaceHalf),
        ProgressTrack(
          key: const Key('rest-timer-progress'),
          value: finished ? 1 : timer.progress,
          color: finished ? AppTokens.accent : AppTokens.info,
        ),
        if (next.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppTokens.spaceHalf),
          Text(
            next,
            key: const Key('live-next-label'),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ],
    );
  }
}

class _LiveExercise {
  const _LiveExercise({
    required this.sessionExercise,
    required this.exercise,
    required this.done,
    required this.target,
    required this.nextSet,
  });

  final SessionExercise sessionExercise;
  final Exercise? exercise;
  final int done;
  final int? target;
  final int nextSet;

  bool get complete => target != null && done >= target!;
}

_LiveExercise? _currentExercise(AppData data, Session session) {
  if (session.exercises.isEmpty) {
    return null;
  }
  SessionExercise selected = session.exercises.first;
  DateTime? latest;
  for (final SessionExercise exercise in session.exercises) {
    for (final SetLog set in exercise.sets) {
      if (latest == null || set.loggedAt.isAfter(latest)) {
        latest = set.loggedAt;
        selected = exercise;
      }
    }
  }
  if (latest != null && _isComplete(selected)) {
    final int index = session.exercises.indexOf(selected);
    for (int next = index + 1; next < session.exercises.length; next++) {
      if (!_isComplete(session.exercises[next])) {
        selected = session.exercises[next];
        break;
      }
    }
  }
  final int done = selected.workingSets.length;
  return _LiveExercise(
    sessionExercise: selected,
    exercise: data.exerciseById(selected.exerciseId),
    done: done,
    target: selected.targetSets,
    nextSet: done + 1,
  );
}

bool _isComplete(SessionExercise exercise) {
  final int? target = exercise.targetSets;
  return target != null && exercise.workingSets.length >= target;
}
