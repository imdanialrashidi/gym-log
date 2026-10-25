import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/text_empty_state.dart';
import '../../../data/app_data_controller.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  Future<void> _addProgram(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final String? name = await showNameDialog(
      context,
      title: l10n.newProgramTitle,
      label: l10n.programNameLabel,
    );
    if (name == null || !context.mounted) {
      return;
    }
    try {
      final Program program = await ref
          .read(appDataControllerProvider.notifier)
          .createProgram(name);
      if (context.mounted) {
        await context.push(AppRoutes.programEditor(program.id));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AppData> asyncData = ref.watch(appDataControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: asyncData.value == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('add-program-fab'),
              onPressed: () => _addProgram(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.addProgram),
            ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => TextEmptyState(
          message: l10n.loadFailed,
          action: OutlinedButton.icon(
            onPressed: () => ref.invalidate(appDataControllerProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ),
        data: (AppData data) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: <Widget>[
              ListTile(
                key: const Key('open-exercise-library'),
                leading: const Icon(Icons.fitness_center),
                title: Text(l10n.exercisesTitle),
                subtitle: Text(l10n.exerciseLibrarySubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.exercises),
              ),
              const Divider(height: 1),
              if (data.programs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppTokens.space3),
                  child: TextEmptyState(
                    message: l10n.programsEmpty,
                    action: FilledButton.icon(
                      key: const Key('add-first-program'),
                      onPressed: () => _addProgram(context, ref),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addProgram),
                    ),
                  ),
                )
              else
                for (final Program program in data.programs)
                  ListTile(
                    key: ValueKey<String>('program-${program.id}'),
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(program.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push(AppRoutes.programEditor(program.id)),
                  ),
            ],
          );
        },
      ),
    );
  }
}
