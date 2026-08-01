import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/learning/mth1w_unit_content.dart';

const contentPath = 'curriculum/content/mth1w/u1-number-systems.v1.json';

String source() => File(contentPath).readAsStringSync();

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
}
