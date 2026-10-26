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
      builder: (BuildContext context, Widget? child) => _StartupTasks(
        child: AppDigitStyleScope(child: child ?? const SizedBox.shrink()),
      ),
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

/// Starts background recovery after the first frame.
///
/// Photo recovery drains image_picker's lost-data cache and prunes orphan
/// files. It must still run on every start (`PHO-001`), but it is not needed
/// for the first paint, so it no longer competes with the document load and
/// the initial frame.
class _StartupTasks extends ConsumerStatefulWidget {
  const _StartupTasks({required this.child});

  final Widget child;

  @override
  ConsumerState<_StartupTasks> createState() => _StartupTasksState();
}

class _StartupTasksState extends ConsumerState<_StartupTasks> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) {
        return;
      }
      _started = true;
      ref.read(photoRecoveryProvider);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
