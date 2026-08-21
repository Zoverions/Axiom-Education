import 'package:flutter/material.dart';

import '../diagnostic/diagnostic_screen.dart';
import '../learning/home_learning_guide_screen.dart';
import '../learning/mth1w_course_screen.dart';
import '../practice/mth1w_practice_screen.dart';

class LearnerHomeScreen extends StatelessWidget {
  const LearnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Axiom Education')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _WelcomeCard(),
                    const SizedBox(height: 20),
                    Text(
                      'Start learning',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PrimaryLearningCard(
                      onOpenCourse: () => _push(
                        context,
                        const Mth1wCourseScreen(),
                      ),
                      onOpenPractice: () => _push(
                        context,
                        const Mth1wPracticeScreen(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Explore',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 680;
                        final children = [
                          _HomeActionCard(
                            icon: Icons.menu_book_rounded,
                            title: 'Browse curriculum',
                            description:
                                'Search the bundled Ontario secondary curriculum by course code or name.',
                            buttonLabel: 'Open curriculum library',
                            onPressed: () => _push(
                              context,
                              const DiagnosticScreen(),
                            ),
                          ),
                          _HomeActionCard(
                            icon: Icons.home_work_rounded,
                            title: 'Home learning guide',
                            description:
                                'Use a simple study routine, including guidance for two learners sharing one device.',
                            buttonLabel: 'Open guide',
                            onPressed: () => _push(
                              context,
                              const HomeLearningGuideScreen(),
                            ),
                          ),
                        ];

                        if (compact) {
                          return Column(
                            children: [
                              children[0],
                              const SizedBox(height: 12),
                              children[1],
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: children[0]),
                            const SizedBox(width: 12),
                            Expanded(child: children[1]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const _CurrentBoundaryCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => screen),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 40,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(height: 14),
            Text(
              'Learn locally. Stay in control.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'The current learning preview works offline and without an AI tutor. '
              'Choose a lesson, practise with exact local feedback, or browse the '
              'curriculum behind the experience.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryLearningCard extends StatelessWidget {
  const _PrimaryLearningCard({
    required this.onOpenCourse,
    required this.onOpenPractice,
  });

  final VoidCallback onOpenCourse;
  final VoidCallback onOpenPractice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colors.secondaryContainer,
                  foregroundColor: colors.onSecondaryContainer,
                  child: const Icon(Icons.functions_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grade 9 Math Foundations',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Open the guided foundation lessons and source-mapped draft units, '
                        'or jump straight into deterministic practice.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const ValueKey('home-open-mth1w-course'),
                  onPressed: onOpenCourse,
                  icon: const Icon(Icons.school_rounded),
                  label: const Text('Open math learning'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('home-open-mth1w-practice'),
                  onPressed: onOpenPractice,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Quick practice'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Preview status: lesson and practice activity is not saved as an '
              'authoritative learner record, grade, credit, or mastery result.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentBoundaryCard extends StatelessWidget {
  const _CurrentBoundaryCard();

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
              'What this app does today',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const _StatusRow(
              icon: Icons.offline_bolt_rounded,
              text: 'Offline lessons, curriculum browsing, and local practice are available.',
            ),
            const _StatusRow(
              icon: Icons.privacy_tip_outlined,
              text: 'Practice feedback is temporary and is not written to a learner record.',
            ),
            const _StatusRow(
              icon: Icons.pending_actions_rounded,
              text: 'AI tutoring, authoritative saved progress, grades, credits, and school-equivalency claims are not enabled.',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
