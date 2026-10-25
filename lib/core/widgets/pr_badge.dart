import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';
import '../l10n/digit_style_scope.dart';
import '../l10n/l10n.dart';

/// Subtle personal-record marker. Uses text and an icon, never color alone.
class PrBadge extends StatelessWidget {
  const PrBadge({required this.types, super.key});

  final Set<PersonalRecordType> types;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l10n = context.l10n;
    final String typeLabels = <String>[
      if (types.contains(PersonalRecordType.heaviestWeight)) l10n.prWeightLabel,
      if (types.contains(PersonalRecordType.mostRepsAtWeight)) l10n.prRepsLabel,
      if (types.contains(PersonalRecordType.estimatedOneRepMax))
        l10n.prE1rmLabel,
    ].join(', ');
    final String tooltip = context.digits(l10n.prBadgeTooltip(typeLabels));

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        container: true,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppTokens.space1,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTokens.highlight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.emoji_events_outlined,
                size: 14,
                color: AppTokens.highlight,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.prBadge,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTokens.highlight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
