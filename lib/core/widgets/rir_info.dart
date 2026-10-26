import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';
import '../l10n/digit_style_scope.dart';
import '../l10n/l10n.dart';

/// Opens the plain-language RIR explainer (`LOG-005`).
///
/// The sheet exists because RIR is jargon: a lifter who has never seen the
/// term must be able to learn it without leaving the set they are logging.
Future<void> showRirInfo(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => const _RirInfoSheet(),
  );
}

/// The info affordance next to the RIR control.
class RirInfoButton extends StatelessWidget {
  const RirInfoButton({super.key, this.buttonKey, this.compact = false});

  final Key? buttonKey;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    if (compact) {
      return IconButton(
        key: buttonKey,
        tooltip: l10n.rirInfoButton,
        visualDensity: VisualDensity.compact,
        onPressed: () => showRirInfo(context),
        icon: const Icon(Icons.info_outline, size: 18),
        style: IconButton.styleFrom(
          foregroundColor: AppTokens.textSecondary,
          minimumSize: const Size(
            AppTokens.minTouchTarget,
            AppTokens.minTouchTarget,
          ),
        ),
      );
    }
    return TextButton.icon(
      key: buttonKey,
      onPressed: () => showRirInfo(context),
      icon: const Icon(Icons.info_outline, size: 17),
      label: Text(l10n.rirInfoButton),
      style: TextButton.styleFrom(
        foregroundColor: AppTokens.info,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppTokens.space1,
        ),
      ),
    );
  }
}

/// One-line description of the selected RIR value.
String rirDescription(AppLocalizations l10n, int? rir) {
  if (rir == null) {
    return l10n.rirDescription(0);
  }
  if (rir >= maximumStoredRir) {
    return l10n.rirFivePlusDescription;
  }
  return l10n.rirDescription(rir);
}

class _RirInfoSheet extends StatelessWidget {
  const _RirInfoSheet();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const Key('rir-info-sheet'),
        padding: EdgeInsetsDirectional.fromSTEB(
          AppTokens.space3,
          AppTokens.space1,
          AppTokens.space3,
          AppTokens.space3 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTokens.info.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  ),
                  child: const Icon(Icons.info_outline, color: AppTokens.info),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Text(
                    l10n.rirInfoTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space2),
            Text(l10n.rirInfoDefinition, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppTokens.space3),
            Text(l10n.rirInfoScaleTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTokens.space1),
            _ScaleRow(
              value: '0',
              text: l10n.rirInfoZero,
              color: AppTokens.danger,
            ),
            _ScaleRow(
              value: '1',
              text: l10n.rirInfoOne,
              color: AppTokens.accent,
            ),
            _ScaleRow(
              value: '2–3',
              text: l10n.rirInfoTwoThree,
              color: AppTokens.accent,
            ),
            _ScaleRow(
              value: '4–5+',
              text: l10n.rirInfoFourFive,
              color: AppTokens.info,
            ),
            const SizedBox(height: AppTokens.space2),
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.all(AppTokens.space2),
              decoration: BoxDecoration(
                color: AppTokens.surface2,
                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                border: const BorderDirectional(
                  start: BorderSide(color: AppTokens.accent, width: 3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppTokens.highlight,
                    size: 20,
                  ),
                  const SizedBox(width: AppTokens.space1),
                  Expanded(
                    child: Text(
                      l10n.rirInfoTip,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('rir-info-close'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.rirInfoClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.value,
    required this.text,
    required this.color,
  });

  final String value;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppTokens.space1,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              context.digits(value),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 5),
              child: Text(
                context.digits(text),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
