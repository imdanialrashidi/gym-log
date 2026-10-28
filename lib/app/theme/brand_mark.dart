import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import 'app_tokens.dart';

/// The in-app brand lockup: the Obsidian aperture emblem plus the wordmark.
///
/// The emblem is painted, not decoded from a bitmap: it stays crisp at every
/// text scale, costs no image decode on the dashboard, and cannot flash blank
/// while an asset loads. The matching PNG is the source for the launcher icon.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 44,
    this.showWordmark = true,
    this.showTagline = false,
  });

  final double size;
  final bool showWordmark;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Semantics(
      label: l10n.appTitle,
      image: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 6,
        children: <Widget>[
          BrandEmblem(size: size),
          if (showWordmark)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.appTitle.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                if (showTagline)
                  Text(
                    l10n.appTagline,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTokens.textMuted),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The square brand emblem drawn with the same geometry as the launcher icon.
///
/// A machined aperture frame holds a barbell; a small index square in the
/// top-left corner is the calibration mark. No circle, gradient, or color is
/// involved.
class BrandEmblem extends StatelessWidget {
  const BrandEmblem({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _EmblemPainter()),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Offset origin = Offset((size.width - s) / 2, (size.height - s) / 2);
    canvas.translate(origin.dx, origin.dy);

    final Paint ink = Paint()
      ..color = AppTokens.textPrimary
      ..isAntiAlias = true;
    final Paint stroke = Paint()
      ..color = AppTokens.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.042
      ..isAntiAlias = true;

    final double inset = s * 0.135;
    canvas.drawRect(Rect.fromLTRB(inset, inset, s - inset, s - inset), stroke);

    // The index square: the calibration mark that makes the frame read as an
    // instrument aperture rather than a generic picture frame.
    canvas.drawRect(
      Rect.fromLTRB(s * 0.200, s * 0.200, s * 0.248, s * 0.248),
      ink,
    );

    final double cy = s * 0.525;
    // Outer plates, inner collars, then the bar: the bar ties the assembly
    // together and keeps the silhouette legible at 24 px.
    for (final double sign in <double>[-1, 1]) {
      final double plateX = s / 2 + sign * s * 0.215;
      canvas.drawRect(
        Rect.fromLTRB(
          plateX - s * 0.0375,
          cy - s * 0.150,
          plateX + s * 0.0375,
          cy + s * 0.150,
        ),
        ink,
      );
    }
    for (final double sign in <double>[-1, 1]) {
      final double collarX = s / 2 + sign * s * 0.135;
      canvas.drawRect(
        Rect.fromLTRB(
          collarX - s * 0.019,
          cy - s * 0.0875,
          collarX + s * 0.019,
          cy + s * 0.0875,
        ),
        ink,
      );
    }
    canvas.drawRect(
      Rect.fromLTRB(
        s / 2 - s * 0.230,
        cy - s * 0.030,
        s / 2 + s * 0.230,
        cy + s * 0.030,
      ),
      ink,
    );
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter oldDelegate) => false;
}
