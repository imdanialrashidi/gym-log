import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_clock.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_formats.dart';

/// In-app rest timer state. The end timestamp is the source of truth; the
/// remaining duration is recomputed from the clock on every tick and when the
/// app resumes, so time spent in the background is accounted for (`LOG-008`).
class RestTimerState {
  const RestTimerState({
    this.endsAt,
    this.remaining = Duration.zero,
    this.finished = false,
  });

  final DateTime? endsAt;
  final Duration remaining;
  final bool finished;

  bool get isVisible => endsAt != null;
}

final NotifierProvider<RestTimerController, RestTimerState>
restTimerControllerProvider =
    NotifierProvider<RestTimerController, RestTimerState>(
      RestTimerController.new,
    );

class RestTimerController extends Notifier<RestTimerState> {
  Timer? _ticker;

  @override
  RestTimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const RestTimerState();
  }

  /// Starts or restarts the timer. Never awaited by logging.
  void start(Duration duration) {
    if (duration <= Duration.zero) {
      return;
    }
    _ticker?.cancel();
    final DateTime endsAt = ref.read(appClockProvider)().add(duration);
    state = RestTimerState(endsAt: endsAt, remaining: duration);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Recomputes from [RestTimerState.endsAt]. Call after the app resumes.
  void refresh() => _tick();

  void dismiss() {
    _ticker?.cancel();
    _ticker = null;
    state = const RestTimerState();
  }

  void _tick() {
    final RestTimerState current = state;
    final DateTime? endsAt = current.endsAt;
    if (endsAt == null || current.finished) {
      return;
    }
    final DateTime now = ref.read(appClockProvider)();
    final Duration remaining = endsAt.difference(now);
    if (remaining <= Duration.zero) {
      _ticker?.cancel();
      _ticker = null;
      state = RestTimerState(endsAt: endsAt, finished: true);
      unawaited(_vibrate());
      return;
    }
    state = RestTimerState(endsAt: endsAt, remaining: remaining);
  }

  Future<void> _vibrate() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {
      // Haptics are best-effort; the visual completion state still stands.
    }
  }
}

/// Non-blocking rest countdown shown above the active logging surface.
class RestTimerBanner extends ConsumerStatefulWidget {
  const RestTimerBanner({super.key});

  @override
  ConsumerState<RestTimerBanner> createState() => _RestTimerBannerState();
}

class _RestTimerBannerState extends ConsumerState<RestTimerBanner>
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
    final RestTimerState timer = ref.watch(restTimerControllerProvider);
    if (!timer.isVisible) {
      return const SizedBox.shrink();
    }

    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('rest-timer-banner'),
        margin: const EdgeInsetsDirectional.only(bottom: AppTokens.space2),
        padding: const EdgeInsetsDirectional.all(AppTokens.space1),
        decoration: BoxDecoration(
          color: AppTokens.surface2,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(
            color: timer.finished ? AppTokens.accent : AppTokens.textSecondary,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              timer.finished
                  ? Icons.notifications_active
                  : Icons.timer_outlined,
              color: timer.finished
                  ? AppTokens.accent
                  : AppTokens.textSecondary,
            ),
            const SizedBox(width: AppTokens.space1),
            Expanded(
              child: Text(
                timer.finished
                    ? l10n.restTimerComplete
                    : context.digits(
                        l10n.restTimerRunning(
                          formatRestDuration(timer.remaining),
                        ),
                      ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: timer.finished
                      ? AppTokens.accent
                      : AppTokens.textPrimary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
            IconButton(
              key: const Key('rest-timer-stop'),
              tooltip: l10n.restTimerStop,
              onPressed: () =>
                  ref.read(restTimerControllerProvider.notifier).dismiss(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
