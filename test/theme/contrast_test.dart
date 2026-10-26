import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/app/theme/app_tokens.dart';

const double _minimumTextContrast = 4.5;

final List<_Pair> _textPairs = <_Pair>[
  const _Pair(
    'textPrimary on background',
    AppTokens.textPrimary,
    AppTokens.background,
  ),
  const _Pair(
    'textPrimary on surface',
    AppTokens.textPrimary,
    AppTokens.surface,
  ),
  const _Pair(
    'textPrimary on surface2',
    AppTokens.textPrimary,
    AppTokens.surface2,
  ),
  const _Pair(
    'textPrimary on surface3',
    AppTokens.textPrimary,
    AppTokens.surface3,
  ),
  const _Pair(
    'textSecondary on background',
    AppTokens.textSecondary,
    AppTokens.background,
  ),
  const _Pair(
    'textSecondary on surface',
    AppTokens.textSecondary,
    AppTokens.surface,
  ),
  const _Pair(
    'textSecondary on surface2',
    AppTokens.textSecondary,
    AppTokens.surface2,
  ),
  const _Pair(
    'textSecondary on surface3',
    AppTokens.textSecondary,
    AppTokens.surface3,
  ),
  const _Pair('accent on background', AppTokens.accent, AppTokens.background),
  const _Pair('accent on surface', AppTokens.accent, AppTokens.surface),
  const _Pair('accent on surface2', AppTokens.accent, AppTokens.surface2),
  const _Pair('accent on surface3', AppTokens.accent, AppTokens.surface3),
  const _Pair(
    'highlight on background',
    AppTokens.highlight,
    AppTokens.background,
  ),
  const _Pair('highlight on surface', AppTokens.highlight, AppTokens.surface),
  const _Pair('highlight on surface2', AppTokens.highlight, AppTokens.surface2),
  const _Pair('highlight on surface3', AppTokens.highlight, AppTokens.surface3),
  const _Pair('danger on background', AppTokens.danger, AppTokens.background),
  const _Pair('danger on surface', AppTokens.danger, AppTokens.surface),
  const _Pair('info on background', AppTokens.info, AppTokens.background),
  const _Pair('info on surface', AppTokens.info, AppTokens.surface),
  const _Pair('info on surface2', AppTokens.info, AppTokens.surface2),
  const _Pair('info on surface3', AppTokens.info, AppTokens.surface3),
  const _Pair('weight on background', AppTokens.weight, AppTokens.background),
  const _Pair('weight on surface', AppTokens.weight, AppTokens.surface),
  const _Pair('weight on surface2', AppTokens.weight, AppTokens.surface2),
  const _Pair('weight on surface3', AppTokens.weight, AppTokens.surface3),
  const _Pair('onAccent on accent', AppTokens.onAccent, AppTokens.accent),
  const _Pair('background on danger', AppTokens.background, AppTokens.danger),
  const _Pair('background on info', AppTokens.background, AppTokens.info),
  const _Pair('background on weight', AppTokens.background, AppTokens.weight),
];

void main() {
  test('every text token pair meets WCAG AA 4.5:1', () {
    final StringBuffer report = StringBuffer(
      'WCAG text contrast (minimum ${_minimumTextContrast.toStringAsFixed(1)}:1):\n',
    );
    final List<String> failures = <String>[];

    for (final _Pair pair in _textPairs) {
      final double ratio = _contrast(pair.foreground, pair.background);
      report.writeln('  ${pair.name}: ${ratio.toStringAsFixed(2)}:1');
      if (ratio < _minimumTextContrast) {
        final _Fix fix = _smallestFix(pair);
        failures.add(
          '${pair.name} = ${ratio.toStringAsFixed(2)}:1; '
          'smallest fix: ${fix.hex} (${fix.ratio.toStringAsFixed(2)}:1)',
        );
      }
    }

    // ignore: avoid_print
    print(report.toString());
    expect(
      failures,
      isEmpty,
      reason:
          'Text contrast failures. The owner palette was not changed:\n'
          '${failures.join('\n')}\n$report',
    );
  });

  test('a failing pair reports a passing smallest fix', () {
    const _Pair failing = _Pair(
      'outline on background',
      AppTokens.outline,
      AppTokens.background,
    );
    expect(
      _contrast(failing.foreground, failing.background),
      lessThan(_minimumTextContrast),
    );

    final _Fix fix = _smallestFix(failing);
    expect(fix.ratio, greaterThanOrEqualTo(_minimumTextContrast));
    expect(fix.hex, matches(RegExp(r'^#[0-9A-F]{6}$')));
  });
}

double _contrast(Color foreground, Color background) {
  final double foregroundLuminance = _relativeLuminance(foreground);
  final double backgroundLuminance = _relativeLuminance(background);
  final double lighter = math.max(foregroundLuminance, backgroundLuminance);
  final double darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  final int value = color.toARGB32();
  final double red = _linearChannel((value >> 16) & 0xFF);
  final double green = _linearChannel((value >> 8) & 0xFF);
  final double blue = _linearChannel(value & 0xFF);
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
}

double _linearChannel(int channel) {
  final double value = channel / 255;
  return value <= 0.04045
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
}

/// Finds the closest sRGB color on the line from the failing foreground to
/// black or white that reaches the text threshold. This is report-only; the
/// palette is never mutated.
_Fix _smallestFix(_Pair pair) {
  final int original = pair.foreground.toARGB32();
  final int originalRed = (original >> 16) & 0xFF;
  final int originalGreen = (original >> 8) & 0xFF;
  final int originalBlue = original & 0xFF;

  _Fix? best;
  for (int step = 1; step <= 255; step++) {
    final double amount = step / 255;
    for (final int target in <int>[0x000000, 0xFFFFFF]) {
      final int red = _blend(originalRed, (target >> 16) & 0xFF, amount);
      final int green = _blend(originalGreen, (target >> 8) & 0xFF, amount);
      final int blue = _blend(originalBlue, target & 0xFF, amount);
      final Color candidate = Color.fromARGB(255, red, green, blue);
      final double ratio = _contrast(candidate, pair.background);
      if (ratio < _minimumTextContrast) {
        continue;
      }
      final int distance =
          (red - originalRed) * (red - originalRed) +
          (green - originalGreen) * (green - originalGreen) +
          (blue - originalBlue) * (blue - originalBlue);
      if (best == null || distance < best.distance) {
        final String hex =
            '#${red.toRadixString(16).padLeft(2, '0')}'
            '${green.toRadixString(16).padLeft(2, '0')}'
            '${blue.toRadixString(16).padLeft(2, '0')}';
        best = _Fix(hex: hex.toUpperCase(), ratio: ratio, distance: distance);
      }
    }
  }
  return best!;
}

int _blend(int from, int to, double amount) {
  return (from + (to - from) * amount).round();
}

class _Pair {
  const _Pair(this.name, this.foreground, this.background);

  final String name;
  final Color foreground;
  final Color background;
}

class _Fix {
  const _Fix({required this.hex, required this.ratio, required this.distance});

  final String hex;
  final double ratio;
  final int distance;
}
