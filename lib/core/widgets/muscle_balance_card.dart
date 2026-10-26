import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';
import '../l10n/digit_style_scope.dart';
import '../l10n/l10n.dart';
import '../l10n/muscle_labels.dart';
import 'app_card.dart';
import 'stat_tile.dart';

/// Weekly working sets grouped by muscle group.
///
/// Sorted by volume so the full body's biggest contributor is readable first.
/// Color is never the only signal: every row carries the localized muscle name
/// and the numeric set count.
class MuscleBalanceCard extends StatefulWidget {
  const MuscleBalanceCard({
    required this.workingSetsByMuscle,
    super.key,
    this.maxVisible = 6,
  });

  final Map<MuscleGroup?, int> workingSetsByMuscle;
  final int maxVisible;

  @override
  State<MuscleBalanceCard> createState() => _MuscleBalanceCardState();
}

class _MuscleBalanceCardState extends State<MuscleBalanceCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<MapEntry<MuscleGroup?, int>> rows =
        widget.workingSetsByMuscle.entries
            .where((MapEntry<MuscleGroup?, int> entry) => entry.value > 0)
            .toList()
          ..sort((
            MapEntry<MuscleGroup?, int> a,
            MapEntry<MuscleGroup?, int> b,
          ) {
            final int byCount = b.value.compareTo(a.value);
            if (byCount != 0) {
              return byCount;
            }
            return _name(l10n, a.key).compareTo(_name(l10n, b.key));
          });
    if (rows.isEmpty) {
      return AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.tune, size: 20, color: AppTokens.textSecondary),
            const SizedBox(width: AppTokens.space1),
            Expanded(
              child: Text(
                l10n.muscleSetsEmpty,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTokens.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final int maxCount = rows.first.value;
    final List<MapEntry<MuscleGroup?, int>> visible = _showAll
        ? rows
        : rows.take(widget.maxVisible).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final MapEntry<MuscleGroup?, int> row in visible)
            MetricBar(
              key: ValueKey<String>(
                'muscle-bar-${row.key?.jsonValue ?? 'unassigned'}',
              ),
              label: _name(l10n, row.key),
              valueLabel: context.digits(l10n.setsLabel(row.value)),
              fraction: row.value / maxCount,
              color: _colorFor(row.key),
            ),
          if (rows.length > widget.maxVisible)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const Key('muscle-balance-toggle'),
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(_showAll ? l10n.showLess : l10n.showAll),
              ),
            ),
        ],
      ),
    );
  }

  String _name(AppLocalizations l10n, MuscleGroup? group) {
    if (group == null) {
      return l10n.unassignedMuscle;
    }
    return muscleGroupLabel(l10n, group);
  }

  /// A restrained two-tone cycle, not a unique hue per group.
  Color _colorFor(MuscleGroup? group) {
    if (group == null) {
      return AppTokens.textSecondary;
    }
    return group.index.isEven ? AppTokens.accent : AppTokens.info;
  }
}
