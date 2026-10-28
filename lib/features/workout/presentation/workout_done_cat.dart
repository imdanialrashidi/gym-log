import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/l10n.dart';

/// The post-workout mascot: a small engraved line cat that announces the
/// finish.
///
/// It is the one intentional levity in the system, rendered in a single ink
/// color and a square speech plate. It is shown once, at the top of the
/// session summary, and enters with one short fade/rise that is skipped when
/// the platform asks for reduced motion.
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
        border: Border.all(color: AppTokens.outlineStrong),
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

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Offset c = Offset(size.width / 2, size.height / 2 + s * 0.02);
    final double r = s * 0.30;
    final double line = math.max(1.2, s * 0.016);
    const Color ink = AppTokens.textPrimary;
    const Color detail = AppTokens.textSecondary;

    final Paint stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = line
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fine = Paint()
      ..color = detail
      ..style = PaintingStyle.stroke
      ..strokeWidth = line * 0.7
      ..strokeCap = StrokeCap.round;
    final Paint face = Paint()..color = AppTokens.surface2;

    // Ears sit behind the head; the head fill covers their bases.
    for (final double sign in <double>[-1, 1]) {
      final Path ear = Path()
        ..moveTo(c.dx + sign * r * 0.64, c.dy - r * 0.46)
        ..lineTo(c.dx + sign * r * 0.88, c.dy - r * 1.24)
        ..lineTo(c.dx + sign * r * 0.16, c.dy - r * 0.92)
        ..close();
      canvas.drawPath(ear, face);
      canvas.drawPath(ear, stroke);
      final Path inner = Path()
        ..moveTo(c.dx + sign * r * 0.64, c.dy - r * 0.62)
        ..lineTo(c.dx + sign * r * 0.79, c.dy - r * 1.04)
        ..lineTo(c.dx + sign * r * 0.37, c.dy - r * 0.86)
        ..close();
      canvas.drawPath(inner, fine);
    }

    // Head plate.
    canvas.drawCircle(c, r, face);
    canvas.drawCircle(c, r, stroke);

    // Three etched forehead ticks.
    for (final double dx in <double>[-0.18, 0, 0.18]) {
      canvas.drawLine(
        Offset(c.dx + r * dx, c.dy - r * 0.72),
        Offset(c.dx + r * dx, c.dy - r * 0.52),
        fine,
      );
    }

    // Whiskers.
    for (final double sign in <double>[-1, 1]) {
      canvas.drawLine(
        Offset(c.dx + sign * r * 0.64, c.dy + r * 0.18),
        Offset(c.dx + sign * r * 0.98, c.dy + r * 0.10),
        fine,
      );
      canvas.drawLine(
        Offset(c.dx + sign * r * 0.64, c.dy + r * 0.34),
        Offset(c.dx + sign * r * 0.98, c.dy + r * 0.38),
        fine,
      );
    }

    // Closed, content eyes: two upward arcs.
    for (final double sign in <double>[-1, 1]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(c.dx + sign * r * 0.38, c.dy - r * 0.10),
          width: r * 0.32,
          height: r * 0.24,
        ),
        math.pi,
        math.pi,
        false,
        stroke,
      );
    }

    // Nose and the small "w" mouth.
    final double noseY = c.dy + r * 0.16;
    final Path nose = Path()
      ..moveTo(c.dx - r * 0.08, noseY)
      ..lineTo(c.dx + r * 0.08, noseY)
      ..lineTo(c.dx, noseY + r * 0.09)
      ..close();
    canvas.drawPath(nose, Paint()..color = detail);
    final Path mouth = Path()
      ..moveTo(c.dx - r * 0.16, noseY + r * 0.17)
      ..quadraticBezierTo(
        c.dx - r * 0.07,
        noseY + r * 0.27,
        c.dx,
        noseY + r * 0.10,
      )
      ..quadraticBezierTo(
        c.dx + r * 0.07,
        noseY + r * 0.27,
        c.dx + r * 0.16,
        noseY + r * 0.17,
      );
    canvas.drawPath(mouth, stroke);

    // Square collar band and a single square tag: no color, just structure.
    final Rect collar = Rect.fromCenter(
      center: Offset(c.dx, c.dy + r * 0.78),
      width: r * 1.44,
      height: r * 0.10,
    );
    canvas.drawRect(collar, Paint()..color = ink);
    final double tag = r * 0.16;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.96),
        width: tag,
        height: tag,
      ),
      Paint()..color = ink,
    );
  }

  @override
  bool shouldRepaint(_CatFacePainter oldDelegate) => false;
}
