import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/l10n/l10n.dart';
import '../data/photo_index_controller.dart';
import 'digit_style_scope.dart';
import 'locale_override.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class GymLogApp extends ConsumerWidget {
  const GymLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale? localeOverride = ref.watch(localeOverrideProvider);
    // Drains image_picker's lost-data cache on every start. Recovery attaches
    // a file only when a pending target survived (`PHO-001`).
    ref.listen(photoRecoveryProvider, (_, _) {});

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      locale: localeOverride,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      localeListResolutionCallback: _resolveLocale,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      builder: (BuildContext context, Widget? child) =>
          AppDigitStyleScope(child: child ?? const SizedBox.shrink()),
      routerConfig: ref.watch(routerProvider),
    );
  }

  static Locale _resolveLocale(
    List<Locale>? deviceLocales,
    Iterable<Locale> supportedLocales,
  ) {
    for (final locale in deviceLocales ?? const <Locale>[]) {
      if (locale.languageCode == 'fa') {
        return const Locale('fa');
      }
    }
    return const Locale('en');
  }
}
