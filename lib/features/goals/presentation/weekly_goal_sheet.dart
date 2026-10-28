import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/square_switch.dart';

/// The values the goal sheet hands back. Both null means "remove the goal".
class WeeklyGoalDraft {
  const WeeklyGoalDraft({required this.sessionGoal, required this.setGoal});

  final int? sessionGoal;
  final int? setGoal;

  bool get isEmpty => sessionGoal == null && setGoal == null;
}

/// Opens the weekly-goal editor and returns the chosen values, or null when the
/// user dismissed it without saving.
Future<WeeklyGoalDraft?> showWeeklyGoalSheet(
  BuildContext context, {
  required AppSettings settings,
}) {
  return showModalBottomSheet<WeeklyGoalDraft>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) =>
        _WeeklyGoalSheet(settings: settings),
  );
}

class _WeeklyGoalSheet extends StatefulWidget {
  const _WeeklyGoalSheet({required this.settings});

  final AppSettings settings;

  @override
  State<_WeeklyGoalSheet> createState() => _WeeklyGoalSheetState();
}

class _WeeklyGoalSheetState extends State<_WeeklyGoalSheet> {
  late int _sessions =
      widget.settings.weeklySessionGoal ?? defaultWeeklySessionGoal;
  late int _sets = widget.settings.weeklySetGoal ?? defaultWeeklySetGoal;
  late bool _sessionsEnabled;
  late bool _setsEnabled;

  @override
  void initState() {
    super.initState();
    // A brand-new goal starts with both targets on. An existing document may
    // legitimately carry only one target; keep the other off instead of
    // silently adding a goal the user never chose.
    final bool hasGoal = widget.settings.hasWeeklyGoal;
    _sessionsEnabled = !hasGoal || widget.settings.weeklySessionGoal != null;
    _setsEnabled = !hasGoal || widget.settings.weeklySetGoal != null;
  }

  bool get _hasGoal => widget.settings.hasWeeklyGoal;

  void _stepSessions(int delta) {
    setState(() {
      _sessions = (_sessions + delta).clamp(
        minimumWeeklySessionGoal,
        maximumWeeklySessionGoal,
      );
    });
  }

  void _stepSets(int delta) {
    setState(() {
      _sets = (_sets + delta).clamp(minimumWeeklySetGoal, maximumWeeklySetGoal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTokens.surface,
            border: Border(top: BorderSide(color: AppTokens.outlineStrong)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTokens.space3,
              AppTokens.space2,
              AppTokens.space3,
              AppTokens.space3,
            ),
            child: SingleChildScrollView(
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
                        child: Text(
                          l10n.goalSheetTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: l10n.close,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space1),
                  Text(
                    l10n.goalSheetBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space3),
                  _GoalStepper(
                    label: l10n.goalSessionTargetLabel,
                    value: context.digits('$_sessions'),
                    enabled: _sessionsEnabled,
                    stepLabel: l10n.goalSessionsLabel,
                    enabledLabel: l10n.goalEnabled,
                    onEnabledChanged: (bool enabled) =>
                        setState(() => _sessionsEnabled = enabled),
                    enabledKey: const Key('goal-session-enabled'),
                    onMinus: _sessions > minimumWeeklySessionGoal
                        ? () => _stepSessions(-1)
                        : null,
                    onPlus: _sessions < maximumWeeklySessionGoal
                        ? () => _stepSessions(1)
                        : null,
                    minusKey: const Key('goal-session-minus'),
                    plusKey: const Key('goal-session-plus'),
                  ),
                  const SizedBox(height: AppTokens.space1),
                  _GoalStepper(
                    label: l10n.goalSetTargetLabel,
                    value: context.digits('$_sets'),
                    enabled: _setsEnabled,
                    stepLabel: l10n.goalSetsLabel,
                    enabledLabel: l10n.goalEnabled,
                    onEnabledChanged: (bool enabled) =>
                        setState(() => _setsEnabled = enabled),
                    enabledKey: const Key('goal-set-enabled'),
                    onMinus: _sets > minimumWeeklySetGoal
                        ? () => _stepSets(-1)
                        : null,
                    onPlus: _sets < maximumWeeklySetGoal
                        ? () => _stepSets(1)
                        : null,
                    minusKey: const Key('goal-set-minus'),
                    plusKey: const Key('goal-set-plus'),
                  ),
                  const SizedBox(height: AppTokens.space3),
                  Row(
                    children: <Widget>[
                      if (_hasGoal)
                        TextButton(
                          key: const Key('goal-remove'),
                          onPressed: () => Navigator.of(context).pop(
                            const WeeklyGoalDraft(
                              sessionGoal: null,
                              setGoal: null,
                            ),
                          ),
                          child: Text(l10n.goalRemove),
                        ),
                      const Spacer(),
                      FilledButton(
                        key: const Key('goal-save'),
                        onPressed: () => Navigator.of(context).pop(
                          WeeklyGoalDraft(
                            sessionGoal: _sessionsEnabled ? _sessions : null,
                            setGoal: _setsEnabled ? _sets : null,
                          ),
                        ),
                        child: Text(l10n.save),
                      ),
                    ],
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

class _GoalStepper extends StatelessWidget {
  const _GoalStepper({
    required this.label,
    required this.value,
    required this.enabled,
    required this.stepLabel,
    required this.enabledLabel,
    required this.onEnabledChanged,
    required this.enabledKey,
    required this.onMinus,
    required this.onPlus,
    required this.minusKey,
    required this.plusKey,
  });

  final String label;
  final String value;
  final bool enabled;
  final String stepLabel;
  final String enabledLabel;
  final ValueChanged<bool> onEnabledChanged;
  final Key enabledKey;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final Key minusKey;
  final Key plusKey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTokens.space2,
        AppTokens.space1,
        AppTokens.space1,
        AppTokens.space1,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surface2,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(label, style: theme.textTheme.labelMedium)),
              Tooltip(
                message: enabledLabel,
                child: SquareSwitch(
                  key: enabledKey,
                  value: enabled,
                  onChanged: onEnabledChanged,
                  semanticLabel: enabledLabel,
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text(
                value,
                key: ValueKey<String>('goal-value-$stepLabel'),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: enabled ? AppTokens.accent : AppTokens.textSecondary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                key: minusKey,
                onPressed: enabled ? onMinus : null,
                tooltip: stepLabel,
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                key: plusKey,
                onPressed: enabled ? onPlus : null,
                tooltip: stepLabel,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
