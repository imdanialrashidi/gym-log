/// Formats the remaining rest time as `mm:ss`. Durations round up so the last
/// visible second lasts the full second.
///
/// Display code applies the active digit style (`L10N-004`) with
/// `context.digits`; the value itself stays ASCII.
String formatRestDuration(Duration remaining) {
  final int totalSeconds = remaining.inMilliseconds <= 0
      ? 0
      : (remaining.inMilliseconds / 1000).ceil();
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
