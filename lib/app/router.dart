import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/exercises/presentation/exercise_editor_screen.dart';
import '../features/exercises/presentation/exercise_library_screen.dart';
import '../features/exercises/presentation/exercise_picker_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/history/presentation/session_detail_screen.dart';
import '../features/programs/presentation/day_editor_screen.dart';
import '../features/programs/presentation/plan_item_editor_screen.dart';
import '../features/programs/presentation/program_editor_screen.dart';
import '../features/programs/presentation/programs_screen.dart';
import '../features/progress/presentation/exercise_progress_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/settings/presentation/about_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/workout/presentation/workout_screen.dart';
import 'routes.dart';

final Provider<GoRouter> routerProvider = Provider<GoRouter>((_) {
  return buildRouter();
});

/// Builds the app router. Tests start at a feature route without changing the
/// production graph.
GoRouter buildRouter({String initialLocation = '/workout'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/workout',
                builder: (BuildContext context, GoRouterState state) =>
                    const WorkoutScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/programs',
                builder: (BuildContext context, GoRouterState state) =>
                    const ProgramsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/history',
                builder: (BuildContext context, GoRouterState state) =>
                    const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/progress',
                builder: (BuildContext context, GoRouterState state) =>
                    const ProgressScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (BuildContext context, GoRouterState state) =>
            const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.exercises,
        builder: (BuildContext context, GoRouterState state) =>
            const ExerciseLibraryScreen(),
      ),
      GoRoute(
        path: '/exercise-editor/:exerciseId',
        builder: (BuildContext context, GoRouterState state) =>
            ExerciseEditorScreen(
              exerciseId: state.pathParameters['exerciseId']!,
            ),
      ),
      GoRoute(
        path: AppRoutes.exercisePicker,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          return ExercisePickerScreen(
            excludedExerciseIds: extra is Set<String>
                ? extra
                : const <String>{},
          );
        },
      ),
      GoRoute(
        path: '/program-editor/:programId',
        builder: (BuildContext context, GoRouterState state) =>
            ProgramEditorScreen(programId: state.pathParameters['programId']!),
      ),
      GoRoute(
        path: '/day-editor/:programId/:dayId',
        builder: (BuildContext context, GoRouterState state) => DayEditorScreen(
          programId: state.pathParameters['programId']!,
          dayId: state.pathParameters['dayId']!,
        ),
      ),
      GoRoute(
        path: '/plan-item-editor/:dayId/:itemId',
        builder: (BuildContext context, GoRouterState state) =>
            PlanItemEditorScreen(
              dayId: state.pathParameters['dayId']!,
              itemId: state.pathParameters['itemId']!,
            ),
      ),
      GoRoute(
        path: '/session/:sessionId',
        builder: (BuildContext context, GoRouterState state) =>
            SessionDetailScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/progress/:exerciseId',
        builder: (BuildContext context, GoRouterState state) =>
            ExerciseProgressScreen(
              exerciseId: state.pathParameters['exerciseId']!,
            ),
      ),
    ],
  );
}
