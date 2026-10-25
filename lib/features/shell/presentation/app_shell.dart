import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/l10n.dart';
import 'export_reminder_banner.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<String> titles = <String>[
      l10n.workoutTab,
      l10n.programsTab,
      l10n.historyTab,
      l10n.progressTab,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[navigationShell.currentIndex]),
        actions: <Widget>[
          IconButton(
            onPressed: () => unawaited(context.push('/settings')),
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const ExportReminderBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        animationDuration: AppTokens.motionFast,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.fitness_center),
            label: l10n.workoutTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.programsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.historyTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart),
            label: l10n.progressTab,
          ),
        ],
      ),
    );
  }
}
