import 'package:flutter/material.dart';

import '../practice/mth1w_practice_screen.dart';

class HomeLearningGuideScreen extends StatelessWidget {
  const HomeLearningGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home learning guide')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BoundaryCard(),
                    SizedBox(height: 12),
                    _GuideSection(
                      icon: Icons.schedule_rounded,
                      title: 'A 45-minute session',
                      items: [
                        '5 minutes: warm up with one earlier example.',
                        '15 minutes: read one lesson and copy the worked example by hand.',
                        '20 minutes: check three different practice questions. Use Another question between them.',
                        '5 minutes: correct one error and explain the method aloud or in writing.',
                      ],
                    ),
                    _GuideSection(
                      icon: Icons.calendar_view_week_rounded,
                      title: 'Starter week',
                      items: [
                        'Day 1: order of operations.',
                        'Day 2: percentages and proportional reasoning.',
                        'Day 3: linear-equation foundations.',
                        'Day 4: lines-from-points foundations.',
                        'Day 5: mixed review with one new question from every available topic.',
                      ],
                    ),
                    _GuideSection(
                      icon: Icons.people_alt_rounded,
                      title: 'Two learners, one device',
                      items: [
                        'Each learner keeps a separate paper notebook.',
                        'Copy the date, topic, questions attempted, and corrections into the notebook.',
                        'Close the practice screen between learners so temporary counters reset.',
                        'Do not compare learners by speed or treat the on-screen count as a grade.',
                      ],
                    ),
                    _GuideSection(
                      icon: Icons.question_answer_rounded,
                      title: 'Adult check-in',
                      items: [
                        'Show me the method you used.',
                        'Which mistake did you correct, and what changed?',
                        'What do you need explained by a teacher or tutor?',
                      ],
                    ),
                    _StartPracticeCard(),
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

class _BoundaryCard extends StatelessWidget {
  const _BoundaryCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use this preview as a study routine',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'It is not a complete MTH1W course, school enrolment, a credit, '
              'a grade, or a Ministry-approved resource. Keep connected with '
              'an authorized school or education provider for official '
              'assessment, accommodations, credits, and graduation planning.',
              style: TextStyle(color: colors.onTertiaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

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
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StartPracticeCard extends StatelessWidget {
  const _StartPracticeCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ready to try the routine?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Open mixed Grade 9 Math practice. Feedback stays temporary and local.',
              style: TextStyle(color: colors.onSecondaryContainer),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('guide-start-mixed-practice'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const Mth1wPracticeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Start mixed practice'),
            ),
          ],
        ),
      ),
    );
  }
}
