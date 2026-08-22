import '../models/learning_resource.dart';

class ResourceRecommendationContext {
  final String learnerSubjectId;
  final String competencyId;
  final ResourceEligibilityContext eligibility;
  final List<LearningResourceFeedback> recentFeedback;
  final List<LearningOutcomeObservation> outcomeObservations;
  final int? preferredMaximumDurationSeconds;

  const ResourceRecommendationContext({
    required this.learnerSubjectId,
    required this.competencyId,
    required this.eligibility,
    this.recentFeedback = const <LearningResourceFeedback>[],
    this.outcomeObservations = const <LearningOutcomeObservation>[],
    this.preferredMaximumDurationSeconds,
  });
}

class ResourceRecommendation {
  final LearningResource resource;
  final double score;
  final List<String> reasons;

  const ResourceRecommendation({
    required this.resource,
    required this.score,
    required this.reasons,
  });
}

/// Deterministic pedagogical recommender.
///
/// It optimizes for competency fit, accessibility, trust, direct learner
/// feedback, and demonstrated outcome evidence. It intentionally has no
/// watch-time, click-through, streak, ad, or generic engagement signal.
class ResourceRecommendationEngine {
  const ResourceRecommendationEngine();

  List<ResourceRecommendation> recommend({
    required List<LearningResource> resources,
    required ResourceRecommendationContext context,
    int limit = 5,
  }) {
    if (limit <= 0) return const <ResourceRecommendation>[];

    final byId = <String, LearningResource>{
      for (final resource in resources) resource.resourceId: resource,
    };

    final recommendations = <ResourceRecommendation>[];
    for (final resource in resources) {
      if (!resource.competencyIds.contains(context.competencyId)) continue;
      if (!context.eligibility.allows(resource)) continue;

      final reasons = <String>['matches target competency'];
      var score = 100.0 + resource.trustState.index * 2.0;

      if (context.eligibility.requiredAccessibilityFeatures.isNotEmpty) {
        reasons.add('meets required accessibility features');
        score += 6;
      }

      final maximumDuration = context.preferredMaximumDurationSeconds;
      if (maximumDuration != null && resource.durationSeconds != null) {
        if (resource.durationSeconds! <= maximumDuration) {
          score += 3;
          reasons.add('fits current duration preference');
        } else {
          score -= 6;
        }
      }

      for (final feedback in context.recentFeedback) {
        if (feedback.learnerSubjectId != context.learnerSubjectId ||
            feedback.competencyId != context.competencyId) {
          continue;
        }

        final previous = byId[feedback.resourceId];
        final sameResource = feedback.resourceId == resource.resourceId;
        final sameFormat = previous != null && previous.format == resource.format;

        for (final signal in feedback.signals) {
          score += _feedbackAdjustment(
            signal: signal,
            candidate: resource,
            previous: previous,
            sameResource: sameResource,
            sameFormat: sameFormat,
          );
        }

        if (sameResource &&
            feedback.signals.contains(LearningFeedbackSignal.helpful)) {
          reasons.add('learner reported this explanation was helpful');
        } else if (sameFormat &&
            feedback.signals.contains(LearningFeedbackSignal.moreLikeThis)) {
          reasons.add('matches a requested presentation format');
        }

        if (sameFormat &&
            feedback.signals.contains(LearningFeedbackSignal.showAnotherWay)) {
          reasons.add('same format deprioritized after request for another way');
        }
      }

      for (final outcome in context.outcomeObservations) {
        if (outcome.learnerSubjectId != context.learnerSubjectId ||
            outcome.competencyId != context.competencyId) {
          continue;
        }

        if (outcome.resourceId == resource.resourceId) {
          score += outcome.delta * 24;
          if (outcome.delta > 0) {
            reasons.add('follow-up evidence improved after this resource');
          } else if (outcome.delta < 0) {
            reasons.add('follow-up evidence did not improve after this resource');
          }
          continue;
        }

        final observedResource = byId[outcome.resourceId];
        if (observedResource != null && observedResource.format == resource.format) {
          score += outcome.delta * 8;
        }
      }

      recommendations.add(
        ResourceRecommendation(
          resource: resource,
          score: score,
          reasons: List<String>.unmodifiable(reasons),
        ),
      );
    }

    recommendations.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.resource.resourceId.compareTo(b.resource.resourceId);
    });

    return List<ResourceRecommendation>.unmodifiable(
      recommendations.take(limit),
    );
  }

  double _feedbackAdjustment({
    required LearningFeedbackSignal signal,
    required LearningResource candidate,
    required LearningResource? previous,
    required bool sameResource,
    required bool sameFormat,
  }) {
    switch (signal) {
      case LearningFeedbackSignal.helpful:
        if (sameResource) return 10;
        if (sameFormat) return 4;
        return 0;
      case LearningFeedbackSignal.moreLikeThis:
        if (sameResource) return 7;
        if (sameFormat) return 6;
        return 0;
      case LearningFeedbackSignal.likedExample:
        if (sameResource) return 5;
        if (sameFormat) return 2;
        return 0;
      case LearningFeedbackSignal.notHelpful:
        if (sameResource) return -16;
        if (sameFormat) return -3;
        return 0;
      case LearningFeedbackSignal.stillConfused:
        if (sameResource) return -14;
        if (sameFormat) return -4;
        return 0;
      case LearningFeedbackSignal.showAnotherWay:
        if (sameResource) return -25;
        if (sameFormat) return -9;
        return 4;
      case LearningFeedbackSignal.alreadyKnewThis:
        if (sameResource) return -10;
        if (previous != null && candidate.difficulty > previous.difficulty) {
          return 5;
        }
        return 0;
      case LearningFeedbackSignal.tooFast:
        if (candidate.pace == LearningResourcePace.slow) return 4;
        if (candidate.pace == LearningResourcePace.fast) return -6;
        return sameResource ? -3 : 0;
      case LearningFeedbackSignal.tooSlow:
        if (candidate.pace == LearningResourcePace.fast) return 4;
        if (candidate.pace == LearningResourcePace.slow) return -6;
        return sameResource ? -3 : 0;
      case LearningFeedbackSignal.tooEasy:
        if (previous != null && candidate.difficulty > previous.difficulty) {
          return 5;
        }
        if (sameResource) return -5;
        return 0;
      case LearningFeedbackSignal.tooHard:
        if (previous != null && candidate.difficulty < previous.difficulty) {
          return 5;
        }
        if (sameResource) return -5;
        return 0;
    }
  }
}
