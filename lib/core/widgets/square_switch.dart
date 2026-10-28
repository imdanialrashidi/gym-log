import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';

/// A square, mechanical toggle for the Obsidian Telemetry system.
///
/// Material's [Switch] is a pill/knob control and cannot be squared through the
/// theme. This widget keeps the same semantics and 48 dp target but uses a
/// rectangular track and a square thumb. It is used for the rest-timer and
/// weekly-goal controls; the enforced-off backup policy uses the disabled
/// state.
class SquareSwitch extends StatelessWidget {
  const SquareSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Duration duration = reduceMotion
        ? Duration.zero
        : AppTokens.motionFast;
    final Color thumb = value
        ? AppTokens.onAccent
        : enabled
        ? AppTokens.textSecondary
        : AppTokens.textMuted;

    return Semantics(
      button: true,
      enabled: enabled,
      toggled: value,
      label: semanticLabel,
      child: SizedBox(
        width: AppTokens.minTouchTarget,
        height: AppTokens.minTouchTarget,
        child: InkResponse(
          onTap: enabled ? () => onChanged!(!value) : null,
          radius: 24,
          containedInkWell: true,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppTokens.accent : AppTokens.surface3,
                border: Border.all(
                  color: value
                      ? AppTokens.accent
                      : enabled
                      ? AppTokens.outlineStrong
                      : AppTokens.outline,
                ),
              ),
              child: AnimatedAlign(
                duration: duration,
                curve: Curves.easeOut,
                alignment: value
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsetsDirectional.symmetric(horizontal: 2),
                  color: thumb,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
