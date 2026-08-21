import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/curriculum_provider.dart';
import '../learning/mth1w_learning_hub_screen.dart';

class CurriculumCourseReferenceScreen extends ConsumerWidget {
  const CurriculumCourseReferenceScreen({
    super.key,
    required this.courseId,
    required this.fallbackCourseName,
  });

  final String courseId;
  final String fallbackCourseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(courseDetailProvider(courseId));

    return Scaffold(
      appBar: AppBar(title: Text(courseId)),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const _ReferenceLoadingState(),
          error: (error, stackTrace) => _ReferenceErrorState(
            onRetry: () => ref.invalidate(courseDetailProvider(courseId)),
          ),
          data: (detail) {
            if (detail.strands.isEmpty) {
              return _ReferenceEmptyState(
                title: fallbackCourseName,
                message: 'No expectations are available for this course.',
              );
            }
            return _CourseReferenceBody(courseId: courseId, detail: detail);
          },
        ),
      ),
    );
  }
}

class _CourseReferenceBody extends StatelessWidget {
  const _CourseReferenceBody({required this.courseId, required this.detail});

  final String courseId;
  final CourseDetail detail;

  @override
  Widget build(BuildContext context) {
    final expectationCount = detail.strands.fold<int>(
      0,
      (total, strand) => total + strand.expectations.length,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: _ReferenceHeader(
              courseId: courseId,
              courseName: detail.name,
              strandCount: detail.strands.length,
              expectationCount: expectationCount,
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final strand in detail.strands)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  title: Text(
                    strand.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${strand.expectations.length} expectations'),
                  children: [
                    for (final expectation in strand.expectations)
                      ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(
                          24,
                          8,
                          24,
                          12,
                        ),
                        title: SelectableText(expectation.text),
                        subtitle: expectation.tags.isEmpty
                            ? null
                            : Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final tag in expectation.tags)
                                      Chip(
                                        label: Text(tag),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReferenceHeader extends StatelessWidget {
  const _ReferenceHeader({
    required this.courseId,
    required this.courseName,
    required this.strandCount,
    required this.expectationCount,
  });

  final String courseId;
  final String courseName;
  final int strandCount;
  final int expectationCount;

  @override
  Widget build(BuildContext context) {
    final isMth1w = courseId == 'MTH1W';
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              courseName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$strandCount strands • $expectationCount expectations',
              style: TextStyle(color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 10),
            Text(
              'Reference view only. Opening or reading an expectation does not '
              'mark it complete, save progress, create a grade, or establish mastery.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
            ),
            if (isMth1w) ...[
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const Mth1wLearningHubScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.school_rounded),
                label: const Text('Open Grade 9 Math learning'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReferenceLoadingState extends StatelessWidget {
  const _ReferenceLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Semantics(
        liveRegion: true,
        label: 'Loading course reference',
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ReferenceErrorState extends StatelessWidget {
  const _ReferenceErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 46, color: colors.error),
              const SizedBox(height: 14),
              Text(
                'This course reference could not be opened',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Try loading this course again from the bundled local curriculum.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceEmptyState extends StatelessWidget {
  const _ReferenceEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 46),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
