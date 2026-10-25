import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screen inventory for the LTR/RTL golden requirement (`L10N-001`).
///
/// Each entry is rendered by one of the golden tests in this folder; this
/// check prevents a screen from silently losing one direction or its files.
const Map<String, String> _screenGoldens = <String, String>{
  'app shell': 'app_shell',
  'workout start': 'workout_start',
  'workout active': 'workout_active',
  'workout PR': 'workout_pr',
  'exercise library empty': 'exercise_library_empty',
  'exercise library populated': 'exercise_library_populated',
  'exercise picker': 'exercise_picker',
  'exercise creator': 'exercise_creator',
  'programs list': 'programs_list',
  'program editor': 'program_editor',
  'day editor': 'day_editor',
  'plan item editor': 'plan_item_editor',
  'plan item validation': 'plan_item_validation',
  'history': 'history',
  'session detail': 'session_detail',
  'progress overview': 'progress_overview',
  'progress detail': 'progress_detail',
  'photo viewer': 'photo_viewer',
  'settings': 'settings',
  'about': 'about',
};

void main() {
  test('every screen has both LTR and RTL golden files', () {
    for (final MapEntry<String, String> screen in _screenGoldens.entries) {
      for (final String direction in <String>['en', 'fa']) {
        final File file = File('test/goldens/${screen.value}_$direction.png');
        expect(
          file.existsSync(),
          isTrue,
          reason: '${screen.key} is missing ${file.path}',
        );
        expect(
          file.lengthSync(),
          greaterThan(0),
          reason: '${screen.key} has an empty ${file.path}',
        );
      }
    }
  });

  test('golden files are never one-direction only', () {
    final Directory goldens = Directory('test/goldens');
    final List<File> files = goldens
        .listSync()
        .whereType<File>()
        .where((File file) => file.path.endsWith('.png'))
        .toList();

    for (final File file in files) {
      final String name = file.uri.pathSegments.last;
      final String? counterpart;
      if (name.endsWith('_en.png')) {
        counterpart = name.replaceFirst('_en.png', '_fa.png');
      } else if (name.endsWith('_fa.png')) {
        counterpart = name.replaceFirst('_fa.png', '_en.png');
      } else {
        continue;
      }
      expect(
        File('${goldens.path}/$counterpart').existsSync(),
        isTrue,
        reason: '${file.path} has no $counterpart counterpart',
      );
    }
  });
}
