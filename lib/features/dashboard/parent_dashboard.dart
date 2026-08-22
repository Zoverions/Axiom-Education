import 'package:flutter/material.dart';

import '../learning/home_learning_guide_screen.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family tools')),
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
                    const _FamilyStatusCard(),
                    const SizedBox(height: 16),
                    Text(
                      'Useful now',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.home_work_rounded,
                      title: 'Home learning routine',
                      description:
                          'Use a 45-minute study structure, a starter week, and guidance for two learners sharing one device.',
                      buttonLabel: 'Open home learning guide',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                const HomeLearningGuideScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const _NotebookCard(),
                    const SizedBox(height: 20),
                    const _FutureProgressCard(),
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

class _FamilyStatusCard extends StatelessWidget {
  const _FamilyStatusCard();

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
              Icons.family_restroom_rounded,
              size: 36,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              'Family support that stays honest',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This preview does not currently maintain an authoritative saved '
              'learner record. Family tools focus on routines and privacy guidance '
              'rather than estimated or made-up study time, task counts, levels, '
              'grades, or activity history.',
              style: TextStyle(color: colors.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
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
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(description),
            const SizedBox(height: 14),
            FilledButton.tonal(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Simple paper record',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'For the current preview, use a separate notebook for each learner. '
              'Record the date, topic, items attempted, corrections, and questions '
              'to bring to a teacher or tutor. Treat on-screen practice feedback as '
              'temporary—not as a grade or mastery record.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureProgressCard extends StatelessWidget {
  const _FutureProgressCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_clock_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved progress is not enabled yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A future family progress view must come from governed learner '
                    'records with the required authority and consent. Until that '
                    'path is available, Axiom Education will not manufacture '
                    'completion, mastery, grade, credit, or activity history.',
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
