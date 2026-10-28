import 'dart:math' as math;

import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_card.dart';

/// A single-series progress chart.
///
/// Time always runs left to right, including in RTL layouts (ADR-0005). A
/// `null` point breaks the line so missing RIR or e1RM values are gaps, not
/// zeros.
class ProgressChart extends StatelessWidget {
  const ProgressChart({
    required this.points,
    required this.formatValue,
    required this.emptyMessage,
    required this.semanticsLabel,
    this.axisKeyPrefix,
    super.key,
  });

  final List<ProgressPoint> points;
  final String Function(double value) formatValue;
  final String emptyMessage;
  final String semanticsLabel;

  /// Optional prefix for stable keys on the first and last date labels.
  final String? axisKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final List<double> values = <double>[
      for (final ProgressPoint point in points)
        if (point.value != null) point.value!,
    ];
    if (values.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            context.digits(emptyMessage),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTokens.textSecondary),
          ),
        ),
      );
    }

    final double highest = values.reduce(math.max);
    final double lowest = values.reduce(math.min);

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.digits(formatValue(highest)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppTokens.textSecondary),
                ),
              ),
              const SizedBox(width: AppTokens.space1),
              Expanded(
                child: Text(
                  context.digits(formatValue(lowest)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppTokens.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ProgressChartPainter(points: points),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _DateAxis(points: points, keyPrefix: axisKeyPrefix),
        ],
      ),
    );
  }
}

/// Card wrapper with title, optional hint, and the chart itself.
class ProgressChartSection extends StatelessWidget {
  const ProgressChartSection({
    required this.title,
    required this.points,
    required this.formatValue,
    required this.emptyMessage,
    this.subtitle,
    this.axisKeyPrefix,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<ProgressPoint> points;
  final String Function(double value) formatValue;
  final String emptyMessage;
  final String? axisKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space2),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.digits(title),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                context.digits(subtitle),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTokens.textSecondary),
              ),
            ],
            const SizedBox(height: AppTokens.space1),
            ProgressChart(
              points: points,
              formatValue: formatValue,
              emptyMessage: emptyMessage,
              semanticsLabel: context.digits(
                '$title. ${l10n.progressSessions(points.length)}',
              ),
              axisKeyPrefix: axisKeyPrefix,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateAxis extends StatelessWidget {
  const _DateAxis({required this.points, this.keyPrefix});

  final List<ProgressPoint> points;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final String first = context.formatDate(points.first.date);
    final String last = context.formatDate(points.last.date);
    // The time axis runs left to right in every locale (ADR-0005), but the
    // date strings themselves are localized. Keep the row order LTR and give
    // each label the ambient paragraph direction, or a Persian
    // "day month year" string is reordered by the bidi algorithm.
    final TextDirection labelDirection = Directionality.of(context);
    final TextStyle? style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: AppTokens.textSecondary);
    final Key? firstKey = keyPrefix == null
        ? null
        : Key('$keyPrefix-axis-first');
    final Key? lastKey = keyPrefix == null ? null : Key('$keyPrefix-axis-last');

    if (first == last) {
      return Text(
        first,
        key: firstKey,
        textDirection: labelDirection,
        textAlign: TextAlign.center,
        style: style,
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                first,
                key: firstKey,
                textDirection: labelDirection,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space1),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                last,
                key: lastKey,
                textDirection: labelDirection,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  const _ProgressChartPainter({required this.points});

  final List<ProgressPoint> points;

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
      final double padding = lowest.abs() < 1 ? 1 : lowest.abs() * 0.1;
      minimum -= padding;
      maximum += padding;
    } else {
      final double padding = (maximum - minimum) * 0.1;
      minimum -= padding;
      maximum += padding;
    }

    final Rect plot = Rect.fromLTRB(4, 8, size.width - 4, size.height - 10);
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

    // Fine dashed coordinate rules, not a filled plot area.
    final Paint grid = Paint()
      ..color = AppTokens.outline
      ..strokeWidth = 1;
    for (int index = 0; index < 3; index++) {
      final double y = plot.top + plot.height * index / 2;
      _dashedLine(canvas, Offset(plot.left, y), Offset(plot.right, y), grid);
    }

    canvas.save();
    canvas.clipRect(plot);

    final Paint line = Paint()
      ..color = AppTokens.textPrimary
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..style = PaintingStyle.stroke;

    Path? linePath;

    void flush() {
      final Path? current = linePath;
      if (current != null) {
        canvas.drawPath(current, line);
      }
      linePath = null;
    }

    for (final ProgressPoint point in points) {
      final double? value = point.value;
      if (value == null) {
        flush();
        continue;
      }
      final Offset offset = Offset(xFor(point.date), yFor(value));
      if (linePath == null) {
        linePath = Path()..moveTo(offset.dx, offset.dy);
      } else {
        linePath!.lineTo(offset.dx, offset.dy);
      }
    }
    flush();

    // Square point markers at readable densities.
    if (points.length <= 60) {
      final Paint dot = Paint()..color = AppTokens.textPrimary;
      for (final ProgressPoint point in withValues) {
        final Offset offset = Offset(xFor(point.date), yFor(point.value!));
        canvas.drawRect(
          Rect.fromCenter(center: offset, width: 2.4, height: 2.4),
          dot,
        );
      }
    }

    // Current cursor: a crosshair plus a diamond, with no glow halo.
    final ProgressPoint last = withValues.last;
    final Offset lastOffset = Offset(xFor(last.date), yFor(last.value!));
    final Paint cursor = Paint()
      ..color = AppTokens.textPrimary
      ..strokeWidth = 1;
    canvas.drawLine(
      lastOffset.translate(-6, 0),
      lastOffset.translate(6, 0),
      cursor,
    );
    canvas.drawLine(
      lastOffset.translate(0, -6),
      lastOffset.translate(0, 6),
      cursor,
    );
    final Path diamond = Path()
      ..moveTo(lastOffset.dx, lastOffset.dy - 3.2)
      ..lineTo(lastOffset.dx + 3.2, lastOffset.dy)
      ..lineTo(lastOffset.dx, lastOffset.dy + 3.2)
      ..lineTo(lastOffset.dx - 3.2, lastOffset.dy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = AppTokens.textPrimary);

    canvas.restore();
  }

  void _dashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dash = 4;
    const double gap = 4;
    final double distance = (end - start).distance;
    if (distance <= 0) {
      return;
    }
    final Offset direction = (end - start) / distance;
    double offset = 0;
    while (offset < distance) {
      final double segment = math.min(dash, distance - offset);
      canvas.drawLine(
        start + direction * offset,
        start + direction * (offset + segment),
        paint,
      );
      offset += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) {
    return !identical(points, oldDelegate.points);
  }
}
