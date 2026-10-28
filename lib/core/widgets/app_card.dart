import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';

/// The app's single panel surface: a square instrument plate with a 1 px
/// hairline.
///
/// Cards are raised by fill and structure, never by shadow, gradient, or blur.
/// [radius] is retained for rare special cases but defaults to the system's
/// hard 0 dp corner.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsetsDirectional.all(AppTokens.space2),
    this.color,
    this.borderColor,
    this.radius = AppTokens.radiusLarge,
    this.onTap,
    this.semanticsLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
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
        color: color ?? AppTokens.surface,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? AppTokens.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, borderRadius: shape, child: content),
      ),
    );

    return Semantics(container: true, label: semanticsLabel, child: core);
  }
}
