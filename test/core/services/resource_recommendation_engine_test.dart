import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/learning_resource.dart';
import 'package:ontarioedai/core/services/resource_recommendation_engine.dart';

LearningResource _resource({
  required String id,
  required LearningResourceFormat format,
  LearningResourceTrustState trust =
      LearningResourceTrustState.educatorReviewed,
  Set<String> accessibility = const <String>{'captions'},
  Set<String> tags = const <String>{},
  LearningResourcePace pace = LearningResourcePace.standard,
  double difficulty = 0.5,
  int? durationSeconds = 300,
  String provider = 'provider:local',
}) {
  return LearningResource(
    resourceId: id,
    providerId: provider,
    title: id,
    competencyIds: const <String>{'math:fractions:equivalence'},
    format: format,
    trustState: trust,
    language: 'en',
    accessibilityFeatures: accessibility,
    contentTags: tags,
    pace: pace,
    difficulty: difficulty,
    durationSeconds: durationSeconds,
    isExternal: provider != 'provider:local',
  );
}

void main() {
  const engine = ResourceRecommendationEngine();
  final now = DateTime.utc(2026, 8, 21, 20);

  test('hard-filters unresolved trust, accessibility, and content policy', () {
    final recommendations = engine.recommend(
      resources: <LearningResource>[
        _resource(
          id: 'resource:low-trust',
          format: LearningResourceFormat.video,
          trust: LearningResourceTrustState.communityReviewed,
        ),
        _resource(
          id: 'resource:no-captions',
          format: LearningResourceFormat.video,
          accessibility: const <String>{},
        ),
        _resource(
          id: 'resource:policy-denied',
          format: LearningResourceFormat.video,
          tags: const <String>{'resolved-policy:denied'},
        ),
        _resource(
          id: 'resource:youtube-reviewed',
          format: LearningResourceFormat.video,
          provider: 'provider:youtube',
        ),
      ],
      context: const ResourceRecommendationContext(
        learnerSubjectId: 'learner:1',
        competencyId: 'math:fractions:equivalence',
        eligibility: ResourceEligibilityContext(
          requiredAccessibilityFeatures: <String>{'captions'},
          deniedContentTags: <String>{'resolved-policy:denied'},
          minimumTrustState: LearningResourceTrustState.educatorReviewed,
        ),
      ),
    );

    expect(recommendations, hasLength(1));
    expect(
      recommendations.single.resource.resourceId,
      'resource:youtube-reviewed',
    );
    expect(recommendations.single.resource.providerId, 'provider:youtube');
  });

  test(
    'direct feedback plus demonstrated outcome can reinforce a useful resource',
    () {
      final video = _resource(
        id: 'resource:video:1',
        format: LearningResourceFormat.video,
        provider: 'provider:youtube',
      );
      final worked = _resource(
        id: 'resource:worked:1',
        format: LearningResourceFormat.workedExample,
      );

      final recommendations = engine.recommend(
        resources: <LearningResource>[video, worked],
        context: ResourceRecommendationContext(
          learnerSubjectId: 'learner:1',
          competencyId: 'math:fractions:equivalence',
          eligibility: const ResourceEligibilityContext(),
          recentFeedback: <LearningResourceFeedback>[
            LearningResourceFeedback(
              feedbackId: 'feedback:1',
              learnerSubjectId: 'learner:1',
              resourceId: video.resourceId,
              competencyId: 'math:fractions:equivalence',
              signals: const <LearningFeedbackSignal>{
                LearningFeedbackSignal.helpful,
                LearningFeedbackSignal.moreLikeThis,
              },
              occurredAt: now,
            ),
          ],
          outcomeObservations: <LearningOutcomeObservation>[
            LearningOutcomeObservation(
              observationId: 'outcome:1',
              learnerSubjectId: 'learner:1',
              competencyId: 'math:fractions:equivalence',
              resourceId: video.resourceId,
              confidenceBefore: 0.35,
              confidenceAfter: 0.70,
              evidenceId: 'evidence:assessment:1',
              occurredAt: now.add(const Duration(minutes: 20)),
            ),
          ],
        ),
      );

      expect(recommendations.first.resource.resourceId, video.resourceId);
      expect(
        recommendations.first.reasons,
        contains('follow-up evidence improved after this resource'),
      );
    },
  );

  test('show another way steers toward a different presentation format', () {
    final firstVideo = _resource(
      id: 'resource:video:1',
      format: LearningResourceFormat.video,
      provider: 'provider:youtube',
    );
    final secondVideo = _resource(
      id: 'resource:video:2',
      format: LearningResourceFormat.video,
      provider: 'provider:oer-video',
    );
    final worked = _resource(
      id: 'resource:worked:1',
      format: LearningResourceFormat.workedExample,
    );

    final recommendations = engine.recommend(
      resources: <LearningResource>[firstVideo, secondVideo, worked],
      context: ResourceRecommendationContext(
        learnerSubjectId: 'learner:1',
        competencyId: 'math:fractions:equivalence',
        eligibility: const ResourceEligibilityContext(),
        recentFeedback: <LearningResourceFeedback>[
          LearningResourceFeedback(
            feedbackId: 'feedback:another-way',
            learnerSubjectId: 'learner:1',
            resourceId: firstVideo.resourceId,
            competencyId: 'math:fractions:equivalence',
            signals: const <LearningFeedbackSignal>{
              LearningFeedbackSignal.stillConfused,
              LearningFeedbackSignal.showAnotherWay,
            },
            occurredAt: now,
          ),
        ],
      ),
    );

    expect(recommendations.first.resource.resourceId, worked.resourceId);
    expect(
      recommendations.first.resource.format,
      LearningResourceFormat.workedExample,
    );
  });

  test(
    'pace and difficulty feedback remain contextual rather than learner labels',
    () {
      final prior = _resource(
        id: 'resource:prior',
        format: LearningResourceFormat.text,
        pace: LearningResourcePace.fast,
        difficulty: 0.8,
      );
      final gentler = _resource(
        id: 'resource:gentler',
        format: LearningResourceFormat.animation,
        pace: LearningResourcePace.slow,
        difficulty: 0.4,
      );
      final harderFast = _resource(
        id: 'resource:hard-fast',
        format: LearningResourceFormat.animation,
        pace: LearningResourcePace.fast,
        difficulty: 0.9,
      );

      final recommendations = engine.recommend(
        resources: <LearningResource>[prior, gentler, harderFast],
        context: ResourceRecommendationContext(
          learnerSubjectId: 'learner:1',
          competencyId: 'math:fractions:equivalence',
          eligibility: const ResourceEligibilityContext(),
          recentFeedback: <LearningResourceFeedback>[
            LearningResourceFeedback(
              feedbackId: 'feedback:pace',
              learnerSubjectId: 'learner:1',
              resourceId: prior.resourceId,
              competencyId: 'math:fractions:equivalence',
              signals: const <LearningFeedbackSignal>{
                LearningFeedbackSignal.tooFast,
                LearningFeedbackSignal.tooHard,
              },
              occurredAt: now,
            ),
          ],
        ),
      );

      expect(recommendations.first.resource.resourceId, gentler.resourceId);
    },
  );
}
