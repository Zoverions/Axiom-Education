import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/mth1w_unit_content.dart';
import '../../core/providers/mth1w_unit_content_provider.dart';
import 'mth1w_draft_unit_screen.dart';

class Mth1wSplitDraftUnitScreen extends ConsumerWidget {
  const Mth1wSplitDraftUnitScreen({super.key, required this.unitNumber})
    : assert(unitNumber == 8 || unitNumber == 9);

  final int unitNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = mth1wUnitProvider(unitNumber);
    final unitAsync = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(title: Text('MTH1W draft Unit $unitNumber')),
      body: SafeArea(
        child: unitAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _SplitUnitLoadError(
            unitNumber: unitNumber,
            onRetry: () => ref.invalidate(provider),
          ),
          data: (unit) => _SplitUnitBody(unit: unit),
        ),
      ),
    );
  }
}

class _SplitUnitLoadError extends StatelessWidget {
  const _SplitUnitLoadError({required this.unitNumber, required this.onRetry});

  final int unitNumber;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                'Draft Unit $unitNumber is unavailable because its split bundled content did not load or validate.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'No partial lesson set is substituted when the manifest or a referenced lesson asset fails validation.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitUnitBody extends StatelessWidget {
  const _SplitUnitBody({required this.unit});

  final Mth1wUnitContent unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final expectationIds = unit.lessons
        .expand((lesson) => lesson.officialExpectationIds)
        .join(', ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: colors.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.construction_rounded, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          unit.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Source-mapped split draft preview bound to official references $expectationIds. The manifest and every lesson asset must validate before this screen opens.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Educator and cultural review remain required. This is not a complete MTH1W course, grade, credit, transcript, Ministry-approved resource, or personal financial advice. Nothing on this screen is saved as progress.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Lessons',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                for (var index = 0; index < unit.lessons.length; index += 1)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      key: ValueKey(
                        'mth1w-split-draft-lesson-${unit.lessons[index].id}',
                      ),
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(unit.lessons[index].title),
                      subtitle: Text(
                        'Official reference ${unit.lessons[index].officialExpectationIds.join(', ')} • About ${unit.lessons[index].estimatedMinutes} minutes',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => Mth1wDraftLessonScreen(
                              lesson: unit.lessons[index],
                              sequence: index + 1,
                              lessonCount: unit.lessons.length,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Unit assessment',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: ValueKey('${unit.unitId}-open-quiz'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            Mth1wDraftQuizScreen(quiz: unit.assessment.quiz),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fact_check_rounded),
                  label: Text(
                    '${unit.assessment.quiz.title} (${unit.assessment.quiz.estimatedMinutes} minutes)',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: ValueKey('${unit.unitId}-open-performance-task'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => Mth1wDraftPerformanceTaskScreen(
                          task: unit.assessment.performanceTask,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_rounded),
                  label: Text(unit.assessment.performanceTask.title),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher background sources',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        for (final source in unit.sourceNotes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  source.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(source.publisher),
                                SelectableText(source.url),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
