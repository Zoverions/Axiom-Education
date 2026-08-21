import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/mth1w_foundation.dart';
import '../../core/practice/mth1w_practice_provider.dart';
import '../../core/providers/curriculum_provider.dart';
import '../practice/mth1w_practice_screen.dart';
import 'home_learning_guide_screen.dart';
import 'mth1w_course_screen.dart';

class Mth1wLearningHubScreen extends ConsumerWidget {
  const Mth1wLearningHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expectationsAsync = ref.watch(mth1wGoldenPathProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Grade 9 Math')),
      body: SafeArea(
        child: expectationsAsync.when(
          loading: () => const _HubLoadingState(),
          error: (error, stackTrace) => _HubErrorState(
            onRetry: () => ref.invalidate(mth1wGoldenPathProvider),
          ),
          data: (expectations) {
            final expectationsById = <String, CurriculumItem>{
              for (final expectation in expectations)
                expectation.id: expectation,
            };
            final complete = mth1wFoundationLessons.every(
              (lesson) => expectationsById.containsKey(lesson.expectationId),
            );
            if (!complete) {
              return _HubErrorState(
                onRetry: () => ref.invalidate(mth1wGoldenPathProvider),
              );
            }

            return _HubBody(expectationsById: expectationsById);
          },
        ),
      ),
    );
  }
}

class _HubBody extends StatelessWidget {
  const _HubBody({required this.expectationsById});

  final Map<String, CurriculumItem> expectationsById;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HubIntroCard(),
                const SizedBox(height: 20),
                Text(
                  'Start here',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Four short foundation lessons lead directly into focused practice.',
                ),
                const SizedBox(height: 12),
                for (final lesson in mth1wFoundationLessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FoundationLessonCard(
                      lesson: lesson,
                      expectation: expectationsById[lesson.expectationId]!,
                    ),
                  ),
                const SizedBox(height: 10),
                _PracticeCard(
                  onPractice: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const Mth1wPracticeScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const _SupportActions(),
                const SizedBox(height: 20),
                const _DraftCourseCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HubIntroCard extends StatelessWidget {
  const _HubIntroCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.functions_rounded,
              size: 38,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              'Build the foundations, then practise',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lessons and answer checking work locally and without an AI tutor. '
              'Choose a lesson below or use mixed practice when you want review.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 10),
            Text(
              'Preview status: this is not a complete MTH1W course, grade, credit, '
              'transcript, or Ministry-approved resource, and progress is not saved.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoundationLessonCard extends StatelessWidget {
  const _FoundationLessonCard({
    required this.lesson,
    required this.expectation,
  });

  final Mth1wFoundationLesson lesson;
  final CurriculumItem expectation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('hub-open-foundation-${lesson.expectationId}'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => Mth1wLessonScreen(
                lesson: lesson,
                expectation: expectation,
                lessonCount: mth1wFoundationLessons.length,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colors.secondaryContainer,
                foregroundColor: colors.onSecondaryContainer,
                child: Text('${lesson.sequence}'),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('About ${lesson.estimatedMinutes} minutes'),
                    const SizedBox(height: 6),
                    Text(lesson.whyItMatters),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.onPractice});

  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.edit_rounded, color: colors.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to practise?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Work through new items with exact local feedback. The '
                    'session summary is temporary and is not a grade or mastery result.',
                    style: TextStyle(color: colors.onSecondaryContainer),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('hub-open-mixed-practice'),
                    onPressed: onPractice,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start mixed practice'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportActions extends StatelessWidget {
  const _SupportActions();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const HomeLearningGuideScreen(),
          ),
        );
      },
      icon: const Icon(Icons.home_work_rounded),
      label: const Text('Open home learning guide'),
    );
  }
}

class _DraftCourseCard extends StatelessWidget {
  const _DraftCourseCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore more Grade 9 Math',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nine draft units are available for exploration. They are linked '
              'to official course expectations, but educator and cultural review '
              'is still required, so they remain separate from the simple start-here path.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('hub-open-draft-course'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const Mth1wCourseScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore draft units'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubLoadingState extends StatelessWidget {
  const _HubLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Loading Grade 9 Math',
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

class _HubErrorState extends StatelessWidget {
  const _HubErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: colors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Grade 9 Math could not be prepared',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The required lesson references are incomplete or unavailable. '
                    'No lesson or practice result was inferred.',
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
        ),
      ),
    );
  }
}
