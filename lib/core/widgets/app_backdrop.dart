import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';

/// The app's ambient night backdrop: a soft electric-blue glow at the top and
/// a faint violet pool at the bottom.
///
/// It is static and repaint-isolated so it never competes with the logging
/// surface. Both glows sit behind cards at very low alpha, never under text.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BackdropPainter(
                  direction: Directionality.of(context),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.direction});

  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: AlignmentDirectional.topCenter.resolve(direction),
          radius: 1.05,
          colors: <Color>[
            AppTokens.accent.withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const <double>[0, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: AlignmentDirectional.bottomEnd.resolve(direction),
          radius: 0.85,
          colors: <Color>[
            AppTokens.weight.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const <double>[0, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.direction != direction;
}
