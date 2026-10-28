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
import '../../../core/widgets/app_backdrop.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/app_data_controller.dart';
import 'exercise_lookup_action.dart';
import 'muscle_group_labels.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

enum _ExerciseMenuAction { edit, archive, unarchive }

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _showArchived = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditor([Exercise? exercise]) async {
    await context.push<Exercise>(
      AppRoutes.exerciseEditor(exercise?.id ?? 'new'),
    );
  }

  Future<void> _setArchived(Exercise exercise, {required bool archived}) async {
    await runDataAction(
      context,
      () => ref
          .read(appDataControllerProvider.notifier)
          .setExerciseArchived(exercise.id, archived: archived),
    );
  }

  void _onMenuAction(Exercise exercise, _ExerciseMenuAction action) {
    switch (action) {
      case _ExerciseMenuAction.edit:
        _openEditor(exercise);
      case _ExerciseMenuAction.archive:
        _setArchived(exercise, archived: true);
      case _ExerciseMenuAction.unarchive:
        _setArchived(exercise, archived: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AppData> asyncData = ref.watch(appDataControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exercisesTitle)),
      floatingActionButton: asyncData.value?.exercises.isNotEmpty ?? false
          ? FloatingActionButton.extended(
              key: const Key('add-exercise-fab'),
              elevation: 0,
              shape: const RoundedRectangleBorder(),
              onPressed: _openEditor,
              icon: const Icon(Icons.add),
              label: Text(l10n.addExercise),
            )
          : null,
      body: AppBackdrop(
        child: DocumentGate(
          builder: (BuildContext context, AppData data) =>
              _buildBody(context, l10n, data),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, AppData data) {
    final double padding = AppTokens.pagePadding(
      MediaQuery.sizeOf(context).width,
    );
    if (data.exercises.isEmpty) {
      return ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          padding,
          AppTokens.space2,
          padding,
          AppTokens.space4,
        ),
        children: <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.exercisesEmpty,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTokens.space1),
                Text(
                  l10n.exerciseLibrarySubtitle,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTokens.textSecondary),
                ),
                const SizedBox(height: AppTokens.space2),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('add-first-exercise'),
                    onPressed: _openEditor,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addFirstExercise),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final List<Exercise> source = _showArchived
        ? data.exercises
        : data.activeExercises;
    final List<Exercise> visible = <Exercise>[
      for (final Exercise exercise in source)
        if (matchesSearchQuery(exercise.name, _query)) exercise,
    ];
    final bool hasArchived = data.exercises.any(
      (Exercise exercise) => exercise.isArchived,
    );
    final Map<String, ExerciseTrainingStats> stats = exerciseTrainingStatsMap(
      sessions: data.sessions,
      exerciseIds: visible.map((Exercise exercise) => exercise.id),
    );

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding,
            AppTokens.space2,
            padding,
            0,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.digits(
                    l10n.exerciseLibraryCount(data.exercises.length),
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTokens.accent,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasArchived)
                _ArchiveToggle(
                  key: const Key('show-archived-chip'),
                  selected: _showArchived,
                  label: l10n.showArchived,
                  onTap: () => setState(() => _showArchived = !_showArchived),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding,
            AppTokens.space1,
            padding,
            0,
          ),
          child: _SearchBar(
            controller: _searchController,
            hint: l10n.searchExercisesHint,
            clearTooltip: l10n.clearSearch,
            onChanged: (String value) => setState(() => _query = value),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
            showClear: _query.isNotEmpty,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsetsDirectional.all(padding),
                    child: Text(
                      _query.isNotEmpty
                          ? l10n.noSearchResults
                          : (!_showArchived && hasArchived)
                          ? l10n.noActiveExercises
                          : l10n.exercisesEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppTokens.textSecondary),
                    ),
                  ),
                )
              : ListView(
                  key: const Key('exercise-list'),
                  padding: EdgeInsetsDirectional.fromSTEB(
                    padding,
                    0,
                    padding,
                    AppTokens.space6 + AppTokens.space3,
                  ),
                  children: <Widget>[
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: <Widget>[
                          for (
                            int index = 0;
                            index < visible.length;
                            index += 1
                          )
                            _ExerciseRow(
                              key: ValueKey<String>(
                                'exercise-${visible[index].id}',
                              ),
                              exercise: visible[index],
                              stats: stats[visible[index].id],
                              showDivider: index < visible.length - 1,
                              onTap: () => _openEditor(visible[index]),
                              onLookup: () => launchExerciseLookup(
                                context,
                                ref,
                                name: visible[index].name,
                                searchTerm: visible[index].searchTerm,
                              ),
                              onMenuAction: (_ExerciseMenuAction action) =>
                                  _onMenuAction(visible[index], action),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ArchiveToggle extends StatelessWidget {
  const _ArchiveToggle({
    required this.selected,
    required this.label,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppTokens.minTouchTarget,
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppTokens.space1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                selected ? Icons.visibility : Icons.visibility_outlined,
                size: 16,
                color: selected ? AppTokens.accent : AppTokens.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? AppTokens.accent : AppTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

  final TextEditingController controller;
  final String hint;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.outline),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: AppTokens.space2),
          const Icon(Icons.search, size: 20, color: AppTokens.textSecondary),
          const SizedBox(width: AppTokens.space1),
          Expanded(
            child: TextField(
              key: const Key('exercise-search-field'),
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  vertical: AppTokens.space2,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
          if (showClear)
            IconButton(
              tooltip: clearTooltip,
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.stats,
    required this.showDivider,
    required this.onTap,
    required this.onLookup,
    required this.onMenuAction,
    super.key,
  });

  final Exercise exercise;
  final ExerciseTrainingStats? stats;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onLookup;
  final ValueChanged<_ExerciseMenuAction> onMenuAction;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool trained = stats != null && stats!.sessionCount > 0;
    final String meta = trained
        ? context.digits(
            '${l10n.exerciseListMeta(stats!.sessionCount, stats!.workingSetCount)}'
            ' · ${l10n.progressLastTrained(context.formatDate(stats!.lastTrainedAt!))}',
          )
        : l10n.exerciseNeverTrained;
    return Column(
      children: <Widget>[
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTokens.space2,
              AppTokens.space1,
              AppTokens.space1,
              AppTokens.space1,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _muscleTone(exercise.muscleGroup)
                        .withValues(alpha: 0.1),
                    border: Border.all(
                      color: _muscleTone(exercise.muscleGroup)
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    Icons.adjust,
                    size: 15,
                    color: _muscleTone(exercise.muscleGroup),
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (_subtitle(l10n) != null)
                        Text(
                          _subtitle(l10n)!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: exercise.isArchived
                                ? AppTokens.highlight
                                : AppTokens.accent,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.lookupImages,
                  onPressed: onLookup,
                  icon: const Icon(Icons.image_search, size: 20),
                ),
                PopupMenuButton<_ExerciseMenuAction>(
                  tooltip: l10n.moreActions,
                  onSelected: onMenuAction,
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<_ExerciseMenuAction>>[
                        PopupMenuItem<_ExerciseMenuAction>(
                          value: _ExerciseMenuAction.edit,
                          child: Text(l10n.edit),
                        ),
                        PopupMenuItem<_ExerciseMenuAction>(
                          value: exercise.isArchived
                              ? _ExerciseMenuAction.unarchive
                              : _ExerciseMenuAction.archive,
                          child: Text(
                            exercise.isArchived ? l10n.unarchive : l10n.archive,
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: AppTokens.space2,
            endIndent: AppTokens.space2,
          ),
      ],
    );
  }

  String? _subtitle(AppLocalizations l10n) {
    final List<String> parts = <String>[
      if (exercise.isArchived) l10n.archivedLabel,
      if (exercise.muscleGroup != null)
        muscleGroupLabel(l10n, exercise.muscleGroup!),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Color _muscleTone(MuscleGroup? group) {
    if (group == null) {
      return AppTokens.textSecondary;
    }
    return group.index.isEven ? AppTokens.accent : AppTokens.info;
  }
}
