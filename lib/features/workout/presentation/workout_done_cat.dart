import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/l10n.dart';

/// The post-workout mascot: a small painted cat that announces the finish.
///
/// It is shown once, at the top of the session summary, and enters with one
/// short fade/rise that is skipped when the platform asks for reduced motion.
class WorkoutDoneCat extends StatelessWidget {
  const WorkoutDoneCat({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Widget content = Row(
      children: <Widget>[
        const _CatFace(size: 92),
        const SizedBox(width: AppTokens.space1),
        Expanded(
          child: _SpeechBubble(
            title: l10n.workoutDoneCat,
            body: l10n.workoutDoneCatHint,
          ),
        ),
      ],
    );
    return Semantics(
      container: true,
      label: '${l10n.workoutDoneCat}. ${l10n.workoutDoneCatHint}',
      child: ExcludeSemantics(
        child: MediaQuery.disableAnimationsOf(context)
            ? content
            : TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 12),
                      child: child,
                    ),
                  );
                },
                child: content,
              ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTokens.space2,
        AppTokens.space1 + AppTokens.spaceHalf,
        AppTokens.space2,
        AppTokens.space1 + AppTokens.spaceHalf,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2,
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(AppTokens.radiusLarge),
          topEnd: Radius.circular(AppTokens.radiusLarge),
          bottomEnd: Radius.circular(AppTokens.radiusLarge),
          bottomStart: Radius.circular(AppTokens.spaceHalf),
        ),
        border: Border.all(color: AppTokens.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.pets, size: 15, color: AppTokens.accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CatFace extends StatelessWidget {
  const _CatFace({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _CatFacePainter()),
    );
  }
}

class _CatFacePainter extends CustomPainter {
  const _CatFacePainter();

  static const Color _fur = Color(0xFFF6DDBC);
  static const Color _furLight = Color(0xFFFFF0DA);
  static const Color _furDark = Color(0xFFD9B384);
  static const Color _earInner = Color(0xFFF3A8A8);
  static const Color _ink = Color(0xFF2B2230);
  static const Color _nose = Color(0xFFE98C8C);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Offset c = Offset(size.width / 2, size.height / 2 + s * 0.03);
    final double r = s * 0.35;
    final double line = math.max(1.6, s * 0.022);

