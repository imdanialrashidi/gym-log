import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';

/// Drag handle for `ReorderableListView` rows. Kept at the 48 dp touch target
/// and labelled for accessibility.
class ReorderHandle extends StatelessWidget {
  const ReorderHandle({required this.index, required this.label, super.key});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Tooltip(
        message: label,
        child: const SizedBox(
          width: AppTokens.minTouchTarget,
          height: AppTokens.minTouchTarget,
          child: Icon(Icons.drag_handle),
        ),
      ),
    );
  }
}
