import 'dart:convert';

class Mth1wUnitContentFormatException implements Exception {
  const Mth1wUnitContentFormatException(this.message);

  final String message;

  @override
  String toString() => 'Mth1wUnitContentFormatException: $message';
}

Map<String, dynamic> _map(Object? value, String path) {
  if (value is! Map<String, dynamic>) {
    throw Mth1wUnitContentFormatException('$path must be an object');
  }
  return value;
}

List<dynamic> _list(Object? value, String path) {
  if (value is! List<dynamic>) {
    throw Mth1wUnitContentFormatException('$path must be an array');
  }
  return value;
}

String _string(Object? value, String path) {
  if (value is! String || value.trim().isEmpty) {
    throw Mth1wUnitContentFormatException('$path must be a non-empty string');
  }
  return value;
}

int _integer(Object? value, String path) {
  if (value is! int) {
    throw Mth1wUnitContentFormatException('$path must be an integer');
  }
  return value;
}

bool _boolean(Object? value, String path) {
  if (value is! bool) {
    throw Mth1wUnitContentFormatException('$path must be a boolean');
  }
  return value;
}

List<String> _strings(Object? value, String path) {
  final values = _list(value, path);
  return [
    for (var index = 0; index < values.length; index += 1)
      _string(values[index], '$path[$index]'),
  ];
}

class Mth1wSourceNote {
  const Mth1wSourceNote({
    required this.title,
    required this.publisher,
    required this.url,
    required this.use,
  });

  factory Mth1wSourceNote.fromJson(Map<String, dynamic> json, String path) {
    return Mth1wSourceNote(
      title: _string(json['title'], '$path.title'),
      publisher: _string(json['publisher'], '$path.publisher'),
      url: _string(json['url'], '$path.url'),
      use: _string(json['use'], '$path.use'),
    );
  }

  final String title;
  final String publisher;
  final String url;
  final String use;
}

class Mth1wVocabularyEntry {
  const Mth1wVocabularyEntry({required this.term, required this.meaning});

  factory Mth1wVocabularyEntry.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    return Mth1wVocabularyEntry(
      term: _string(json['term'], '$path.term'),
      meaning: _string(json['meaning'], '$path.meaning'),
    );
  }

  final String term;
  final String meaning;
}

class Mth1wInstructionBlock {
  const Mth1wInstructionBlock({required this.heading, required this.body});

  factory Mth1wInstructionBlock.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    return Mth1wInstructionBlock(
      heading: _string(json['heading'], '$path.heading'),
      body: _string(json['body'], '$path.body'),
    );
  }

  final String heading;
  final String body;
}

class Mth1wMethodRouteContent {
  const Mth1wMethodRouteContent({
    required this.id,
    required this.title,
    required this.steps,
    required this.whenUseful,
    required this.check,
  });

  factory Mth1wMethodRouteContent.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    return Mth1wMethodRouteContent(
      id: _string(json['id'], '$path.id'),
      title: _string(json['title'], '$path.title'),
      steps: _strings(json['steps'], '$path.steps'),
      whenUseful: _string(json['when_useful'], '$path.when_useful'),
      check: _string(json['check'], '$path.check'),
    );
  }

  final String id;
  final String title;
  final List<String> steps;
  final String whenUseful;
  final String check;
}

class Mth1wRepresentationContent {
  const Mth1wRepresentationContent({
    required this.id,
    required this.label,
    required this.description,
    required this.textAlternative,
  });

  factory Mth1wRepresentationContent.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    return Mth1wRepresentationContent(
      id: _string(json['id'], '$path.id'),
      label: _string(json['label'], '$path.label'),
      description: _string(json['description'], '$path.description'),
      textAlternative: _string(
        json['text_alternative'],
        '$path.text_alternative',
      ),
    );
  }

  final String id;
  final String label;
  final String description;
  final String textAlternative;
}

class Mth1wWorkedStepContent {
  const Mth1wWorkedStepContent({
    required this.label,
    required this.explanation,
  });

  factory Mth1wWorkedStepContent.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    return Mth1wWorkedStepContent(
      label: _string(json['label'], '$path.label'),
      explanation: _string(json['explanation'], '$path.explanation'),
    );
  }

  final String label;
  final String explanation;
}