    // Soft blue halo so the mascot sits in the app's light.
    final Rect halo = Rect.fromCircle(center: c, radius: s * 0.48);
    canvas.drawCircle(
      c,
      s * 0.48,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            AppTokens.accent.withValues(alpha: 0.20),
            AppTokens.accent.withValues(alpha: 0),
          ],
        ).createShader(halo),
    );

    // Ears sit behind the head; the head circle covers their bases.
    for (final double sign in <double>[-1, 1]) {
      final Path ear = Path()
        ..moveTo(c.dx + sign * r * 0.86, c.dy - r * 0.28)
        ..lineTo(c.dx + sign * r * 0.95, c.dy - r * 1.24)
        ..lineTo(c.dx + sign * r * 0.18, c.dy - r * 0.82)
        ..close();
      canvas.drawPath(ear, Paint()..color = _fur);
      final Offset earCenter = Offset(c.dx + sign * r * 0.63, c.dy - r * 0.62);
      final Path inner = Path()
        ..moveTo(c.dx + sign * r * 0.77, c.dy - r * 0.36)
        ..lineTo(c.dx + sign * r * 0.83, c.dy - r * 0.96)
        ..lineTo(c.dx + sign * r * 0.37, c.dy - r * 0.72)
        ..close();
      canvas.save();
      canvas.translate(earCenter.dx, earCenter.dy);
      canvas.scale(0.94);
      canvas.translate(-earCenter.dx, -earCenter.dy);
      canvas.drawPath(inner, Paint()..color = _earInner);
      canvas.restore();
    }

    // Head.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1.4,
          colors: <Color>[_furLight, _fur],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Forehead stripes.
    final Paint stripe = Paint()
      ..color = _furDark.withValues(alpha: 0.55)
      ..strokeWidth = line
      ..strokeCap = StrokeCap.round;
    for (final double dx in <double>[-0.18, 0, 0.18]) {
      canvas.drawLine(
        Offset(c.dx + r * dx, c.dy - r * 0.74),
        Offset(c.dx + r * dx, c.dy - r * 0.55),
        stripe,
      );
    }

    // Whiskers, then blush, so the cheeks sit on top.
    final Paint whisker = Paint()
      ..color = _furDark.withValues(alpha: 0.65)
      ..strokeWidth = math.max(1, line * 0.55)
      ..strokeCap = StrokeCap.round;
    for (final double sign in <double>[-1, 1]) {
      canvas.drawLine(
        Offset(c.dx + sign * r * 0.62, c.dy + r * 0.16),
        Offset(c.dx + sign * r * 0.97, c.dy + r * 0.10),
        whisker,
      );
      canvas.drawLine(
        Offset(c.dx + sign * r * 0.62, c.dy + r * 0.32),
        Offset(c.dx + sign * r * 0.97, c.dy + r * 0.36),
        whisker,
      );
    }
    final Paint blush = Paint()..color = _nose.withValues(alpha: 0.28);
    for (final double sign in <double>[-1, 1]) {
      canvas.drawCircle(
        Offset(c.dx + sign * r * 0.58, c.dy + r * 0.22),
        r * 0.13,
        blush,
      );
    }

    // Happy closed eyes.
    final Paint eye = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = line * 1.2
      ..strokeCap = StrokeCap.round;
    for (final double sign in <double>[-1, 1]) {
      final Rect eyeRect = Rect.fromCenter(
        center: Offset(c.dx + sign * r * 0.40, c.dy - r * 0.12),
        width: r * 0.34,
        height: r * 0.26,
      );
      canvas.drawArc(eyeRect, math.pi, math.pi, false, eye);
    }

    // Nose and the small "w" mouth.
    final double noseY = c.dy + r * 0.18;
    final Path nose = Path()
      ..moveTo(c.dx - r * 0.09, noseY)
      ..lineTo(c.dx + r * 0.09, noseY)
      ..lineTo(c.dx, noseY + r * 0.10)
      ..close();
    canvas.drawPath(
      nose,
      Paint()
        ..color = _nose
        ..strokeJoin = StrokeJoin.round,
    );
    final Path mouth = Path()
      ..moveTo(c.dx - r * 0.17, noseY + r * 0.17)
      ..quadraticBezierTo(
        c.dx - r * 0.08,
        noseY + r * 0.27,
        c.dx,
        noseY + r * 0.11,
      )
      ..quadraticBezierTo(
        c.dx + r * 0.08,
        noseY + r * 0.27,
        c.dx + r * 0.17,
        noseY + r * 0.17,
      );
    canvas.drawPath(
      mouth,
      Paint()
        ..color = _ink.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = line
        ..strokeCap = StrokeCap.round,
    );

    // Blue collar with the gold brand marker.
    final Rect collar = Rect.fromCenter(
      center: Offset(c.dx, c.dy + r * 0.78),
      width: r * 1.5,
      height: r * 0.18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(collar, Radius.circular(r * 0.09)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[AppTokens.accent, AppTokens.accentDeep],
        ).createShader(collar),
    );
    final Offset bell = Offset(c.dx, c.dy + r * 0.95);
    canvas.drawCircle(bell, r * 0.11, Paint()..color = AppTokens.highlight);
    canvas.drawLine(
      bell.translate(0, -r * 0.04),
      bell.translate(0, r * 0.03),
      Paint()
        ..color = _ink.withValues(alpha: 0.55)
        ..strokeWidth = math.max(1, line * 0.5)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CatFacePainter oldDelegate) => false;
}
