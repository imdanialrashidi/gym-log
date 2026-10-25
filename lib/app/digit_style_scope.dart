import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../core/l10n/digit_style_scope.dart';
import '../data/app_data_controller.dart';

/// Resolves the digit style from persisted settings and the active locale.
///
/// Mounted by `MaterialApp.router`'s builder, so its own context sits below
/// `Localizations` even though the builder context does not.
class AppDigitStyleScope extends ConsumerWidget {
  const AppDigitStyleScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DigitStyle? explicit = ref.watch(
      appDataControllerProvider.select(
        (AsyncValue<AppData> value) => value.value?.settings.digitStyle,
      ),
    );
    final Locale locale = Localizations.localeOf(context);
    final DigitStyle style =
        explicit ??
        (locale.languageCode == 'fa' ? DigitStyle.persian : DigitStyle.latin);
    return DigitStyleScope(style: style, child: child);
  }
}