class Mth1wWorkedExampleContent {
  const Mth1wWorkedExampleContent({
    required this.id,
    required this.prompt,
    required this.methodRouteId,
    required this.steps,
    required this.answer,
    required this.verification,
  });

  factory Mth1wWorkedExampleContent.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    final steps = _list(json['steps'], '$path.steps');
    return Mth1wWorkedExampleContent(
      id: _string(json['id'], '$path.id'),
      prompt: _string(json['prompt'], '$path.prompt'),
      methodRouteId: _string(json['method_route_id'], '$path.method_route_id'),
      steps: [
        for (var index = 0; index < steps.length; index += 1)
          Mth1wWorkedStepContent.fromJson(
            _map(steps[index], '$path.steps[$index]'),
            '$path.steps[$index]',
          ),
      ],
      answer: _string(json['answer'], '$path.answer'),
      verification: _string(json['verification'], '$path.verification'),
    );
  }

  final String id;
  final String prompt;
  final String methodRouteId;
  final List<Mth1wWorkedStepContent> steps;
  final String answer;
  final String verification;
}

class Mth1wMisconceptionContent {
  const Mth1wMisconceptionContent({
    required this.claim,
    required this.correction,
  });

  factory Mth1wMisconceptionContent.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    return Mth1wMisconceptionContent(
      claim: _string(json['claim'], '$path.claim'),
      correction: _string(json['correction'], '$path.correction'),
    );
  }

  final String claim;
  final String correction;
}

enum Mth1wResponseType { selected, shortText, constructed }

class Mth1wResponseContract {
  const Mth1wResponseContract({
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.acceptedAnswers,
    required this.criteria,
    required this.sampleResponse,
    required this.educatorReviewRequired,
  });

  factory Mth1wResponseContract.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    final typeText = _string(json['type'], '$path.type');
    final type = switch (typeText) {
      'selected' => Mth1wResponseType.selected,
      'short_text' => Mth1wResponseType.shortText,
      'constructed' => Mth1wResponseType.constructed,
      _ => throw Mth1wUnitContentFormatException(
        '$path.type is unsupported: $typeText',
      ),
    };

    return Mth1wResponseContract(
      type: type,
      options: type == Mth1wResponseType.selected
          ? _strings(json['options'], '$path.options')
          : const [],
      correctAnswer: type == Mth1wResponseType.selected
          ? _string(json['correct_answer'], '$path.correct_answer')
          : null,
      acceptedAnswers: type == Mth1wResponseType.shortText
          ? _strings(json['accepted_answers'], '$path.accepted_answers')
          : const [],
      criteria: type == Mth1wResponseType.constructed
          ? _strings(json['criteria'], '$path.criteria')
          : const [],
      sampleResponse: type == Mth1wResponseType.constructed
          ? _string(json['sample_response'], '$path.sample_response')
          : null,
      educatorReviewRequired: type == Mth1wResponseType.constructed
          ? _boolean(
              json['educator_review_required'],
              '$path.educator_review_required',
            )
          : false,
    );
  }

  final Mth1wResponseType type;
  final List<String> options;
  final String? correctAnswer;
  final List<String> acceptedAnswers;
  final List<String> criteria;
  final String? sampleResponse;
  final bool educatorReviewRequired;

  bool get isAutoCheckable => type != Mth1wResponseType.constructed;

  bool isCorrect(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (type) {
      Mth1wResponseType.selected =>
        normalized == correctAnswer!.trim().toLowerCase(),
      Mth1wResponseType.shortText => acceptedAnswers.any(
        (answer) => answer.trim().toLowerCase() == normalized,
      ),
      Mth1wResponseType.constructed => false,
    };
  }

  String get disclosedAnswer {
    return switch (type) {
      Mth1wResponseType.selected => correctAnswer!,
      Mth1wResponseType.shortText => acceptedAnswers.join(' or '),
      Mth1wResponseType.constructed => sampleResponse!,
    };
  }
}

class Mth1wPracticeItemContent {
  const Mth1wPracticeItemContent({
    required this.id,
    required this.prompt,
    required this.response,
    required this.rationale,
    required this.officialExpectationIds,
  });

