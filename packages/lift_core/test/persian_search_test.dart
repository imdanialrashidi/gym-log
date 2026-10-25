import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeForSearch', () {
    test('lowercases Latin and trims', () {
      expect(normalizeForSearch('  Bench PRESS  '), 'bench press');
    });

    test('treats Arabic and Persian yeh as equal', () {
      expect(normalizeForSearch('سينه'), normalizeForSearch('سینه'));
    });

    test('treats Arabic and Persian kaf as equal', () {
      expect(normalizeForSearch('كيك'), normalizeForSearch('کیک'));
    });

    test('ignores ZWNJ', () {
      expect(normalizeForSearch('می\u200Cرود'), 'میرود');
    });
  });

  group('matchesSearchQuery', () {
    final List<({String text, String query, bool expected})> cases =
        <({String text, String query, bool expected})>[
          (text: 'Bench Press', query: 'ben', expected: true),
          (text: 'Bench Press', query: 'BENCH', expected: true),
          (text: 'Bench Press', query: 'squat', expected: false),
          (text: 'پرس سینه', query: 'پرس سينه', expected: true),
          (text: 'پرس سینه', query: 'پرس سینه', expected: true),
          (text: 'پرس سینه', query: 'پرس  سینه', expected: true),
          (text: 'می\u200Cرود', query: 'میرود', expected: true),
          (text: 'میرود', query: 'می\u200Cرود', expected: true),
          (text: 'کیک', query: 'كيك', expected: true),
          (text: 'سینه', query: '', expected: true),
          (text: 'سینه', query: '   ', expected: true),
          (text: 'اسکوات', query: 'پرس', expected: false),
        ];

    for (final ({String text, String query, bool expected}) testCase in cases) {
      test('"${testCase.text}" vs "${testCase.query}"', () {
        expect(
          matchesSearchQuery(testCase.text, testCase.query),
          testCase.expected,
        );
      });
    }
  });
}
