import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/claw_experience_graph.dart';
import 'package:ontarioedai/core/models/claw_experience_presentation.dart';
import 'package:ontarioedai/features/claw/claw_foundations_story_arc.dart';
import 'package:ontarioedai/widgets/claw_experience_renderer.dart';

void main() {
  testWidgets(
    'learner can request another representation without target drift',
    (tester) async {
      final evidence = <ClawLocalEvidenceCandidate>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClawExperiencePlayer(
                graph: ClawFoundationsStoryArc.graph,
                presentations: ClawFoundationsStoryArc.presentations,
                availability: ClawFoundationsStoryArc.availability,
                onEvidenceCandidate: evidence.add,
              ),
            ),
          ),
        ),
      );

      expect(find.text('The bridge with four lanterns'), findsOneWidget);
      expect(
        find.text('Learning target: ${ClawFoundationsStoryArc.competencyId}'),
        findsOneWidget,
      );

      await _tap(tester, const ValueKey('claw-continue'));
      expect(find.text('One half can wear another name'), findsOneWidget);

      await _tap(tester, const ValueKey('claw-another-way'));
      expect(find.text('Picture the same whole'), findsOneWidget);
      expect(
        find.text('Learning target: ${ClawFoundationsStoryArc.competencyId}'),
        findsOneWidget,
      );

      await _tap(tester, const ValueKey('claw-continue'));
      expect(find.text('Which fraction matches 1/2?'), findsOneWidget);

      await _tap(tester, const ValueKey('claw-choice-three-fourths'));
      expect(find.text('Keep the amount fixed'), findsOneWidget);
      expect(evidence, hasLength(1));
      expect(evidence.single.route, ClawLocalEvidenceRoute.insufficient);
      expect(evidence.single.createsMasteryClaim, isFalse);

      await _tap(tester, const ValueKey('claw-continue'));
      expect(find.text('Which fraction matches 1/2?'), findsOneWidget);

      await _tap(tester, const ValueKey('claw-choice-two-fourths'));
      expect(find.text('You found an equivalent fraction'), findsOneWidget);
      expect(evidence, hasLength(2));
      expect(evidence.last.route, ClawLocalEvidenceRoute.satisfied);
      expect(evidence.last.persistsLearnerRecord, isFalse);
    },
  );

  testWidgets('Socratic handler displays instructional text without evidence', (
    tester,
  ) async {
    final requests = <ClawSocraticRequest>[];
    final evidence = <ClawLocalEvidenceCandidate>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClawExperiencePlayer(
              graph: ClawFoundationsStoryArc.graph,
              presentations: ClawFoundationsStoryArc.presentations,
              availability: const ClawExperienceAvailability(
                modelAvailable: true,
              ),
              socraticHandler: (request) async {
                requests.add(request);
                return const ClawSocraticResult.success(
                  'What changed when both parts were multiplied by 2?',
                );
              },
              onEvidenceCandidate: evidence.add,
            ),
          ),
        ),
      ),
    );

    await _enterSocraticNode(tester);
    expect(find.byKey(const ValueKey('claw-socratic-input')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('claw-socratic-input')),
      'Both numbers doubled, but the amount stayed the same.',
    );
    await _tap(tester, const ValueKey('claw-socratic-submit'));

    expect(requests, hasLength(1));
    expect(requests.single.nodeId, 'socratic');
    expect(requests.single.targetCompetencyIds, const <String>{
      ClawFoundationsStoryArc.competencyId,
    });
    expect(
      requests.single.learnerInput,
      'Both numbers doubled, but the amount stayed the same.',
    );
    expect(
      find.text('What changed when both parts were multiplied by 2?'),
      findsOneWidget,
    );
    expect(evidence, isEmpty);
  });

  testWidgets('empty Socratic input cannot invoke the handler', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClawExperiencePlayer(
              graph: ClawFoundationsStoryArc.graph,
              presentations: ClawFoundationsStoryArc.presentations,
              availability: const ClawExperienceAvailability(
                modelAvailable: true,
              ),
              socraticHandler: (request) async {
                calls += 1;
                return const ClawSocraticResult.success('unused');
              },
            ),
          ),
        ),
      ),
    );

    await _enterSocraticNode(tester);

    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('claw-socratic-input')),
    );
    expect(input.maxLength, 280);
    final submit = tester.widget<FilledButton>(
      find.byKey(const ValueKey('claw-socratic-submit')),
    );
    expect(submit.onPressed, isNull);
    expect(calls, 0);
  });

  testWidgets('Socratic failure routes to reviewed non-model fallback', (
    tester,
  ) async {
    final evidence = <ClawLocalEvidenceCandidate>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClawExperiencePlayer(
              graph: ClawFoundationsStoryArc.graph,
              presentations: ClawFoundationsStoryArc.presentations,
              availability: const ClawExperienceAvailability(
                modelAvailable: true,
              ),
              socraticHandler: (request) async =>
                  const ClawSocraticResult.failure('provider-failure'),
              onEvidenceCandidate: evidence.add,
            ),
          ),
        ),
      ),
    );

    await _enterSocraticNode(tester);
    await tester.enterText(
      find.byKey(const ValueKey('claw-socratic-input')),
      'I think they are equal because both numbers changed.',
    );
    await _tap(tester, const ValueKey('claw-socratic-submit'));

    expect(find.text('Picture the same whole'), findsOneWidget);
    expect(
      find.text(
        'Tutor unavailable. Showing the reviewed non-model explanation.',
      ),
      findsOneWidget,
    );
    expect(evidence, isEmpty);
  });

  testWidgets('missing presentation fails visibly without invented content', (
    tester,
  ) async {
    final graph = ClawExperienceGraph(
      graphId: 'claw:test:missing-presentation',
      graphVersion: '1.0.0',
      entryNodeId: 'missing',
      nodes: const <String, ClawExperienceNode>{
        'missing': ClawExperienceNode(
          nodeId: 'missing',
          targetCompetencyIds: <String>{'competency:test'},
          experienceType: ClawExperienceNodeType.textExplanation,
          instructionalStrategyIds: <String>{'strategy:test'},
        ),
      },
      transitions: const <ClawExperienceTransition>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClawExperiencePlayer(
            graph: graph,
            presentations: const <String, ClawExperiencePresentation>{},
            availability: const ClawExperienceAvailability(),
          ),
        ),
      ),
    );

    expect(find.text('Content unavailable'), findsOneWidget);
    expect(
      find.textContaining('no learner-facing presentation yet'),
      findsOneWidget,
    );
    expect(find.text('Learning target: competency:test'), findsOneWidget);
  });
}

Future<void> _enterSocraticNode(WidgetTester tester) async {
  await _tap(tester, const ValueKey('claw-continue'));
  await _tap(tester, const ValueKey('claw-socratic-choice'));
  expect(find.text('Explain what stayed the same'), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, ValueKey<String> key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