  factory Mth1wPracticeItemContent.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    return Mth1wPracticeItemContent(
      id: _string(json['id'], '$path.id'),
      prompt: _string(json['prompt'], '$path.prompt'),
      response: Mth1wResponseContract.fromJson(
        _map(json['response'], '$path.response'),
        '$path.response',
      ),
      rationale: _string(json['rationale'], '$path.rationale'),
      officialExpectationIds: json.containsKey('official_expectation_ids')
          ? _strings(
              json['official_expectation_ids'],
              '$path.official_expectation_ids',
            )
          : const [],
    );
  }

  final String id;
  final String prompt;
  final Mth1wResponseContract response;
  final String rationale;
  final List<String> officialExpectationIds;
}

class Mth1wPracticeSetsContent {
  const Mth1wPracticeSetsContent({
    required this.guided,
    required this.independent,
    required this.retrieval,
  });

  factory Mth1wPracticeSetsContent.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    List<Mth1wPracticeItemContent> parseItems(String key) {
      final items = _list(json[key], '$path.$key');
      return [
        for (var index = 0; index < items.length; index += 1)
          Mth1wPracticeItemContent.fromJson(
            _map(items[index], '$path.$key[$index]'),
            '$path.$key[$index]',
          ),
      ];
    }

    return Mth1wPracticeSetsContent(
      guided: parseItems('guided'),
      independent: parseItems('independent'),
      retrieval: parseItems('retrieval'),
    );
  }

  final List<Mth1wPracticeItemContent> guided;
  final List<Mth1wPracticeItemContent> independent;
  final List<Mth1wPracticeItemContent> retrieval;
}

class Mth1wLessonAccessibilityContent {
  const Mth1wLessonAccessibilityContent({
    required this.printableEquivalent,
    required this.nonvisualRoute,
    required this.responseOptions,
  });

  factory Mth1wLessonAccessibilityContent.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    return Mth1wLessonAccessibilityContent(
      printableEquivalent: _boolean(
        json['printable_equivalent'],
        '$path.printable_equivalent',
      ),
      nonvisualRoute: _string(json['nonvisual_route'], '$path.nonvisual_route'),
      responseOptions: _strings(
        json['response_options'],
        '$path.response_options',
      ),
    );
  }

  final bool printableEquivalent;
  final String nonvisualRoute;
  final List<String> responseOptions;
}

class Mth1wLessonContent {
  const Mth1wLessonContent({
    required this.id,
    required this.title,
    required this.officialExpectationIds,
    required this.estimatedMinutes,
    required this.learningGoals,
    required this.successCriteria,
    required this.vocabulary,
    required this.whyItMatters,
    required this.directInstruction,
    required this.methodRoutes,
    required this.representations,
    required this.workedExamples,
    required this.misconceptions,
    required this.practiceSets,
    required this.reflectionPrompt,
    required this.accessibility,
  });

  factory Mth1wLessonContent.fromJson(Map<String, dynamic> json, String path) {
    final vocabulary = _list(json['vocabulary'], '$path.vocabulary');
    final instruction = _list(
      json['direct_instruction'],
      '$path.direct_instruction',
    );
    final methods = _list(json['method_routes'], '$path.method_routes');
    final representations = _list(
      json['representations'],
      '$path.representations',
    );
    final examples = _list(json['worked_examples'], '$path.worked_examples');
    final misconceptions = _list(
      json['misconceptions'],
      '$path.misconceptions',
    );
    return Mth1wLessonContent(
      id: _string(json['id'], '$path.id'),
      title: _string(json['title'], '$path.title'),
      officialExpectationIds: _strings(
        json['official_expectation_ids'],
        '$path.official_expectation_ids',
      ),
      estimatedMinutes: _integer(
        json['estimated_minutes'],
        '$path.estimated_minutes',
      ),
      learningGoals: _strings(json['learning_goals'], '$path.learning_goals'),
      successCriteria: _strings(
        json['success_criteria'],
        '$path.success_criteria',
      ),
      vocabulary: [
        for (var index = 0; index < vocabulary.length; index += 1)
          Mth1wVocabularyEntry.fromJson(
            _map(vocabulary[index], '$path.vocabulary[$index]'),
            '$path.vocabulary[$index]',
          ),
      ],
      whyItMatters: _string(json['why_it_matters'], '$path.why_it_matters'),
      directInstruction: [
        for (var index = 0; index < instruction.length; index += 1)
          Mth1wInstructionBlock.fromJson(
            _map(instruction[index], '$path.direct_instruction[$index]'),
            '$path.direct_instruction[$index]',
          ),
      ],
      methodRoutes: [
        for (var index = 0; index < methods.length; index += 1)
          Mth1wMethodRouteContent.fromJson(
            _map(methods[index], '$path.method_routes[$index]'),
            '$path.method_routes[$index]',
          ),
      ],
      representations: [
        for (var index = 0; index < representations.length; index += 1)
          Mth1wRepresentationContent.fromJson(
            _map(representations[index], '$path.representations[$index]'),
            '$path.representations[$index]',
          ),
      ],
      workedExamples: [
        for (var index = 0; index < examples.length; index += 1)
          Mth1wWorkedExampleContent.fromJson(
            _map(examples[index], '$path.worked_examples[$index]'),
            '$path.worked_examples[$index]',
          ),
      ],
      misconceptions: [
        for (var index = 0; index < misconceptions.length; index += 1)
          Mth1wMisconceptionContent.fromJson(
            _map(misconceptions[index], '$path.misconceptions[$index]'),
            '$path.misconceptions[$index]',
          ),
      ],
      practiceSets: Mth1wPracticeSetsContent.fromJson(
        _map(json['practice_sets'], '$path.practice_sets'),
        '$path.practice_sets',
      ),
      reflectionPrompt: _string(
        json['reflection_prompt'],
        '$path.reflection_prompt',
      ),
      accessibility: Mth1wLessonAccessibilityContent.fromJson(
        _map(json['accessibility'], '$path.accessibility'),
        '$path.accessibility',
      ),
    );
  }

