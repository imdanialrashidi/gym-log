import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/document_gate.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/text_empty_state.dart';
import '../../../data/photo_index_controller.dart';
import '../../../data/photo_storage.dart';
import '../../photos/presentation/photo_thumbnail.dart';
import 'muscle_group_labels.dart';

/// Modal exercise selection with the D15 search rules. Archived exercises are
/// never offered. Creating an exercise here returns it to the caller
/// immediately so it can be used without a second selection.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({
    this.excludedExerciseIds = const <String>{},
    super.key,
  });

  /// Exercises already attached to the current workout are not offered.
  final Set<String> excludedExerciseIds;

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final Exercise? created = await context.push<Exercise>(
      AppRoutes.exerciseEditor('new'),
    );
    if (created != null && mounted) {
      context.pop<Exercise>(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final PhotoIndex? photoIndex = ref.watch(photoIndexProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exercisePickerTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.addExercise,
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: DocumentGate(
        builder: (BuildContext context, AppData data) {
          if (data.activeExercises.isEmpty) {
            final bool hasArchived = data.exercises.isNotEmpty;
            return TextEmptyState(
              message: hasArchived
                  ? l10n.noActiveExercisesPicker
                  : l10n.exercisesEmpty,
              action: FilledButton.icon(
                key: const Key('picker-add-first-exercise'),
                onPressed: _openCreate,
                icon: const Icon(Icons.add),
                label: Text(
                  hasArchived ? l10n.addExercise : l10n.addFirstExercise,
                ),
              ),
            );
          }
          final List<Exercise> available = data.activeExercises
              .where(
                (Exercise exercise) =>
                    !widget.excludedExerciseIds.contains(exercise.id),
              )
              .toList();
          if (available.isEmpty) {
            return TextEmptyState(
              message: l10n.noExercisesAvailableForSession,
              action: FilledButton.icon(
                key: const Key('picker-add-exercise'),
                onPressed: _openCreate,
                icon: const Icon(Icons.add),
                label: Text(l10n.addExercise),
              ),
            );
          }
          final List<Exercise> visible = available
              .where(
                (Exercise exercise) =>
                    matchesSearchQuery(exercise.name, _query),
              )
              .toList();
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
                  key: const Key('exercise-picker-search'),
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
                  ),
                  onChanged: (String value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? TextEmptyState(message: l10n.noSearchResults)
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final Exercise exercise = visible[index];
                          final String? photoName = photoIndex
                              ?.exerciseFileName(exercise.id);
                          return ListTile(
                            key: ValueKey<String>('picker-${exercise.id}'),
                            leading: photoName == null
                                ? null
                                : PhotoThumbnail(
                                    key: ValueKey<String>(
                                      'picker-photo-${exercise.id}',
                                    ),
                                    file: photoIndex!.file(photoName),
                                    label: l10n.exercisePhotoLabel,
                                    size: 48,
                                  ),
                            title: Text(exercise.name),
                            subtitle: exercise.muscleGroup == null
                                ? null
                                : Text(
                                    muscleGroupLabel(
                                      l10n,
                                      exercise.muscleGroup!,
                                    ),
                                  ),
                            onTap: () => context.pop<Exercise>(exercise),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
