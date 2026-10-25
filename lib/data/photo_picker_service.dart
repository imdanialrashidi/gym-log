import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'photo_pending_store.dart';
import 'photo_picker.dart';
import 'photo_storage.dart';

enum PhotoRecoveryOutcome { none, recovered, discarded, failed }

/// Couples the system picker, the persisted pending target, and private
/// storage so a process restart can recover a pick without leaving partial
/// files.
class PhotoPickerService {
  const PhotoPickerService({
    required this.picker,
    required this.pending,
    required this.storage,
  });

  final PhotoPicker picker;
  final PhotoPendingStore pending;
  final PhotoStorage storage;

  /// Marks [target] as pending, launches the system UI, and returns the
  /// temporary source file. `null` means cancellation; the marker is cleared.
  Future<File?> pick({
    required PhotoSource source,
    required PhotoTarget target,
  }) async {
    try {
      await pending.write(target);
    } catch (_) {
      throw const PhotoPickException();
    }
    try {
      final File? file = await picker.pick(source);
      if (file == null) {
        await finish();
      }
      return file;
    } catch (_) {
      await finish();
      throw const PhotoPickException();
    }
  }

  /// Called after the caller has imported or rejected [pick]'s file.
  Future<void> finish() async {
    try {
      await pending.clear();
    } catch (_) {
      // Recovery clears it on the next start.
    }
  }

  /// Deletes the picker's temporary cache copy. Failures are non-fatal.
  Future<void> discard(File? file) async {
    if (file == null) {
      return;
    }
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // The OS cache owns this copy; it is never our stored photo.
    }
  }

  /// Runs at app startup. A lost file is attached only when a pending target
  /// still exists; otherwise it is discarded without writing a stored file.
  Future<PhotoRecoveryOutcome> recover({
    required Set<String> exerciseIds,
    required Set<String> sessionIds,
  }) async {
    PhotoTarget? target;
    try {
      target = await pending.read();
    } catch (_) {
      target = null;
    }

    File? lost;
    try {
      lost = await picker.retrieveLost();
    } catch (_) {
      await finish();
      return PhotoRecoveryOutcome.failed;
    }
    if (lost == null) {
      if (target != null) {
        await finish();
      }
      return PhotoRecoveryOutcome.none;
    }

    PhotoRecoveryOutcome outcome = PhotoRecoveryOutcome.discarded;
    if (target != null) {
      try {
        switch (target.kind) {
          case PhotoTargetKind.exercise:
            if (exerciseIds.contains(target.id)) {
              await storage.importExercisePhoto(
                exerciseId: target.id,
                source: lost,
              );
              outcome = PhotoRecoveryOutcome.recovered;
            }
          case PhotoTargetKind.session:
            if (sessionIds.contains(target.id)) {
              await storage.importSessionPhoto(
                sessionId: target.id,
                source: lost,
              );
              outcome = PhotoRecoveryOutcome.recovered;
            }
        }
      } on PhotoStorageException catch (error) {
        outcome = error.failure == PhotoFailure.limitReached
            ? PhotoRecoveryOutcome.discarded
            : PhotoRecoveryOutcome.failed;
      } catch (_) {
        outcome = PhotoRecoveryOutcome.failed;
      }
    }

    await finish();
    await discard(lost);
    return outcome;
  }
}

final Provider<PhotoPicker> photoPickerProvider = Provider<PhotoPicker>((
  Ref ref,
) {
  return ImagePickerPhotoPicker();
});

final Provider<PhotoPickerService> photoPickerServiceProvider =
    Provider<PhotoPickerService>((Ref ref) {
      return PhotoPickerService(
        picker: ref.watch(photoPickerProvider),
        pending: ref.watch(photoPendingStoreProvider),
        storage: ref.watch(photoStorageProvider),
      );
    });
