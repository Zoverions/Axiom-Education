import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/mth1w_unit_content.dart';
import '../../core/providers/mth1w_unit_content_provider.dart';

class Mth1wDraftUnitScreen extends ConsumerWidget {
  const Mth1wDraftUnitScreen({super.key, this.unitNumber = 1})
    : assert(unitNumber >= 1 && unitNumber <= 6);

  final int unitNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitProvider = mth1wUnitProvider(unitNumber);
    final unitAsync = ref.watch(unitProvider);
    return Scaffold(
      appBar: AppBar(title: Text('MTH1W draft Unit $unitNumber')),
      body: SafeArea(
        child: unitAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _LoadError(
            unitNumber: unitNumber,
            onRetry: () => ref.invalidate(unitProvider),
          ),
          data: (unit) => _UnitBody(unit: unit),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.unitNumber, required this.onRetry});

  final int unitNumber;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              'Draft Unit $unitNumber is unavailable because its bundled content did not load or validate.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _UnitBody extends StatelessWidget {
  const _UnitBody({required this.unit});

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
                          'Source-mapped draft preview. These lessons are original Axiom Education content bound to official references $expectationIds. They still require educator and cultural review.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This unit is not a complete MTH1W course, grade, credit, transcript, or Ministry-approved resource. Responses and results stay on this screen and are not saved.',
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LessonTile(
                      lesson: unit.lessons[index],
                      sequence: index + 1,
                      lessonCount: unit.lessons.length,
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
                _ContentSection(
                  icon: Icons.source_rounded,
                  title: 'Teacher background sources',
                  children: [
                    const Text(
                      'These sources support lesson authoring; students should still evaluate sources used in their own work.',
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.sequence,
    required this.lessonCount,
  });

  final Mth1wLessonContent lesson;
  final int sequence;
  final int lessonCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('mth1w-draft-lesson-${lesson.id}'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => Mth1wDraftLessonScreen(
                lesson: lesson,
                sequence: sequence,
                lessonCount: lessonCount,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text('$sequence')),
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
                      'Official reference ${lesson.officialExpectationIds.join(', ')} • About ${lesson.estimatedMinutes} minutes',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Chip(
                          label: Text('${lesson.methodRoutes.length} methods'),
                        ),
                        Chip(
                          label: Text(
                            '${lesson.workedExamples.length} worked examples',
                          ),
                        ),
                        const Chip(label: Text('Practice + retrieval')),
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

class Mth1wDraftLessonScreen extends StatelessWidget {
  const Mth1wDraftLessonScreen({
    super.key,
    required this.lesson,
    required this.sequence,
    required this.lessonCount,
  });

  final Mth1wLessonContent lesson;
  final int sequence;
  final int lessonCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draft MTH1W lesson')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Lesson $sequence of $lessonCount'),
                    const SizedBox(height: 4),
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Draft official mapping ${lesson.officialExpectationIds.join(', ')} • About ${lesson.estimatedMinutes} minutes',
                    ),
                    const SizedBox(height: 14),
                    const _DraftBoundaryCard(),
                    _ContentSection(
                      icon: Icons.flag_rounded,
                      title: 'Learning goals',
                      children: [
                        for (final goal in lesson.learningGoals) _Bullet(goal),
                      ],
                    ),
                    _ContentSection(
                      icon: Icons.checklist_rounded,
                      title: 'Success criteria',
                      children: [
                        for (final criterion in lesson.successCriteria)
                          _Bullet(criterion),
                      ],
                    ),
                    _ContentSection(
                      icon: Icons.translate_rounded,
                      title: 'Vocabulary',
                      children: [
                        for (final entry in lesson.vocabulary)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${entry.term}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: entry.meaning),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    _ContentSection(
                      icon: Icons.menu_book_rounded,
                      title: 'Learn',
                      children: [
                        Text(lesson.whyItMatters),
                        const SizedBox(height: 14),
                        for (final block in lesson.directInstruction)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  block.heading,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(block.body),
                              ],
                            ),
                          ),
                      ],
                    ),
                    _ContentSection(
                      icon: Icons.alt_route_rounded,
                      title: 'Compare methods',
                      children: [
                        const Text(
                          'Choose a strategy for the task, not a fixed learner type. Try both routes before deciding which makes the reasoning clearest.',
                        ),
                        const SizedBox(height: 8),
                        for (final route in lesson.methodRoutes)
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(route.title),
                            children: [
                              for (
                                var index = 0;
                                index < route.steps.length;
                                index += 1
                              )
                                _NumberedText(index + 1, route.steps[index]),
                              const SizedBox(height: 6),
                              Text('Useful when: ${route.whenUseful}'),
                              const SizedBox(height: 6),
                              Text('Check: ${route.check}'),
                              const SizedBox(height: 10),
                            ],
                          ),
                      ],
                    ),
                    _ContentSection(
                      icon: Icons.hub_rounded,
                      title: 'Represent it more than one way',
                      children: [
                        for (final representation in lesson.representations)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  representation.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(representation.description),
                                const SizedBox(height: 4),
                                Text(
                                  'Text alternative: ${representation.textAlternative}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    for (
                      var index = 0;
                      index < lesson.workedExamples.length;
                      index += 1
                    )
                      _WorkedExampleCard(
                        example: lesson.workedExamples[index],
                        sequence: index + 1,
                      ),
                    _ContentSection(
                      icon: Icons.warning_amber_rounded,
                      title: 'Misconceptions to check',
                      children: [
                        for (final misconception in lesson.misconceptions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${misconception.claim} ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: misconception.correction),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    _PracticePhase(
                      title: 'Guided practice',
                      description:
                          'Use the prompts and feedback while the method is still visible.',
                      items: lesson.practiceSets.guided,
                    ),
                    _PracticePhase(
                      title: 'Independent practice',
                      description:
                          'Attempt these without copying a worked example. Revise after checking.',
                      items: lesson.practiceSets.independent,
                    ),
                    _PracticePhase(
                      title: 'Retrieval practice',
                      description:
                          'Return later and answer from memory before reopening the lesson.',
                      items: lesson.practiceSets.retrieval,
                    ),
                    _ContentSection(
                      icon: Icons.psychology_alt_rounded,
                      title: 'Reflect and choose next steps',
                      children: [Text(lesson.reflectionPrompt)],
                    ),
                    _ContentSection(
                      icon: Icons.accessibility_new_rounded,
                      title: 'Accessibility routes',
                      children: [
                        Text(lesson.accessibility.nonvisualRoute),
                        const SizedBox(height: 8),
                        for (final option
                            in lesson.accessibility.responseOptions)
                          _Bullet(option),
                      ],
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

class _DraftBoundaryCard extends StatelessWidget {
  const _DraftBoundaryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Draft preview: use for supported study with an adult or educator where possible. Constructed responses show criteria and a sample but are not automatically graded. Nothing is saved as progress or mastery.',
        ),
      ),
    );
  }
}

class _WorkedExampleCard extends StatelessWidget {
  const _WorkedExampleCard({required this.example, required this.sequence});

  final Mth1wWorkedExampleContent example;
  final int sequence;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worked example $sequence',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(example.prompt),
            const SizedBox(height: 12),
            for (var index = 0; index < example.steps.length; index += 1)
              _NumberedStep(index + 1, example.steps[index]),
            const Divider(),
            Text(
              'Answer: ${example.answer}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Verification: ${example.verification}'),
          ],
        ),
      ),
    );
  }
}

