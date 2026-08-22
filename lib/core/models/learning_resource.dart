enum LearningResourceFormat {
  video,
  text,
  audio,
  animation,
  workedExample,
  simulation,
  game,
  story,
  project,
  humanInstruction,
  externalExperience,
}

enum LearningResourceTrustState {
  discovered,
  machineAnalyzed,
  communityReviewed,
  educatorReviewed,
  institutionApproved,
  jurisdictionApproved,
}

enum LearningResourcePace { slow, standard, fast }

enum LearningFeedbackSignal {
  helpful,
  notHelpful,
  stillConfused,
  tooFast,
  tooSlow,
  tooEasy,
  tooHard,
  likedExample,
  showAnotherWay,
  moreLikeThis,
  alreadyKnewThis,
}

/// A pedagogical presentation of one or more competencies.
///
/// Providers are intentionally generic. YouTube, an OER library, a school,
/// Claw Academy, a simulation service, or a locally generated experience can
/// all describe resources through the same object.
class LearningResource {
  final String resourceId;
  final String providerId;
  final String title;
  final Set<String> competencyIds;
  final LearningResourceFormat format;
  final LearningResourceTrustState trustState;
  final String language;
  final Set<String> accessibilityFeatures;
  final Set<String> contentTags;
  final LearningResourcePace pace;
  final double difficulty;
  final int? durationSeconds;
  final String? sourceLocator;
  final bool isExternal;

  const LearningResource({
    required this.resourceId,
    required this.providerId,
    required this.title,
    required this.competencyIds,
    required this.format,
    required this.trustState,
    required this.language,
    this.accessibilityFeatures = const <String>{},
    this.contentTags = const <String>{},
    this.pace = LearningResourcePace.standard,
    this.difficulty = 0.5,
    this.durationSeconds,
    this.sourceLocator,
    this.isExternal = false,
  }) : assert(difficulty >= 0 && difficulty <= 1);
}

/// Explicit learner feedback about whether a teaching presentation helped.
///
/// This is pedagogical evidence. It is not a popularity rating and it does not
/// decide whether a competency belongs in the curriculum.
class LearningResourceFeedback {
  final String feedbackId;
  final String learnerSubjectId;
  final String resourceId;
  final String competencyId;
  final Set<LearningFeedbackSignal> signals;
  final DateTime occurredAt;

  const LearningResourceFeedback({
    required this.feedbackId,
    required this.learnerSubjectId,
    required this.resourceId,
    required this.competencyId,
    required this.signals,
    required this.occurredAt,
  });
}

/// A later observation that helps distinguish "I liked it" from "it helped".
class LearningOutcomeObservation {
  final String observationId;
  final String learnerSubjectId;
  final String competencyId;
  final String? resourceId;
  final double confidenceBefore;
  final double confidenceAfter;
  final String evidenceId;
  final DateTime occurredAt;

  const LearningOutcomeObservation({
    required this.observationId,
    required this.learnerSubjectId,
    required this.competencyId,
    required this.resourceId,
    required this.confidenceBefore,
    required this.confidenceAfter,
    required this.evidenceId,
    required this.occurredAt,
  }) : assert(confidenceBefore >= 0 && confidenceBefore <= 1),
       assert(confidenceAfter >= 0 && confidenceAfter <= 1);

  double get delta => confidenceAfter - confidenceBefore;
}

/// Output of the already-resolved content/readiness/governance policy layer.
///
/// The recommendation engine consumes this decision; it does not invent legal,
/// guardian, safeguarding, school, or jurisdiction rules itself.
class ResourceEligibilityContext {
  final Set<String> deniedResourceIds;
  final Set<String> deniedContentTags;
  final Set<String> requiredAccessibilityFeatures;
  final Set<String> acceptedLanguages;
  final LearningResourceTrustState minimumTrustState;

  const ResourceEligibilityContext({
    this.deniedResourceIds = const <String>{},
    this.deniedContentTags = const <String>{},
    this.requiredAccessibilityFeatures = const <String>{},
    this.acceptedLanguages = const <String>{'en'},
    this.minimumTrustState = LearningResourceTrustState.educatorReviewed,
  });

  bool allows(LearningResource resource) {
    if (deniedResourceIds.contains(resource.resourceId)) return false;
    if (resource.contentTags.any(deniedContentTags.contains)) return false;
    if (resource.trustState.index < minimumTrustState.index) return false;
    if (acceptedLanguages.isNotEmpty &&
        !acceptedLanguages.contains(resource.language)) {
      return false;
    }
    if (!resource.accessibilityFeatures.containsAll(
      requiredAccessibilityFeatures,
    )) {
      return false;
    }
    return true;
  }
}
