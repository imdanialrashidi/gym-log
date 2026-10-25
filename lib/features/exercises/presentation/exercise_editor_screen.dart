import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/number_input.dart';
import '../../../core/widgets/text_empty_state.dart';
import '../../../data/app_data_controller.dart';
import '../../photos/presentation/exercise_photo_section.dart';
import 'exercise_lookup_action.dart';
import 'muscle_group_labels.dart';

/// Creates an exercise when [exerciseId] is `new`; otherwise edits the stored
/// exercise. Pops with the saved exercise so the picker can select a newly
/// created record immediately.
class ExerciseEditorScreen extends ConsumerStatefulWidget {
  const ExerciseEditorScreen({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  ConsumerState<ExerciseEditorScreen> createState() =>
      _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends ConsumerState<ExerciseEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _searchTerm = TextEditingController();
  final TextEditingController _repMin = TextEditingController();
  final TextEditingController _repMax = TextEditingController();
  final TextEditingController _increment = TextEditingController();
  MuscleGroup? _muscleGroup;
  WeightUnit _unit = WeightUnit.kilograms;
  bool _initialized = false;
  bool _saving = false;

  bool get _isNew => widget.exerciseId == 'new';

  @override
  void dispose() {
    _name.dispose();
    _searchTerm.dispose();
    _repMin.dispose();
    _repMax.dispose();
    _increment.dispose();
    super.dispose();
  }

  void _initialize(Exercise? exercise, AppData data, BuildContext context) {
    _unit = data.settings.weightUnit;
    _name.text = exercise?.name ?? '';
    _searchTerm.text = exercise?.searchTerm ?? '';
    _repMin.text = context.digits(exercise?.defaultRepMin ?? '');
    _repMax.text = context.digits(exercise?.defaultRepMax ?? '');
    _muscleGroup = exercise?.muscleGroup;
    _increment.text = context.digits(
      formatWeight(
        exercise?.incrementGrams ?? data.settings.incrementFor(_unit),
        _unit,
      ),
    );
    _initialized = true;
  }

  int? _parseOptionalInt(String value) {
    final String trimmed = normalizeDigits(value.trim());
    return trimmed.isEmpty ? null : int.tryParse(trimmed);
  }

  String? _validateRepMin(String? value) {
    final String text = normalizeDigits(value?.trim() ?? '');
    if (text.isEmpty) {
      return _repMax.text.trim().isEmpty
          ? null
          : context.l10n.errorEnterBothReps;
    }
    final int? parsed = int.tryParse(text);
    if (parsed == null) {
      return context.l10n.errorNumberRequired;
    }
    if (parsed < minimumReps || parsed > maximumReps) {
      return context.digits(context.l10n.errorRepRange);
    }
    return null;
  }

  String? _validateRepMax(String? value) {
    final String text = normalizeDigits(value?.trim() ?? '');
    if (text.isEmpty) {
      return _repMin.text.trim().isEmpty
          ? null
          : context.l10n.errorEnterBothReps;
    }
    final int? parsed = int.tryParse(text);
    if (parsed == null) {
      return context.l10n.errorNumberRequired;
    }
    if (parsed < minimumReps || parsed > maximumReps) {
      return context.digits(context.l10n.errorRepRange);
    }
    final int? min = int.tryParse(normalizeDigits(_repMin.text.trim()));
    if (min != null && min > parsed) {
      return context.l10n.errorMinExceedsMax;
    }
    return null;
  }

  int? _incrementGrams() {
    final WeightParseResult parsed = parseWeightInput(_increment.text, _unit);
    if (!parsed.isValid || parsed.grams! <= 0) {
      return null;
    }
    return parsed.grams;
  }

  Future<void> _lookup() async {
    await launchExerciseLookup(
      context,
      ref,
      name: _name.text,
      searchTerm: _searchTerm.text,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final AppData? data = ref.read(appDataControllerProvider).value;
    if (data == null) {
      return;
    }
    final Exercise? existing = _isNew
        ? null
        : data.exerciseById(widget.exerciseId);
    if (!_isNew && existing == null) {
      return;
    }
    final int? incrementGrams = _incrementGrams();
    if (incrementGrams == null) {
      return;
    }
    final String name = _name.text.trim();
    final bool duplicate = data.exercises.any(
      (Exercise exercise) =>
          exercise.id != existing?.id &&
          normalizeForSearch(exercise.name) == normalizeForSearch(name),
    );
    if (duplicate) {
      final bool saveAnyway = await _confirmDuplicate(name);
      if (!saveAnyway) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() => _saving = true);

    final String? searchTerm = _searchTerm.text.trim().isEmpty
        ? null
        : _searchTerm.text.trim();
    final int? repMin = _parseOptionalInt(_repMin.text);
    final int? repMax = _parseOptionalInt(_repMax.text);

    try {
      final Exercise saved;
      if (existing == null) {
        saved = await ref
            .read(appDataControllerProvider.notifier)
            .createExercise(
              name: name,
              searchTerm: searchTerm,
              muscleGroup: _muscleGroup,
              defaultRepMin: repMin,
              defaultRepMax: repMax,
              incrementGrams: incrementGrams,
            );
      } else {
        saved = await ref
            .read(appDataControllerProvider.notifier)
            .updateExercise(
              existing.copyWith(
                name: name,
                searchTerm: searchTerm,
                muscleGroup: _muscleGroup,
                defaultRepMin: repMin,
                defaultRepMax: repMax,
                incrementGrams: incrementGrams,
              ),
            );
      }
      if (!mounted) {
        return;
      }
      context.pop<Exercise>(saved);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
    }
  }

  Future<bool> _confirmDuplicate(String name) async {
    final AppLocalizations l10n = context.l10n;
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.duplicateExerciseNameTitle),
        content: Text(l10n.duplicateExerciseNameBody(name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('save-duplicate-exercise'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.saveAnyway),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AppData> asyncData = ref.watch(appDataControllerProvider);

    return asyncData.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.exercisesTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stack) => Scaffold(
        appBar: AppBar(title: Text(l10n.exercisesTitle)),
        body: TextEmptyState(
          message: l10n.loadFailed,
          action: OutlinedButton.icon(
            onPressed: () => ref.invalidate(appDataControllerProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ),
      ),
      data: (AppData data) {
        final Exercise? existing = _isNew
            ? null
            : data.exerciseById(widget.exerciseId);
        if (!_isNew && existing == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.exercisesTitle)),
            body: TextEmptyState(message: l10n.exerciseNotFound),
          );
        }
        if (!_initialized) {
          _initialize(existing, data, context);
        }
        return _buildForm(context, l10n, data, existing);
      },
    );
  }

  String _unitLabel(BuildContext context, WeightUnit unit) {
    return switch (unit) {
      WeightUnit.kilograms => context.l10n.unitKilograms,
      WeightUnit.pounds => context.l10n.unitPounds,
    };
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    AppData data,
    Exercise? existing,
  ) {
    final bool canLookup =
        _name.text.trim().isNotEmpty || _searchTerm.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.newExerciseTitle : l10n.editExerciseTitle),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.space2),
          children: <Widget>[
            TextFormField(
              key: const Key('exercise-name-field'),
              controller: _name,
              autofocus: _isNew,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.nameLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (String? value) =>
                  value == null || value.trim().isEmpty
                  ? l10n.errorNameRequired
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            if (existing != null) ...<Widget>[
              const SizedBox(height: AppTokens.space2),
              ExercisePhotoSection(exerciseId: existing.id),
            ],
            const SizedBox(height: AppTokens.space2),
            TextFormField(
              key: const Key('exercise-search-term-field'),
              controller: _searchTerm,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.searchTermLabel,
                helperText: l10n.searchTermHint,
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppTokens.space1),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: const Key('exercise-lookup-button'),
                onPressed: canLookup ? _lookup : null,
                icon: const Icon(Icons.image_search),
                label: Text(l10n.lookupImages),
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            DropdownButtonFormField<MuscleGroup?>(
              key: const Key('exercise-muscle-group-field'),
              initialValue: _muscleGroup,
              decoration: InputDecoration(
                labelText: l10n.muscleGroupLabel,
                border: const OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<MuscleGroup?>>[
                DropdownMenuItem<MuscleGroup?>(
                  child: Text(l10n.muscleGroupNone),
                ),
                for (final MuscleGroup group in MuscleGroup.values)
                  DropdownMenuItem<MuscleGroup?>(
                    value: group,
                    child: Text(muscleGroupLabel(l10n, group)),
                  ),
              ],
              onChanged: (MuscleGroup? value) =>
                  setState(() => _muscleGroup = value),
            ),
            const SizedBox(height: AppTokens.space3),
            Text(
              l10n.defaultRepRangeLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.space1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    key: const Key('exercise-rep-min-field'),
                    controller: _repMin,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[wholeNumberInput],
                    decoration: InputDecoration(
                      labelText: l10n.repMinLabel,
                      errorMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                    validator: _validateRepMin,
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: TextFormField(
                    key: const Key('exercise-rep-max-field'),
                    controller: _repMax,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[wholeNumberInput],
                    decoration: InputDecoration(
                      labelText: l10n.repMaxLabel,
                      errorMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                    validator: _validateRepMax,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space2),
            TextFormField(
              key: const Key('exercise-increment-field'),
              controller: _increment,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[decimalNumberInput],
              decoration: InputDecoration(
                labelText: l10n.incrementLabel,
                suffixText: _unitLabel(context, data.settings.weightUnit),
                helperText:
                    existing == null &&
                        data.settings.defaultIncrementGrams == null
                    ? context.digits(l10n.incrementDefaultHint)
                    : null,
                errorMaxLines: 2,
                border: const OutlineInputBorder(),
              ),
              validator: (String? value) =>
                  _incrementGrams() == null ? l10n.errorIncrement : null,
            ),
            const SizedBox(height: AppTokens.space3),
            FilledButton(
              key: const Key('save-exercise'),
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
