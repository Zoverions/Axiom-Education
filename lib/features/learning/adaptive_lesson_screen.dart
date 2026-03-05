import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/student_profile.dart';
import '../../core/services/adaptive_engine.dart';
import '../../core/providers/curriculum_provider.dart';
import '../handwriting/handwriting_canvas.dart';
import '../../widgets/focus_break_dialog.dart';

enum _LessonPhase {
  loading,
  intro,
  practiceQuestion,
  handwritingReflection,
  metacognitionPrompt,
  complete,
}

class AdaptiveLessonScreen extends ConsumerStatefulWidget {
  final StudentProfile profile;
  final String courseCode;

  const AdaptiveLessonScreen({
    super.key,
    required this.profile,
    required this.courseCode,
  });

  @override
  ConsumerState<AdaptiveLessonScreen> createState() =>
      _AdaptiveLessonScreenState();
}

class _AdaptiveLessonScreenState
    extends ConsumerState<AdaptiveLessonScreen> {
  _LessonPhase _phase = _LessonPhase.loading;
  List<CurriculumItem> _itemQueue = [];
  int _queueIndex = 0;
  CurriculumItem? _current;
  final List<double> _responses = [];
  final List<double> _difficulties = [];
  double _sessionTheta = 0.0;
  int _correctCount = 0;
  late Stopwatch _sessionTimer;
  late Duration _sessionTarget;

  // Handwriting reflection state
  double _reflectionPressure = 0.0;
  double _reflectionConsistency = 0.0;

  @override
  void initState() {
    super.initState();
    _sessionTheta = widget.profile.irtTheta;
    _sessionTarget = AdaptiveEngine.sessionLength(widget.profile);
    _sessionTimer = Stopwatch()..start();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final bank = await ref.read(curriculumBankProvider.future);
    final filter = CurriculumFilter.aroundTheta(
      _sessionTheta,
      courseCode: widget.courseCode,
    );
    final filtered = bank
        .where((item) =>
            item.courseCode == filter.courseCode &&
            item.irtB >= filter.minDifficulty &&
            item.irtB <= filter.maxDifficulty)
        .toList()
      ..sort((a, b) => a.irtB.compareTo(b.irtB));

    if (filtered.isEmpty) {
      // Fallback: any items from this course
      _itemQueue = bank
          .where((item) => item.courseCode == widget.courseCode)
          .toList();
    } else {
      _itemQueue = filtered;
    }
    if (mounted && _itemQueue.isNotEmpty) {
      setState(() {
        _phase = _LessonPhase.intro;
        _current = _itemQueue.first;
      });
    }
  }

  void _advanceItem(bool correct) {
    _responses.add(correct ? 1.0 : 0.0);
    _difficulties.add(_current!.irtB);
    _sessionTheta = AdaptiveEngine.updateTheta(
      currentTheta: _sessionTheta,
      responses: _responses,
      difficulties: _difficulties,
    );
    if (correct) _correctCount++;

    // Check focus break (every 4 questions)
    if (_responses.length % 4 == 0) {
      _showFocusBreak();
      return;
    }

    // Check session time
    if (_sessionTimer.elapsed >= _sessionTarget) {
      setState(() => _phase = _LessonPhase.handwritingReflection);
      return;
    }

    _queueIndex = (_queueIndex + 1).clamp(0, _itemQueue.length - 1);
    setState(() {
      _current = _itemQueue[_queueIndex];
      _phase = _LessonPhase.practiceQuestion;
    });
  }

  Future<void> _showFocusBreak() async {
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FocusBreakDialog(),
    );
    if (resume == true && mounted) {
      _queueIndex = (_queueIndex + 1).clamp(0, _itemQueue.length - 1);
      setState(() {
        _current = _itemQueue[_queueIndex];
        _phase = _LessonPhase.practiceQuestion;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.courseCode} — Adaptive Session'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_sessionTimer.elapsed.inMinutes}m / ${_sessionTarget.inMinutes}m',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildPhase(),
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _LessonPhase.loading:
        return const Center(child: CircularProgressIndicator());

      case _LessonPhase.intro:
        return _IntroSlide(
          item: _current!,
          sessionLength: _sessionTarget,
          band: widget.profile.irtBand,
          onStart: () => setState(() => _phase = _LessonPhase.practiceQuestion),
        );

      case _LessonPhase.practiceQuestion:
        return _PracticeQuestion(
          item: _current!,
          questionNumber: _responses.length + 1,
          onCorrect: () => _advanceItem(true),
          onIncorrect: () => _advanceItem(false),
        );

      case _LessonPhase.handwritingReflection:
        return _HandwritingReflection(
          prompt: _reflectionPrompt(),
          onScore: (p, c) {
            _reflectionPressure = p;
            _reflectionConsistency = c;
          },
          onNext: () => setState(
              () => _phase = _LessonPhase.metacognitionPrompt),
        );

      case _LessonPhase.metacognitionPrompt:
        return _MetacognitionPrompt(
          band: widget.profile.irtBand,
          onDone: () => setState(() => _phase = _LessonPhase.complete),
        );

      case _LessonPhase.complete:
        return _SessionSummary(
          questionsAnswered: _responses.length,
          correctCount: _correctCount,
          thetaStart: widget.profile.irtTheta,
          thetaEnd: _sessionTheta,
          ontarioLevel: AdaptiveEngine.ontarioLevel(_sessionTheta),
          elapsed: _sessionTimer.elapsed,
          strokeConsistency: _reflectionConsistency,
          nextReview: AdaptiveEngine.nextReviewInterval(
              _responses.length, 2.5),
        );
    }
  }

  String _reflectionPrompt() {
    final prompts = {
      'MTH1W': 'In 2–3 sentences, explain how you would solve a linear equation. Use your own words.',
      'ENL1W': 'Write a topic sentence for an essay about a text you have recently read.',
      'SNC1W': 'Describe one real-world application of what you practised today.',
      'CGC1W': 'Write a short geographic observation about your local area using today\'s concepts.',
      'BEM1O': 'Describe one entrepreneurial quality you saw in today\'s examples.',
    };
    return prompts[widget.courseCode] ??
        'In 2–3 sentences, reflect on what you learned today and one question you still have.';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _IntroSlide extends StatelessWidget {
  final CurriculumItem item;
  final Duration sessionLength;
  final String band;
  final VoidCallback onStart;
  const _IntroSlide(
      {required this.item, required this.sessionLength,
       required this.band, required this.onStart});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Today\'s Focus', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 4),
      Text('${item.courseCode} — ${item.strand.replaceAll('_', ' ')}',
          style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade900.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade700),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ontario Expectation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
          const SizedBox(height: 6),
          Text(item.expectation, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('ID: ${item.id}',
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 20),
      _BandHint(band: band),
      const SizedBox(height: 20),
      Row(children: [
        Icon(Icons.timer_outlined, color: Colors.orange, size: 18),
        const SizedBox(width: 6),
        Text('Session: ${sessionLength.inMinutes} minutes (focus burst)',
            style: const TextStyle(color: Colors.orange)),
      ]),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Practice'),
      ),
    ],
  );
}

