import 'dart:math' as math;

import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';

/// A compact, label-free trend line for cards.
///
/// Gaps (`null` values) break the line in the same way the full progress chart
/// does. The widget paints only; the caller supplies the accessible summary.
class MiniTrend extends StatelessWidget {
  const MiniTrend({
    required this.points,
    this.color = AppTokens.accent,
    this.height = 48,
    this.strokeWidth = 2,
    super.key,
  });

  final List<ProgressPoint> points;
  final Color color;
  final double height;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final bool hasValues = points.any(
      (ProgressPoint point) => point.value != null,
    );
    if (!hasValues) {
      return SizedBox(height: height);
    }
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _MiniTrendPainter(
            points: points,
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  const _MiniTrendPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  final List<ProgressPoint> points;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final List<ProgressPoint> withValues = <ProgressPoint>[
      for (final ProgressPoint point in points)
        if (point.value != null) point,
    ];
    if (withValues.isEmpty || size.isEmpty) {
      return;
    }
    final double highest = withValues
        .map((ProgressPoint point) => point.value!)
        .reduce(math.max);
    final double lowest = withValues
        .map((ProgressPoint point) => point.value!)
        .reduce(math.min);
    double minimum = lowest;
    double maximum = highest;
    if (minimum == maximum) {
      final double padding = lowest.abs() < 1 ? 1 : lowest.abs() * 0.04;
      minimum -= padding;
      maximum += padding;
    } else {
      final double padding = (maximum - minimum) * 0.18;
      minimum -= padding;
      maximum += padding;
    }

    final Rect plot = Rect.fromLTRB(
      strokeWidth + 1,
      strokeWidth + 3,
      size.width - strokeWidth - 1,
      size.height - strokeWidth - 3,
    );
    final int start = points.first.date.millisecondsSinceEpoch;
    final int end = points.last.date.millisecondsSinceEpoch;
    final int span = end - start;

    double xFor(DateTime date) {
      if (span <= 0) {
        return plot.center.dx;
      }
      final double fraction = (date.millisecondsSinceEpoch - start) / span;
      return plot.left + plot.width * fraction;
    }

    double yFor(double value) {
      final double fraction = (value - minimum) / (maximum - minimum);
      return plot.bottom - plot.height * fraction;
    }

    final Paint stroke = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    Path? line;
    for (final ProgressPoint point in points) {
      final double? value = point.value;
      if (value == null) {
        if (line != null) {
          canvas.drawPath(line, stroke);
          line = null;
        }
        continue;
      }
      final Offset offset = Offset(xFor(point.date), yFor(value));
      if (line == null) {
        line = Path()..moveTo(offset.dx, offset.dy);
      } else {
        line.lineTo(offset.dx, offset.dy);
      }
    }
    if (line != null) {
      canvas.drawPath(line, stroke);
    }

    final ProgressPoint last = withValues.last;
    final Offset lastOffset = Offset(xFor(last.date), yFor(last.value!));
    canvas.drawCircle(
      lastOffset,
      strokeWidth + 2.5,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    canvas.drawCircle(lastOffset, strokeWidth + 0.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) {
    return !identical(points, oldDelegate.points) ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
