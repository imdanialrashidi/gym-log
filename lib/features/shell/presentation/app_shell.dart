import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/brand_mark.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_backdrop.dart';
import '../../workout/presentation/workout_live_bar.dart';
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
        toolbarHeight: 64,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsetsDirectional.only(start: AppTokens.space2),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: BrandMark(size: 32, showWordmark: false),
          ),
        ),
        titleSpacing: AppTokens.space1,
        title: Text(titles[navigationShell.currentIndex]),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppTokens.space2),
            child: IconButton(
              onPressed: () => unawaited(context.push('/settings')),
              tooltip: l10n.settingsTitle,
              style: IconButton.styleFrom(
                side: const BorderSide(color: AppTokens.outlineStrong),
                shape: const RoundedRectangleBorder(),
              ),
              icon: const Icon(Icons.settings_outlined, size: 20),
            ),
          ),
        ],
      ),
      body: AppBackdrop(
        child: Column(
          children: <Widget>[
            const ExportReminderBanner(),
            const WorkoutLiveBar(),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTokens.surface,
          border: Border(top: BorderSide(color: AppTokens.outline)),
        ),
        child: NavigationBar(
          animationDuration: AppTokens.motionFast,
          backgroundColor: Colors.transparent,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (int index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.fitness_center_outlined),
              selectedIcon: const Icon(Icons.fitness_center),
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
              selectedIcon: const Icon(Icons.insights),
              label: l10n.progressTab,
            ),
          ],
        ),
      ),
    );
  }
}
