import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/learning/mth1w_unit_content.dart';
import 'package:ontarioedai/core/providers/mth1w_unit_content_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads split Unit 8 through the same runtime content model', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final unit = await container.read(mth1wUnitEightProvider.future);

    expect(unit.unitId, 'mth1w-u8');
    expect(unit.title, 'Unit 8: Geometry and measurement');
    expect(unit.lessons, hasLength(6));
    expect(
      unit.lessons.map((lesson) => lesson.officialExpectationIds.single),
      orderedEquals(['E1.1', 'E1.2', 'E1.3', 'E1.4', 'E1.5', 'E1.6']),
    );
    expect(
      unit.lessons.expand((lesson) => lesson.workedExamples),
      hasLength(12),
    );
    expect(
      unit.lessons.expand(
        (lesson) => [
          ...lesson.practiceSets.guided,
          ...lesson.practiceSets.independent,
          ...lesson.practiceSets.retrieval,
        ],
      ),
      hasLength(66),
    );
    expect(unit.assessment.quiz.items, hasLength(10));
    expect(unit.assessment.performanceTask.officialExpectationIds, {
      'E1.1',
      'E1.2',
      'E1.3',
      'E1.4',
      'E1.5',
      'E1.6',
    });
  });

  test('keeps unauthored Unit 9 unavailable', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await expectLater(
      container.read(mth1wUnitProvider(9).future),
      throwsA(isA<Mth1wUnitContentFormatException>()),
    );
  });
}
