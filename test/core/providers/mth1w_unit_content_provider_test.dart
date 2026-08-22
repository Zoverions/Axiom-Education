import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/learning/mth1w_unit_content.dart';
import 'package:ontarioedai/core/providers/mth1w_unit_content_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads split Units 8 and 9 through the same runtime model', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final unitEight = await container.read(mth1wUnitEightProvider.future);
    final unitNine = await container.read(mth1wUnitNineProvider.future);

    expect(unitEight.unitId, 'mth1w-u8');
    expect(unitEight.title, 'Unit 8: Geometry and measurement');
    expect(unitEight.lessons, hasLength(6));
    expect(
      unitEight.lessons.map((lesson) => lesson.officialExpectationIds.single),
      orderedEquals(['E1.1', 'E1.2', 'E1.3', 'E1.4', 'E1.5', 'E1.6']),
    );
    expect(
      unitEight.lessons.expand((lesson) => lesson.workedExamples),
      hasLength(12),
    );
    expect(
      unitEight.lessons.expand(
        (lesson) => [
          ...lesson.practiceSets.guided,
          ...lesson.practiceSets.independent,
          ...lesson.practiceSets.retrieval,
        ],
      ),
      hasLength(66),
    );
    expect(unitEight.assessment.quiz.items, hasLength(10));

    expect(unitNine.unitId, 'mth1w-u9');
    expect(unitNine.title, 'Unit 9: Financial literacy and decisions');
    expect(unitNine.lessons, hasLength(4));
    expect(
      unitNine.lessons.map((lesson) => lesson.officialExpectationIds.single),
      orderedEquals(['F1.1', 'F1.2', 'F1.3', 'F1.4']),
    );
    expect(
      unitNine.lessons.expand((lesson) => lesson.workedExamples),
      hasLength(8),
    );
    expect(
      unitNine.lessons.expand(
        (lesson) => [
          ...lesson.practiceSets.guided,
          ...lesson.practiceSets.independent,
          ...lesson.practiceSets.retrieval,
        ],
      ),
      hasLength(44),
    );
    expect(unitNine.assessment.quiz.items, hasLength(10));
    expect(unitNine.assessment.performanceTask.officialExpectationIds, {
      'F1.1',
      'F1.2',
      'F1.3',
      'F1.4',
    });
  });

  test('keeps out-of-blueprint Unit 10 unavailable', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await expectLater(
      container.read(mth1wUnitProvider(10).future),
      throwsA(isA<Mth1wUnitContentFormatException>()),
    );
  });
}
