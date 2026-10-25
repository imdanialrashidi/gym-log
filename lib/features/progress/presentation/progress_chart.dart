import 'dart:math' as math;

import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';

/// A single-series progress chart.
///
/// Time always runs left to right, including in RTL layouts (ADR-0005). A
/// `null` point breaks the line so missing RIR or e1RM values are gaps, not
/// zeros.
class ProgressChart extends StatelessWidget {
  const ProgressChart({
    required this.points,
    required this.color,
    required this.formatValue,
    required this.emptyMessage,
    required this.semanticsLabel,
    this.axisKeyPrefix,
    super.key,
  });

  final List<ProgressPoint> points;
  final Color color;
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
            child: CustomPaint(
              painter: _ProgressChartPainter(points: points, color: color),
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
    required this.color,
    required this.formatValue,
    required this.emptyMessage,
    this.subtitle,
    this.axisKeyPrefix,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<ProgressPoint> points;
  final Color color;
  final String Function(double value) formatValue;
  final String emptyMessage;
  final String? axisKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppTokens.space2),
      padding: const EdgeInsetsDirectional.all(AppTokens.space2),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
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
            color: color,
            formatValue: formatValue,
            emptyMessage: emptyMessage,
            semanticsLabel: context.digits(
              '$title. ${l10n.progressSessions(points.length)}',
            ),
            axisKeyPrefix: axisKeyPrefix,
          ),
        ],
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
    final TextStyle? style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: AppTokens.textSecondary);
    final Key? firstKey = keyPrefix == null
        ? null
        : Key('$keyPrefix-axis-first');
    final Key? lastKey = keyPrefix == null ? null : Key('$keyPrefix-axis-last');

    if (first == last) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          first,
          key: firstKey,
          textAlign: TextAlign.center,
          style: style,
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              first,
              key: firstKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: style,
            ),
          ),
          const SizedBox(width: AppTokens.space1),
          Expanded(
            child: Text(
              last,
              key: lastKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  const _ProgressChartPainter({required this.points, required this.color});

  final List<ProgressPoint> points;
  final Color color;

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
      final double padding = (maximum - minimum) * 0.08;
      minimum -= padding;
      maximum += padding;
    }

    final Rect plot = Rect.fromLTRB(4, 6, size.width - 4, size.height - 6);
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

    final Paint grid = Paint()
      ..color = AppTokens.outline
      ..strokeWidth = 1;
    for (int index = 0; index < 3; index++) {
      final double y = plot.top + plot.height * index / 2;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }

    canvas.save();
    canvas.clipRect(plot);

    final Paint line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    Path? path;
    void flush() {
      if (path != null) {
        canvas.drawPath(path!, line);
        path = null;
      }
    }

    for (final ProgressPoint point in points) {
      final double? value = point.value;
      if (value == null) {
        flush();
        continue;
      }
      final Offset offset = Offset(xFor(point.date), yFor(value));
      if (path == null) {
        path = Path()..moveTo(offset.dx, offset.dy);
      } else {
        path!.lineTo(offset.dx, offset.dy);
      }
    }
    flush();

    if (points.length <= 60) {
      final Paint dot = Paint()..color = color;
      for (final ProgressPoint point in withValues) {
        canvas.drawCircle(Offset(xFor(point.date), yFor(point.value!)), 3, dot);
      }
    } else {
      final ProgressPoint last = withValues.last;
      canvas.drawCircle(
        Offset(xFor(last.date), yFor(last.value!)),
        3,
        Paint()..color = color,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) {
    return !identical(points, oldDelegate.points) || color != oldDelegate.color;
  }
}
