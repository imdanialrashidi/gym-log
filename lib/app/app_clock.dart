import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single clock injected by tests that need deterministic time.
typedef AppClock = DateTime Function();

final Provider<AppClock> appClockProvider = Provider<AppClock>(
  (Ref ref) => DateTime.now,
);
