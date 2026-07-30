import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/practice/math_answer_verifier.dart';
import 'package:ontarioedai/core/practice/practice_item.dart';

void main() {
  const verifier = MathAnswerVerifier();

  PracticeItem rationalItem() => PracticeItem.create(
        expectationId: 'MTH1W-A2',
        expectationText: 'Apply rates, ratios, and percentages.',
        generatorSeed: 1,
        prompt: 'What is 75% of 1?',
        answerKind: PracticeAnswerKind.rational,
        canonicalAnswer: '3/4',
        hints: const ['Rewrite the percentage as a fraction.'],
        difficultyValue: -0.3,
      );

  PracticeItem lineItem() => PracticeItem.create(
        expectationId: 'MTH1W-B4',
        expectationText: 'Determine the equation of a line.',
        generatorSeed: 2,
        prompt: 'Find the line.',
        answerKind: PracticeAnswerKind.lineSlopeIntercept,
        canonicalAnswer: '-2,3',
        hints: const ['Find slope, then intercept.'],
        difficultyValue: 1.1,
      );

  group('MathAnswerVerifier', () {
    test('accepts exact equivalent rational forms', () {
      final result = verifier.verify(rationalItem(), '0.75');

      expect(result.status, VerificationStatus.correct);
      expect(result.normalizedAnswer, '3/4');
      expect(result.isExact, isTrue);
    });

    test('distinguishes incorrect and malformed rational answers', () {
      expect(
        verifier.verify(rationalItem(), '2/3').status,
        VerificationStatus.incorrect,
      );
      expect(
        verifier.verify(rationalItem(), 'three quarters').status,
        VerificationStatus.invalidInput,
      );
      expect(
        verifier.verify(rationalItem(), '').status,
        VerificationStatus.invalidInput,
      );
    });

    test('parses slope-intercept form with exact coefficients', () {
      final result = verifier.verify(lineItem(), 'y = -2x + 3');

      expect(result.status, VerificationStatus.correct);
      expect(result.normalizedAnswer, 'y=-2x+3');
    });

    test('rejects a wrong or malformed line equation', () {
      expect(
        verifier.verify(lineItem(), 'y = -2x + 4').status,
        VerificationStatus.incorrect,
      );
      expect(
        verifier.verify(lineItem(), 'x = 4').status,
        VerificationStatus.invalidInput,
      );
    });

    test('fails closed when the item digest is invalid', () {
      final json = Map<String, dynamic>.from(rationalItem().toJson());
      json['prompt'] = 'Changed after generation';
      final tampered = PracticeItem.fromJson(json);

      final result = verifier.verify(tampered, '3/4');
      expect(result.status, VerificationStatus.integrityFailure);
      expect(result.isCorrect, isFalse);
    });
  });
}
