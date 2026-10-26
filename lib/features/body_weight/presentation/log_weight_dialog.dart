import 'package:flutter/services.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/number_input.dart';

/// Prompts for a body-weight reading and validates it before returning grams.
///
/// The dialog is deliberately small: one field, the active unit, and one
/// primary action. A value outside the accepted human range stays in the
/// dialog with a localized error instead of becoming a weird trend point.
Future<int?> showLogWeightDialog(
  BuildContext context, {
  required WeightUnit unit,
  int? initialGrams,
}) {
  return showDialog<int>(
    context: context,
    builder: (BuildContext dialogContext) =>
        _LogWeightDialog(unit: unit, initialGrams: initialGrams),
  );
}

class _LogWeightDialog extends StatefulWidget {
  const _LogWeightDialog({required this.unit, this.initialGrams});

  final WeightUnit unit;
  final int? initialGrams;

  @override
  State<_LogWeightDialog> createState() => _LogWeightDialogState();
}

class _LogWeightDialogState extends State<_LogWeightDialog> {
  late final TextEditingController _value = TextEditingController(
    text: widget.initialGrams == null
        ? ''
        : context.digits(formatWeight(widget.initialGrams!, widget.unit)),
  );
  String? _error;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _save() {
    final WeightParseResult parsed = parseWeightField(
      _value.text,
      unit: widget.unit,
      originalGrams: widget.initialGrams,
    );
    final int? grams = parsed.grams;
    if (grams == null || !isValidBodyWeightGrams(grams)) {
      setState(() => _error = context.l10n.bodyWeightErrorRange);
      return;
    }
    Navigator.of(context).pop(grams);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String unitLabel = switch (widget.unit) {
      WeightUnit.kilograms => l10n.unitKilograms,
      WeightUnit.pounds => l10n.unitPounds,
    };
    return AlertDialog(
      title: Text(l10n.bodyWeightLogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.bodyWeightHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppTokens.space2),
            TextField(
              key: const Key('body-weight-field'),
              controller: _value,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[decimalNumberInput],
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: InputDecoration(
                labelText: l10n.weightLabel,
                suffixText: unitLabel,
                errorText: _error,
                errorMaxLines: 2,
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('body-weight-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('body-weight-save'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
