import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `null` follows the device locale; a value is an explicit in-session choice.
final NotifierProvider<LocaleOverrideController, Locale?>
localeOverrideProvider = NotifierProvider<LocaleOverrideController, Locale?>(
  LocaleOverrideController.new,
);

class LocaleOverrideController extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void select(Locale locale) => state = locale;
}
