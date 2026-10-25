import 'dart:ui';

/// Canonical design tokens for Gym Log.
///
/// The dark palette comes from the product specification, Section 29.4.
/// `docs/DESIGN.md` mirrors these values; change both together and re-run the
/// contrast test before using a new pair.
abstract final class AppTokens {
  static const Color background = Color(0xFF0E1116);
  static const Color surface = Color(0xFF161B22);
  static const Color surface2 = Color(0xFF1F2630);
  static const Color outline = Color(0xFF2A3340);
  static const Color textPrimary = Color(0xFFE8EDF2);
  static const Color textSecondary = Color(0xFF9AA7B5);
  static const Color accent = Color(0xFF3DDC97);
  static const Color onAccent = Color(0xFF06251A);
  static const Color highlight = Color(0xFFFFC44D);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF6AA9FF);

  static const double space1 = 8;
  static const double space2 = 16;
  static const double space3 = 24;

  static const double radiusSmall = 12;
  static const double radiusLarge = 16;
  static const double minTouchTarget = 48;

  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionNormal = Duration(milliseconds: 200);

  static const String fontFamily = 'Vazirmatn';
}
