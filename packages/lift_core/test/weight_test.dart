import 'package:lift_core/lift_core.dart';
import 'package:test/test.dart';

String _inputFromHundredths(int hundredths) {
  final int whole = hundredths ~/ 100;
  final int fraction = hundredths % 100;
  if (fraction == 0) {
    return '$whole';
  }
  if (fraction % 10 == 0) {
    return '$whole.${fraction ~/ 10}';
  }
  return '$whole.${fraction.toString().padLeft(2, '0')}';
}

void main() {
  group('weight round-trip', () {
    test('every two-decimal kg input round-trips through grams', () {
      final List<String> failures = <String>[];
      for (int hundredths = 0; hundredths <= 100000; hundredths++) {
        final String input = _inputFromHundredths(hundredths);
        final WeightParseResult parsed = parseWeightInput(
          input,
          WeightUnit.kilograms,
        );
        final String displayed = parsed.grams == null
            ? '<${parsed.problem}>'
            : formatWeight(parsed.grams!, WeightUnit.kilograms);
        if (displayed != input) {
          failures.add('$input -> ${parsed.grams} -> $displayed');
        }
      }
      expect(failures, isEmpty);
    });

    test('every two-decimal lb input round-trips through grams', () {
      final List<String> failures = <String>[];
      for (int hundredths = 0; hundredths <= 220462; hundredths++) {
        final String input = _inputFromHundredths(hundredths);
        final WeightParseResult parsed = parseWeightInput(
          input,
          WeightUnit.pounds,
        );
        final String displayed = parsed.grams == null
            ? '<${parsed.problem}>'
            : formatWeight(parsed.grams!, WeightUnit.pounds);
        if (displayed != input) {
          failures.add('$input -> ${parsed.grams} -> $displayed');
        }
      }
      expect(failures, isEmpty);
    });

    test('45 lb is the documented plate-weight case', () {
      final WeightParseResult parsed = parseWeightInput(
        '45',
        WeightUnit.pounds,
      );
      expect(parsed.grams, 20412);
      expect(formatWeight(20412, WeightUnit.pounds), '45');
      expect(formatWeight(20412, WeightUnit.kilograms), '20.41');
    });

    test('formatting rounds to the nearest hundredth', () {
      expect(formatWeight(0, WeightUnit.kilograms), '0');
      expect(formatWeight(80500, WeightUnit.kilograms), '80.5');
      expect(formatWeight(80505, WeightUnit.kilograms), '80.51');
      expect(formatWeight(2268, WeightUnit.pounds), '5');
      expect(formatWeight(4536, WeightUnit.pounds), '10');
    });
  });

  group('parseWeightInput', () {
    final List<
      ({String input, WeightUnit unit, int? grams, NumberProblem? problem})
    >
    cases =
        <({String input, WeightUnit unit, int? grams, NumberProblem? problem})>[
          (
            input: '۸۰٫۵',
            unit: WeightUnit.kilograms,
            grams: 80500,
            problem: null,
          ),
          (
            input: '80.5',
            unit: WeightUnit.kilograms,
            grams: 80500,
            problem: null,
          ),
          (
            input: '٨٠٫٥',
            unit: WeightUnit.kilograms,
            grams: 80500,
            problem: null,
          ),
          (
            input: '٨٠.٥',
            unit: WeightUnit.kilograms,
            grams: 80500,
            problem: null,
          ),
          (
            input: ' 80 ',
            unit: WeightUnit.kilograms,
            grams: 80000,
            problem: null,
          ),
          (
            input: '80.50',
            unit: WeightUnit.kilograms,
            grams: 80500,
            problem: null,
          ),
          (input: '.5', unit: WeightUnit.kilograms, grams: 500, problem: null),
          (input: '٠', unit: WeightUnit.kilograms, grams: 0, problem: null),
          (input: '0.01', unit: WeightUnit.kilograms, grams: 10, problem: null),
          (input: '45', unit: WeightUnit.pounds, grams: 20412, problem: null),
          (input: '45.5', unit: WeightUnit.pounds, grams: 20638, problem: null),
          (input: '5', unit: WeightUnit.pounds, grams: 2268, problem: null),
          (input: '2.5', unit: WeightUnit.pounds, grams: 1134, problem: null),
          (input: '0.01', unit: WeightUnit.pounds, grams: 5, problem: null),
          (
            input: '',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.empty,
          ),
          (
            input: '   ',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.empty,
          ),
          (
            input: '-2',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.negative,
          ),
          (
            input: '80.555',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.tooManyDecimals,
          ),
          (
            input: '80.',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.invalid,
          ),
          (
            input: '80,5',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.invalid,
          ),
          (
            input: '1,000',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.invalid,
          ),
          (
            input: '1٬000',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.invalid,
          ),
          (
            input: 'abc',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.invalid,
          ),
          (
            input: '80 kg',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.invalid,
          ),
          (
            input: '1000',
            unit: WeightUnit.kilograms,
            grams: 1000000,
            problem: null,
          ),
          (
            input: '1000.01',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.outOfRange,
          ),
          (
            input: '2205',
            unit: WeightUnit.pounds,
            grams: null,
            problem: NumberProblem.outOfRange,
          ),
          (
            input: '9223372036854775',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.outOfRange,
          ),
          (
            input: '9223372036854776',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.outOfRange,
          ),
          (
            input: '9223372036854775',
            unit: WeightUnit.pounds,
            grams: null,
            problem: NumberProblem.outOfRange,
          ),
          (
            input: '9223372036854775807',
            unit: WeightUnit.kilograms,
            grams: null,
            problem: NumberProblem.outOfRange,
          ),
          (
            input: '9223372036854775807',
            unit: WeightUnit.pounds,
            grams: null,
            problem: NumberProblem.outOfRange,
          ),
        ];

    for (final testCase in cases) {
      test('"${testCase.input}" in ${testCase.unit.name}', () {
        final WeightParseResult result = parseWeightInput(
          testCase.input,
          testCase.unit,
        );
        expect(result.grams, testCase.grams);
        expect(result.problem, testCase.problem);
      });
    }

    test('never throws for arbitrary input', () {
      for (final String input in <String>[
        '🙂',
        '\n',
        '123456789012345678901234567890',
        '٫',
        '.',
        '+1',
        'NaN',
        'Infinity',
      ]) {
        final WeightParseResult result = parseWeightInput(
          input,
          WeightUnit.kilograms,
        );
        expect(result.grams, isNull, reason: 'Unexpected grams for "$input"');
      }
    });
  });

  group('parseWeightField', () {
    const List<int> canonicalGrams = <int>[
      0,
      1,
      2500,
      99999,
      100000,
      80500,
      453592,
      1000000,
    ];

    for (final WeightUnit unit in WeightUnit.values) {
      for (final int grams in canonicalGrams) {
        test('unchanged ${unit.name} display keeps $grams g', () {
          final String display = formatWeight(grams, unit);
          final WeightParseResult result = parseWeightField(
            display,
            unit: unit,
            originalGrams: grams,
          );
          expect(result.grams, grams);
          expect(result.problem, isNull);
        });

        test('unchanged Persian-digit ${unit.name} display keeps $grams g', () {
          final String display = applyDigitStyle(
            formatWeight(grams, unit),
            DigitStyle.persian,
          );
          final WeightParseResult result = parseWeightField(
            display,
            unit: unit,
            originalGrams: grams,
          );
          expect(result.grams, grams);
        });
      }
    }

    test('a changed lb value parses the typed value', () {
      final WeightParseResult result = parseWeightField(
        '5.52',
        unit: WeightUnit.pounds,
        originalGrams: 2500,
      );
      expect(result.grams, 2504);
      expect(result.grams, isNot(2500));
    });

    test('an invalid typed value reports the parseWeightInput problem', () {
      for (final String input in <String>['', '-1', '1.234', 'abc']) {
        final WeightParseResult helper = parseWeightField(
          input,
          unit: WeightUnit.kilograms,
          originalGrams: 2500,
        );
        final WeightParseResult parser = parseWeightInput(
          input,
          WeightUnit.kilograms,
        );
        expect(helper.grams, isNull, reason: 'Unexpected grams for "$input"');
        expect(helper.problem, parser.problem);
      }
    });

    test('a null original behaves exactly like parseWeightInput', () {
      for (final String input in <String>['5.51', '۱۰', '0', 'abc']) {
        final WeightParseResult helper = parseWeightField(
          input,
          unit: WeightUnit.pounds,
        );
        final WeightParseResult parser = parseWeightInput(
          input,
          WeightUnit.pounds,
        );
        expect(helper.grams, parser.grams);
        expect(helper.problem, parser.problem);
      }
    });
  });

  group('parseRepsInput', () {
    final List<({String input, int? reps, NumberProblem? problem})> cases =
        <({String input, int? reps, NumberProblem? problem})>[
          (input: '8', reps: 8, problem: null),
          (input: '۸', reps: 8, problem: null),
          (input: '٨', reps: 8, problem: null),
          (input: ' 12 ', reps: 12, problem: null),
          (input: '1000', reps: 1000, problem: null),
          (input: '', reps: null, problem: NumberProblem.empty),
          (input: '0', reps: null, problem: NumberProblem.outOfRange),
          (input: '1001', reps: null, problem: NumberProblem.outOfRange),
          (input: '-1', reps: null, problem: NumberProblem.negative),
          (input: '1.5', reps: null, problem: NumberProblem.invalid),
          (input: '۸٫۵', reps: null, problem: NumberProblem.invalid),
          (input: 'abc', reps: null, problem: NumberProblem.invalid),
        ];

    for (final testCase in cases) {
      test('"${testCase.input}"', () {
        final RepsParseResult result = parseRepsInput(testCase.input);
        expect(result.reps, testCase.reps);
        expect(result.problem, testCase.problem);
      });
    }
  });
}
