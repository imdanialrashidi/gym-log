import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';

/// Shared decorative gradients. The visual system is a night-session navy
/// canvas lit by a single electric-blue action color.
///
/// Gradients are ornament only: every gradient also sits on a solid color that
/// carries the measured contrast, so text never depends on the gradient stop.
abstract final class AppGradients {
  static const LinearGradient hero = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: <Color>[Color(0xFF172C54), Color(0xFF0C1628), AppTokens.surface],
    stops: <double>[0, 0.55, 1],
  );

  static const LinearGradient accent = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: <Color>[AppTokens.accent, AppTokens.accentDeep],
  );

  static const LinearGradient weight = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: <Color>[AppTokens.weight, AppTokens.info],
  );

  static const LinearGradient gold = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: <Color>[Color(0xFFFFD98A), AppTokens.highlight],
  );

  /// Subtle top-lit surface used by raised cards and the app bar.
  static const LinearGradient surface = LinearGradient(
    begin: AlignmentDirectional.topCenter,
    end: AlignmentDirectional.bottomCenter,
    colors: <Color>[Color(0xFF152038), AppTokens.surface],
  );

  static List<BoxShadow> glow(Color color) => <BoxShadow>[
    BoxShadow(
      color: color.withValues(alpha: 0.16),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];
}
