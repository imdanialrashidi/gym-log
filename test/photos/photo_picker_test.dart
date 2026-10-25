import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/photo_picker.dart';
import 'package:image_picker/image_picker.dart';

class _FakeImagePicker extends ImagePicker {
  LostDataResponse response = LostDataResponse.empty();
  int retrieveCount = 0;

  @override
  Future<LostDataResponse> retrieveLostData() async {
    retrieveCount += 1;
    return response;
  }
}

void main() {
  test(
    'lost data uses the files list, then falls back to the single file',
    () async {
      final _FakeImagePicker picker = _FakeImagePicker();
      final ImagePickerPhotoPicker adapter = ImagePickerPhotoPicker(
        picker: picker,
        android: true,
      );

      picker.response = LostDataResponse(
        files: <XFile>[XFile('/tmp/recovered-a.jpg')],
        file: XFile('/tmp/recovered-last.jpg'),
        type: RetrieveType.image,
      );
      expect((await adapter.retrieveLost())?.path, '/tmp/recovered-a.jpg');

      picker.response = LostDataResponse(
        file: XFile('/tmp/recovered-single.jpg'),
        type: RetrieveType.image,
      );
      expect((await adapter.retrieveLost())?.path, '/tmp/recovered-single.jpg');
      expect(picker.retrieveCount, 2);
    },
  );

  test('an empty or failed lost response does not yield a file', () async {
    final _FakeImagePicker picker = _FakeImagePicker();
    final ImagePickerPhotoPicker adapter = ImagePickerPhotoPicker(
      picker: picker,
      android: true,
    );

    expect(await adapter.retrieveLost(), isNull);

    picker.response = LostDataResponse(
      exception: PlatformException(code: 'lost'),
      type: RetrieveType.image,
    );
    await expectLater(
      adapter.retrieveLost(),
      throwsA(isA<PhotoPickException>()),
    );
  });

  test('non-Android platforms skip the Android-only recovery API', () async {
    final _FakeImagePicker picker = _FakeImagePicker();
    final ImagePickerPhotoPicker adapter = ImagePickerPhotoPicker(
      picker: picker,
      android: false,
    );

    expect(await adapter.retrieveLost(), isNull);
    expect(picker.retrieveCount, 0);
  });
}
