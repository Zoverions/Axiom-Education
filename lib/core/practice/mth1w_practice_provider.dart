import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/curriculum_provider.dart';
import 'math_practice_generator.dart';

class Mth1wPracticeConfigurationException implements Exception {
  const Mth1wPracticeConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'Mth1wPracticeConfigurationException: $message';
}

const List<String> mth1wGoldenPathOrder = [
  'MTH1W-A1',
  'MTH1W-A2',
  'MTH1W-B2',
  'MTH1W-B4',
];

final mth1wGoldenPathProvider = FutureProvider<List<CurriculumItem>>((
  ref,
) async {
  final bank = await ref.watch(curriculumBankProvider.future);
  final byId = <String, CurriculumItem>{
    for (final item in bank)
      if (item.courseCode == 'MTH1W' &&
          MathPracticeGenerator.supportedExpectationIds.contains(item.id))
        item.id: item,
  };

  final missing = mth1wGoldenPathOrder
      .where((expectationId) => !byId.containsKey(expectationId))
      .toList(growable: false);
  if (missing.isNotEmpty) {
    throw Mth1wPracticeConfigurationException(
      'The signed curriculum source is missing golden-path expectations: '
      '${missing.join(', ')}.',
    );
  }

  return List<CurriculumItem>.unmodifiable(
    mth1wGoldenPathOrder.map((expectationId) => byId[expectationId]!),
  );
});
