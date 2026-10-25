import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/locale_override.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_formats.dart';
import '../../../core/widgets/number_input.dart';
import '../../../data/app_data_controller.dart';
import 'backup_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final String languageCode = Localizations.localeOf(context).languageCode;
    final String selectedLanguage = languageCode == 'fa' ? 'fa' : 'en';
    final AsyncValue<AppData> asyncData = ref.watch(appDataControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(AppTokens.space2),
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space1),
            child: Text(
              l10n.languageLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space1),
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
          const SizedBox(height: AppTokens.space2),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space1),
            child: Text(
              l10n.digitStyleLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space1),
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
              onSelectionChanged: asyncData.hasValue
                  ? (Set<DigitStyle> selection) {
                      unawaited(_setDigitStyle(context, ref, selection.single));
                    }
                  : null,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space1),
            child: Text(
              l10n.weightUnitLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space1),
            child: asyncData.when(
              loading: () => const Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (Object error, StackTrace stack) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.loadFailed,
                    style: const TextStyle(color: AppTokens.danger),
                  ),
                  const SizedBox(height: AppTokens.space1),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(appDataControllerProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
              data: (AppData data) => SegmentedButton<WeightUnit>(
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
          ),
          const SizedBox(height: AppTokens.space2),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space1),
            child: Text(
              l10n.defaultIncrementLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          asyncData.when(
            loading: () => const Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (Object error, StackTrace stack) => Padding(
              padding: const EdgeInsetsDirectional.all(AppTokens.space1),
              child: Text(
                l10n.loadFailed,
                style: const TextStyle(color: AppTokens.danger),
              ),
            ),
            data: (AppData data) {
              final WeightUnit unit = data.settings.weightUnit;
              final int grams = data.settings.incrementFor(unit);
              final String unitLabel = switch (unit) {
                WeightUnit.kilograms => l10n.unitKilograms,
                WeightUnit.pounds => l10n.unitPounds,
              };
              return ListTile(
                key: const Key('default-increment-row'),
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppTokens.space1,
                ),
                title: Text(
                  '${context.digits(formatWeight(grams, unit))} $unitLabel',
                ),
                subtitle: Text(l10n.defaultIncrementHint),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () =>
                    unawaited(_editDefaultIncrement(context, ref, unit, grams)),
              );
            },
          ),
          const SizedBox(height: AppTokens.space2),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.space1),
            child: Text(
              l10n.restTimerLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          asyncData.when(
            loading: () => const Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (Object error, StackTrace stack) => Padding(
              padding: const EdgeInsetsDirectional.all(AppTokens.space1),
              child: Text(
                l10n.loadFailed,
                style: const TextStyle(color: AppTokens.danger),
              ),
            ),
            data: (AppData data) => Column(
              children: <Widget>[
                SwitchListTile(
                  key: const Key('rest-timer-enabled'),
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppTokens.space1,
                  ),
                  title: Text(l10n.restTimerEnabled),
                  subtitle: Text(l10n.restTimerHint),
                  value: data.settings.restTimerEnabled,
                  onChanged: (bool enabled) =>
                      unawaited(_setRestTimerEnabled(context, ref, enabled)),
                ),
                Row(
                  children: <Widget>[
                    const SizedBox(width: AppTokens.space1),
                    Text(l10n.restTimerDuration),
                    const Spacer(),
                    IconButton(
                      key: const Key('rest-timer-duration-minus'),
                      tooltip: l10n.decreaseRestTimer,
                      onPressed:
                          data.settings.restTimerDurationSeconds >
                              minimumRestTimerSeconds
                          ? () => unawaited(
                              _setRestTimerDuration(
                                context,
                                ref,
                                data.settings.restTimerDurationSeconds - 15,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      context.digits(
                        formatRestDuration(
                          Duration(
                            seconds: data.settings.restTimerDurationSeconds,
                          ),
                        ),
                      ),
                      key: const Key('rest-timer-duration-value'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      key: const Key('rest-timer-duration-plus'),
                      tooltip: l10n.increaseRestTimer,
                      onPressed:
                          data.settings.restTimerDurationSeconds <
                              maximumRestTimerSeconds
                          ? () => unawaited(
                              _setRestTimerDuration(
                                context,
                                ref,
                                data.settings.restTimerDurationSeconds + 15,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          asyncData.when(
            loading: () => const SizedBox.shrink(),
            error: (Object error, StackTrace stack) => const SizedBox.shrink(),
            data: (AppData data) => BackupSection(data: data),
          ),
        ],
      ),
    );
  }

  Future<void> _setUnit(
    BuildContext context,
    WidgetRef ref,
    WeightUnit unit,
  ) async {
    try {
      await ref.read(appDataControllerProvider.notifier).setWeightUnit(unit);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
      }
    }
  }

  Future<void> _setDigitStyle(
    BuildContext context,
    WidgetRef ref,
    DigitStyle style,
  ) async {
    try {
      await ref.read(appDataControllerProvider.notifier).setDigitStyle(style);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
      }
    }
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
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .setDefaultIncrementGrams(grams);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
      }
    }
  }

  Future<void> _setRestTimerEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .setRestTimerEnabled(enabled);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
      }
    }
  }

  Future<void> _setRestTimerDuration(
    BuildContext context,
    WidgetRef ref,
    int seconds,
  ) async {
    final int clamped = seconds.clamp(
      minimumRestTimerSeconds,
      maximumRestTimerSeconds,
    );
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .setRestTimerDurationSeconds(clamped);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
      }
    }
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
    final WeightParseResult parsed = parseWeightInput(_value.text, widget.unit);
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
