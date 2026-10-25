import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import 'set_input_errors.dart';
import 'set_row.dart';

/// Edits one already logged set (`LOG-006`). Returns the new values or `null`
/// when cancelled; the parent owns persistence and failure feedback.
Future<SetDraft?> showSetEditDialog(
  BuildContext context, {
  required SetLog set,
  required WeightUnit unit,
}) {
  return showDialog<SetDraft>(
    context: context,
    builder: (BuildContext context) => _SetEditDialog(set: set, unit: unit),
  );
}

class _SetEditDialog extends StatefulWidget {
  const _SetEditDialog({required this.set, required this.unit});

  final SetLog set;
  final WeightUnit unit;

  @override
  State<_SetEditDialog> createState() => _SetEditDialogState();
}

class _SetEditDialogState extends State<_SetEditDialog> {
  late final TextEditingController _weight = TextEditingController(
    text: context.digits(formatWeight(widget.set.weightGrams, widget.unit)),
  );
  late final TextEditingController _reps = TextEditingController(
    text: context.digits(widget.set.reps),
  );
  late int? _rir = widget.set.rir;
  late bool _warmup = widget.set.isWarmup;
  String? _weightError;
  String? _repsError;

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  void _save() {
    final AppLocalizations l10n = context.l10n;
    final WeightParseResult weight = parseWeightInput(
      _weight.text,
      widget.unit,
    );
    final RepsParseResult reps = parseRepsInput(_reps.text);
    if (!weight.isValid || !reps.isValid) {
      setState(() {
        _weightError = weight.problem == null
            ? null
            : context.digits(weightErrorText(l10n, weight.problem!));
        _repsError = reps.problem == null
            ? null
            : context.digits(repsErrorText(l10n, reps.problem!));
      });
      return;
    }
    Navigator.of(context).pop(
      SetDraft(
        weightGrams: weight.grams!,
        reps: reps.reps!,
        rir: _rir,
        isWarmup: _warmup,
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      borderSide: BorderSide(color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String unitLabel = switch (widget.unit) {
      WeightUnit.kilograms => l10n.unitKilograms,
      WeightUnit.pounds => l10n.unitPounds,
    };

    return AlertDialog(
      title: Text(l10n.editSet),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                key: const Key('edit-set-weight'),
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.weightLabel,
                  suffixText: unitLabel,
                  errorText: _weightError,
                  border: _border(AppTokens.textSecondary),
                  enabledBorder: _border(AppTokens.textSecondary),
                  focusedBorder: _border(AppTokens.accent),
                ),
                onChanged: (_) => setState(() => _weightError = null),
              ),
              const SizedBox(height: AppTokens.space2),
              TextField(
                key: const Key('edit-set-reps'),
                controller: _reps,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.repsLabel,
                  errorText: _repsError,
                  border: _border(AppTokens.textSecondary),
                  enabledBorder: _border(AppTokens.textSecondary),
                  focusedBorder: _border(AppTokens.accent),
                ),
                onChanged: (_) => setState(() => _repsError = null),
              ),
              const SizedBox(height: AppTokens.space2),
              Text(
                l10n.rirLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppTokens.space1),
              Wrap(
                spacing: AppTokens.space1,
                runSpacing: AppTokens.space1,
                children: <Widget>[
                  for (int value = 0; value <= maximumStoredRir; value++)
                    ChoiceChip(
                      key: ValueKey<String>('edit-set-rir-$value'),
                      label: Text(
                        context.digits(
                          value == maximumStoredRir ? l10n.rirFivePlus : value,
                        ),
                      ),
                      selected: _rir == value,
                      showCheckmark: false,
                      selectedColor: AppTokens.accent,
                      backgroundColor: AppTokens.surface2,
                      side: BorderSide(
                        color: _rir == value
                            ? AppTokens.accent
                            : AppTokens.textSecondary,
                      ),
                      onSelected: (_) =>
                          setState(() => _rir = _rir == value ? null : value),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                    ),
                ],
              ),
              const SizedBox(height: AppTokens.space1),
              FilterChip(
                key: const Key('edit-set-warmup'),
                label: Text(l10n.warmupLabel),
                selected: _warmup,
                selectedColor: AppTokens.accent,
                backgroundColor: AppTokens.surface2,
                side: BorderSide(
                  color: _warmup ? AppTokens.accent : AppTokens.textSecondary,
                ),
                checkmarkColor: AppTokens.onAccent,
                onSelected: (_) => setState(() => _warmup = !_warmup),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('edit-set-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('edit-set-save'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
