enum ContentPolicySource {
  learnerPreference,
  guardianPreference,
  educatorRecommendation,
  institutionPolicy,
  jurisdictionPolicy,
  safeguarding,
}

enum ContentPolicyEffect { allow, defer, prioritize, deny }

enum ContentPolicyStrength { advisory, required, nonWaivable }

enum ContentReadinessStatus {
  allowed,
  deferred,
  prioritized,
  denied,
  reviewRequired,
}

/// An already-issued policy or preference input relevant to one educational
/// content decision.
///
/// This object does not infer law, maturity, capacity, guardianship, or school
/// policy. Those facts must arrive as evidenced directives from the applicable
/// authority domain.
class ContentPolicyDirective {
  final String directiveId;
  final ContentPolicySource source;
  final ContentPolicyEffect effect;
  final ContentPolicyStrength strength;
  final int priority;
  final Set<String> competencyIds;
  final Set<String> contentTags;
  final Set<String> evidenceIds;
  final DateTime validFrom;
  final DateTime? validUntil;
  final DateTime? revokedAt;
  final String? reasonCode;

  const ContentPolicyDirective({
    required this.directiveId,
    required this.source,
    required this.effect,
    required this.strength,
    required this.priority,
    required this.competencyIds,
    required this.contentTags,
    required this.evidenceIds,
    required this.validFrom,
    this.validUntil,
    this.revokedAt,
    this.reasonCode,
  }) : assert(priority >= 0);

  bool get isEvidenceBacked => evidenceIds.isNotEmpty;

  bool isActiveAt(DateTime at) {
    if (at.isBefore(validFrom)) return false;
    if (revokedAt != null && !at.isBefore(revokedAt!)) return false;
    if (validUntil != null && !at.isBefore(validUntil!)) return false;
    return true;
  }

  bool appliesTo({
    required String competencyId,
    required Set<String> targetContentTags,
  }) {
    final competencyMatch =
        competencyIds.isEmpty || competencyIds.contains(competencyId);
    final tagMatch =
        contentTags.isEmpty || contentTags.any(targetContentTags.contains);
    return competencyMatch && tagMatch;
  }
}

class ContentReadinessDecision {
  final ContentReadinessStatus status;
  final int sequenceAdjustment;
  final Set<String> directiveIds;
  final Set<String> evidenceIds;
  final List<String> reasons;

  const ContentReadinessDecision({
    required this.status,
    required this.sequenceAdjustment,
    required this.directiveIds,
    required this.evidenceIds,
    required this.reasons,
  });

  bool get permitsPresentation =>
      status == ContentReadinessStatus.allowed ||
      status == ContentReadinessStatus.prioritized;
}
