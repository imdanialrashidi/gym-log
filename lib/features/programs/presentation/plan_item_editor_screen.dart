import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/document_gate.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/action_runner.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/number_input.dart';
import '../../../core/widgets/text_empty_state.dart';
import '../../../data/app_data_controller.dart';

class PlanItemEditorScreen extends ConsumerStatefulWidget {
  const PlanItemEditorScreen({
    required this.dayId,
    required this.itemId,
    super.key,
  });

  final String dayId;
  final String itemId;

  @override
  ConsumerState<PlanItemEditorScreen> createState() =>
      _PlanItemEditorScreenState();
}

class _PlanItemEditorScreenState extends ConsumerState<PlanItemEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _targetSets = TextEditingController();
  final TextEditingController _repMin = TextEditingController();
  final TextEditingController _repMax = TextEditingController();
  String? _exerciseId;
  bool _initialized = false;
  bool _saving = false;

  bool get _isNew => widget.itemId == 'new';

  @override
  void dispose() {
    _targetSets.dispose();
    _repMin.dispose();
    _repMax.dispose();
    super.dispose();
  }

  void _initialize(PlanItem? item, BuildContext context) {
    _targetSets.text = context.digits(item?.targetSets ?? 3);
    _repMin.text = context.digits(item?.repMin ?? 8);
    _repMax.text = context.digits(item?.repMax ?? 12);
    _exerciseId = item?.exerciseId;
    _initialized = true;
  }

  String? _validateSets(String? value) {
    final int? parsed = int.tryParse(normalizeDigits(value?.trim() ?? ''));
    if (parsed == null) {
      return context.l10n.errorNumberRequired;
    }
    if (parsed < 1 || parsed > 20) {
      return context.digits(context.l10n.errorSetsRange);
    }
    return null;
  }

  String? _validateRepMin(String? value) {
    final int? parsed = int.tryParse(normalizeDigits(value?.trim() ?? ''));
    if (parsed == null) {
      return context.l10n.errorNumberRequired;
    }
    if (parsed < minimumReps || parsed > maximumReps) {
      return context.digits(context.l10n.errorRepRange);
    }
    return null;
  }

  String? _validateRepMax(String? value) {
    final int? parsed = int.tryParse(normalizeDigits(value?.trim() ?? ''));
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

  Future<void> _pickExercise(FormFieldState<String> field) async {
    final Exercise? picked = await context.push<Exercise>(
      AppRoutes.exercisePicker,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _exerciseId = picked.id);
    field.didChange(picked.id);
    field.validate();
  }

  Future<void> _save(PlanItem? existing) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String? exerciseId = _exerciseId;
    if (exerciseId == null) {
      return;
    }
    final int? sets = int.tryParse(normalizeDigits(_targetSets.text.trim()));
    final int? repMin = int.tryParse(normalizeDigits(_repMin.text.trim()));
    final int? repMax = int.tryParse(normalizeDigits(_repMax.text.trim()));
    if (sets == null || repMin == null || repMax == null) {
      return;
    }
    setState(() => _saving = true);
    final bool saved = await runDataAction(context, () async {
      final AppDataController controller = ref.read(
        appDataControllerProvider.notifier,
      );
      if (existing == null) {
        await controller.addPlanItem(
          dayId: widget.dayId,
          exerciseId: exerciseId,
          targetSets: sets,
          repMin: repMin,
          repMax: repMax,
        );
      } else {
        await controller.updatePlanItem(
          existing.copyWith(
            exerciseId: exerciseId,
            targetSets: sets,
            repMin: repMin,
            repMax: repMax,
          ),
        );
      }
    });
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() => _saving = false);
    } else if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> _delete(PlanItem item) async {
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await confirmDestructive(
      context,
      title: l10n.deletePlanItemTitle,
      message: l10n.deletePlanItemBody,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final bool saved = await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .deletePlanItem(widget.dayId, item.id),
    );
    if (saved && mounted && context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return DocumentGate(
      fallbackTitle: l10n.newPlanItemTitle,
      builder: (BuildContext context, AppData data) {
        final ProgramDay? day = data.dayById(widget.dayId);
        PlanItem? existing;
        if (!_isNew && day != null) {
          for (final PlanItem candidate in day.items) {
            if (candidate.id == widget.itemId) {
              existing = candidate;
            }
          }
        }
        if (day == null || (!_isNew && existing == null)) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.newPlanItemTitle)),
            body: TextEmptyState(message: l10n.planItemNotFound),
          );
        }
        if (!_initialized) {
          _initialize(existing, context);
        }
        return _buildForm(context, l10n, data, existing);
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    AppData data,
    PlanItem? existing,
  ) {
    final Exercise? selected = _exerciseId == null
        ? null
        : data.exerciseById(_exerciseId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.newPlanItemTitle : l10n.editPlanItemTitle),
        actions: <Widget>[
          if (existing != null)
            IconButton(
              tooltip: l10n.delete,
              onPressed: () => _delete(existing),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.space2),
          children: <Widget>[
            Text(
              l10n.exerciseLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.space1),
            FormField<String>(
              initialValue: _exerciseId,
              validator: (String? value) =>
                  value == null ? l10n.errorExerciseRequired : null,
              builder: (FormFieldState<String> field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OutlinedButton.icon(
                      key: const Key('choose-exercise'),
                      onPressed: () => _pickExercise(field),
                      icon: const Icon(Icons.fitness_center),
                      label: Text(selected?.name ?? l10n.chooseExercise),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          top: AppTokens.space1,
                          start: AppTokens.space2,
                        ),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTokens.space3),
            TextFormField(
              key: const Key('target-sets-field'),
              controller: _targetSets,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[wholeNumberInput],
              decoration: InputDecoration(
                labelText: l10n.targetSetsLabel,
                errorMaxLines: 2,
              ),
              validator: _validateSets,
            ),
            const SizedBox(height: AppTokens.space2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    key: const Key('plan-rep-min-field'),
                    controller: _repMin,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[wholeNumberInput],
                    decoration: InputDecoration(
                      labelText: l10n.repMinLabel,
                      errorMaxLines: 2,
                    ),
                    validator: _validateRepMin,
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: TextFormField(
                    key: const Key('plan-rep-max-field'),
                    controller: _repMax,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[wholeNumberInput],
                    decoration: InputDecoration(
                      labelText: l10n.repMaxLabel,
                      errorMaxLines: 2,
                    ),
                    validator: _validateRepMax,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space3),
            FilledButton(
              key: const Key('save-plan-item'),
              onPressed: _saving ? null : () => _save(existing),
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
