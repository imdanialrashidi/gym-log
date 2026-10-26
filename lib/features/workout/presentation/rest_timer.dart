import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_clock.dart';
import '../../../data/rest_timer_store.dart';

/// In-app rest timer state. The end timestamp is the source of truth; the
/// remaining duration is recomputed from the clock on every tick and when the
/// app resumes, so time spent in the background is accounted for (`LOG-008`).
class RestTimerState {
  const RestTimerState({
    this.endsAt,
    this.remaining = Duration.zero,
    this.finished = false,
    this.duration = Duration.zero,
  });

  final DateTime? endsAt;
  final Duration remaining;
  final bool finished;

  /// The configured length of this countdown, used for progress feedback.
  final Duration duration;

  bool get isVisible => endsAt != null;

  /// Completed fraction in `0..1`; zero when the configured length is unknown.
  double get progress {
    if (duration <= Duration.zero) {
      return 0;
    }
    final double value = 1 - remaining.inMilliseconds / duration.inMilliseconds;
    return value.clamp(0, 1);
  }
}

final NotifierProvider<RestTimerController, RestTimerState>
restTimerControllerProvider =
    NotifierProvider<RestTimerController, RestTimerState>(
      RestTimerController.new,
    );

class RestTimerController extends Notifier<RestTimerState> {
  Timer? _ticker;
  bool _restoring = false;
  int _generation = 0;

  @override
  RestTimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    // A process death during the workout must not lose the countdown. Restoring
    // is best-effort and never blocks the first paint.
    unawaited(_restore());
    return const RestTimerState();
  }

  /// Starts or restarts the timer. Never awaited by logging.
  void start(Duration duration) {
    if (duration <= Duration.zero) {
      return;
    }
    _generation += 1;
    final DateTime endsAt = ref.read(appClockProvider)().add(duration);
    state = RestTimerState(
      endsAt: endsAt,
      remaining: duration,
      duration: duration,
    );
    _startTicker();
    unawaited(
      ref
          .read(restTimerStoreProvider)
          .save(PersistedRestTimer(endsAt: endsAt, duration: duration)),
    );
  }

  /// Recomputes from [RestTimerState.endsAt]. Call after the app resumes.
  void refresh() => _tick();

  void dismiss() {
    _generation += 1;
    _ticker?.cancel();
    _ticker = null;
    state = const RestTimerState();
    unawaited(ref.read(restTimerStoreProvider).clear());
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _restore() async {
    if (_restoring) {
      return;
    }
    _restoring = true;
    final int generation = _generation;
    try {
      final RestTimerStore store = ref.read(restTimerStoreProvider);
      final PersistedRestTimer? saved = await store.load();
      if (saved == null ||
          generation != _generation ||
          state.isVisible ||
          _ticker != null) {
        return;
      }
      final Duration remaining = saved.endsAt.difference(
        ref.read(appClockProvider)(),
      );
      if (remaining <= Duration.zero) {
        await store.clear();
        return;
      }
      state = RestTimerState(
        endsAt: saved.endsAt,
        remaining: remaining,
        duration: saved.duration,
      );
      _startTicker();
    } catch (_) {
      // The rest timer is optional; a missing or unreadable marker leaves the
      // app fully usable.
    } finally {
      _restoring = false;
    }
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
      state = RestTimerState(
        endsAt: endsAt,
        finished: true,
        duration: current.duration,
      );
      unawaited(ref.read(restTimerStoreProvider).clear());
      unawaited(_vibrate());
      return;
    }
    state = RestTimerState(
      endsAt: endsAt,
      remaining: remaining,
      duration: current.duration,
    );
  }

  Future<void> _vibrate() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {
      // Haptics are best-effort; the visual completion state still stands.
    }
  }
}
