import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;

/// Longest stored edge for a photo (`PHO-002` downscaling).
const int photoMaxDimension = 1600;

/// JPEG quality for the re-encoded stored copy.
const int photoJpegQuality = 85;

/// Refuses absurd source files before decoding; camera originals stay below
/// this bound, and the picker already resizes its temporary copy.
const int photoMaximumSourceBytes = 40 * 1024 * 1024;

/// A decoded, downscaled, metadata-free copy ready for private storage.
class ProcessedPhoto {
  const ProcessedPhoto({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Raised when an image cannot be decoded or encoded. The message never
/// includes a path or image content.
class PhotoProcessingException implements Exception {
  const PhotoProcessingException();

  @override
  String toString() => 'PhotoProcessingException';
}

/// Decodes [source], applies EXIF orientation, downscales the longest edge to
/// [photoMaxDimension], clears every metadata directory (including GPS), and
/// re-encodes as JPEG.
///
/// Re-encoding a decoded pixel buffer drops EXIF, XMP, and thumbnails that were
/// present in the source. Clearing [image.Image.exif] explicitly prevents the
/// JPEG encoder from writing those tags back (`PHO-002`).
ProcessedPhoto processPhotoBytes(Uint8List source) {
  if (source.isEmpty || source.length > photoMaximumSourceBytes) {
    throw const PhotoProcessingException();
  }

  final image.Image decoded;
  try {
    final image.Image? result = image.decodeImage(source);
    if (result == null || result.width < 1 || result.height < 1) {
      throw const PhotoProcessingException();
    }
    decoded = result;
  } catch (error) {
    if (error is PhotoProcessingException) {
      rethrow;
    }
    throw const PhotoProcessingException();
  }

  try {
    final image.Image oriented = image.bakeOrientation(decoded);
    final int longest = math.max(oriented.width, oriented.height);
    final image.Image resized;
    if (longest > photoMaxDimension) {
      final double scale = photoMaxDimension / longest;
      final int width = math.max(1, (oriented.width * scale).round());
      final int height = math.max(1, (oriented.height * scale).round());
      resized = image.copyResize(
        oriented,
        width: width,
        height: height,
        interpolation: image.Interpolation.linear,
      );
    } else {
      resized = oriented;
    }

    // The source may carry GPS, device, or thumbnail metadata. The encoder
    // writes image.exif back into the JPEG, so clear it after resizing.
    resized.exif = image.ExifData();

    final Uint8List encoded = image.encodeJpg(
      resized,
      quality: photoJpegQuality,
    );
    if (encoded.isEmpty) {
      throw const PhotoProcessingException();
    }
    return ProcessedPhoto(
      bytes: encoded,
      width: resized.width,
      height: resized.height,
    );
  } catch (error) {
    if (error is PhotoProcessingException) {
      rethrow;
    }
    throw const PhotoProcessingException();
  }
}
