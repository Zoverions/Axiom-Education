import 'practice_item.dart';
import 'rational.dart';

class UnsupportedPracticeExpectationException implements Exception {
  const UnsupportedPracticeExpectationException(this.expectationId);

  final String expectationId;

  @override
  String toString() =>
      'UnsupportedPracticeExpectationException: no deterministic generator is '
      'registered for $expectationId';
}

class MathPracticeGenerator {
  static const Set<String> supportedExpectationIds = {
    'MTH1W-A1',
    'MTH1W-A2',
    'MTH1W-B2',
    'MTH1W-B4',
  };

  const MathPracticeGenerator();

  PracticeItem generate({
    required String expectationId,
    required String expectationText,
    required double difficultyValue,
    required int seed,
  }) {
    if (!supportedExpectationIds.contains(expectationId)) {
      throw UnsupportedPracticeExpectationException(expectationId);
    }

    final sequence = _DeterministicSequence(
      seed ^ _stableStringSeed(expectationId),
    );
    return switch (expectationId) {
      'MTH1W-A1' => _generateOrderOfOperations(
        expectationId,
        expectationText,
        difficultyValue,
        seed,
        sequence,
      ),
      'MTH1W-A2' => _generatePercentage(
        expectationId,
        expectationText,
        difficultyValue,
        seed,
        sequence,
      ),
      'MTH1W-B2' => _generateLinearEquation(
        expectationId,
        expectationText,
        difficultyValue,
        seed,
        sequence,
      ),
      'MTH1W-B4' => _generateLineFromPoints(
        expectationId,
        expectationText,
        difficultyValue,
        seed,
        sequence,
      ),
      _ => throw UnsupportedPracticeExpectationException(expectationId),
    };
  }

  PracticeItem _generateOrderOfOperations(
    String expectationId,
    String expectationText,
    double difficultyValue,
    int seed,
    _DeterministicSequence sequence,
  ) {
    final first = sequence.nextBetween(-12, 12);
    final second = sequence.nextBetween(2, 9);
    final third = sequence.nextBetween(2, 7);
    final fourth = sequence.nextBetween(-8, 8);
    final answer = Rational(first + second * third - fourth);

    return PracticeItem.create(
      expectationId: expectationId,
      expectationText: expectationText,
      generatorSeed: seed,
      prompt:
          'Evaluate using order of operations: $first + $second × $third − '
          '(${_signedValue(fourth)})',
      answerKind: PracticeAnswerKind.rational,
      canonicalAnswer: answer.toString(),
      hints: [
        'Multiply $second × $third before adding or subtracting.',
        'Subtracting a signed value changes the final step; simplify the '
            'parentheses carefully.',
      ],
      difficultyValue: difficultyValue,
    );
  }

  PracticeItem _generatePercentage(
    String expectationId,
    String expectationText,
    double difficultyValue,
    int seed,
    _DeterministicSequence sequence,
  ) {
    const percentages = [10, 20, 25, 30, 40, 50, 60, 75];
    final percentage = percentages[sequence.nextInt(percentages.length)];
    final total = sequence.nextBetween(4, 40) * 5;
    final answer = Rational(percentage * total, 100);

    return PracticeItem.create(
      expectationId: expectationId,
      expectationText: expectationText,
      generatorSeed: seed,
      prompt: 'What is $percentage% of $total?',
      answerKind: PracticeAnswerKind.rational,
      canonicalAnswer: answer.toString(),
      hints: [
        'Rewrite $percentage% as the fraction $percentage/100.',
        'Multiply $total by $percentage/100, then reduce the result.',
      ],
      difficultyValue: difficultyValue,
    );
  }

  PracticeItem _generateLinearEquation(
    String expectationId,
    String expectationText,
    double difficultyValue,
    int seed,
    _DeterministicSequence sequence,
  ) {
    var coefficient = sequence.nextBetween(-8, 8);
    if (coefficient == 0) coefficient = 3;
    final solution = sequence.nextBetween(-10, 10);
    final constant = sequence.nextBetween(-12, 12);
    final rightSide = coefficient * solution + constant;

    return PracticeItem.create(
      expectationId: expectationId,
      expectationText: expectationText,
      generatorSeed: seed,
      prompt:
          'Solve for x: ${_linearExpression(coefficient, constant)} = '
          '$rightSide',
      answerKind: PracticeAnswerKind.rational,
      canonicalAnswer: Rational(solution).toString(),
      hints: [
        constant == 0
            ? 'The x-term is already isolated on the left.'
            : 'Undo ${_constantOperation(constant)} on both sides first.',
        'Divide both sides by $coefficient to isolate x.',
      ],
      difficultyValue: difficultyValue,
    );
  }

  PracticeItem _generateLineFromPoints(
    String expectationId,
    String expectationText,
    double difficultyValue,
    int seed,
    _DeterministicSequence sequence,
  ) {
    var slope = sequence.nextBetween(-5, 5);
    if (slope == 0) slope = 2;
    final intercept = sequence.nextBetween(-9, 9);
    final firstX = sequence.nextBetween(-5, -1);
    final secondX = sequence.nextBetween(1, 5);
    final firstY = slope * firstX + intercept;
    final secondY = slope * secondX + intercept;

    return PracticeItem.create(
      expectationId: expectationId,
      expectationText: expectationText,
      generatorSeed: seed,
      prompt:
          'Find the equation of the line through ($firstX, $firstY) and '
          '($secondX, $secondY). Answer in the form y = mx + b.',
      answerKind: PracticeAnswerKind.lineSlopeIntercept,
      canonicalAnswer: '${Rational(slope)},${Rational(intercept)}',
      hints: [
        'Find the slope with (y₂ − y₁) ÷ (x₂ − x₁).',
        'Substitute one point into y = mx + b to determine b.',
      ],
      difficultyValue: difficultyValue,
    );
  }

  static int _stableStringSeed(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static String _linearExpression(int coefficient, int constant) {
    final xTerm = switch (coefficient) {
      1 => 'x',
      -1 => '−x',
      _ => '${coefficient}x',
    };
    if (constant == 0) return xTerm;
    return constant > 0 ? '$xTerm + $constant' : '$xTerm − ${constant.abs()}';
  }

  static String _constantOperation(int constant) {
    return constant > 0 ? 'adding $constant' : 'subtracting ${constant.abs()}';
  }

  static String _signedValue(int value) =>
      value >= 0 ? '$value' : '−${value.abs()}';
}

class _DeterministicSequence {
  _DeterministicSequence(int seed) : _state = seed & 0x7fffffff;

  int _state;

  int nextInt(int maximum) {
    if (maximum <= 0) {
      throw RangeError.value(maximum, 'maximum', 'must be positive');
    }
    _state = (1103515245 * _state + 12345) & 0x7fffffff;
    return _state % maximum;
  }

  int nextBetween(int minimum, int maximum) {
    if (maximum < minimum) {
      throw RangeError.range(maximum, minimum, null, 'maximum');
    }
    return minimum + nextInt(maximum - minimum + 1);
  }
}
