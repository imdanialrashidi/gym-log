import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';

/// The flat canvas behind every route.
///
/// Obsidian Telemetry rejects ambient glows, gradients, and blur. The backdrop
/// is a single solid color so content contrast never depends on a painted
/// effect; the class remains the one place a future structural canvas texture
/// would live.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // A Material ancestor keeps list-tile ink and splash painting correct; a
    // bare ColoredBox would hide them (and trip the ListTile assertion).
    return Material(color: AppTokens.background, child: child);
  }
}
