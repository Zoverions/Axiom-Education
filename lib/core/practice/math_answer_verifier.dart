import 'practice_item.dart';
import 'rational.dart';

enum VerificationStatus {
  correct,
  incorrect,
  invalidInput,
  unavailable,
  integrityFailure,
}

class VerificationResult {
  const VerificationResult({
    required this.status,
    required this.message,
    required this.itemDigest,
    this.normalizedAnswer,
  });

  final VerificationStatus status;
  final String message;
  final String itemDigest;
  final String? normalizedAnswer;

  bool get isCorrect => status == VerificationStatus.correct;
  bool get isExact =>
      status == VerificationStatus.correct ||
      status == VerificationStatus.incorrect;

  String get evidenceLabel => switch (status) {
    VerificationStatus.correct ||
    VerificationStatus.incorrect => 'Exact deterministic verification',
    VerificationStatus.invalidInput => 'No result — answer could not be parsed',
    VerificationStatus.unavailable => 'No result — verifier unavailable',
    VerificationStatus.integrityFailure =>
      'No result — practice item integrity failed',
  };
}

abstract interface class PracticeVerifier {
  VerificationResult verify(PracticeItem item, String learnerAnswer);
}

class MathAnswerVerifier implements PracticeVerifier {
  const MathAnswerVerifier();

  static const String verifierId = 'axiom.math.exact.v1';

  @override
  VerificationResult verify(PracticeItem item, String learnerAnswer) {
    if (!item.hasValidDigest) {
      return VerificationResult(
        status: VerificationStatus.integrityFailure,
        message:
            'This practice item changed after generation and was not checked.',
        itemDigest: item.itemDigest,
      );
    }

    if (learnerAnswer.trim().isEmpty) {
      return VerificationResult(
        status: VerificationStatus.invalidInput,
        message: 'Enter an answer before checking it.',
        itemDigest: item.itemDigest,
      );
    }

    return switch (item.answerKind) {
      PracticeAnswerKind.rational => _verifyRational(item, learnerAnswer),
      PracticeAnswerKind.lineSlopeIntercept => _verifyLineEquation(
        item,
        learnerAnswer,
      ),
    };
  }

  VerificationResult _verifyRational(PracticeItem item, String learnerAnswer) {
    final expected = Rational.tryParse(item.canonicalAnswer);
    final actual = Rational.tryParse(learnerAnswer);
    if (expected == null) {
      return VerificationResult(
        status: VerificationStatus.integrityFailure,
        message: 'The generated answer contract is invalid.',
        itemDigest: item.itemDigest,
      );
    }
    if (actual == null) {
      return VerificationResult(
        status: VerificationStatus.invalidInput,
        message: 'Use an integer, decimal, or fraction such as 3/4.',
        itemDigest: item.itemDigest,
      );
    }

    final correct = actual == expected;
    return VerificationResult(
      status: correct
          ? VerificationStatus.correct
          : VerificationStatus.incorrect,
      message: correct
          ? 'Correct. The exact rational result matches.'
          : 'Not yet. The exact rational result does not match.',
      itemDigest: item.itemDigest,
      normalizedAnswer: actual.toString(),
    );
  }

  VerificationResult _verifyLineEquation(
    PracticeItem item,
    String learnerAnswer,
  ) {
    final expectedParts = item.canonicalAnswer.split(',');
    if (expectedParts.length != 2) {
      return VerificationResult(
        status: VerificationStatus.integrityFailure,
        message: 'The generated line-answer contract is invalid.',
        itemDigest: item.itemDigest,
      );
    }
    final expectedSlope = Rational.tryParse(expectedParts[0]);
    final expectedIntercept = Rational.tryParse(expectedParts[1]);
    final actual = _parseSlopeIntercept(learnerAnswer);
    if (expectedSlope == null || expectedIntercept == null) {
      return VerificationResult(
        status: VerificationStatus.integrityFailure,
        message: 'The generated line-answer values are invalid.',
        itemDigest: item.itemDigest,
      );
    }
    if (actual == null) {
      return VerificationResult(
        status: VerificationStatus.invalidInput,
        message: 'Use slope-intercept form, for example y = 2x - 3.',
        itemDigest: item.itemDigest,
      );
    }

    final correct =
        actual.slope == expectedSlope && actual.intercept == expectedIntercept;
    return VerificationResult(
      status: correct
          ? VerificationStatus.correct
          : VerificationStatus.incorrect,
      message: correct
          ? 'Correct. Both the exact slope and intercept match.'
          : 'Not yet. Check the exact slope and y-intercept.',
      itemDigest: item.itemDigest,
      normalizedAnswer: actual.normalized,
    );
  }

  _SlopeIntercept? _parseSlopeIntercept(String input) {
    var value = input
        .trim()
        .toLowerCase()
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll(' ', '')
        .replaceAll('*', '');
    if (value.startsWith('y=')) value = value.substring(2);

    final match = RegExp(
      r'^([+-]?(?:(?:\d+(?:/\d+)?)|(?:\d*\.\d+))?)x'
      r'([+-](?:(?:\d+(?:/\d+)?)|(?:\d*\.\d+)))?$',
    ).firstMatch(value);
    if (match == null) return null;

    final slopeToken = match.group(1) ?? '';
    final interceptToken = match.group(2);
    final slope = switch (slopeToken) {
      '' || '+' => Rational(1),
      '-' => Rational(-1),
      _ => Rational.tryParse(slopeToken),
    };
    final intercept = interceptToken == null
        ? Rational(0)
        : Rational.tryParse(interceptToken);
    if (slope == null || intercept == null) return null;

    return _SlopeIntercept(slope, intercept);
  }
}

class _SlopeIntercept {
  const _SlopeIntercept(this.slope, this.intercept);

  final Rational slope;
  final Rational intercept;

  String get normalized {
    final interceptText = intercept.numerator >= 0
        ? '+${intercept.toString()}'
        : intercept.toString();
    return 'y=${slope}x$interceptText';
  }
}
