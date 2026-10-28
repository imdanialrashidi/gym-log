import 'dart:ui';

/// Canonical design tokens for Gym Log.
///
/// The system is **Obsidian Telemetry**: an achromatic, industrial instrument
/// surface. Black canvas, machined zinc surfaces, hairline structure, and pure
/// white as the only focal signal. There is no chromatic accent, glow, blur, or
/// decorative gradient in the UI canvas.
///
/// The palette intentionally uses the achromatic subset of the Obsidian
/// Telemetry reference. Muted labels use [#8E9192] instead of `#71717A`: at
/// small sizes `#71717A` measures 4.12:1 on the canvas, below this project's
/// 4.5:1 text floor. `#71717A` remains the non-text control-boundary token
/// ([outlineStrong]) and passes 3:1.
///
/// Measured contrast ratios live in `docs/DESIGN.md`; change the table and
/// re-run `test/theme/contrast_test.dart` when a value changes.
abstract final class AppTokens {
  /// OLED-safe near-black canvas; not pure black, to avoid banding and smear.
  static const Color background = Color(0xFF09090B);

  /// Machined chassis: cards, sheets, navigation bar.
  static const Color surface = Color(0xFF121214);

  /// Raised control surface: inputs, segmented controls, saved rows.
  static const Color surface2 = Color(0xFF18181B);

  /// Pressed/selected recess.
  static const Color surface3 = Color(0xFF201F22);

  /// Highest contrast utility fill, used sparingly.
  static const Color surface4 = Color(0xFF2A2A2C);

  /// Decorative panel hairline. Not a control boundary and never the only
  /// state signal.
  static const Color outline = Color(0xFF27272A);

  /// Interactive control boundary. 4.12:1 on the canvas and 3.87:1 on
  /// [surface], so it satisfies the 3:1 non-text floor.
  static const Color outlineStrong = Color(0xFF71717A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);

  /// Technical microcopy and passive indices. Accessible on all surfaces up to
  /// [surface4] (4.53:1).
  static const Color textMuted = Color(0xFF8E9192);

  /// Pure white strike-point: the single action, link, focus, and selected
  /// state. This is deliberately achromatic.
  static const Color accent = Color(0xFFFFFFFF);
  static const Color onAccent = Color(0xFF09090B);

  /// Former gradient companion. Kept as a decorative gray; gradients are no
  /// longer used by the UI.
  static const Color accentDeep = Color(0xFFA1A1AA);

  /// Personal-record signal. Always paired with the "PR" label and a glyph;
  /// never carried by color alone.
  static const Color highlight = Color(0xFFFFFFFF);

  /// Destructive/error signal. The interface communicates it with a label,
  /// icon, and 2 px stroke, never with hue.
  static const Color danger = Color(0xFFFFFFFF);
  static const Color onDanger = Color(0xFF09090B);

  /// Passive hint/readout gray.
  static const Color info = Color(0xFFA1A1AA);
  static const Color onInfo = Color(0xFF09090B);

  /// Body-weight series. Distinguished from training series by its label and
  /// dashed trace, not by hue.
  static const Color weight = Color(0xFFA1A1AA);

  static const double spaceHalf = 4;
  static const double space1 = 8;
  static const double space2 = 16;
  static const double space3 = 24;
  static const double space4 = 32;
  static const double space5 = 40;
  static const double space6 = 48;

  /// Obsidian Telemetry enforces square hardlines: `roundedness: 0`.
  static const double radiusSmall = 0;
  static const double radiusMedium = 0;
  static const double radiusLarge = 0;
  static const double radiusPill = 0;
  static const double hairline = 1;
  static const double minTouchTarget = 48;

  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionNormal = Duration(milliseconds: 200);
  static const Duration motionSlow = Duration(milliseconds: 300);

  static const String fontFamily = 'Vazirmatn';

  /// Tabular figures and a slashed zero for live telemetry so counters do not
  /// shift while they stream.
  static const List<FontFeature> telemetryFeatures = <FontFeature>[
    FontFeature.tabularFigures(),
    FontFeature.slashedZero(),
  ];

  /// Horizontal page padding, slightly tighter on narrow phones so large text
  /// and three-column stats still fit.
  static double pagePadding(double width) => width < 360 ? space2 : space3;
}
