import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/learning/mth1w_unit_content.dart';

const contentPath = 'curriculum/content/mth1w/u1-number-systems.v1.json';
const unitTwoContentPath = 'curriculum/content/mth1w/u2-powers.v1.json';
const unitThreeContentPath =
    'curriculum/content/mth1w/u3-rational-applications.v1.json';
const unitFourContentPath =
    'curriculum/content/mth1w/u4-algebraic-thinking.v1.json';

String source() => File(contentPath).readAsStringSync();
String unitTwoSource() => File(unitTwoContentPath).readAsStringSync();
String unitThreeSource() => File(unitThreeContentPath).readAsStringSync();
String unitFourSource() => File(unitFourContentPath).readAsStringSync();

void main() {
  group('MTH1W authored Unit 1 content', () {
    test('loads the complete offline teaching package', () {
      final unit = Mth1wUnitContent.fromJsonString(source());

      expect(unit.unitId, 'mth1w-u1');
      expect(unit.lessons, hasLength(3));
      expect(
        unit.lessons.expand((lesson) => lesson.workedExamples),
        hasLength(6),
      );
      expect(
        unit.lessons.expand(
          (lesson) => [
            ...lesson.practiceSets.guided,
            ...lesson.practiceSets.independent,
            ...lesson.practiceSets.retrieval,
          ],
        ),
        hasLength(33),
      );
      expect(unit.assessment.quiz.items, hasLength(10));
      expect(unit.assessment.performanceTask.rubric, hasLength(5));
    });

    test('auto-checks selected and short-text responses exactly', () {
      final unit = Mth1wUnitContent.fromJsonString(source());
      final selected = unit.lessons.first.practiceSets.guided.first.response;
      final shortText = unit.lessons[1].practiceSets.retrieval.last.response;

      expect(selected.isAutoCheckable, isTrue);
      expect(selected.isCorrect(selected.correctAnswer!), isTrue);
      expect(selected.isCorrect('wrong'), isFalse);
      expect(shortText.isCorrect('NATURAL NUMBER'), isTrue);
      expect(shortText.isCorrect('integer'), isFalse);
    });

    test('constructed responses remain educator-reviewed', () {
      final unit = Mth1wUnitContent.fromJsonString(source());
      final response = unit.lessons.first.practiceSets.guided.last.response;

      expect(response.type, Mth1wResponseType.constructed);
      expect(response.isAutoCheckable, isFalse);
      expect(response.educatorReviewRequired, isTrue);
      expect(response.criteria, isNotEmpty);
      expect(response.sampleResponse, isNotEmpty);
    });

    test('fails closed when the preview boundary is altered', () {
      final payload = jsonDecode(source()) as Map<String, dynamic>;
      (payload['review']
              as Map<String, dynamic>)['complete_course_claim_allowed'] =
          true;

      expect(
        () => Mth1wUnitContent.fromJson(payload),
        throwsA(isA<Mth1wUnitContentFormatException>()),
      );
    });

    test('fails closed for an unsupported response contract', () {
      final payload = jsonDecode(source()) as Map<String, dynamic>;
      final lessons = payload['lessons'] as List<dynamic>;
      final firstLesson = lessons.first as Map<String, dynamic>;
      final practice = firstLesson['practice_sets'] as Map<String, dynamic>;
      final guided = practice['guided'] as List<dynamic>;
      final firstItem = guided.first as Map<String, dynamic>;
      (firstItem['response'] as Map<String, dynamic>)['type'] = 'mystery';

      expect(
        () => Mth1wUnitContent.fromJson(payload),
        throwsA(isA<Mth1wUnitContentFormatException>()),
      );
    });
  });

  group('MTH1W authored Unit 2 content', () {
    test('loads the complete offline teaching package', () {
      final unit = Mth1wUnitContent.fromJsonString(unitTwoSource());

      expect(unit.unitId, 'mth1w-u2');
      expect(unit.lessons, hasLength(2));
      expect(
        unit.lessons.expand((lesson) => lesson.workedExamples),
        hasLength(4),
      );
      expect(
        unit.lessons.expand(
          (lesson) => [
            ...lesson.practiceSets.guided,
            ...lesson.practiceSets.independent,
            ...lesson.practiceSets.retrieval,
          ],
        ),
        hasLength(22),
      );
      expect(unit.assessment.quiz.items, hasLength(10));
      expect(unit.assessment.performanceTask.rubric, hasLength(5));
    });

    test('checks exact quiz responses and preserves written review', () {
      final unit = Mth1wUnitContent.fromJsonString(unitTwoSource());
      final exact = unit.assessment.quiz.items[3].response;
      final written = unit.assessment.quiz.items[4].response;

      expect(exact.isCorrect('870,000'), isTrue);
      expect(exact.isCorrect('87000'), isFalse);
      expect(written.type, Mth1wResponseType.constructed);
      expect(written.isAutoCheckable, isFalse);
      expect(written.educatorReviewRequired, isTrue);
    });
  });

  group('MTH1W authored Unit 3 content', () {
    test('loads the complete rational-application package', () {
      final unit = Mth1wUnitContent.fromJsonString(unitThreeSource());

      expect(unit.unitId, 'mth1w-u3');
      expect(unit.lessons, hasLength(5));
      expect(
        unit.lessons.expand((lesson) => lesson.workedExamples),
        hasLength(10),
      );
      expect(
        unit.lessons.expand(
          (lesson) => [
            ...lesson.practiceSets.guided,
            ...lesson.practiceSets.independent,
            ...lesson.practiceSets.retrieval,
          ],
        ),
        hasLength(55),
      );
      expect(unit.assessment.quiz.items, hasLength(10));
      expect(unit.assessment.performanceTask.rubric, hasLength(5));
    });
  });

  group('MTH1W authored Unit 4 content', () {
    test('loads the complete algebraic-thinking package', () {
      final unit = Mth1wUnitContent.fromJsonString(unitFourSource());

      expect(unit.unitId, 'mth1w-u4');
      expect(unit.lessons, hasLength(5));
      expect(
        unit.lessons.expand((lesson) => lesson.workedExamples),
        hasLength(10),
      );
      expect(
        unit.lessons.expand(
          (lesson) => [
            ...lesson.practiceSets.guided,
            ...lesson.practiceSets.independent,
            ...lesson.practiceSets.retrieval,
          ],
        ),
        hasLength(55),
      );
      expect(unit.assessment.quiz.items, hasLength(10));
      expect(unit.assessment.performanceTask.rubric, hasLength(5));
    });
  });
}