class _BandHint extends StatelessWidget {
  final String band;
  const _BandHint({required this.band});

  @override
  Widget build(BuildContext context) {
    final hints = {
      'intensive': '🔵 We\'ll work through this step by step with worked examples.',
      'developing': '🟡 Look for the pattern — you\'ve got more of this than you think.',
      'grade_level': '🟢 Apply the method you know. Challenge yourself on the harder ones.',
      'enriched': '🟠 Try to solve it more than one way. Look for connections to other ideas.',
      'gifted': '🔴 Push into the extension. What breaks the rule? Where are its limits?',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(hints[band] ?? hints['grade_level']!),
    );
  }
}

class _PracticeQuestion extends StatefulWidget {
  final CurriculumItem item;
  final int questionNumber;
  final VoidCallback onCorrect;
  final VoidCallback onIncorrect;
  const _PracticeQuestion({
    required this.item, required this.questionNumber,
    required this.onCorrect, required this.onIncorrect,
  });

  @override
  State<_PracticeQuestion> createState() => _PracticeQuestionState();
}

class _PracticeQuestionState extends State<_PracticeQuestion> {
  bool? _answered;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Question ${widget.questionNumber}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('${widget.item.courseCode} — ${widget.item.strand.replaceAll('_', ' ')}',
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(widget.item.expectation,
            style: const TextStyle(fontSize: 18)),
      ),
      const SizedBox(height: 16),
      const Text(
        'Did you understand and apply this concept?',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
      const SizedBox(height: 12),
      if (_answered == null) ...[
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _answered = true);
                Future.delayed(
                    const Duration(milliseconds: 300), widget.onCorrect);
              },
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text('Yes — got it'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _answered = false);
                Future.delayed(
                    const Duration(milliseconds: 300), widget.onIncorrect);
              },
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Not yet'),
            ),
          ),
        ]),
      ] else ...[
        Row(children: [
          Icon(_answered! ? Icons.check_circle : Icons.cancel,
              color: _answered! ? Colors.green : Colors.orange),
          const SizedBox(width: 8),
          Text(
            _answered!
                ? 'Great — moving on.'
                : 'That\'s okay — the next question will help.',
            style: TextStyle(color: _answered! ? Colors.green : Colors.orange),
          ),
        ]),
      ],
      const SizedBox(height: 16),
      // Spaced repetition hint
      if (widget.item.tags.contains('eqao'))
        const Chip(
          label: Text('📋 EQAO-linked expectation'),
          backgroundColor: Colors.deepPurple,
        ),
    ],
  );
}

