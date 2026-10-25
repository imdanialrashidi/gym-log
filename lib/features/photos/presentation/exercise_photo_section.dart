import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/photo_index_controller.dart';
import '../../../data/photo_storage.dart';
import 'photo_actions.dart';
import 'photo_failure_text.dart';
import 'photo_thumbnail.dart';
import 'photo_viewer_screen.dart';

/// Optional exercise photo in the exercise editor (`EXR-005`, `PHO-002`).
class ExercisePhotoSection extends ConsumerWidget {
  const ExercisePhotoSection({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<PhotoIndex> asyncIndex = ref.watch(photoIndexProvider);

    return Padding(
      key: const Key('exercise-photo-section'),
      padding: const EdgeInsetsDirectional.only(bottom: AppTokens.space2),
      child: asyncIndex.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (Object error, StackTrace stack) => Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.photoLoadFailed,
                style: const TextStyle(color: AppTokens.danger),
              ),
            ),
            TextButton(
              key: const Key('retry-exercise-photo'),
              onPressed: () => ref.invalidate(photoIndexProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
        data: (PhotoIndex index) => _buildContent(context, ref, index),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, PhotoIndex index) {
    final AppLocalizations l10n = context.l10n;
    final String? fileName = index.exerciseFileName(exerciseId);
    final File? file = fileName == null ? null : index.file(fileName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.exercisePhotoLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTokens.space1),
        Wrap(
          spacing: AppTokens.space1,
          runSpacing: AppTokens.space1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (file != null)
              PhotoThumbnail(
                key: const Key('exercise-photo-thumbnail'),
                file: file,
                label: l10n.exercisePhotoLabel,
                onTap: () => _openViewer(context, ref, file),
              ),
            OutlinedButton.icon(
              key: const Key('add-exercise-photo'),
              onPressed: () async {
                await addExercisePhoto(context, ref, exerciseId);
              },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(file == null ? l10n.addPhoto : l10n.changePhoto),
            ),
            if (file != null)
              TextButton.icon(
                key: const Key('remove-exercise-photo'),
                onPressed: () async {
                  await _remove(context, ref);
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.removePhoto),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.photoPrivateHint,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppTokens.textSecondary),
        ),
      ],
    );
  }

  Future<void> _openViewer(
    BuildContext context,
    WidgetRef ref,
    File file,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext routeContext) => PhotoViewerScreen(
          file: file,
          onRemove: () async {
            await ref
                .read(photoIndexProvider.notifier)
                .removeExercisePhoto(exerciseId);
            return true;
          },
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await confirmDestructive(
      context,
      title: l10n.removePhotoTitle,
      message: l10n.removePhotoBody,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(photoIndexProvider.notifier)
          .removeExercisePhoto(exerciseId);
    } on PhotoStorageException catch (error) {
      if (context.mounted) {
        _showFailure(context, photoFailureMessage(context, error));
      }
    } catch (_) {
      if (context.mounted) {
        _showFailure(context, l10n.photoDeleteFailed);
      }
    }
  }

  void _showFailure(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
