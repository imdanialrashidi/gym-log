import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildExerciseLookupUri', () {
    test('uses the name and a Google image-search query', () {
      final Uri uri = buildExerciseLookupUri(name: 'Bench Press');

      expect(uri.scheme, 'https');
      expect(uri.host, exerciseLookupHost);
      expect(uri.path, exerciseLookupPath);
      expect(uri.queryParameters['tbm'], 'isch');
      expect(uri.queryParameters['q'], 'Bench Press');
      expect(uri.toString(), contains('Bench+Press'));
    });

    test('prefers a non-empty search term', () {
      final Uri uri = buildExerciseLookupUri(
        name: 'Bench Press',
        searchTerm: '  flat bench press  ',
      );

      expect(uri.queryParameters['q'], 'flat bench press');
    });

    test('falls back to the name when the search term is blank', () {
      final Uri uri = buildExerciseLookupUri(
        name: '  Squat  ',
        searchTerm: '   ',
      );

      expect(uri.queryParameters['q'], 'Squat');
    });

    test('encodes Persian, spaces, ampersands, and hashes', () {
      final Uri persian = buildExerciseLookupUri(name: 'پرس سینه');
      final Uri symbols = buildExerciseLookupUri(name: 'AT&T #1');

      expect(persian.queryParameters['q'], 'پرس سینه');
      expect(persian.toString(), contains('%D9%BE'));
      expect(persian.toString(), isNot(contains('پرس')));

      expect(symbols.queryParameters['q'], 'AT&T #1');
      expect(symbols.toString(), contains('%26'));
      expect(symbols.toString(), contains('%23'));
      expect(symbols.toString(), isNot(contains('AT&T')));
    });

    test('rejects an empty name and search term', () {
      expect(
        () => buildExerciseLookupUri(name: '  ', searchTerm: ''),
        throwsArgumentError,
      );
    });
  });
}