class _HandwritingReflection extends StatelessWidget {
  final String prompt;
  final void Function(double, double) onScore;
  final VoidCallback onNext;
  const _HandwritingReflection(
      {required this.prompt, required this.onScore, required this.onNext});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Stylus Reflection',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade900.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(prompt, style: const TextStyle(fontSize: 16)),
      ),
      const SizedBox(height: 16),
      HandwritingCanvas(onScore: onScore),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onNext, child: const Text('Continue →')),
    ],
  );
}

class _MetacognitionPrompt extends StatefulWidget {
  final String band;
  final VoidCallback onDone;
  const _MetacognitionPrompt({required this.band, required this.onDone});

  @override
  State<_MetacognitionPrompt> createState() => _MetacognitionPromptState();
}

class _MetacognitionPromptState extends State<_MetacognitionPrompt> {
  int? _confidence; // 1–5

  static const _prompts = [
    'What was the hardest part of today\'s session?',
    'What strategy helped you the most?',
    'What would you do differently next time?',
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Quick Reflection 🧠',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Metacognition builds stronger long-term memory.',
          style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 20),
      ...List.generate(_prompts.length, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${i + 1}. ${_prompts[i]}'),
        ),
      )),
      const SizedBox(height: 12),
      const Text('How confident do you feel now? (1 = unsure, 5 = solid)'),
      const SizedBox(height: 8),
      Row(children: List.generate(5, (i) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text('${i + 1}'),
          selected: _confidence == i + 1,
          onSelected: (_) => setState(() => _confidence = i + 1),
        ),
      ))),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _confidence != null ? widget.onDone : null,
        child: const Text('Finish Session'),
      ),
    ],
  );
}

class _SessionSummary extends StatelessWidget {
  final int questionsAnswered, correctCount;
  final double thetaStart, thetaEnd;
  final String ontarioLevel;
  final Duration elapsed;
  final double strokeConsistency;
  final Duration nextReview;

  const _SessionSummary({
    required this.questionsAnswered, required this.correctCount,
    required this.thetaStart, required this.thetaEnd,
    required this.ontarioLevel, required this.elapsed,
    required this.strokeConsistency, required this.nextReview,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Session Complete! 🎉',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      _SummaryRow('Questions answered', '$questionsAnswered'),
      _SummaryRow('Correct responses',
          '$correctCount / $questionsAnswered (${questionsAnswered > 0 ? (correctCount / questionsAnswered * 100).toStringAsFixed(0) : 0}%)'),
      _SummaryRow('Ability change',
          'θ ${thetaStart.toStringAsFixed(2)} → ${thetaEnd.toStringAsFixed(2)}'),
      _SummaryRow('Current level', ontarioLevel),
      _SummaryRow('Session time', '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s'),
      _SummaryRow('Penmanship consistency',
          '${(strokeConsistency * 100).toStringAsFixed(0)}%'),
      _SummaryRow('Next review in', '${nextReview.inDays} days'),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade900.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade700),
        ),
        child: Text(
          thetaEnd > thetaStart
              ? '📈 Ability improved this session. Come back in ${nextReview.inDays} days for best retention (spaced practice).'
              : '💪 Challenging session — that\'s where growth happens. Rest and return tomorrow.',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    ]),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 220,
          child: Text(label, style: const TextStyle(color: Colors.grey))),
      Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500))),
    ]),
  );
}
