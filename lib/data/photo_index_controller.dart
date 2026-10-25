import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lift_core/lift_core.dart';

import 'app_data_controller.dart';
import 'photo_picker_service.dart';
import 'photo_storage.dart';

/// Filesystem-backed index of private photos.
///
/// Loading is non-destructive. The destructive orphan prune runs once at
/// startup, and imports explicitly prune; deleting a photo or session removes
/// its exact files. Watching a stable identity fingerprint keeps a logged set
/// from rescanning the photo directory.
final AsyncNotifierProvider<PhotoIndexController, PhotoIndex>
photoIndexProvider = AsyncNotifierProvider<PhotoIndexController, PhotoIndex>(
  PhotoIndexController.new,
  retry: (int retryCount, Object error) => null,
);

String _photoIdentityFingerprint(AsyncValue<AppData> value) {
  final AppData? data = value.value;
  if (data == null) {
    return '';
  }
  final StringBuffer buffer = StringBuffer();
  for (final Exercise exercise in data.exercises) {
    buffer
      ..write('e:')
      ..write(exercise.id)
      ..write(';');
  }
  for (final Session session in data.sessions) {
    buffer
      ..write('s:')
      ..write(session.id)
      ..write(';');
  }
  return buffer.toString();
}

void clearPhotoImageCache() {
  PaintingBinding.instance.imageCache
    ..clear()
    ..clearLiveImages();
}

class PhotoIndexController extends AsyncNotifier<PhotoIndex> {
  @override
  Future<PhotoIndex> build() async {
    final PhotoStorage storage = ref.watch(photoStorageProvider);
    ref.watch(
      appDataControllerProvider.select<String>(_photoIdentityFingerprint),
    );
    if (ref.read(appDataControllerProvider).value == null) {
      await ref.read(appDataControllerProvider.future);
    }
    return storage.load();
  }

  Future<void> addExercisePhoto(String exerciseId, File source) async {
    final PhotoIndex next = await ref
        .read(photoStorageProvider)
        .importExercisePhoto(exerciseId: exerciseId, source: source);
    _setIndex(next);
  }

  Future<void> addSessionPhoto(String sessionId, File source) async {
    final PhotoIndex next = await ref
        .read(photoStorageProvider)
        .importSessionPhoto(sessionId: sessionId, source: source);
    _setIndex(next);
  }

  Future<void> removeExercisePhoto(String exerciseId) async {
    final PhotoIndex next = await ref
        .read(photoStorageProvider)
        .removeExercisePhoto(exerciseId);
    _setIndex(next);
  }

  Future<void> removeSessionPhoto(String sessionId, int slot) async {
    final PhotoIndex next = await ref
        .read(photoStorageProvider)
        .removeSessionPhoto(sessionId: sessionId, slot: slot);
    _setIndex(next);
  }

  void _setIndex(PhotoIndex next) {
    state = AsyncData<PhotoIndex>(next);
    clearPhotoImageCache();
  }
}

/// One-shot startup recovery required by image_picker for Android activity
/// death, plus the orphan prune for files left by a failed previous deletion
/// or a Replace import. It runs even when nothing is pending so the plugin's
/// lost-data cache is drained.
///
/// The initial data read deliberately uses `read`, not `watch`: a later save
/// must not re-run recovery and clear a pending marker while the system picker
/// is in front of the app.
final FutureProvider<PhotoRecoveryOutcome> photoRecoveryProvider =
    FutureProvider<PhotoRecoveryOutcome>((Ref ref) async {
      final PhotoStorage storage = ref.watch(photoStorageProvider);
      final AppData data = await ref.read(appDataControllerProvider.future);
      final Set<String> exerciseIds = <String>{
        for (final Exercise exercise in data.exercises) exercise.id,
      };
      final Set<String> sessionIds = <String>{
        for (final Session session in data.sessions) session.id,
      };
      try {
        await storage.pruneAndLoad(
          exerciseIds: exerciseIds,
          sessionIds: sessionIds,
        );
        ref.invalidate(photoIndexProvider);
      } catch (_) {
        // The destructive prune is retried on the next start or index load.
      }

      final PhotoPickerService service = ref.watch(photoPickerServiceProvider);
      final PhotoRecoveryOutcome outcome = await service.recover(
        exerciseIds: exerciseIds,
        sessionIds: sessionIds,
      );
      if (outcome == PhotoRecoveryOutcome.recovered) {
        clearPhotoImageCache();
        ref.invalidate(photoIndexProvider);
      }
      return outcome;
    });
