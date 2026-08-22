import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/mth1w_foundation.dart';
import '../../core/practice/mth1w_practice_provider.dart';
import '../../core/providers/curriculum_provider.dart';
import '../practice/mth1w_practice_screen.dart';
import 'home_learning_guide_screen.dart';
import 'mth1w_draft_unit_screen.dart';
import 'mth1w_split_draft_unit_screen.dart';

const _draftUnits = <_DraftUnitLink>[
  _DraftUnitLink(
    unitNumber: 1,
    icon: Icons.construction_rounded,
    description:
        'Three draft lessons mapped to official B1.1-B1.3: number systems, histories, density, infinity, and limits.',
  ),
  _DraftUnitLink(
    unitNumber: 2,
    icon: Icons.exposure_rounded,
    description:
        'Two draft lessons mapped to official B2.1-B2.2: powers, scientific notation, and exponent relationships.',
  ),
  _DraftUnitLink(
    unitNumber: 3,
    icon: Icons.calculate_rounded,
    description:
        'Five draft lessons mapped to official B3.1-B3.5: signed quantities, fractions, rates, percentages, and proportions.',
  ),
  _DraftUnitLink(
    unitNumber: 4,
    icon: Icons.functions_rounded,
    description:
        'Five draft lessons mapped to official C1.1-C1.5: algebraic histories, patterns, equivalence, simplification, and equations.',
  ),
  _DraftUnitLink(
    unitNumber: 5,
    icon: Icons.code_rounded,
    description:
        'Three draft lessons mapped to official C2.1-C2.3: variables, conditions, algorithm decomposition, prediction, testing, and revision.',
  ),
  _DraftUnitLink(
    unitNumber: 6,
    icon: Icons.show_chart_rounded,
    description:
        'Seven draft lessons mapped to official C3.1-C4.4: relations, representations, intersections, graph features, solution regions, transformations, and linear equations.',
  ),
  _DraftUnitLink(
    unitNumber: 7,
    icon: Icons.analytics_rounded,
    description:
        'Eight draft lessons mapped to official D1.1-D2.5: responsible data use, distributions, regression, and a safe evidence-to-model investigation cycle.',
  ),
  _DraftUnitLink(
    unitNumber: 8,
    icon: Icons.straighten_rounded,
    description:
        'Six split draft lessons mapped to official E1.1-E1.6: geometry, construction, measurement, scale, Pythagorean reasoning, and composite measurement.',
  ),
  _DraftUnitLink(
    unitNumber: 9,
    icon: Icons.account_balance_wallet_rounded,
    description:
        'Four split draft lessons mapped to official F1.1-F1.4: financial context, value over time, borrowing scenarios, and budget revision without product recommendations.',
  ),
];

class _DraftUnitLink {
  const _DraftUnitLink({
    required this.unitNumber,
    required this.icon,
    required this.description,
  });

  final int unitNumber;
  final IconData icon;
  final String description;
}

class Mth1wCourseScreen extends ConsumerWidget {
  const Mth1wCourseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expectationsAsync = ref.watch(mth1wGoldenPathProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Grade 9 Math Foundations')),
      body: SafeArea(
        child: expectationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _CourseConfigurationError(
            onRetry: () => ref.invalidate(mth1wGoldenPathProvider),
          ),
          data: (expectations) {
            final expectationsById = {
              for (final expectation in expectations)
                expectation.id: expectation,
            };
            final complete = mth1wFoundationLessons.every(
              (lesson) => expectationsById.containsKey(lesson.expectationId),
            );
            if (!complete) {
              return _CourseConfigurationError(
                onRetry: () => ref.invalidate(mth1wGoldenPathProvider),
              );
            }

            return _CourseBody(
              lessons: mth1wFoundationLessons,
              expectationsById: expectationsById,
            );
          },
        ),
      ),
    );
  }
}

class _CourseBody extends StatelessWidget {
  const _CourseBody({required this.lessons, required this.expectationsById});

