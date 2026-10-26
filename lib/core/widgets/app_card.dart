import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';

/// The app's single panel surface: a rounded navy card with a hairline border.
///
/// Cards are raised by fill and border, not by shadow. [AppCard.gradient] is
/// decorative and clips to the same radius; the base color stays underneath so
/// text contrast never depends on a gradient stop.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsetsDirectional.all(AppTokens.space2),
    this.color,
    this.gradient,
    this.borderColor,
    this.radius = AppTokens.radiusLarge,
    this.onTap,
    this.semanticsLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final BorderRadius shape = BorderRadius.circular(radius);
    final Widget content = Padding(padding: padding, child: child);
    final Widget core = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppTokens.surface) : null,
        gradient: gradient,
        borderRadius: shape,
        border: Border.all(
          color: borderColor ?? AppTokens.outline.withValues(alpha: 0.8),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, borderRadius: shape, child: content),
      ),
    );

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: gradient == null
          ? core
          : ClipRRect(borderRadius: shape, child: core),
    );
  }
}
