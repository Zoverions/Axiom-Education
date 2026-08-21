import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/practice/math_answer_verifier.dart';
import '../../core/practice/math_practice_generator.dart';
import '../../core/practice/mth1w_practice_provider.dart';
import '../../core/practice/practice_item.dart';
import '../../core/providers/curriculum_provider.dart';

class Mth1wPracticeScreen extends ConsumerStatefulWidget {
  const Mth1wPracticeScreen({
    super.key,
    this.verifier = const MathAnswerVerifier(),
    this.generator = const MathPracticeGenerator(),
    this.initialExpectationId,
  });

  final PracticeVerifier? verifier;
  final MathPracticeGenerator generator;
  final String? initialExpectationId;

  @override
  ConsumerState<Mth1wPracticeScreen> createState() =>
      _Mth1wPracticeScreenState();
}

class _Mth1wPracticeScreenState extends ConsumerState<Mth1wPracticeScreen> {
  final TextEditingController _answerController = TextEditingController();
  int _expectationIndex = 0;
  int _itemSequence = 0;
  int _visibleHintCount = 0;
  int _sessionAttemptCount = 0;
  bool _answerHasContent = false;
  final Set<String> _checkedItemIds = <String>{};
  final Set<String> _correctItemIds = <String>{};
  VerificationResult? _result;

