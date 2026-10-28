import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';

/// Opens the plate and warm-up calculator.
Future<void> showPlateCalculatorSheet(
  BuildContext context, {
  required WeightUnit unit,
  int? initialGrams,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) =>
        PlateCalculatorSheet(unit: unit, initialGrams: initialGrams),
  );
}

class PlateCalculatorSheet extends StatefulWidget {
  const PlateCalculatorSheet({
    required this.unit,
    super.key,
    this.initialGrams,
  });

  final WeightUnit unit;
  final int? initialGrams;

  @override
  State<PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<PlateCalculatorSheet> {
  late final TextEditingController _target = TextEditingController(
    text: context.digits(
      formatWeight(
        widget.initialGrams ??
            (widget.unit == WeightUnit.kilograms ? 60000 : 61235),
        widget.unit,
      ),
    ),
  );

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  WeightParseResult get _parsed => parseWeightInput(_target.text, widget.unit);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final WeightParseResult parsed = _parsed;
    final int targetGrams = parsed.grams ?? 0;
    final PlateLoadout? loadout = parsed.isValid
        ? solvePlateLoadout(targetGrams: targetGrams, unit: widget.unit)
        : null;
    final List<WarmupStep> warmup = parsed.isValid
        ? warmupRamp(workingGrams: targetGrams, unit: widget.unit)
        : const <WarmupStep>[];
    final String unitLabel = switch (widget.unit) {
      WeightUnit.kilograms => l10n.unitKilograms,
      WeightUnit.pounds => l10n.unitPounds,
    };

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTokens.surface,
            border: Border(top: BorderSide(color: AppTokens.outlineStrong)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppTokens.space3,
                AppTokens.space2,
                AppTokens.space3,
                AppTokens.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTokens.accent,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusPill,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.space1),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              l10n.plateKicker,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTokens.accent,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              l10n.plateCalculatorTitle,
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: l10n.close,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space2),
                  TextField(
                    key: const Key('plate-target'),
                    controller: _target,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: theme.textTheme.headlineSmall,
                    decoration: InputDecoration(
                      labelText: l10n.plateTargetLabel,
                      suffixText: unitLabel,
                      errorText: parsed.isValid
                          ? null
                          : context.digits(l10n.plateInvalidWeight),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  if (loadout != null)
                    _LoadoutResult(
                      loadout: loadout,
                      unit: widget.unit,
                      unitLabel: unitLabel,
                    ),
                  const SizedBox(height: AppTokens.space3),
                  Row(
                    children: <Widget>[
                      Text(
                        l10n.plateWarmupTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.unit == WeightUnit.kilograms
                            ? l10n.plateAssumption
                            : l10n.plateAssumptionPounds,
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space1),
                  if (warmup.isEmpty)
                    Text(
                      l10n.plateWarmupNoSteps,
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    for (final WarmupStep step in warmup)
                      _WarmupRow(
                        step: step,
                        unit: widget.unit,
                        unitLabel: unitLabel,
                      ),
                  const SizedBox(height: AppTokens.space3),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('plate-close'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.plateClose),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadoutResult extends StatelessWidget {
  const _LoadoutResult({
    required this.loadout,
    required this.unit,
    required this.unitLabel,
  });

  final PlateLoadout loadout;
  final WeightUnit unit;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final int barGrams = loadout.barGrams;
    final String status;
    if (loadout.isBelowBar) {
      status = l10n.plateBelowBar;
    } else if (loadout.isExact) {
      status = l10n.plateExact;
    } else {
      status = context.digits(
        l10n.plateRemainder(
          '${formatWeight(loadout.remainderGrams, unit)} $unitLabel',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.all(AppTokens.space2),
          decoration: BoxDecoration(
            color: AppTokens.surface2,
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            border: Border.all(color: AppTokens.outline.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      context.digits(formatWeight(loadout.actualGrams, unit)),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: loadout.isExact
                            ? AppTokens.accent
                            : AppTokens.highlight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(unitLabel, style: theme.textTheme.labelMedium),
                  const Spacer(),
                  Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: loadout.isExact
                          ? AppTokens.accent
                          : AppTokens.highlight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space1),
              Text(
                context.digits(
                  l10n.plateBarLabel(
                    '${formatWeight(barGrams, unit)} $unitLabel',
                  ),
                ),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppTokens.space2),
              _Barbell(loadout: loadout),
              const SizedBox(height: AppTokens.space2),
              if (loadout.platesPerSideGrams.isEmpty)
                Text(l10n.plateEmpty, style: theme.textTheme.bodySmall)
              else
                Wrap(
                  spacing: AppTokens.space1,
                  runSpacing: AppTokens.space1,
                  children: <Widget>[
                    for (final MapEntry<int, int> plate
                        in loadout.plateCounts.entries)
                      _PlateCount(
                        grams: plate.key,
                        count: plate.value,
                        unit: unit,
                        unitLabel: unitLabel,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Barbell extends StatelessWidget {
  const _Barbell({required this.loadout});

  final PlateLoadout loadout;

  @override
  Widget build(BuildContext context) {
    final List<int> plates = loadout.platesPerSideGrams;
    return SizedBox(
      height: 102,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final int plate in plates.reversed) _PlateGlyph(grams: plate),
            Container(width: 86, height: 5, color: AppTokens.textSecondary),
            for (final int plate in plates) _PlateGlyph(grams: plate),
          ],
        ),
      ),
    );
  }
}

class _PlateGlyph extends StatelessWidget {
  const _PlateGlyph({required this.grams});

  final int grams;

  @override
  Widget build(BuildContext context) {
    final double kilograms = grams / 1000;
    final double height = (34 + kilograms * 1.8).clamp(34, 90);
    final Color color = switch (kilograms) {
      >= 20.0 => AppTokens.accentDeep,
      >= 10.0 => AppTokens.highlight,
      >= 5.0 => AppTokens.info,
      _ => AppTokens.textSecondary,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 1.5),
      child: Container(
        width: 13,
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          border: Border.all(color: color),
        ),
      ),
    );
  }
}

class _PlateCount extends StatelessWidget {
  const _PlateCount({
    required this.grams,
    required this.count,
    required this.unit,
    required this.unitLabel,
  });

  final int grams;
  final int count;
  final WeightUnit unit;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppTokens.space1,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTokens.background,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        context.digits('$count × ${formatWeight(grams, unit)} $unitLabel'),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppTokens.textPrimary),
      ),
    );
  }
}

class _WarmupRow extends StatelessWidget {
  const _WarmupRow({
    required this.step,
    required this.unit,
    required this.unitLabel,
  });

  final WarmupStep step;
  final WeightUnit unit;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String label = step.isBar
        ? l10n.plateWarmupBar
        : '${(step.fraction * 100).round()}%';
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppTokens.space1,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTokens.outline)),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 66,
            child: Text(label, style: theme.textTheme.labelSmall),
          ),
          Expanded(
            child: Text(
              context.digits(
                '${formatWeight(step.weightGrams, unit)} $unitLabel',
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            context.digits('× ${step.reps}'),
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(width: AppTokens.space2),
          Text(
            context.digits(
              l10n.platePerSideCount(step.loadout.plateCountPerSide),
            ),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
