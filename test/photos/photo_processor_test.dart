import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/photo_processor.dart';
import 'package:image/image.dart' as image;

void main() {
  test('a geotagged source is downscaled and every metadata block is gone', () {
    final Uint8List sourceBytes = File('test/fixtures/photos/geotagged.jpg')
        .readAsBytesSync();
    final image.Image source = image.decodeJpg(sourceBytes)!;
    expect(source.width, 2400);
    expect(source.height, 1800);
    expect(source.exif.gpsIfd.isEmpty, isFalse);

    final ProcessedPhoto result = processPhotoBytes(sourceBytes);
    final image.Image stored = image.decodeJpg(result.bytes)!;

    expect(stored.width, 1600);
    expect(stored.height, 1200);
    expect(result.width, 1600);
    expect(result.height, 1200);
    expect(stored.exif.gpsIfd.isEmpty, isTrue);
    expect(stored.exif.isEmpty, isTrue);
    expect(
      String.fromCharCodes(result.bytes).contains('GymLog Test Camera'),
      isFalse,
      reason: 'the stored copy must not carry the source camera metadata',
    );
    expect(result.bytes.length, lessThan(sourceBytes.length));
  });

  test('an unreadable payload is rejected without producing bytes', () {
    expect(
      () => processPhotoBytes(Uint8List.fromList(<int>[1, 2, 3, 4])),
      throwsA(isA<PhotoProcessingException>()),
    );
  });
}
