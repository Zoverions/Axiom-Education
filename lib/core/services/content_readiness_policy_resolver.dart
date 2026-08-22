import '../models/content_readiness_policy.dart';

/// Resolves evidenced content/readiness directives without inventing policy.
///
/// Denial is fail-closed at the strongest applicable binding level. Conflicting
/// equally strong binding directions require review rather than silently
/// guessing which authority should win. Advisory preferences influence
/// sequencing only and never create an access denial by themselves.
class ContentReadinessPolicyResolver {
  const ContentReadinessPolicyResolver();

  ContentReadinessDecision resolve({
    required String competencyId,
    required Set<String> contentTags,
    required List<ContentPolicyDirective> directives,
    required DateTime at,
  }) {
    final applicable = directives
        .where((directive) =>
            directive.isEvidenceBacked &&
            directive.isActiveAt(at) &&
            directive.appliesTo(
              competencyId: competencyId,
              targetContentTags: contentTags,
            ))
        .toList(growable: false);

    final binding = applicable
        .where((directive) => directive.strength != ContentPolicyStrength.advisory)
        .toList(growable: false);

    if (binding.isNotEmpty) {
      final strongest = binding
          .map((directive) => directive.strength.index)
          .reduce((a, b) => a > b ? a : b);
      final strongestDirectives = binding
          .where((directive) => directive.strength.index == strongest)
          .toList(growable: false);
      final highestPriority = strongestDirectives
          .map((directive) => directive.priority)
          .reduce((a, b) => a > b ? a : b);
      final controlling = strongestDirectives
          .where((directive) => directive.priority == highestPriority)
          .toList(growable: false);

      if (controlling.any((directive) => directive.effect == ContentPolicyEffect.deny)) {
        return _decision(
          ContentReadinessStatus.denied,
          controlling,
          sequenceAdjustment: 0,
          reason: 'Strongest applicable binding policy denies presentation.',
        );
      }

      final effects = controlling.map((directive) => directive.effect).toSet();
      if (effects.length > 1) {
        return _decision(
          ContentReadinessStatus.reviewRequired,
          controlling,
          sequenceAdjustment: 0,
          reason: 'Equally strong binding policy directions conflict.',
        );
      }

      switch (effects.single) {
        case ContentPolicyEffect.allow:
          return _decision(
            ContentReadinessStatus.allowed,
            controlling,
            sequenceAdjustment: _advisoryAdjustment(applicable),
            reason: 'Strongest applicable binding policy allows presentation.',
          );
        case ContentPolicyEffect.defer:
          return _decision(
            ContentReadinessStatus.deferred,
            controlling,
            sequenceAdjustment: -1,
            reason: 'Strongest applicable binding policy requires deferral.',
          );
        case ContentPolicyEffect.prioritize:
          return _decision(
            ContentReadinessStatus.prioritized,
            controlling,
            sequenceAdjustment: 1,
            reason: 'Strongest applicable binding policy requires prioritization.',
          );
        case ContentPolicyEffect.deny:
          throw StateError('deny handled before effect switch');
      }
    }

    final adjustment = _advisoryAdjustment(applicable);
    return ContentReadinessDecision(
      status: adjustment > 0
          ? ContentReadinessStatus.prioritized
          : adjustment < 0
              ? ContentReadinessStatus.deferred
              : ContentReadinessStatus.allowed,
      sequenceAdjustment: adjustment,
      directiveIds: Set<String>.unmodifiable(
        applicable.map((directive) => directive.directiveId),
      ),
      evidenceIds: Set<String>.unmodifiable(
        applicable.expand((directive) => directive.evidenceIds),
      ),
      reasons: List<String>.unmodifiable(<String>[
        if (applicable.isEmpty)
          'No applicable evidenced directive changes the default sequence.'
        else if (adjustment > 0)
          'Evidenced advisory preferences favor earlier sequencing.'
        else if (adjustment < 0)
          'Evidenced advisory preferences favor later sequencing when allowed.'
        else
          'Evidenced advisory preferences are neutral or balanced.',
      ]),
    );
  }

  int _advisoryAdjustment(List<ContentPolicyDirective> directives) {
    var score = 0;
    for (final directive in directives) {
      if (directive.strength != ContentPolicyStrength.advisory) continue;
      switch (directive.effect) {
        case ContentPolicyEffect.prioritize:
          score += 1;
          break;
        case ContentPolicyEffect.defer:
          score -= 1;
          break;
        case ContentPolicyEffect.allow:
        case ContentPolicyEffect.deny:
          // Advisory allow/deny signals are intentionally non-authorizing.
          break;
      }
    }
    if (score > 0) return 1;
    if (score < 0) return -1;
    return 0;
  }

  ContentReadinessDecision _decision(
    ContentReadinessStatus status,
    List<ContentPolicyDirective> controlling, {
    required int sequenceAdjustment,
    required String reason,
  }) {
    return ContentReadinessDecision(
      status: status,
      sequenceAdjustment: sequenceAdjustment,
      directiveIds: Set<String>.unmodifiable(
        controlling.map((directive) => directive.directiveId),
      ),
      evidenceIds: Set<String>.unmodifiable(
        controlling.expand((directive) => directive.evidenceIds),
      ),
      reasons: List<String>.unmodifiable(<String>[
        reason,
        ...controlling
            .map((directive) => directive.reasonCode)
            .whereType<String>(),
      ]),
    );
  }
}
