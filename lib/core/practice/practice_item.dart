import 'dart:convert';

import 'package:crypto/crypto.dart';

enum PracticeAnswerKind {
  rational('rational'),
  lineSlopeIntercept('line_slope_intercept');

  const PracticeAnswerKind(this.wireName);

  final String wireName;

  static PracticeAnswerKind fromWireName(String value) {
    return PracticeAnswerKind.values.firstWhere(
      (kind) => kind.wireName == value,
      orElse: () => throw FormatException('Unsupported answer kind: $value'),
    );
  }
}

class PracticeItem {
  const PracticeItem._({
    required this.itemId,
    required this.courseCode,
    required this.expectationId,
    required this.expectationText,
    required this.generatorSeed,
    required this.prompt,
    required this.answerKind,
    required this.canonicalAnswer,
    required this.hints,
    required this.difficultyValue,
    required this.itemDigest,
  });

  static const String schema = 'axiom-education-practice-item.v1';
  static const String generatorId = 'mth1w-deterministic-practice';
  static const String generatorVersion = '1.0.0';
  static const String difficultySource = 'curriculum_irt_b';
  static const String difficultyStatus = 'uncalibrated';

  final String itemId;
  final String courseCode;
  final String expectationId;
  final String expectationText;
  final int generatorSeed;
  final String prompt;
  final PracticeAnswerKind answerKind;
  final String canonicalAnswer;
  final List<String> hints;
  final double difficultyValue;
  final String itemDigest;

  factory PracticeItem.create({
    required String expectationId,
    required String expectationText,
    required int generatorSeed,
    required String prompt,
    required PracticeAnswerKind answerKind,
    required String canonicalAnswer,
    required List<String> hints,
    required double difficultyValue,
  }) {
    if (generatorSeed < 0 || generatorSeed > 0x7fffffff) {
      throw RangeError.range(generatorSeed, 0, 0x7fffffff, 'generatorSeed');
    }
    if (expectationId.trim().isEmpty || expectationText.trim().isEmpty) {
      throw const FormatException(
        'Expectation identity and text are required.',
      );
    }
    if (prompt.trim().isEmpty || canonicalAnswer.trim().isEmpty) {
      throw const FormatException('Prompt and canonical answer are required.');
    }
    if (hints.isEmpty || hints.any((hint) => hint.trim().isEmpty)) {
      throw const FormatException('At least one non-empty hint is required.');
    }

    final itemId = 'practice:mth1w:v1:$expectationId:$generatorSeed';
    final normalizedHints = List<String>.unmodifiable(
      hints.map((hint) => hint.trim()),
    );
    final digestPayload = _digestPayload(
      itemId: itemId,
      courseCode: 'MTH1W',
      expectationId: expectationId.trim(),
      expectationText: expectationText.trim(),
      generatorSeed: generatorSeed,
      prompt: prompt.trim(),
      answerKind: answerKind,
      canonicalAnswer: canonicalAnswer.trim(),
      hints: normalizedHints,
      difficultyValue: difficultyValue,
    );
    final digest = sha256
        .convert(utf8.encode(jsonEncode(digestPayload)))
        .toString();

    return PracticeItem._(
      itemId: itemId,
      courseCode: 'MTH1W',
      expectationId: expectationId.trim(),
      expectationText: expectationText.trim(),
      generatorSeed: generatorSeed,
      prompt: prompt.trim(),
      answerKind: answerKind,
      canonicalAnswer: canonicalAnswer.trim(),
      hints: normalizedHints,
      difficultyValue: difficultyValue,
      itemDigest: digest,
    );
  }

  factory PracticeItem.fromJson(Map<String, dynamic> json) {
    final expectation = json['expectation'] as Map<String, dynamic>;
    final generator = json['generator'] as Map<String, dynamic>;
    final answer = json['answer'] as Map<String, dynamic>;
    final difficulty = json['difficulty'] as Map<String, dynamic>;

    if (json['schema'] != schema ||
        generator['id'] != generatorId ||
        generator['version'] != generatorVersion ||
        difficulty['source'] != difficultySource ||
        difficulty['status'] != difficultyStatus) {
      throw const FormatException('Unsupported practice item contract.');
    }

    return PracticeItem._(
      itemId: json['item_id'] as String,
      courseCode: json['course_code'] as String,
      expectationId: expectation['id'] as String,
      expectationText: expectation['text'] as String,
      generatorSeed: generator['seed'] as int,
      prompt: json['prompt'] as String,
      answerKind: PracticeAnswerKind.fromWireName(answer['kind'] as String),
      canonicalAnswer: answer['canonical'] as String,
      hints: List<String>.unmodifiable((json['hints'] as List).cast<String>()),
      difficultyValue: (difficulty['value'] as num).toDouble(),
      itemDigest: json['item_digest'] as String,
    );
  }

  bool get hasValidDigest {
    final payload = _digestPayload(
      itemId: itemId,
      courseCode: courseCode,
      expectationId: expectationId,
      expectationText: expectationText,
      generatorSeed: generatorSeed,
      prompt: prompt,
      answerKind: answerKind,
      canonicalAnswer: canonicalAnswer,
      hints: hints,
      difficultyValue: difficultyValue,
    );
    final actual = sha256.convert(utf8.encode(jsonEncode(payload))).toString();
    return actual == itemDigest;
  }

  Map<String, dynamic> toJson() => {
    ..._digestPayload(
      itemId: itemId,
      courseCode: courseCode,
      expectationId: expectationId,
      expectationText: expectationText,
      generatorSeed: generatorSeed,
      prompt: prompt,
      answerKind: answerKind,
      canonicalAnswer: canonicalAnswer,
      hints: hints,
      difficultyValue: difficultyValue,
    ),
    'item_digest': itemDigest,
  };

  static Map<String, dynamic> _digestPayload({
    required String itemId,
    required String courseCode,
    required String expectationId,
    required String expectationText,
    required int generatorSeed,
    required String prompt,
    required PracticeAnswerKind answerKind,
    required String canonicalAnswer,
    required List<String> hints,
    required double difficultyValue,
  }) {
    return {
      'schema': schema,
      'item_id': itemId,
      'course_code': courseCode,
      'expectation': {'id': expectationId, 'text': expectationText},
      'generator': {
        'id': generatorId,
        'version': generatorVersion,
        'seed': generatorSeed,
      },
      'prompt': prompt,
      'answer': {'kind': answerKind.wireName, 'canonical': canonicalAnswer},
      'hints': List<String>.from(hints),
      'difficulty': {
        'value': difficultyValue,
        'source': difficultySource,
        'status': difficultyStatus,
      },
    };
  }
}
