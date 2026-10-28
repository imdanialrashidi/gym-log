import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';
import '../l10n/digit_style_scope.dart';

/// A hero number with a quiet label, used by the dashboard and summaries.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    super.key,
    this.unit,
    this.icon,
    this.tone = AppTokens.textPrimary,
    this.compact = false,
  });

  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color tone;

  /// Drops the icon and uses a smaller value; for dense three-column rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!compact)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 15, color: AppTokens.textSecondary),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  context.digits(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          )
        else
          Text(
            context.digits(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Flexible(
              child: Text(
                context.digits(value),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: tone,
                  fontSize: compact ? 19 : 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (unit != null) ...<Widget>[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  context.digits(unit),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// A labelled progress bar for muscle-group set counts and similar shares.
class MetricBar extends StatelessWidget {
  const MetricBar({
    required this.label,
    required this.valueLabel,
    required this.fraction,
    super.key,
    this.color = AppTokens.accent,
  });

  final String label;
  final String valueLabel;

  /// 0..1 share of the strongest row.
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double safe = fraction.isNaN ? 0 : fraction.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.digits(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space1),
              Text(
                context.digits(valueLabel),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 5,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const ColoredBox(color: AppTokens.surface3),
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: safe == 0 ? 0.02 : safe,
                  child: ColoredBox(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
