import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/pr_badge.dart';
import 'progression_reason_text.dart';
import 'set_input_errors.dart';

/// A committed set plus any personal records it earned.
class SetLogOutcome {
  const SetLogOutcome({
    required this.set,
    this.personalRecords = const <PersonalRecordType>{},
  });

  final SetLog set;
  final Set<PersonalRecordType> personalRecords;
}

/// One set's editable draft values.
class SetDraft {
  const SetDraft({
    required this.weightGrams,
    required this.reps,
    required this.isWarmup,
    this.rir,
  });

  final int weightGrams;
  final int reps;
  final int? rir;
  final bool isWarmup;
}

/// The set row: typed or stepped weight/reps, optional RIR chips, a warm-up
/// toggle, and one check action that commits immediately.
///
/// All state is local so tapping check rebuilds this row only. Saved rows keep
/// their values visible and never write again.
class SetRow extends StatefulWidget {
  const SetRow({
    required this.rowKey,
    required this.setNumber,
    required this.unit,
    required this.incrementGrams,
    required this.onLog,
    this.savedSet,
    this.personalRecords = const <PersonalRecordType>{},
    this.initialWeightGrams,
    this.initialReps,
    this.initialRir,
    this.initialWarmup = false,
    this.suggestion,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final String rowKey;
  final int setNumber;
  final WeightUnit unit;
  final int incrementGrams;
  final Future<SetLogOutcome> Function(SetDraft draft) onLog;
  final SetLog? savedSet;
  final Set<PersonalRecordType> personalRecords;
  final int? initialWeightGrams;
  final int? initialReps;
  final int? initialRir;
  final bool initialWarmup;

  /// Optional `INT-002` target. When present it is shown with its reason,
  /// overrides the prefill in the editable fields, and can be reverted to
  /// [initialWeightGrams] and [initialReps] in one action (ADR-0009).
  final ProgressionSuggestion? suggestion;

  /// Actions for an already logged set (`LOG-006`). Hidden when null.
  final void Function(SetLog set)? onEdit;
  final void Function(SetLog set)? onDelete;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  SetLog? _saved;
  Set<PersonalRecordType> _personalRecords = const <PersonalRecordType>{};
  int? _rir;
  bool _warmup = false;
  bool _saving = false;
  bool _suggestionDismissed = false;
  String? _weightError;
  String? _repsError;
  String? _saveError;
  late DigitStyle _digitStyle;
  bool _valuesInitialized = false;

  bool get _locked => _saved != null || _saving;

  @override
  void initState() {
    super.initState();
    _saved = widget.savedSet;
    _personalRecords = widget.personalRecords;
    _weight = TextEditingController();
    _reps = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final DigitStyle style = DigitStyleScope.of(context);
    if (!_valuesInitialized) {
      _digitStyle = style;
      _applyInitialValues();
      _valuesInitialized = true;
      return;
    }
    if (_digitStyle != style) {
      _digitStyle = style;
      _weight.text = applyDigitStyle(_weight.text, _digitStyle);
      _reps.text = applyDigitStyle(_reps.text, _digitStyle);
    }
  }

  void _applyInitialValues() {
    final SetLog? saved = _saved;
    final ProgressionSuggestion? suggestion = _suggestionDismissed
        ? null
        : widget.suggestion;
    final int? weightGrams =
        saved?.weightGrams ??
        suggestion?.weightGrams ??
        widget.initialWeightGrams;
    final int? reps =
        saved?.reps ?? suggestion?.targetReps ?? widget.initialReps;
    _rir = saved == null ? widget.initialRir : saved.rir;
    _warmup = saved?.isWarmup ?? widget.initialWarmup;
    _weight.text = weightGrams == null
        ? ''
        : applyDigitStyle(formatWeight(weightGrams, widget.unit), _digitStyle);
    _reps.text = applyDigitStyle(reps?.toString() ?? '', _digitStyle);
  }

  void _revertSuggestion() {
    setState(() {
      _suggestionDismissed = true;
      final int? weightGrams = widget.initialWeightGrams;
      _weight.text = weightGrams == null
          ? ''
          : applyDigitStyle(
              formatWeight(weightGrams, widget.unit),
              _digitStyle,
            );
      _reps.text = applyDigitStyle(
        widget.initialReps?.toString() ?? '',
        _digitStyle,
      );
      _weightError = null;
      _repsError = null;
    });
  }

  @override
  void didUpdateWidget(SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final SetLog? saved = widget.savedSet;
    if (saved == null && _saved != null) {
      _saved = null;
      _personalRecords = widget.personalRecords;
      _applyInitialValues();
      return;
    }
    if (saved != null && !identical(saved, _saved)) {
      _saved = saved;
      _personalRecords = widget.personalRecords;
      _applyInitialValues();
      return;
    }
    final bool sameRecords =
        widget.personalRecords.length == oldWidget.personalRecords.length &&
        widget.personalRecords.containsAll(oldWidget.personalRecords);
    if (!sameRecords) {
      _personalRecords = widget.personalRecords;
    }
    if (oldWidget.unit == widget.unit) {
      return;
    }
    if (saved != null) {
      _weight.text = context.digits(
        formatWeight(saved.weightGrams, widget.unit),
      );
      return;
    }
    final WeightParseResult parsed = parseWeightInput(
      _weight.text,
      oldWidget.unit,
    );
    if (parsed.grams != null) {
      _weight.text = applyDigitStyle(
        formatWeight(parsed.grams!, widget.unit),
        _digitStyle,
      );
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  WeightParseResult get _parsedWeight =>
      parseWeightInput(_weight.text, widget.unit);

  int? get _parsedReps => parseRepsInput(_reps.text).reps;

  bool get _canDecreaseWeight {
    final int? grams = _parsedWeight.grams;
    return !_locked && grams != null && grams > 0;
  }

  bool get _canIncreaseWeight {
    if (_locked) {
      return false;
    }
    final WeightParseResult parsed = _parsedWeight;
    if (_weight.text.trim().isEmpty) {
      return true;
    }
    return parsed.grams != null && parsed.grams! < maximumSetWeightGrams;
  }

  bool get _canDecreaseReps {
    final int? reps = _parsedReps;
    return !_locked && reps != null && reps > 1;
  }

  bool get _canIncreaseReps {
    if (_locked) {
      return false;
    }
    final int? reps = _parsedReps;
    if (_reps.text.trim().isEmpty) {
      return true;
    }
    return reps != null && reps < maximumSetRepetitions;
  }

  void _stepWeight(int direction) {
    final int base = _parsedWeight.grams ?? 0;
    final int next = (base + direction * widget.incrementGrams).clamp(
      0,
      maximumSetWeightGrams,
    );
    _weight.text = applyDigitStyle(
      formatWeight(next, widget.unit),
      _digitStyle,
    );
    setState(() => _weightError = null);
  }

  void _stepReps(int direction) {
    final int base = _parsedReps ?? 0;
    final int next = (base + direction).clamp(1, maximumSetRepetitions);
    _reps.text = applyDigitStyle('$next', _digitStyle);
    setState(() => _repsError = null);
  }

  void _toggleWarmup() {
    setState(() => _warmup = !_warmup);
  }

  void _toggleRir(int value) {
    setState(() => _rir = _rir == value ? null : value);
  }

  String _weightErrorText(AppLocalizations l10n, NumberProblem problem) {
    return weightErrorText(l10n, problem);
  }

  String _repsErrorText(AppLocalizations l10n, NumberProblem problem) {
    return repsErrorText(l10n, problem);
  }

  Future<void> _check() async {
    final AppLocalizations l10n = context.l10n;
    final WeightParseResult weight = _parsedWeight;
    final RepsParseResult reps = parseRepsInput(_reps.text);
    if (!weight.isValid || !reps.isValid) {
      setState(() {
        _weightError = weight.problem == null
            ? null
            : context.digits(_weightErrorText(l10n, weight.problem!));
        _repsError = reps.problem == null
            ? null
            : context.digits(_repsErrorText(l10n, reps.problem!));
        _saveError = null;
      });
      return;
    }

    setState(() {
      _saving = true;
      _weightError = null;
      _repsError = null;
      _saveError = null;
    });
    try {
      final SetLogOutcome outcome = await widget.onLog(
        SetDraft(
          weightGrams: weight.grams!,
          reps: reps.reps!,
          rir: _rir,
          isWarmup: _warmup,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _saved = outcome.set;
        _personalRecords = outcome.personalRecords;
        _applyInitialValues();
        _saving = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _saveError = l10n.saveFailed;
      });
    }
  }

  String get _unitLabel => switch (widget.unit) {
    WeightUnit.kilograms => context.l10n.unitKilograms,
    WeightUnit.pounds => context.l10n.unitPounds,
  };

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool saved = _saved != null;
    final ProgressionSuggestion? suggestion = saved || _suggestionDismissed
        ? null
        : widget.suggestion;
    final TextStyle numberStyle =
        Theme.of(context).textTheme.titleLarge
            ?.copyWith(color: AppTokens.textPrimary) ??
        const TextStyle(color: AppTokens.textPrimary);

    return Semantics(
      container: true,
      label: context.digits(l10n.setNumber(widget.setNumber)),
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: AppTokens.space1),
        padding: const EdgeInsetsDirectional.all(AppTokens.space2),
        decoration: BoxDecoration(
          color: saved ? AppTokens.surface2 : AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(
            color: saved ? AppTokens.accent : AppTokens.outline,
            width: saved ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    spacing: AppTokens.space1,
                    runSpacing: AppTokens.space1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(context.digits(l10n.setNumber(widget.setNumber))),
                      if (saved && _personalRecords.isNotEmpty)
                        PrBadge(
                          key: ValueKey<String>('${widget.rowKey}-pr'),
                          types: _personalRecords,
                        ),
                      FilterChip(
                        key: ValueKey<String>('${widget.rowKey}-warmup'),
                        label: Text(
                          l10n.warmupLabel,
                          style: TextStyle(
                            color: _warmup
                                ? AppTokens.onAccent
                                : AppTokens.textPrimary,
                          ),
                        ),
                        selected: _warmup,
                        onSelected: _locked ? null : (_) => _toggleWarmup(),
                        selectedColor: AppTokens.accent,
                        backgroundColor: AppTokens.surface2,
                        side: BorderSide(
                          color: _warmup
                              ? AppTokens.accent
                              : AppTokens.textSecondary,
                        ),
                        checkmarkColor: AppTokens.onAccent,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.space1),
                if (saved)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle,
                        color: AppTokens.accent,
                        size: 20,
                      ),
                      const SizedBox(width: AppTokens.space1),
                      Text(
                        l10n.setSaved,
                        key: ValueKey<String>('${widget.rowKey}-saved'),
                        style: const TextStyle(
                          color: AppTokens.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.onEdit != null || widget.onDelete != null)
                        PopupMenuButton<String>(
                          key: ValueKey<String>('${widget.rowKey}-actions'),
                          tooltip: l10n.setActions,
                          onSelected: (String action) {
                            if (action == 'edit') {
                              widget.onEdit?.call(_saved!);
                            } else {
                              widget.onDelete?.call(_saved!);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  key: ValueKey<String>(
                                    '${widget.rowKey}-edit',
                                  ),
                                  value: 'edit',
                                  child: Text(l10n.editSet),
                                ),
                                PopupMenuItem<String>(
                                  key: ValueKey<String>(
                                    '${widget.rowKey}-delete',
                                  ),
                                  value: 'delete',
                                  child: Text(l10n.deleteSet),
                                ),
                              ],
                          icon: const Icon(Icons.more_vert),
                        ),
                    ],
                  )
                else
                  IconButton.filled(
                    key: ValueKey<String>('${widget.rowKey}-check'),
                    tooltip: l10n.logSet,
                    onPressed: _saving ? null : _check,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTokens.accent,
                      foregroundColor: AppTokens.onAccent,
                      minimumSize: const Size(
                        AppTokens.minTouchTarget,
                        AppTokens.minTouchTarget,
                      ),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTokens.onAccent,
                            ),
                          )
                        : const Icon(Icons.check),
                  ),
              ],
            ),
            if (suggestion != null) ...<Widget>[
              const SizedBox(height: AppTokens.space1),
              Container(
                key: ValueKey<String>('${widget.rowKey}-suggestion'),
                width: double.infinity,
                padding: const EdgeInsetsDirectional.all(AppTokens.space1),
                decoration: BoxDecoration(
                  color: AppTokens.surface2,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  border: const BorderDirectional(
                    start: BorderSide(color: AppTokens.highlight, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.trending_up,
                          color: AppTokens.highlight,
                          size: 18,
                        ),
                        const SizedBox(width: AppTokens.space1),
                        Text(
                          l10n.progressionSuggestionLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppTokens.highlight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progressionReasonText(context, suggestion, widget.unit),
                      key: ValueKey<String>(
                        '${widget.rowKey}-suggestion-reason',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (widget.initialWeightGrams != null &&
                        widget.initialReps != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: AppTokens.space1,
                        runSpacing: AppTokens.space1,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            context.digits(
                              l10n.progressionLastSession(
                                formatWeight(
                                  widget.initialWeightGrams!,
                                  widget.unit,
                                ),
                                widget.initialReps!,
                              ),
                            ),
                            key: ValueKey<String>(
                              '${widget.rowKey}-suggestion-last',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTokens.textSecondary),
                          ),
                          TextButton(
                            key: ValueKey<String>(
                              '${widget.rowKey}-suggestion-revert',
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(
                                AppTokens.minTouchTarget,
                                AppTokens.minTouchTarget,
                              ),
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppTokens.space1,
                              ),
                            ),
                            onPressed: _revertSuggestion,
                            child: Text(l10n.progressionUseLastSession),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppTokens.space1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  key: ValueKey<String>('${widget.rowKey}-weight-minus'),
                  tooltip: l10n.decreaseWeight,
                  onPressed: _canDecreaseWeight ? () => _stepWeight(-1) : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: TextField(
                    key: ValueKey<String>('${widget.rowKey}-weight'),
                    controller: _weight,
                    readOnly: _locked,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: numberStyle,
                    decoration: InputDecoration(
                      labelText: l10n.weightLabel,
                      suffixText: _unitLabel,
                      errorText: _weightError,
                      errorMaxLines: 2,
                      border: _inputBorder(AppTokens.textSecondary),
                      enabledBorder: _inputBorder(AppTokens.textSecondary),
                      focusedBorder: _inputBorder(AppTokens.accent, width: 2),
                      disabledBorder: _inputBorder(AppTokens.textSecondary),
                      errorBorder: _inputBorder(AppTokens.danger, width: 2),
                      focusedErrorBorder: _inputBorder(
                        AppTokens.danger,
                        width: 2,
                      ),
                    ),
                    onChanged: (_) => setState(() => _weightError = null),
                  ),
                ),
                IconButton(
                  key: ValueKey<String>('${widget.rowKey}-weight-plus'),
                  tooltip: l10n.increaseWeight,
                  onPressed: _canIncreaseWeight ? () => _stepWeight(1) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  key: ValueKey<String>('${widget.rowKey}-reps-minus'),
                  tooltip: l10n.decreaseReps,
                  onPressed: _canDecreaseReps ? () => _stepReps(-1) : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: TextField(
                    key: ValueKey<String>('${widget.rowKey}-reps'),
                    controller: _reps,
                    readOnly: _locked,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: numberStyle,
                    decoration: InputDecoration(
                      labelText: l10n.repsLabel,
                      errorText: _repsError,
                      errorMaxLines: 2,
                      border: _inputBorder(AppTokens.textSecondary),
                      enabledBorder: _inputBorder(AppTokens.textSecondary),
                      focusedBorder: _inputBorder(AppTokens.accent, width: 2),
                      disabledBorder: _inputBorder(AppTokens.textSecondary),
                      errorBorder: _inputBorder(AppTokens.danger, width: 2),
                      focusedErrorBorder: _inputBorder(
                        AppTokens.danger,
                        width: 2,
                      ),
                    ),
                    onChanged: (_) => setState(() => _repsError = null),
                  ),
                ),
                IconButton(
                  key: ValueKey<String>('${widget.rowKey}-reps-plus'),
                  tooltip: l10n.increaseReps,
                  onPressed: _canIncreaseReps ? () => _stepReps(1) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space1),
            Text(l10n.rirLabel, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppTokens.space1),
            Wrap(
              spacing: AppTokens.space1,
              runSpacing: AppTokens.space1,
              children: <Widget>[
                for (int value = 0; value <= maximumStoredRir; value++)
                  ChoiceChip(
                    key: ValueKey<String>('${widget.rowKey}-rir-$value'),
                    label: Text(
                      context.digits(
                        value == maximumStoredRir ? l10n.rirFivePlus : value,
                      ),
                      style: TextStyle(
                        color: _rir == value
                            ? AppTokens.onAccent
                            : AppTokens.textPrimary,
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
                    onSelected: _locked ? null : (_) => _toggleRir(value),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                  ),
              ],
            ),
            if (_saveError != null) ...<Widget>[
              const SizedBox(height: AppTokens.space1),
              Text(
                _saveError!,
                style: const TextStyle(color: AppTokens.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
