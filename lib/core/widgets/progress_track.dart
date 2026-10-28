import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';

/// A small, direction-aware progress track.
///
/// [FractionallySizedBox] with [AlignmentDirectional.centerStart] makes the
/// fill grow from the leading edge, so the same widget reads correctly in
/// Persian RTL and English LTR. The Material progress indicator paints from
/// the physical left in both directions, which is wrong for this app.
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    required this.value,
    super.key,
    this.color = AppTokens.accent,
    this.backgroundColor = AppTokens.surface3,
    this.height = 5,
  });

  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double safe = value.isNaN ? 0 : value.clamp(0.0, 1.0);
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(color: backgroundColor),
          FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: safe,
            child: ColoredBox(color: color),
          ),
        ],
      ),
    );
  }
}
