import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'photo_processor.dart';

enum PhotoSource { camera, gallery }

/// Camera or gallery through a system intent. Returning `null` means the user
/// cancelled; failures throw [PhotoPickException].
abstract interface class PhotoPicker {
  Future<File?> pick(PhotoSource source);

  /// Recovers a result lost when Android killed the activity while the system
  /// picker or camera intent was in front of the app.
  Future<File?> retrieveLost();
}

/// No path or platform exception text is carried, so callers cannot log it.
class PhotoPickException implements Exception {
  const PhotoPickException();

  @override
  String toString() => 'PhotoPickException';
}

/// Android implementation backed by `image_picker` 1.2.4.
///
/// No Android permission is requested: picks use the system document UI /
/// Photo Picker and the camera uses `MediaStore.ACTION_IMAGE_CAPTURE`. The
/// plugin resizes the temporary copy, and the app re-encodes it again with GPS
/// metadata cleared.
class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker({ImagePicker? picker, bool? android})
    : _picker = picker ?? ImagePicker(),
      _android = android ?? Platform.isAndroid;

  final ImagePicker _picker;
  final bool _android;

  @override
  Future<File?> pick(PhotoSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: photoMaxDimension.toDouble(),
        maxHeight: photoMaxDimension.toDouble(),
        imageQuality: photoJpegQuality,
        requestFullMetadata: false,
      );
      return file == null ? null : File(file.path);
    } catch (_) {
      throw const PhotoPickException();
    }
  }

  @override
  Future<File?> retrieveLost() async {
    if (!_android) {
      return null;
    }
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) {
        return null;
      }
      final List<XFile>? files = response.files;
      final XFile? recovered = files != null && files.isNotEmpty
          ? files.first
          : response.file;
      if (recovered == null) {
        throw const PhotoPickException();
      }
      return File(recovered.path);
    } catch (error) {
      if (error is PhotoPickException) {
        rethrow;
      }
      throw const PhotoPickException();
    }
  }
}
