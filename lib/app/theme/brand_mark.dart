import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import 'app_tokens.dart';

/// The in-app brand lockup: the electric-blue barbell emblem plus the wordmark.
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
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (showTagline)
                  Text(
                    l10n.appTagline,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTokens.textSecondary),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The square brand emblem drawn with the same geometry as the launcher icon.
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
    final double s = math.min(size.width, size.height);
    final Rect square = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: s,
      height: s,
    );
    final RRect shape = RRect.fromRectAndRadius(
      square,
      Radius.circular(s * 0.235),
    );
    canvas.save();
    canvas.clipRRect(shape);

    canvas.drawRect(
      square,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          colors: <Color>[Color(0xFF172C54), Color(0xFF070B14)],
        ).createShader(square),
    );

    final Offset center = square.center;
    canvas.drawCircle(
      center,
      s * 0.32,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            AppTokens.accentDeep.withValues(alpha: 0.22),
            AppTokens.accentDeep.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: s * 0.32)),
    );

    final Rect ringRect = Rect.fromCircle(center: center, radius: s * 0.305);
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.042
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment(-1, -1),
        end: Alignment(1, 1),
        colors: <Color>[AppTokens.accent, AppTokens.accentDeep],
      ).createShader(square);
    const double startAngle = 132 * math.pi / 180;
    const double sweepAngle = 280 * math.pi / 180;
    canvas.drawArc(ringRect, startAngle, sweepAngle, false, ring);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    _drawBarbell(canvas, s);
    canvas.restore();

    const double endAngle = startAngle + sweepAngle;
    canvas.drawCircle(
      Offset(
        center.dx + ringRect.width / 2 * math.cos(endAngle),
        center.dy + ringRect.width / 2 * math.sin(endAngle),
      ),
      s * 0.032,
      Paint()..color = AppTokens.highlight,
    );

    canvas.restore();
  }

  void _drawBarbell(Canvas canvas, double s) {
    final Paint bar = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-1, -1),
        end: Alignment(1, 1),
        colors: <Color>[AppTokens.accent, AppTokens.accentDeep],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: s, height: s));
    final Paint plate = Paint()..color = AppTokens.textPrimary;
    Rect rounded(double left, double top, double right, double bottom) {
      return Rect.fromLTRB(left * s, top * s, right * s, bottom * s);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rounded(-0.202, -0.033, 0.202, 0.033),
        Radius.circular(s * 0.026),
      ),
      bar,
    );
    // Inner collars, then the outer plates: the same ordering as the icon.
    for (final double cx in <double>[-0.101, 0.101]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rounded(cx - 0.024, -0.048, cx + 0.024, 0.048),
          Radius.circular(s * 0.014),
        ),
        plate,
      );
    }
    for (final double cx in <double>[-0.21, 0.21]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rounded(cx - 0.030, -0.117, cx + 0.030, 0.117),
          Radius.circular(s * 0.022),
        ),
        plate,
      );
    }
    for (final double cx in <double>[-0.14, 0.14]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rounded(cx - 0.023, -0.089, cx + 0.023, 0.089),
          Radius.circular(s * 0.016),
        ),
        plate,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter oldDelegate) => false;
}
