import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_tokens.dart';

/// A text-only empty state. M0 deliberately ships no imagery.
class TextEmptyState extends StatelessWidget {
  const TextEmptyState({required this.message, this.action, super.key});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppTokens.space3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppTokens.textSecondary),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: AppTokens.space2),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