  final String id;
  final String title;
  final List<String> officialExpectationIds;
  final int estimatedMinutes;
  final List<String> learningGoals;
  final List<String> successCriteria;
  final List<Mth1wVocabularyEntry> vocabulary;
  final String whyItMatters;
  final List<Mth1wInstructionBlock> directInstruction;
  final List<Mth1wMethodRouteContent> methodRoutes;
  final List<Mth1wRepresentationContent> representations;
  final List<Mth1wWorkedExampleContent> workedExamples;
  final List<Mth1wMisconceptionContent> misconceptions;
  final Mth1wPracticeSetsContent practiceSets;
  final String reflectionPrompt;
  final Mth1wLessonAccessibilityContent accessibility;
}

class Mth1wQuizContent {
  const Mth1wQuizContent({
    required this.id,
    required this.title,
    required this.estimatedMinutes,
    required this.items,
  });

  factory Mth1wQuizContent.fromJson(Map<String, dynamic> json, String path) {
    final items = _list(json['items'], '$path.items');
    return Mth1wQuizContent(
      id: _string(json['id'], '$path.id'),
      title: _string(json['title'], '$path.title'),
      estimatedMinutes: _integer(
        json['estimated_minutes'],
        '$path.estimated_minutes',
      ),
      items: [
        for (var index = 0; index < items.length; index += 1)
          Mth1wPracticeItemContent.fromJson(
            _map(items[index], '$path.items[$index]'),
            '$path.items[$index]',
          ),
      ],
    );
  }

  final String id;
  final String title;
  final int estimatedMinutes;
  final List<Mth1wPracticeItemContent> items;
}

class Mth1wRubricDimensionContent {
  const Mth1wRubricDimensionContent({
    required this.dimension,
    required this.criteria,
  });

  factory Mth1wRubricDimensionContent.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    return Mth1wRubricDimensionContent(
      dimension: _string(json['dimension'], '$path.dimension'),
      criteria: _string(json['criteria'], '$path.criteria'),
    );
  }

  final String dimension;
  final String criteria;
}

class Mth1wPerformanceTaskContent {
  const Mth1wPerformanceTaskContent({
    required this.id,
    required this.title,
    required this.estimatedMinutes,
    required this.officialExpectationIds,
    required this.prompt,
    required this.requiredComponents,
    required this.rubric,
  });

  factory Mth1wPerformanceTaskContent.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    final rubric = _list(json['rubric'], '$path.rubric');
    return Mth1wPerformanceTaskContent(
      id: _string(json['id'], '$path.id'),
      title: _string(json['title'], '$path.title'),
      estimatedMinutes: _integer(
        json['estimated_minutes'],
        '$path.estimated_minutes',
      ),
      officialExpectationIds: _strings(
        json['official_expectation_ids'],
        '$path.official_expectation_ids',
      ),
      prompt: _string(json['prompt'], '$path.prompt'),
      requiredComponents: _strings(
        json['required_components'],
        '$path.required_components',
      ),
      rubric: [
        for (var index = 0; index < rubric.length; index += 1)
          Mth1wRubricDimensionContent.fromJson(
            _map(rubric[index], '$path.rubric[$index]'),
            '$path.rubric[$index]',
          ),
      ],
    );
  }

  final String id;
  final String title;
  final int estimatedMinutes;
  final List<String> officialExpectationIds;
  final String prompt;
  final List<String> requiredComponents;
  final List<Mth1wRubricDimensionContent> rubric;
}

