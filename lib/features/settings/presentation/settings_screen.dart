import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/document_gate.dart';
import '../../../app/locale_override.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/action_runner.dart';
import '../../../core/widgets/app_backdrop.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_formats.dart';
import '../../../core/widgets/number_input.dart';
import '../../../data/app_data_controller.dart';
import '../../goals/presentation/weekly_goal_sheet.dart';
import 'backup_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final String languageCode = Localizations.localeOf(context).languageCode;
    final String selectedLanguage = languageCode == 'fa' ? 'fa' : 'en';
    // The digit style is persisted, so the control stays disabled until the
    // document loads; the gate below owns the failure surface.
    final bool dataLoaded = ref.watch(appDataControllerProvider).hasValue;
    final double padding = AppTokens.pagePadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: AppBackdrop(
        child: ListView(
          key: const Key('settings-list'),
          padding: EdgeInsetsDirectional.fromSTEB(
            padding,
            AppTokens.space2,
            padding,
            AppTokens.space4,
          ),
          children: <Widget>[
            _SettingsGroup(
              title: l10n.settingsAppearanceSection,
              children: <Widget>[
                _ControlRow(
                  title: l10n.languageLabel,
                  child: SegmentedButton<String>(
                    segments: <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'fa',
                        label: Text(l10n.languagePersian),
                      ),
                      ButtonSegment<String>(
                        value: 'en',
                        label: Text(l10n.languageEnglish),
                      ),
                    ],
                    selected: <String>{selectedLanguage},
                    onSelectionChanged: (Set<String> selection) {
                      ref
                          .read(localeOverrideProvider.notifier)
                          .select(Locale(selection.single));
                    },
                  ),
                ),
                _ControlRow(
                  title: l10n.digitStyleLabel,
                  child: SegmentedButton<DigitStyle>(
                    key: const Key('digit-style-control'),
                    segments: <ButtonSegment<DigitStyle>>[
                      ButtonSegment<DigitStyle>(
                        value: DigitStyle.persian,
                        label: Text(l10n.digitStylePersian),
                      ),
                      ButtonSegment<DigitStyle>(
                        value: DigitStyle.latin,
                        label: Text(l10n.digitStyleLatin),
                      ),
                    ],
                    selected: <DigitStyle>{DigitStyleScope.of(context)},
                    onSelectionChanged: dataLoaded
                        ? (Set<DigitStyle> selection) {
                            unawaited(
                              _setDigitStyle(context, ref, selection.single),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space2),
            DocumentGate(
              builder: (BuildContext context, AppData data) => Column(
                children: <Widget>[
                  _SettingsGroup(
                    title: l10n.settingsTrainingSection,
                    children: <Widget>[
                      _ControlRow(
                        title: l10n.weightUnitLabel,
                        child: SegmentedButton<WeightUnit>(
                          key: const Key('weight-unit-control'),
                          segments: <ButtonSegment<WeightUnit>>[
                            ButtonSegment<WeightUnit>(
                              value: WeightUnit.kilograms,
                              label: Text(l10n.unitKilograms),
                            ),
                            ButtonSegment<WeightUnit>(
                              value: WeightUnit.pounds,
                              label: Text(l10n.unitPounds),
                            ),
                          ],
                          selected: <WeightUnit>{data.settings.weightUnit},
                          onSelectionChanged: (Set<WeightUnit> selection) {
                            unawaited(_setUnit(context, ref, selection.single));
                          },
                        ),
                      ),
                      _LinkRow(
                        key: const Key('default-increment-row'),
                        icon: Icons.straighten,
                        title: l10n.defaultIncrementLabel,
                        value:
                            '${context.digits(formatWeight(data.settings.incrementFor(data.settings.weightUnit), data.settings.weightUnit))} '
                            '${switch (data.settings.weightUnit) {
                              WeightUnit.kilograms => l10n.unitKilograms,
                              WeightUnit.pounds => l10n.unitPounds,
                            }}',
                        subtitle: l10n.defaultIncrementHint,
                        onTap: () => unawaited(
                          _editDefaultIncrement(
                            context,
                            ref,
                            data.settings.weightUnit,
                            data.settings.incrementFor(
                              data.settings.weightUnit,
                            ),
                          ),
                        ),
                      ),
                      _SwitchRow(
                        icon: Icons.timer_outlined,
                        title: l10n.restTimerEnabled,
                        subtitle: l10n.restTimerHint,
                        value: data.settings.restTimerEnabled,
                        onChanged: (bool enabled) => unawaited(
                          _setRestTimerEnabled(context, ref, enabled),
                        ),
                      ),
                      _DurationRow(
                        title: l10n.restTimerDuration,
                        value: context.digits(
                          formatRestDuration(
                            Duration(
                              seconds: data.settings.restTimerDurationSeconds,
                            ),
                          ),
                        ),
                        onMinus:
                            data.settings.restTimerDurationSeconds >
                                minimumRestTimerSeconds
                            ? () => unawaited(
                                _adjustRestTimerDuration(context, ref, -15),
                              )
                            : null,
                        onPlus:
                            data.settings.restTimerDurationSeconds <
                                maximumRestTimerSeconds
                            ? () => unawaited(
                                _adjustRestTimerDuration(context, ref, 15),
                              )
                            : null,
                      ),
                      _LinkRow(
                        key: const Key('weekly-goal-row'),
                        icon: Icons.flag_outlined,
                        title: l10n.goalWeeklyTitle,
                        value: _goalValue(context, l10n, data.settings),
                        subtitle: l10n.goalSettingsSubtitle,
                        onTap: () =>
                            unawaited(_editGoal(context, ref, data.settings)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space2),
                  _SettingsGroup(
                    title: l10n.settingsDataSection,
                    children: <Widget>[
                      BackupSection(data: data, showHeading: false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            AppCard(
              key: const Key('open-about'),
              onTap: () => unawaited(context.push(AppRoutes.about)),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppTokens.textSecondary,
                  ),
                  const SizedBox(width: AppTokens.space2),
                  Expanded(
                    child: Text(
                      l10n.aboutTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _goalValue(
    BuildContext context,
    AppLocalizations l10n,
    AppSettings settings,
  ) {
    if (!settings.hasWeeklyGoal) {
      return l10n.settingsNoGoal;
    }
    final int? sessions = settings.weeklySessionGoal;
    final int? sets = settings.weeklySetGoal;
    if (sessions != null && sets != null) {
      return context.digits(l10n.settingsGoalValue(sessions, sets));
    }
    if (sessions != null) {
      return context.digits('$sessions ${l10n.goalSessionsLabel}');
    }
    return context.digits('$sets ${l10n.goalSetsLabel}');
  }

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final WeeklyGoalDraft? draft = await showWeeklyGoalSheet(
      context,
      settings: settings,
    );
    if (draft == null || !context.mounted) {
      return;
    }
    final AppDataController controller = ref.read(
      appDataControllerProvider.notifier,
    );
    final bool saved = await runDataAction(context, () {
      if (draft.isEmpty) {
        return controller.clearWeeklyGoals();
      }
      return controller.setWeeklyGoals(
        sessionGoal: draft.sessionGoal,
        setGoal: draft.setGoal,
      );
    });
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.goalSaved)));
    }
  }

  Future<void> _setUnit(
    BuildContext context,
    WidgetRef ref,
    WeightUnit unit,
  ) async {
    await runDataAction(
      context,
      () => ref.read(appDataControllerProvider.notifier).setWeightUnit(unit),
    );
  }

  Future<void> _setDigitStyle(
    BuildContext context,
    WidgetRef ref,
    DigitStyle style,
  ) async {
    await runDataAction(
      context,
      () => ref.read(appDataControllerProvider.notifier).setDigitStyle(style),
    );
  }

  Future<void> _editDefaultIncrement(
    BuildContext context,
    WidgetRef ref,
    WeightUnit unit,
    int currentGrams,
  ) async {
    final int? grams = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _DefaultIncrementDialog(unit: unit, initialGrams: currentGrams),
    );
    if (grams == null || !context.mounted) {
      return;
    }
    final int? explicit = ref
        .read(appDataControllerProvider)
        .requireValue
        .settings
        .defaultIncrementGrams;
    if (grams == currentGrams && explicit == null) {
      return;
    }
    await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .setDefaultIncrementGrams(grams),
    );
  }

  Future<void> _setRestTimerEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .setRestTimerEnabled(enabled),
    );
  }

  Future<void> _adjustRestTimerDuration(
    BuildContext context,
    WidgetRef ref,
    int delta,
  ) async {
    await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .adjustRestTimerDurationSeconds(delta),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTokens.space2,
              AppTokens.space2,
              AppTokens.space2,
              AppTokens.space1,
            ),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (int index = 0; index < children.length; index += 1) ...<Widget>[
            if (index > 0)
              const Divider(
                height: 1,
                indent: AppTokens.space2,
                endIndent: AppTokens.space2,
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTokens.space2,
        AppTokens.space2,
        AppTokens.space2,
        AppTokens.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppTokens.space1),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    super.key,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppTokens.space2,
          AppTokens.space2,
          AppTokens.space2,
          AppTokens.space2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: AppTokens.textSecondary),
            const SizedBox(width: AppTokens.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTokens.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.space1),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTokens.space2,
        AppTokens.space1,
        AppTokens.space1,
        AppTokens.space1,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: AppTokens.textSecondary),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            key: const Key('rest-timer-enabled'),
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DurationRow extends StatelessWidget {
  const _DurationRow({
    required this.title,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String title;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTokens.space2,
        AppTokens.space1,
        AppTokens.space1,
        AppTokens.space1,
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.hourglass_empty,
            size: 20,
            color: AppTokens.textSecondary,
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          IconButton(
            key: const Key('rest-timer-duration-minus'),
            tooltip: context.l10n.decreaseRestTimer,
            onPressed: onMinus,
            icon: const Icon(Icons.remove, size: 20),
          ),
          Text(
            value,
            key: const Key('rest-timer-duration-value'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            key: const Key('rest-timer-duration-plus'),
            tooltip: context.l10n.increaseRestTimer,
            onPressed: onPlus,
            icon: const Icon(Icons.add, size: 20),
          ),
        ],
      ),
    );
  }
}

class _DefaultIncrementDialog extends StatefulWidget {
  const _DefaultIncrementDialog({
    required this.unit,
    required this.initialGrams,
  });

  final WeightUnit unit;
  final int initialGrams;

  @override
  State<_DefaultIncrementDialog> createState() =>
      _DefaultIncrementDialogState();
}

class _DefaultIncrementDialogState extends State<_DefaultIncrementDialog> {
  late final TextEditingController _value = TextEditingController(
    text: context.digits(formatWeight(widget.initialGrams, widget.unit)),
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
    if (!parsed.isValid || parsed.grams! <= 0) {
      setState(() => _error = context.l10n.errorIncrement);
      return;
    }
    Navigator.of(context).pop(parsed.grams);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String unitLabel = switch (widget.unit) {
      WeightUnit.kilograms => l10n.unitKilograms,
      WeightUnit.pounds => l10n.unitPounds,
    };

    return AlertDialog(
      title: Text(l10n.defaultIncrementDialogTitle),
      content: TextField(
        key: const Key('default-increment-field'),
        controller: _value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[decimalNumberInput],
        decoration: InputDecoration(
          labelText: l10n.defaultIncrementLabel,
          suffixText: unitLabel,
          errorText: _error,
          errorMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() => _error = null),
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('default-increment-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('default-increment-save'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
