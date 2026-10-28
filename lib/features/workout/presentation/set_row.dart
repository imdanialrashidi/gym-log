import 'dart:async';

import 'package:flutter/services.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/pr_badge.dart';
import '../../../core/widgets/rir_info.dart';
import '../../../core/widgets/training_formats.dart';
import 'progression_reason_text.dart';
import 'set_input_errors.dart';

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
  final Future<LoggedSet> Function(SetEntry entry) onLog;
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

class _SetRowState extends State<SetRow>
    with AutomaticKeepAliveClientMixin<SetRow> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  SetLog? _saved;
  Set<PersonalRecordType> _personalRecords = const <PersonalRecordType>{};
  int? _rir;
  bool _warmup = false;
  bool _saving = false;
  bool _suggestionDismissed = false;
  NumberProblem? _weightProblem;
  NumberProblem? _repsProblem;
  bool _saveFailed = false;
  int? _canonicalWeightGrams;
  late DigitStyle _digitStyle;
  bool _valuesInitialized = false;

  bool get _locked => _saved != null || _saving;

  /// Keep an in-progress draft alive when the user scrolls to another exercise
  /// and back. Saved rows are cheap, so keeping them is harmless.
  @override
  bool get wantKeepAlive => true;

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
    _canonicalWeightGrams = weightGrams;
    _weight.text = weightGrams == null
        ? ''
        : applyDigitStyle(formatWeight(weightGrams, widget.unit), _digitStyle);
    _reps.text = applyDigitStyle(reps?.toString() ?? '', _digitStyle);
  }

  void _revertSuggestion() {
    setState(() {
      _suggestionDismissed = true;
      final int? weightGrams = widget.initialWeightGrams;
      _canonicalWeightGrams = weightGrams;
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
      _weightProblem = null;
      _repsProblem = null;
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
      _canonicalWeightGrams = saved.weightGrams;
      _weight.text = context.digits(
        formatWeight(saved.weightGrams, widget.unit),
      );
      return;
    }
    final int? canonical = _canonicalWeightGrams;
    if (canonical != null) {
      _weight.text = applyDigitStyle(
        formatWeight(canonical, widget.unit),
        _digitStyle,
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

  WeightParseResult get _parsedWeight => parseWeightField(
    _weight.text,
    unit: widget.unit,
    originalGrams: _canonicalWeightGrams,
  );

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
    _canonicalWeightGrams = next;
    _weight.text = applyDigitStyle(
      formatWeight(next, widget.unit),
      _digitStyle,
    );
    setState(() => _weightProblem = null);
  }

  void _stepReps(int direction) {
    final int base = _parsedReps ?? 0;
    final int next = (base + direction).clamp(1, maximumSetRepetitions);
    _reps.text = applyDigitStyle('$next', _digitStyle);
    setState(() => _repsProblem = null);
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
    final WeightParseResult weight = _parsedWeight;
    final RepsParseResult reps = parseRepsInput(_reps.text);
    if (!weight.isValid || !reps.isValid) {
      setState(() {
        _weightProblem = weight.problem;
        _repsProblem = reps.problem;
        _saveFailed = false;
      });
      return;
    }

    setState(() {
      _saving = true;
      _weightProblem = null;
      _repsProblem = null;
      _saveFailed = false;
    });
    try {
      final LoggedSet outcome = await widget.onLog(
        SetEntry(
          weightGrams: weight.grams!,
          reps: reps.reps!,
          rir: _rir,
          isWarmup: _warmup,
        ),
      );
      if (!mounted) {
        return;
      }
      unawaited(
        outcome.personalRecords.isEmpty
            ? HapticFeedback.lightImpact()
            : HapticFeedback.mediumImpact(),
      );
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
        _saveFailed = true;
      });
    }
  }

  String get _unitLabel => switch (widget.unit) {
    WeightUnit.kilograms => context.l10n.unitKilograms,
    WeightUnit.pounds => context.l10n.unitPounds,
  };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final AppLocalizations l10n = context.l10n;
    final SetLog? savedSet = _saved;
    if (savedSet != null) {
      return _buildSaved(context, l10n, savedSet);
    }
    final ProgressionSuggestion? suggestion = _suggestionDismissed
        ? null
        : widget.suggestion;
    final NumberProblem? weightProblem = _weightProblem;
    final NumberProblem? repsProblem = _repsProblem;

    return Semantics(
      container: true,
      label: context.digits(l10n.setNumber(widget.setNumber)),
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: AppTokens.space1),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTokens.background,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          border: Border.all(color: AppTokens.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppTokens.space2,
                AppTokens.space1,
                AppTokens.space1,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Wrap(
                      spacing: AppTokens.space1,
                      runSpacing: AppTokens.space1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        _SetBadge(number: widget.setNumber, saved: false),
                        _WarmupToggle(
                          key: ValueKey<String>('${widget.rowKey}-warmup'),
                          label: l10n.warmupLabel,
                          selected: _warmup,
                          onTap: _locked ? null : _toggleWarmup,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.space1),
                  _CheckSquare(
                    rowKey: widget.rowKey,
                    saving: _saving,
                    onTap: _saving ? null : _check,
                    tooltip: l10n.logSet,
                  ),
                ],
              ),
            ),
            if (suggestion != null)
              _SuggestionBlock(
                rowKey: widget.rowKey,
                suggestion: suggestion,
                unit: widget.unit,
                initialWeightGrams: widget.initialWeightGrams,
                initialReps: widget.initialReps,
                onRevert: _revertSuggestion,
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppTokens.space2,
                AppTokens.space1,
                AppTokens.space2,
                AppTokens.space2,
              ),
              child: Column(
                children: <Widget>[
                  _NumberDeck(
                    label: l10n.weightLabel,
                    unitLabel: _unitLabel,
                    fieldKey: ValueKey<String>('${widget.rowKey}-weight'),
                    controller: _weight,
                    readOnly: _locked,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    errorText: weightProblem == null
                        ? null
                        : context.digits(_weightErrorText(l10n, weightProblem)),
                    minusKey: ValueKey<String>('${widget.rowKey}-weight-minus'),
                    plusKey: ValueKey<String>('${widget.rowKey}-weight-plus'),
                    minusTooltip: l10n.decreaseWeight,
                    plusTooltip: l10n.increaseWeight,
                    onMinus: _canDecreaseWeight ? () => _stepWeight(-1) : null,
                    onPlus: _canIncreaseWeight ? () => _stepWeight(1) : null,
                    onChanged: (_) => setState(() {
                      _weightProblem = null;
                      _canonicalWeightGrams = null;
                    }),
                  ),
                  const SizedBox(height: AppTokens.space1),
                  _NumberDeck(
                    label: l10n.repsLabel,
                    fieldKey: ValueKey<String>('${widget.rowKey}-reps'),
                    controller: _reps,
                    readOnly: _locked,
                    keyboardType: TextInputType.number,
                    errorText: repsProblem == null
                        ? null
                        : context.digits(_repsErrorText(l10n, repsProblem)),
                    minusKey: ValueKey<String>('${widget.rowKey}-reps-minus'),
                    plusKey: ValueKey<String>('${widget.rowKey}-reps-plus'),
                    minusTooltip: l10n.decreaseReps,
                    plusTooltip: l10n.increaseReps,
                    onMinus: _canDecreaseReps ? () => _stepReps(-1) : null,
                    onPlus: _canIncreaseReps ? () => _stepReps(1) : null,
                    onChanged: (_) => setState(() => _repsProblem = null),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Row(
                    children: <Widget>[
                      Text(
                        l10n.rirLabel,
                        style: const TextStyle(
                          color: AppTokens.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      RirInfoButton(
                        buttonKey: ValueKey<String>(
                          '${widget.rowKey}-rir-info',
                        ),
                        compact: true,
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          context.digits(
                            _rir == null
                                ? l10n.rirHintShort
                                : rirDescription(l10n, _rir),
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: _rir == null
                                    ? AppTokens.textSecondary
                                    : AppTokens.accent,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space1),
                  _RirScale(
                    rowKey: widget.rowKey,
                    selected: _rir,
                    onSelected: _locked ? null : _toggleRir,
                  ),
                  if (_saveFailed) ...<Widget>[
                    const SizedBox(height: AppTokens.space1),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        l10n.saveFailed,
                        style: const TextStyle(color: AppTokens.danger),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaved(
    BuildContext context,
    AppLocalizations l10n,
    SetLog saved,
  ) {
    final ThemeData theme = Theme.of(context);
    final String weight = context.digits(
      formatWeight(saved.weightGrams, widget.unit),
    );
    final String rir = saved.rir == null
        ? ''
        : saved.rir == maximumStoredRir
        ? 'RIR ${l10n.rirFivePlus}'
        : l10n.rirSummary(saved.rir!);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space1),
      child: Semantics(
        container: true,
        label: context.digits(
          '${l10n.setNumber(widget.setNumber)} · $weight '
          '${weightUnitLabel(context, widget.unit)} × ${saved.reps}',
        ),
        child: Container(
          key: ValueKey<String>('${widget.rowKey}-summary'),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppTokens.space2,
            AppTokens.space1,
            AppTokens.spaceHalf,
            AppTokens.space1,
          ),
          decoration: BoxDecoration(
            color: AppTokens.surface2,
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            border: Border.all(color: AppTokens.accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: <Widget>[
              _SetBadge(number: widget.setNumber, saved: true),
              const SizedBox(width: AppTokens.space1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Wrap(
                      spacing: 5,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: <Widget>[
                        Text(
                          weight,
                          key: ValueKey<String>(
                            '${widget.rowKey}-summary-weight',
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: 2),
                          child: Text(
                            weightUnitLabel(context, widget.unit),
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            bottom: 1,
                            start: 2,
                            end: 2,
                          ),
                          child: Text('×', style: theme.textTheme.labelMedium),
                        ),
                        Text(
                          context.digits('${saved.reps}'),
                          key: ValueKey<String>(
                            '${widget.rowKey}-summary-reps',
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        if (saved.isWarmup)
                          _SavedMetaChip(
                            icon: Icons.local_fire_department_outlined,
                            label: l10n.warmupLabel,
                          ),
                        if (rir.isNotEmpty)
                          KeyedSubtree(
                            key: ValueKey<String>(
                              '${widget.rowKey}-summary-rir',
                            ),
                            child: _SavedMetaChip(
                              icon: Icons.timelapse,
                              label: context.digits(rir),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.check_circle,
                              color: AppTokens.accent,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.setSaved,
                              key: ValueKey<String>('${widget.rowKey}-saved'),
                              style: const TextStyle(
                                color: AppTokens.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (_personalRecords.isNotEmpty)
                          PrBadge(
                            key: ValueKey<String>('${widget.rowKey}-pr'),
                            types: _personalRecords,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.onEdit != null || widget.onDelete != null)
                PopupMenuButton<String>(
                  key: ValueKey<String>('${widget.rowKey}-actions'),
                  tooltip: l10n.setActions,
                  onSelected: (String action) {
                    if (action == 'edit') {
                      widget.onEdit?.call(saved);
                    } else {
                      widget.onDelete?.call(saved);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          key: ValueKey<String>('${widget.rowKey}-edit'),
                          value: 'edit',
                          child: Text(l10n.editSet),
                        ),
                        PopupMenuItem<String>(
                          key: ValueKey<String>('${widget.rowKey}-delete'),
                          value: 'delete',
                          child: Text(l10n.deleteSet),
                        ),
                      ],
                  icon: const Icon(Icons.more_vert),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedMetaChip extends StatelessWidget {
  const _SavedMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 1),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface3,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: AppTokens.textSecondary),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SetBadge extends StatelessWidget {
  const _SetBadge({required this.number, required this.saved});

  final int number;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 32,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppTokens.space1,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: saved ? AppTokens.accent.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(
          color: saved ? AppTokens.accentDeep : AppTokens.outline,
        ),
      ),
      child: Text(
        context.digits(number.toString().padLeft(2, '0')),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: saved ? AppTokens.accent : AppTokens.textPrimary,
          fontWeight: FontWeight.w700,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _WarmupToggle extends StatelessWidget {
  const _WarmupToggle({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTokens.minTouchTarget),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppTokens.space1,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppTokens.accent.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              border: Border.all(
                color: selected ? AppTokens.accent : AppTokens.outlineStrong,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.local_fire_department_outlined,
                  size: 14,
                  color: selected ? AppTokens.accent : AppTokens.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? AppTokens.accent
                        : AppTokens.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckSquare extends StatelessWidget {
  const _CheckSquare({
    required this.rowKey,
    required this.saving,
    required this.onTap,
    required this.tooltip,
  });

  final String rowKey;
  final bool saving;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          key: ValueKey<String>('$rowKey-check'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: Container(
            width: AppTokens.minTouchTarget,
            height: AppTokens.minTouchTarget,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accent,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTokens.onAccent,
                    ),
                  )
                : const Icon(Icons.check, color: AppTokens.onAccent, size: 24),
          ),
        ),
      ),
    );
  }
}

class _NumberDeck extends StatelessWidget {
  const _NumberDeck({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.readOnly,
    required this.keyboardType,
    required this.minusKey,
    required this.plusKey,
    required this.minusTooltip,
    required this.plusTooltip,
    required this.onMinus,
    required this.onPlus,
    required this.onChanged,
    this.unitLabel,
    this.errorText,
  });

  final String label;
  final String? unitLabel;
  final Key fieldKey;
  final TextEditingController controller;
  final bool readOnly;
  final TextInputType keyboardType;
  final Key minusKey;
  final Key plusKey;
  final String minusTooltip;
  final String plusTooltip;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTokens.surface2,
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            border: Border(
              bottom: BorderSide(
                color: errorText == null
                    ? AppTokens.outlineStrong
                    : AppTokens.danger,
                width: errorText == null ? 1 : 2,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              _StepButton(
                key: minusKey,
                tooltip: minusTooltip,
                icon: Icons.remove,
                onTap: onMinus,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 4),
                    Text(
                      unitLabel == null ? label : '$label · $unitLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                    TextField(
                      key: fieldKey,
                      controller: controller,
                      readOnly: readOnly,
                      keyboardType: keyboardType,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: context.digits('0'),
                        contentPadding: const EdgeInsetsDirectional.symmetric(
                          vertical: 2,
                        ),
                      ),
                      onChanged: onChanged,
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
              _StepButton(
                key: plusKey,
                tooltip: plusTooltip,
                icon: Icons.add,
                onTap: onPlus,
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: Text(
              errorText!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTokens.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        minimumSize: const Size(
          AppTokens.minTouchTarget,
          AppTokens.minTouchTarget,
        ),
        foregroundColor: AppTokens.textPrimary,
        disabledForegroundColor: AppTokens.textSecondary.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}

class _RirScale extends StatelessWidget {
  const _RirScale({
    required this.rowKey,
    required this.selected,
    required this.onSelected,
  });

  final String rowKey;
  final int? selected;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: AppTokens.outlineStrong),
      ),
      child: Column(
        children: <Widget>[
          for (int row = 0; row < 2; row += 1) ...<Widget>[
            if (row > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppTokens.outlineStrong,
              ),
            Row(
              children: <Widget>[
                for (int column = 0; column < 3; column += 1) ...<Widget>[
                  if (column > 0)
                    const SizedBox(
                      width: 1,
                      height: AppTokens.minTouchTarget,
                      child: ColoredBox(color: AppTokens.outlineStrong),
                    ),
                  Expanded(
                    child: _RirCell(
                      key: ValueKey<String>('$rowKey-rir-${row * 3 + column}'),
                      value: row * 3 + column,
                      selected: selected == row * 3 + column,
                      label: context.digits(
                        row * 3 + column == maximumStoredRir
                            ? l10n.rirFivePlus
                            : row * 3 + column,
                      ),
                      onTap: onSelected == null
                          ? null
                          : () => onSelected!(row * 3 + column),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RirCell extends StatelessWidget {
  const _RirCell({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final int value;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppTokens.minTouchTarget,
          ),
          alignment: Alignment.center,
          color: selected ? AppTokens.accent : Colors.transparent,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTokens.onAccent : AppTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionBlock extends StatelessWidget {
  const _SuggestionBlock({
    required this.rowKey,
    required this.suggestion,
    required this.unit,
    required this.onRevert,
    this.initialWeightGrams,
    this.initialReps,
  });

  final String rowKey;
  final ProgressionSuggestion suggestion;
  final WeightUnit unit;
  final VoidCallback onRevert;
  final int? initialWeightGrams;
  final int? initialReps;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Container(
      key: ValueKey<String>('$rowKey-suggestion'),
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppTokens.space2,
        AppTokens.space1,
        AppTokens.space2,
        0,
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTokens.space1,
        AppTokens.space1,
        AppTokens.space1,
        AppTokens.space1,
      ),
      decoration: const BoxDecoration(
        color: AppTokens.surface2,
        border: BorderDirectional(
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
            progressionReasonText(context, suggestion, unit),
            key: ValueKey<String>('$rowKey-suggestion-reason'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (initialWeightGrams != null && initialReps != null) ...<Widget>[
            const SizedBox(height: 4),
            Wrap(
              spacing: AppTokens.space1,
              runSpacing: AppTokens.space1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  context.digits(
                    l10n.progressionLastSession(
                      formatWeight(initialWeightGrams!, unit),
                      initialReps!,
                    ),
                  ),
                  key: ValueKey<String>('$rowKey-suggestion-last'),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTokens.textSecondary),
                ),
                TextButton(
                  key: ValueKey<String>('$rowKey-suggestion-revert'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      AppTokens.minTouchTarget,
                      AppTokens.minTouchTarget,
                    ),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppTokens.space1,
                    ),
                  ),
                  onPressed: onRevert,
                  child: Text(l10n.progressionUseLastSession),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