class _PracticePhase extends StatelessWidget {
  const _PracticePhase({
    required this.title,
    required this.description,
    required this.items,
  });

  final String title;
  final String description;
  final List<Mth1wPracticeItemContent> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        key: PageStorageKey(title),
        leading: const Icon(Icons.edit_note_rounded),
        title: Text(title),
        subtitle: Text(description),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          for (var index = 0; index < items.length; index += 1)
            _PracticeItemCard(item: items[index], sequence: index + 1),
        ],
      ),
    );
  }
}

class _PracticeItemCard extends StatefulWidget {
  const _PracticeItemCard({required this.item, required this.sequence});

  final Mth1wPracticeItemContent item;
  final int sequence;

  @override
  State<_PracticeItemCard> createState() => _PracticeItemCardState();
}

class _PracticeItemCardState extends State<_PracticeItemCard> {
  String _response = '';
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final contract = widget.item.response;
    final correct = contract.isAutoCheckable && contract.isCorrect(_response);
    return Card.outlined(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.sequence}. ${widget.item.prompt}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _ResponseInput(
              key: PageStorageKey('response-${widget.item.id}-$_checked'),
              contract: contract,
              value: _response,
              enabled: !_checked,
              onChanged: (value) => setState(() => _response = value),
            ),
            const SizedBox(height: 10),
            if (!_checked)
              FilledButton(
                key: ValueKey('check-${widget.item.id}'),
                onPressed: _response.trim().isEmpty
                    ? null
                    : () => setState(() => _checked = true),
                child: Text(
                  contract.isAutoCheckable
                      ? 'Check response'
                      : 'Open review criteria',
                ),
              )
            else ...[
              _ResponseFeedback(
                contract: contract,
                rationale: widget.item.rationale,
                correct: correct,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => setState(() => _checked = false),
                child: const Text('Revise response'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResponseInput extends StatelessWidget {
  const _ResponseInput({
    super.key,
    required this.contract,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final Mth1wResponseContract contract;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (contract.type == Mth1wResponseType.selected) {
      return DropdownButtonFormField<String>(
        initialValue: value.isEmpty ? null : value,
        decoration: const InputDecoration(
          labelText: 'Choose one response',
          border: OutlineInputBorder(),
        ),
        items: [
          for (final option in contract.options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: enabled ? (selection) => onChanged(selection ?? '') : null,
        isExpanded: true,
      );
    }

    return TextFormField(
      initialValue: value,
      enabled: enabled,
      minLines: contract.type == Mth1wResponseType.constructed ? 3 : 1,
      maxLines: contract.type == Mth1wResponseType.constructed ? 8 : 2,
      decoration: InputDecoration(
        labelText: contract.type == Mth1wResponseType.constructed
            ? 'Write an explanation'
            : 'Enter an exact response',
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

class _ResponseFeedback extends StatelessWidget {
  const _ResponseFeedback({
    required this.contract,
    required this.rationale,
    required this.correct,
  });

  final Mth1wResponseContract contract;
  final String rationale;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    if (!contract.isAutoCheckable) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adult or educator review required',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            for (final criterion in contract.criteria) _Bullet(criterion),
            const SizedBox(height: 6),
            Text('Sample response: ${contract.sampleResponse}'),
            const SizedBox(height: 6),
            Text(rationale),
          ],
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      color: correct ? colors.primaryContainer : colors.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? 'Correct' : 'Not yet',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (!correct) Text('Expected response: ${contract.disclosedAnswer}'),
          const SizedBox(height: 4),
          Text(rationale),
        ],
      ),
    );
  }
}

class Mth1wDraftQuizScreen extends StatefulWidget {
  const Mth1wDraftQuizScreen({super.key, required this.quiz});

  final Mth1wQuizContent quiz;

  @override
  State<Mth1wDraftQuizScreen> createState() => _Mth1wDraftQuizScreenState();
}

class _Mth1wDraftQuizScreenState extends State<Mth1wDraftQuizScreen> {
  final Map<String, String> _responses = {};
  bool _submitted = false;

  bool get _allAnswered => widget.quiz.items.every(
    (item) => (_responses[item.id] ?? '').trim().isNotEmpty,
  );

  @override
  Widget build(BuildContext context) {
    final autoItems = widget.quiz.items
        .where((item) => item.response.isAutoCheckable)
        .toList();
    final exactCorrect = autoItems
        .where((item) => item.response.isCorrect(_responses[item.id] ?? ''))
        .length;
    final constructed = widget.quiz.items.length - autoItems.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Draft Unit 1 quiz')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.quiz.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text('About ${widget.quiz.estimatedMinutes} minutes'),
                    const SizedBox(height: 12),
                    const _DraftBoundaryCard(),
                    for (
                      var index = 0;
                      index < widget.quiz.items.length;
                      index += 1
                    )
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ${widget.quiz.items[index].prompt}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _ResponseInput(
                                key: PageStorageKey(
                                  'quiz-response-${widget.quiz.items[index].id}-$_submitted',
                                ),
                                contract: widget.quiz.items[index].response,
                                value:
                                    _responses[widget.quiz.items[index].id] ??
                                    '',
                                enabled: !_submitted,
                                onChanged: (value) {
                                  setState(() {
                                    _responses[widget.quiz.items[index].id] =
                                        value;
                                  });
                                },
                              ),
                              if (_submitted) ...[
                                const SizedBox(height: 10),
                                _ResponseFeedback(
                                  contract: widget.quiz.items[index].response,
                                  rationale: widget.quiz.items[index].rationale,
                                  correct: widget.quiz.items[index].response
                                      .isCorrect(
                                        _responses[widget
                                                .quiz
                                                .items[index]
                                                .id] ??
                                            '',
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (!_submitted)
                      FilledButton(
                        key: const ValueKey('mth1w-u1-submit-quiz'),
                        onPressed: _allAnswered
                            ? () => setState(() => _submitted = true)
                            : null,
                        child: const Text('Submit all responses'),
                      )
                    else ...[
                      Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '$exactCorrect of ${autoItems.length} automatically checkable responses are exact. $constructed constructed responses still require adult or educator review. This is feedback for correction, not a grade or mastery result.',
                          ),
                        ),
                      ),
                      OutlinedButton(
                        key: const ValueKey('mth1w-u1-correct-quiz'),
                        onPressed: () => setState(() => _submitted = false),
                        child: const Text('Correct and resubmit'),
                      ),
                    ],
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

class Mth1wDraftPerformanceTaskScreen extends StatelessWidget {
  const Mth1wDraftPerformanceTaskScreen({super.key, required this.task});

  final Mth1wPerformanceTaskContent task;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draft performance task')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'About ${task.estimatedMinutes} minutes • References ${task.officialExpectationIds.join(', ')}',
                    ),
                    const SizedBox(height: 12),
                    const _DraftBoundaryCard(),
                    _ContentSection(
                      icon: Icons.assignment_rounded,
                      title: 'Task',
                      children: [Text(task.prompt)],
                    ),
                    _ContentSection(
                      icon: Icons.checklist_rounded,
                      title: 'Required components',
                      children: [
                        for (final component in task.requiredComponents)
                          _Bullet(component),
                      ],
                    ),
                    _ContentSection(
                      icon: Icons.rule_rounded,
                      title: 'Review rubric',
                      children: [
                        const Text(
                          'An adult or educator must review this task. The rubric is transparent but does not generate a grade in the app.',
                        ),
                        const SizedBox(height: 10),
                        for (final dimension in task.rubric)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${dimension.dimension}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: dimension.criteria),
                                ],
                              ),
                            ),
                          ),
                      ],
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

class _ContentSection extends StatelessWidget {
  const _ContentSection({
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

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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

class _NumberedText extends StatelessWidget {
  const _NumberedText(this.number, this.text);

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: Text('$number.')),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep(this.number, this.step);

  final int number;
  final Mth1wWorkedStepContent step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, child: Text('$number')),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(step.explanation),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