  final List<Mth1wFoundationLesson> lessons;
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
                const _CourseOverviewCard(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const HomeLearningGuideScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.home_work_rounded),
                  label: const Text('Open home learning guide'),
                ),
                for (final unit in _draftUnits) _DraftUnitEntry(unit: unit),
                const SizedBox(height: 16),
                Text(
                  'Foundation lessons',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Follow the sequence or open any lesson for review.',
                ),
                const SizedBox(height: 10),
                for (final lesson in lessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LessonTile(
                      lesson: lesson,
                      expectation: expectationsById[lesson.expectationId]!,
                    ),
                  ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const Mth1wPracticeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('Open mixed practice'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DraftUnitEntry extends StatelessWidget {
  const _DraftUnitEntry({required this.unit});

  final _DraftUnitLink unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: ValueKey('mth1w-open-draft-unit-${unit.unitNumber}'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => unit.unitNumber >= 8
                      ? Mth1wSplitDraftUnitScreen(unitNumber: unit.unitNumber)
                      : Mth1wDraftUnitScreen(unitNumber: unit.unitNumber),
                ),
              );
            },
            icon: Icon(unit.icon),
            label: Text('Open draft Unit ${unit.unitNumber}'),
          ),
          const SizedBox(height: 8),
          Text(
            '${unit.description} Educator and cultural review remain required.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CourseOverviewCard extends StatelessWidget {
  const _CourseOverviewCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.school_rounded,
              size: 36,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              'Foundations preview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Learn each concept, study a worked example, then practise with '
              'exact local feedback. Every lesson works offline and without an '
              'AI tutor.',
              style: TextStyle(color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 10),
            Text(
              'This is not a complete MTH1W course, credit, grade, transcript, '
              'or Ministry-approved resource. The draft is linked to the official '
              'course expectations, but educator review is still pending and no '
              'progress is saved.',
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

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.expectation});

  final Mth1wFoundationLesson lesson;
  final CurriculumItem expectation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
                    const SizedBox(height: 5),
                    Text(
                      'Curriculum reference ${lesson.expectationId} • About '
                      '${lesson.estimatedMinutes} minutes',
                    ),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Chip(label: Text('Lesson')),
                        Chip(label: Text('Worked example')),
                        Chip(label: Text('Practice')),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class Mth1wLessonScreen extends StatelessWidget {
  const Mth1wLessonScreen({
    super.key,
    required this.lesson,
    required this.expectation,
    required this.lessonCount,
  });

  final Mth1wFoundationLesson lesson;
  final CurriculumItem expectation;
  final int lessonCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Math foundations lesson')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Lesson ${lesson.sequence} of $lessonCount',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text('About ${lesson.estimatedMinutes} minutes'),
                    const SizedBox(height: 6),
                    Text(
                      'Curriculum reference ${lesson.expectationId}; educator review of this draft is still pending.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    _LessonSection(
                      icon: Icons.flag_rounded,
                      title: 'Learning goals',
                      children: [
                        for (final goal in lesson.learningGoals)
                          _BulletText(goal),
                      ],
                    ),
                    _LessonSection(
                      icon: Icons.link_rounded,
                      title: 'Before you begin',
                      children: [
                        for (final prerequisite in lesson.prerequisites)
                          _BulletText(prerequisite),
                      ],
                    ),
                    _LessonSection(
                      icon: Icons.lightbulb_rounded,
                      title: 'Learn',
                      children: [
                        Text(lesson.whyItMatters),
                        const SizedBox(height: 12),
                        Text(
                          lesson.directInstruction,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    _WorkedExampleCard(lesson: lesson),
                    _LessonSection(
                      icon: Icons.alt_route_rounded,
                      title: 'Compare methods',
                      children: [
                        const Text(mth1wMethodChoiceNote),
                        const SizedBox(height: 14),
                        for (final route in lesson.methodRoutes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${route.label}: ${route.approach}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(route.explanation),
                              ],
                            ),
                          ),
                      ],
                    ),
                    _LessonSection(
                      icon: Icons.hub_rounded,
                      title: 'Represent it more than one way',
                      children: [
                        for (final representation in lesson.representations)
                          _BulletText(representation),
                        const SizedBox(height: 6),
                        Text(
                          lesson.compareMethodsPrompt,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    _LessonSection(
                      icon: Icons.warning_amber_rounded,
                      title: 'Common mistake to avoid',
                      children: [Text(lesson.commonMisconception)],
                    ),
                    _LessonSection(
                      icon: Icons.psychology_alt_rounded,
                      title: 'Plan before you solve',
                      children: [Text(lesson.reflectionPrompt)],
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Independent practice',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(expectation.expectation),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              key: ValueKey(
                                'mth1w-start-practice-${lesson.expectationId}',
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) => Mth1wPracticeScreen(
                                      initialExpectationId:
                                          lesson.expectationId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Start focused practice'),
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
        ),
      ),
    );
  }
}

class _LessonSection extends StatelessWidget {
  const _LessonSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _WorkedExampleCard extends StatelessWidget {
  const _WorkedExampleCard({required this.lesson});

  final Mth1wFoundationLesson lesson;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_list_numbered_rounded),
                const SizedBox(width: 10),
                Text(
                  'Worked example',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              lesson.workedExamplePrompt,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            for (
              var index = 0;
              index < lesson.workedExampleSteps.length;
              index += 1
            )
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 14, child: Text('${index + 1}')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.workedExampleSteps[index].label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(lesson.workedExampleSteps[index].explanation),
                        ],
                      ),
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

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _CourseConfigurationError extends StatelessWidget {
  const _CourseConfigurationError({required this.onRetry});

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
              const Icon(Icons.menu_book_outlined, size: 52),
              const SizedBox(height: 16),
              Text(
                'The math foundations preview is unavailable',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'The required curriculum expectations could not be validated. '
                'No ungrounded lesson or practice item was substituted.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
