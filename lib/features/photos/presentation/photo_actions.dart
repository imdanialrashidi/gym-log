import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/photo_index_controller.dart';
import '../../../data/photo_pending_store.dart';
import '../../../data/photo_picker.dart';
import '../../../data/photo_picker_service.dart';
import '../../../data/photo_storage.dart';
import 'photo_failure_text.dart';

Future<PhotoSource?> showPhotoSourceSheet(BuildContext context) {
  final AppLocalizations l10n = context.l10n;
  return showModalBottomSheet<PhotoSource>(
    context: context,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              key: const Key('photo-source-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.camera),
            ),
            ListTile(
              key: const Key('photo-source-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.gallery),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> addSessionPhoto(
  BuildContext context,
  WidgetRef ref,
  String sessionId,
) {
  return _addPhoto(
    context,
    ref,
    target: PhotoTarget.session(sessionId),
    importPhoto: (File file) =>
        ref.read(photoIndexProvider.notifier).addSessionPhoto(sessionId, file),
  );
}

Future<void> addExercisePhoto(
  BuildContext context,
  WidgetRef ref,
  String exerciseId,
) {
  return _addPhoto(
    context,
    ref,
    target: PhotoTarget.exercise(exerciseId),
    importPhoto: (File file) => ref
        .read(photoIndexProvider.notifier)
        .addExercisePhoto(exerciseId, file),
  );
}

Future<void> _addPhoto(
  BuildContext context,
  WidgetRef ref, {
  required PhotoTarget target,
  required Future<void> Function(File file) importPhoto,
}) async {
  final PhotoSource? source = await showPhotoSourceSheet(context);
  if (source == null || !context.mounted) {
    return;
  }

  final PhotoPickerService service = ref.read(photoPickerServiceProvider);
  File? picked;
  try {
    picked = await service.pick(source: source, target: target);
    if (picked == null) {
      return;
    }
    await importPhoto(picked);
  } on PhotoPickException {
    if (context.mounted) {
      _showFailure(context, context.l10n.photoPickFailed);
    }
  } on PhotoStorageException catch (error) {
    if (context.mounted) {
      _showFailure(context, photoFailureMessage(context, error));
    }
  } catch (_) {
    if (context.mounted) {
      _showFailure(context, context.l10n.photoSaveFailed);
    }
  } finally {
    await service.finish();
    await service.discard(picked);
  }
}

void _showFailure(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
