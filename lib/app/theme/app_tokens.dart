import 'dart:ui';

/// Canonical design tokens for Gym Log.
///
/// The palette is the owner's dark navy, electric-blue night-session palette
/// (2026-10-26 redesign). Measured contrast ratios live in `docs/DESIGN.md`;
/// change the table and re-run `test/theme/contrast_test.dart` when a value
/// changes.
abstract final class AppTokens {
  static const Color background = Color(0xFF070B14);
  static const Color surface = Color(0xFF0E1524);
  static const Color surface2 = Color(0xFF162034);
  static const Color surface3 = Color(0xFF1F2B42);
  static const Color outline = Color(0xFF26344F);
  static const Color textPrimary = Color(0xFFF4F7FF);
  static const Color textSecondary = Color(0xFF9AA9C4);

  /// Electric blue: the single action color, and the app's link/focus color.
  static const Color accent = Color(0xFF5B9BFF);

  /// Gradient/decorative companion to [accent]; never used for small text.
  static const Color accentDeep = Color(0xFF2F6BFF);
  static const Color onAccent = Color(0xFF061024);
  static const Color highlight = Color(0xFFFFC857);
  static const Color danger = Color(0xFFFF6B7A);
  static const Color info = Color(0xFF6EE7F9);

  /// Body-weight series. Keeping it separate from [accent] makes the weight
  /// chart distinguishable from training volume without relying on a legend.
  static const Color weight = Color(0xFFA78BFA);

  static const double spaceHalf = 4;
  static const double space1 = 8;
  static const double space2 = 16;
  static const double space3 = 24;
  static const double space4 = 32;
  static const double space5 = 40;
  static const double space6 = 48;

  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 20;
  static const double radiusPill = 999;
  static const double minTouchTarget = 48;

  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionNormal = Duration(milliseconds: 200);
  static const Duration motionSlow = Duration(milliseconds: 300);

  static const String fontFamily = 'Vazirmatn';

  /// Horizontal page padding, slightly tighter on narrow phones so large text
  /// and three-column stats still fit.
  static double pagePadding(double width) => width < 360 ? space2 : space3;
}
