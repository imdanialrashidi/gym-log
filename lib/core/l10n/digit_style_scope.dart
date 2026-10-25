import 'package:flutter/widgets.dart';
import 'package:lift_core/lift_core.dart';

/// Supplies the resolved digit style to every descendant (`SET-002`,
/// `L10N-004`).
///
/// [AppDigitStyleScope] resolves the explicit setting or the UI-language
/// default and inserts this scope; widgets read it through [AppDigits].
class DigitStyleScope extends InheritedWidget {
  const DigitStyleScope({required this.style, required super.child, super.key});

  final DigitStyle style;

  static DigitStyle of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<DigitStyleScope>()
            ?.style ??
        DigitStyle.latin;
  }

  @override
  bool updateShouldNotify(DigitStyleScope oldWidget) =>
      oldWidget.style != style;
}

/// Renders numbers and digit-bearing strings in the active digit style.
extension AppDigits on BuildContext {
  /// Applies the active digit style to [value].
  String digits(Object? value) =>
      applyDigitStyle(value?.toString() ?? '', DigitStyleScope.of(this));
}
