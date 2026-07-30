import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/practice/math_practice_generator.dart';
import 'package:ontarioedai/core/practice/practice_item.dart';

void main() {
  const generator = MathPracticeGenerator();
  const expectations = {
    'MTH1W-A1':
        'Perform operations on integers and rational numbers, including order of operations.',
    'MTH1W-A2':
        'Apply rates, ratios, percentages, and proportional reasoning to solve problems in various contexts.',
    'MTH1W-B2':
        'Solve linear equations and inequalities algebraically and represent solutions on a number line.',
    'MTH1W-B4':
        'Determine the equation of a line given slope and y-intercept, or two points.',
  };

  group('MathPracticeGenerator', () {
    for (final entry in expectations.entries) {
      test('${entry.key} is deterministic and digest-bound', () {
        final first = generator.generate(
          expectationId: entry.key,
          expectationText: entry.value,
          difficultyValue: 0.4,
          seed: 42,
        );
        final second = generator.generate(
          expectationId: entry.key,
          expectationText: entry.value,
          difficultyValue: 0.4,
          seed: 42,
        );
        final different = generator.generate(
          expectationId: entry.key,
          expectationText: entry.value,
          difficultyValue: 0.4,
          seed: 43,
        );

        expect(first.toJson(), second.toJson());
        expect(first.itemDigest, isNot(different.itemDigest));
        expect(first.expectationId, entry.key);
        expect(first.expectationText, entry.value);
        expect(first.hints, isNotEmpty);
        expect(first.hasValidDigest, isTrue);
        expect(first.difficultyValue, 0.4);
      });
    }

    test('unsupported expectations fail closed', () {
      expect(
        () => generator.generate(
          expectationId: 'MTH1W-C1',
          expectationText: 'Data analysis',
          difficultyValue: -0.4,
          seed: 1,
        ),
        throwsA(isA<UnsupportedPracticeExpectationException>()),
      );
    });

    test('digest verification detects field mutation', () {
      final item = generator.generate(
        expectationId: 'MTH1W-A1',
        expectationText: expectations['MTH1W-A1']!,
        difficultyValue: -0.8,
        seed: 5,
      );
      final mutated = Map<String, dynamic>.from(item.toJson());
      mutated['prompt'] = 'Tampered prompt';

      final decoded = PracticeItem.fromJson(mutated);
      expect(decoded.hasValidDigest, isFalse);
    });
  });
}