  @override
  void initState() {
    super.initState();
    final initialExpectationId = widget.initialExpectationId;
    if (initialExpectationId != null) {
      final requestedIndex = mth1wGoldenPathOrder.indexOf(initialExpectationId);
      if (requestedIndex >= 0) _expectationIndex = requestedIndex;
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _clearResponse() {
    _answerController.clear();
    _result = null;
    _visibleHintCount = 0;
    _answerHasContent = false;
  }

  void _onAnswerChanged(String value) {
    final hasContent = value.trim().isNotEmpty;
    if (hasContent == _answerHasContent) return;
    setState(() => _answerHasContent = hasContent);
  }

  void _checkAnswer(PracticeItem item) {
    if (_answerController.text.trim().isEmpty) return;

    final verifier = widget.verifier;
    if (verifier == null) {
      setState(() {
        _result = VerificationResult(
          status: VerificationStatus.unavailable,
          message:
              'The deterministic verifier is not configured. No result was '
              'recorded or inferred.',
          itemDigest: item.itemDigest,
        );
      });
      return;
    }

    final result = verifier.verify(item, _answerController.text);
    setState(() {
      _result = result;
      _sessionAttemptCount += 1;
      _checkedItemIds.add(item.itemId);
      if (result.status == VerificationStatus.correct) {
        _correctItemIds.add(item.itemId);
      }
    });
  }

  void _showNextHint(PracticeItem item) {
    if (_visibleHintCount >= item.hints.length) return;
    setState(() => _visibleHintCount += 1);
  }

  void _nextExpectation(int expectationCount) {
    setState(() {
      _expectationIndex = (_expectationIndex + 1) % expectationCount;
      _itemSequence = 0;
      _clearResponse();
    });
  }

  void _newItem() {
    setState(() {
      _itemSequence += 1;
      _clearResponse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final expectationsAsync = ref.watch(mth1wGoldenPathProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Grade 9 Math Practice Preview')),
      body: SafeArea(
        child: expectationsAsync.when(
          loading: () => const Center(
            child: Semantics(
              liveRegion: true,
              label: 'Loading Grade 9 Math practice',
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => _ConfigurationError(
            onRetry: () => ref.invalidate(mth1wGoldenPathProvider),
          ),
          data: (expectations) {
            if (expectations.isEmpty) {
              return _ConfigurationError(
                onRetry: () => ref.invalidate(mth1wGoldenPathProvider),
              );
            }
            final initialExpectationId = widget.initialExpectationId;
            if (initialExpectationId != null &&
                !expectations.any(
                  (expectation) => expectation.id == initialExpectationId,
                )) {
              return _ConfigurationError(
                onRetry: () => ref.invalidate(mth1wGoldenPathProvider),
              );
            }
            final currentIndex = _expectationIndex % expectations.length;
            final expectation = expectations[currentIndex];
            final seed = currentIndex * 100000 + _itemSequence;

            try {
              final item = widget.generator.generate(
                expectationId: expectation.id,
                expectationText: expectation.expectation,
                difficultyValue: expectation.irtB,
                seed: seed,
              );
              return _PracticeBody(
                item: item,
                expectation: expectation,
                position: currentIndex + 1,
                total: expectations.length,
                answerController: _answerController,
                answerHasContent: _answerHasContent,
                result: _result,
                visibleHintCount: _visibleHintCount,
                sessionAttemptCount: _sessionAttemptCount,
                distinctCorrectCount: _correctItemIds.length,
                distinctItemCount: _checkedItemIds.length,
                verifierAvailable: widget.verifier != null,
                onAnswerChanged: _onAnswerChanged,
                onCheck: () => _checkAnswer(item),
                onShowHint: () => _showNextHint(item),
                onNewItem: _newItem,
                onNextExpectation: () => _nextExpectation(expectations.length),
              );
            } on UnsupportedPracticeExpectationException {
              return _ConfigurationError(
                onRetry: () => ref.invalidate(mth1wGoldenPathProvider),
              );
            }
          },
        ),
      ),
    );
  }
}

class _PracticeBody extends StatelessWidget {
  const _PracticeBody({
    required this.item,
    required this.expectation,
    required this.position,
    required this.total,
    required this.answerController,
    required this.answerHasContent,
    required this.result,
    required this.visibleHintCount,
    required this.sessionAttemptCount,
    required this.distinctCorrectCount,
    required this.distinctItemCount,
    required this.verifierAvailable,
    required this.onAnswerChanged,
    required this.onCheck,
    required this.onShowHint,
    required this.onNewItem,
    required this.onNextExpectation,
  });

  final PracticeItem item;
  final CurriculumItem expectation;
  final int position;
  final int total;
  final TextEditingController answerController;
  final bool answerHasContent;
  final VerificationResult? result;
  final int visibleHintCount;
  final int sessionAttemptCount;
  final int distinctCorrectCount;
  final int distinctItemCount;
  final bool verifierAvailable;
  final ValueChanged<String> onAnswerChanged;
  final VoidCallback onCheck;
  final VoidCallback onShowHint;
  final VoidCallback onNewItem;
  final VoidCallback onNextExpectation;

  @override
  Widget build(BuildContext context) {
    final canCheck = verifierAvailable && answerHasContent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusBanner(verifierAvailable: verifierAvailable),
                const SizedBox(height: 12),
                _SessionSummary(
                  attemptCount: sessionAttemptCount,
                  distinctCorrectCount: distinctCorrectCount,
                  distinctItemCount: distinctItemCount,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: position / total),
                const SizedBox(height: 6),
                Text(
                  'Practice topic $position of $total',
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 12),
                _ExpectationCard(item: item, expectation: expectation),
                const SizedBox(height: 12),
                _QuestionCard(item: item),
                const SizedBox(height: 12),
                TextField(
                  controller: answerController,
                  enabled: verifierAvailable,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Your answer',
                    hintText: item.answerKind == PracticeAnswerKind.rational
                        ? 'Integer, decimal, or fraction'
                        : 'y = mx + b',
                    helperText: verifierAvailable
                        ? 'Enter an answer to check it on this device.'
                        : 'Answer checking is unavailable right now.',
                  ),
                  onChanged: onAnswerChanged,
                  onSubmitted: canCheck ? (_) => onCheck() : null,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: canCheck ? onCheck : null,
                      icon: const Icon(Icons.verified_rounded),
                      label: const Text('Check answer'),
                    ),
                    OutlinedButton.icon(
                      onPressed: visibleHintCount < item.hints.length
                          ? onShowHint
                          : null,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text('Show hint'),
                    ),
                  ],
                ),
                if (visibleHintCount > 0) ...[
                  const SizedBox(height: 12),
                  _HintCard(hints: item.hints.take(visibleHintCount).toList()),
                ],
                if (result != null) ...[
                  const SizedBox(height: 12),
                  _VerificationCard(result: result!),
                ],
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: onNewItem,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Another question'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onNextExpectation,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Next topic'),
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

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({
    required this.attemptCount,
    required this.distinctCorrectCount,
    required this.distinctItemCount,
  });

  final int attemptCount;
  final int distinctCorrectCount;
  final int distinctItemCount;

  @override
  Widget build(BuildContext context) {
    final attempts = attemptCount == 1 ? '1 attempt' : '$attemptCount attempts';
    final correct = distinctCorrectCount == 1
        ? '1 question correct'
        : '$distinctCorrectCount questions correct';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text('$attempts • $correct'),
            const SizedBox(height: 4),
            Text('$distinctItemCount of 3 different questions checked'),
            if (distinctItemCount >= 3) ...[
              const SizedBox(height: 4),
              const Text(
                'Suggested practice set finished. This is not a grade or mastery result.',
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Repeated checks of the same question do not increase the '
              'correct-question total. Nothing is saved to a learner record.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.verifierAvailable});

  final bool verifierAvailable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: verifierAvailable
          ? colors.primaryContainer
          : colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              verifierAvailable
                  ? Icons.offline_bolt_rounded
                  : Icons.block_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                verifierAvailable
                    ? 'Offline practice is ready. Answers are checked on this '
                          'device using fixed rules. This preview is not a complete '
                          'course or grade, and it does not use an AI tutor or '
                          'learner record.'
                    : 'Answer checking is unavailable, so answers cannot be '
                          'submitted or treated as correct.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpectationCard extends StatelessWidget {
  const _ExpectationCard({required this.item, required this.expectation});

  final PracticeItem item;
  final CurriculumItem expectation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What you're practising",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(item.expectationText),
            const SizedBox(height: 10),
            Chip(label: Text(expectation.strand)),
            const SizedBox(height: 6),
            ExpansionTile(
              key: const ValueKey('practice-curriculum-details'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              title: const Text('Curriculum details'),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    'Curriculum reference ${item.expectationId}\n'
                    'Practice difficulty ${item.difficultyValue.toStringAsFixed(1)} — uncalibrated\n'
                    'Official mapping status: review pending',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.item});

  final PracticeItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Practice question',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(
              item.prompt,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ExpansionTile(
              key: const ValueKey('practice-technical-details'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              title: const Text('Technical details'),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    'Generator ${PracticeItem.generatorVersion}\n'
                    'Seed ${item.generatorSeed}\n'
                    'Item digest ${item.itemDigest}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.hints});

  final List<String> hints;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hints', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var index = 0; index < hints.length; index += 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${index + 1}. ${hints[index]}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.result});

  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final successful = result.status == VerificationStatus.correct;
    final unavailable =
        result.status == VerificationStatus.unavailable ||
        result.status == VerificationStatus.integrityFailure;
    final background = successful
        ? colors.primaryContainer
        : unavailable
        ? colors.errorContainer
        : colors.tertiaryContainer;
    final title = successful
        ? 'Correct'
        : unavailable
        ? 'Answer checking unavailable'
        : 'Try again';

    return Semantics(
      liveRegion: true,
      child: Card(
        color: background,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(result.message),
              if (result.normalizedAnswer != null) ...[
                const SizedBox(height: 6),
                Text('Checked as: ${result.normalizedAnswer}'),
              ],
              const SizedBox(height: 6),
              ExpansionTile(
                key: const ValueKey('verification-technical-details'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                title: const Text('Verification details'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      'Evidence ${result.evidenceLabel}\n'
                      'Verifier ${MathAnswerVerifier.verifierId}\n'
                      'Item digest ${result.itemDigest}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigurationError extends StatelessWidget {
  const _ConfigurationError({required this.onRetry});

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
              const Icon(Icons.gpp_bad_rounded, size: 52),
              const SizedBox(height: 16),
              Text(
                'Math foundations practice is unavailable',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'The local curriculum or answer-checking setup could not be '
                'verified. No replacement question was generated.',
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
