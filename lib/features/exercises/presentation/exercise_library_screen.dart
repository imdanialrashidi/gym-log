import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/text_empty_state.dart';
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
    try {
      await ref
          .read(appDataControllerProvider.notifier)
          .setExerciseArchived(exercise.id, archived: archived);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
    }
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
              onPressed: _openEditor,
              icon: const Icon(Icons.add),
              label: Text(l10n.addExercise),
            )
          : null,
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => _LoadError(
          onRetry: () => ref.invalidate(appDataControllerProvider),
        ),
        data: (AppData data) => _buildBody(context, l10n, data),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, AppData data) {
    if (data.exercises.isEmpty) {
      return TextEmptyState(
        message: l10n.exercisesEmpty,
        action: FilledButton.icon(
          key: const Key('add-first-exercise'),
          onPressed: _openEditor,
          icon: const Icon(Icons.add),
          label: Text(l10n.addFirstExercise),
        ),
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

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppTokens.space2,
            AppTokens.space1,
            AppTokens.space2,
            0,
          ),
          child: TextField(
            key: const Key('exercise-search-field'),
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchExercisesHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.clearSearch,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (String value) => setState(() => _query = value),
          ),
        ),
        if (hasArchived)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space2,
              vertical: AppTokens.space1,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilterChip(
                key: const Key('show-archived-chip'),
                label: Text(l10n.showArchived),
                selected: _showArchived,
                onSelected: (bool selected) =>
                    setState(() => _showArchived = selected),
              ),
            ),
          ),
        Expanded(
          child: visible.isEmpty
              ? TextEmptyState(
                  message: _query.isNotEmpty
                      ? l10n.noSearchResults
                      : (!_showArchived && hasArchived)
                      ? l10n.noActiveExercises
                      : l10n.exercisesEmpty,
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: AppTokens.space2),
                  itemBuilder: (BuildContext context, int index) {
                    final Exercise exercise = visible[index];
                    return _ExerciseTile(
                      exercise: exercise,
                      onTap: () => _openEditor(exercise),
                      onLookup: () => launchExerciseLookup(
                        context,
                        ref,
                        name: exercise.name,
                        searchTerm: exercise.searchTerm,
                      ),
                      onMenuAction: (_ExerciseMenuAction action) =>
                          _onMenuAction(exercise, action),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.onTap,
    required this.onLookup,
    required this.onMenuAction,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onLookup;
  final ValueChanged<_ExerciseMenuAction> onMenuAction;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<String> subtitleParts = <String>[
      if (exercise.isArchived) l10n.archivedLabel,
      if (exercise.muscleGroup != null)
        muscleGroupLabel(l10n, exercise.muscleGroup!),
    ];

    return ListTile(
      key: ValueKey<String>('exercise-${exercise.id}'),
      title: Text(exercise.name),
      subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: l10n.lookupImages,
            icon: const Icon(Icons.image_search),
            onPressed: onLookup,
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
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return TextEmptyState(
      message: l10n.loadFailed,
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: Text(l10n.retry),
      ),
    );
  }
}