class Mth1wUnitAssessmentContent {
  const Mth1wUnitAssessmentContent({
    required this.quiz,
    required this.performanceTask,
  });

  factory Mth1wUnitAssessmentContent.fromJson(
    Map<String, dynamic> json,
    String path,
  ) {
    return Mth1wUnitAssessmentContent(
      quiz: Mth1wQuizContent.fromJson(
        _map(json['quiz'], '$path.quiz'),
        '$path.quiz',
      ),
      performanceTask: Mth1wPerformanceTaskContent.fromJson(
        _map(json['performance_task'], '$path.performance_task'),
        '$path.performance_task',
      ),
    );
  }

  final Mth1wQuizContent quiz;
  final Mth1wPerformanceTaskContent performanceTask;
}

class Mth1wUnitContent {
  static const sourceInventoryRecordsSha256 =
      'd023c3ee1e441c13d0b8ca6bd9a87f9b6004766f92182303385511b517642766';

  const Mth1wUnitContent({
    required this.unitId,
    required this.title,
    required this.version,
    required this.lessons,
    required this.sourceNotes,
    required this.assessment,
  });

  factory Mth1wUnitContent.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 'axiom-education-unit-content.v1') {
      throw const Mth1wUnitContentFormatException(
        'unsupported unit content schema',
      );
    }
    if (json['course_code'] != 'MTH1W') {
      throw const Mth1wUnitContentFormatException(
        'unit content course must be MTH1W',
      );
    }
    if (json['source_inventory_records_sha256'] !=
        sourceInventoryRecordsSha256) {
      throw const Mth1wUnitContentFormatException(
        'unit content source inventory digest is invalid',
      );
    }
    final review = _map(json['review'], 'review');
    if (review['authoring_status'] != 'machine_verified_draft' ||
        review['educator_review_status'] != 'required' ||
        review['cultural_review_status'] != 'required') {
      throw const Mth1wUnitContentFormatException(
        'unit content review boundary is invalid',
      );
    }
    if (review['student_availability'] !=
        'draft_preview_with_adult_review_recommended') {
      throw const Mth1wUnitContentFormatException(
        'unit content availability boundary is invalid',
      );
    }
    if (review['complete_course_claim_allowed'] != false) {
      throw const Mth1wUnitContentFormatException(
        'unit content must not permit a complete-course claim',
      );
    }

    final lessons = _list(json['lessons'], 'lessons');
    final sources = _list(json['source_notes'], 'source_notes');
    if (lessons.isEmpty || sources.length < 2) {
      throw const Mth1wUnitContentFormatException(
        'unit content teaching or source evidence is incomplete',
      );
    }
    return Mth1wUnitContent(
      unitId: _string(json['unit_id'], 'unit_id'),
      title: _string(json['title'], 'title'),
      version: _string(json['version'], 'version'),
      lessons: [
        for (var index = 0; index < lessons.length; index += 1)
          Mth1wLessonContent.fromJson(
            _map(lessons[index], 'lessons[$index]'),
            'lessons[$index]',
          ),
      ],
      sourceNotes: [
        for (var index = 0; index < sources.length; index += 1)
          Mth1wSourceNote.fromJson(
            _map(sources[index], 'source_notes[$index]'),
            'source_notes[$index]',
          ),
      ],
      assessment: Mth1wUnitAssessmentContent.fromJson(
        _map(json['unit_assessment'], 'unit_assessment'),
        'unit_assessment',
      ),
    );
  }

  factory Mth1wUnitContent.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    return Mth1wUnitContent.fromJson(_map(decoded, 'root'));
  }

  final String unitId;
  final String title;
  final String version;
  final List<Mth1wLessonContent> lessons;
  final List<Mth1wSourceNote> sourceNotes;
  final Mth1wUnitAssessmentContent assessment;
}
