import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/document_gate.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/calendar/calendar_service.dart';
import '../../../core/l10n/digit_style_scope.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/action_runner.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/app_data_controller.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  Future<void> _addProgram(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final String? name = await showNameDialog(
      context,
      title: l10n.newProgramTitle,
      label: l10n.programNameLabel,
      maxLength: maximumProgramNameLength,
    );
    if (name == null || !context.mounted) {
      return;
    }
    Program? program;
    final bool saved = await runDataAction(context, () async {
      program = await ref
          .read(appDataControllerProvider.notifier)
          .createProgram(name);
    });
    if (!saved || program == null || !context.mounted) {
      return;
    }
    await context.push(AppRoutes.programEditor(program!.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AppData> asyncData = ref.watch(appDataControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: asyncData.hasValue
          ? FloatingActionButton.extended(
              key: const Key('add-program-fab'),
              elevation: 0,
              shape: const RoundedRectangleBorder(),
              onPressed: () => _addProgram(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.addProgram),
            )
          : null,
      body: DocumentGate(
        builder: (BuildContext context, AppData data) {
          final double padding = AppTokens.pagePadding(
            MediaQuery.sizeOf(context).width,
          );
          return ListView(
            key: const Key('programs-list'),
            padding: EdgeInsetsDirectional.fromSTEB(
              padding,
              AppTokens.space2,
              padding,
              AppTokens.space6 + AppTokens.space3,
            ),
            children: <Widget>[
              _LibraryPanel(
                exerciseCount: data.activeExercises.length,
                onTap: () => context.push(AppRoutes.exercises),
              ),
              const SizedBox(height: AppTokens.space4),
              _ProgramsHeading(count: data.programs.length),
              const SizedBox(height: AppTokens.space1),
              if (data.programs.isEmpty)
                _EmptyPrograms(onAdd: () => _addProgram(context, ref))
              else
                for (int index = 0; index < data.programs.length; index += 1)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppTokens.space2,
                    ),
                    child: _ProgramCard(
                      key: ValueKey<String>(
                        'program-${data.programs[index].id}',
                      ),
                      program: data.programs[index],
                      sessions: data.sessions,
                      onTap: () => context.push(
                        AppRoutes.programEditor(data.programs[index].id),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _LibraryPanel extends StatelessWidget {
  const _LibraryPanel({required this.exerciseCount, required this.onTap});

  final int exerciseCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return AppCard(
      key: const Key('open-exercise-library'),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accent.withValues(alpha: 0.1),
              border: Border.all(
                color: AppTokens.accent.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 21,
              color: AppTokens.accent,
            ),
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.exerciseLibraryTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.digits(l10n.exerciseLibraryCount(exerciseCount)),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}

class _ProgramsHeading extends StatelessWidget {
  const _ProgramsHeading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            l10n.programsSectionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(context.digits('$count'), style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _EmptyPrograms extends StatelessWidget {
  const _EmptyPrograms({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.programsEmpty,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTokens.space1),
          Text(
            l10n.programEmptyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('add-first-program'),
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addProgram),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.sessions,
    required this.onTap,
    super.key,
  });

  final Program program;
  final List<Session> sessions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final int exerciseCount = program.days.fold<int>(
      0,
      (int total, ProgramDay day) => total + day.items.length,
    );
    final int setCount = program.days.fold<int>(
      0,
      (int total, ProgramDay day) =>
          total +
          day.items.fold<int>(
            0,
            (int sets, PlanItem item) => sets + item.targetSets,
          ),
    );
    final Set<String> dayIds = <String>{
      for (final ProgramDay day in program.days) day.id,
    };
    DateTime? lastTrained;
    for (final Session session in sessions) {
      if (session.isActive ||
          session.programDayId == null ||
          !dayIds.contains(session.programDayId)) {
        continue;
      }
      if (lastTrained == null || session.startedAt.isAfter(lastTrained)) {
        lastTrained = session.startedAt;
      }
    }
    return AppCard(
      key: ValueKey<String>('program-card-${program.id}'),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 20,
                  color: AppTokens.accent,
                ),
              ),
              const SizedBox(width: AppTokens.space1 + AppTokens.spaceHalf),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      program.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.digits(
                        '${l10n.programDaysCount(program.days.length)} · '
                        '${l10n.programExercisesCount(exerciseCount)}'
                        '${setCount == 0 ? '' : ' · ${l10n.programSetsCount(setCount)}'}',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
          if (program.days.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppTokens.space2),
            Wrap(
              spacing: AppTokens.space1,
              runSpacing: AppTokens.space1,
              children: <Widget>[
                for (final ProgramDay day in program.days.take(4))
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppTokens.space1,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.surface2,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                    child: Text(
                      day.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTokens.textPrimary,
                      ),
                    ),
                  ),
                if (program.days.length > 4)
                  Text(
                    '+${context.digits('${program.days.length - 4}')}',
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppTokens.space1),
          Text(
            lastTrained == null
                ? l10n.programNeverTrained
                : context.digits(
                    l10n.progressLastTrained(context.formatDate(lastTrained)),
                  ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: lastTrained == null
                  ? AppTokens.textSecondary
                  : AppTokens.accent,
            ),
          ),
        ],
      ),
    );
  }
}
