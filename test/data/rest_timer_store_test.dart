import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/data/rest_timer_store.dart';

Future<File> _tempFile() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'gym_log_rest_timer_test_',
  );
  addTearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });
  return File('${directory.path}${Platform.pathSeparator}rest_timer.json');
}

void main() {
  test('a rest marker round-trips, serializes writes, and clears', () async {
    final File file = await _tempFile();
    final JsonRestTimerStore store = JsonRestTimerStore(
      Future<File>.value(file),
    );
    final DateTime firstEnd = DateTime.utc(2026, 10, 21, 11, 1);
    final DateTime secondEnd = DateTime.utc(2026, 10, 21, 11, 2);

    await Future.wait(<Future<void>>[
      store.save(
        PersistedRestTimer(
          endsAt: firstEnd,
          duration: const Duration(seconds: 60),
        ),
      ),
      store.save(
        PersistedRestTimer(
          endsAt: secondEnd,
          duration: const Duration(seconds: 90),
        ),
      ),
    ]);

    final PersistedRestTimer? loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.endsAt, secondEnd);
    expect(loaded.duration, const Duration(seconds: 90));
    expect(File('${file.path}.tmp').existsSync(), isFalse);

    await store.clear();
    expect(await store.load(), isNull);
    expect(file.existsSync(), isFalse);
  });

  test('a corrupt rest marker is ignored instead of failing the app', () async {
    final File file = await _tempFile();
    await file.parent.create(recursive: true);
    await file.writeAsString('{not json');

    final JsonRestTimerStore store = JsonRestTimerStore(
      Future<File>.value(file),
    );

    expect(await store.load(), isNull);
  });
}
