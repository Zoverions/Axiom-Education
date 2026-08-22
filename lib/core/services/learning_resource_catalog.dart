import '../models/learning_resource.dart';

/// Pedagogical discovery request sent to a resource provider.
///
/// There is intentionally no learner identifier, guardian identifier, school
/// identifier, learner history, diagnosis, or raw policy context in this
/// request. Personalization happens inside Axiom before this minimum query is
/// created.
class LearningResourceDiscoveryRequest {
  final String competencyId;
  final Set<LearningResourceFormat> formats;
  final String language;
  final Set<String> requiredAccessibilityFeatures;
  final int? maximumDurationSeconds;
  final Set<String> searchTags;

  const LearningResourceDiscoveryRequest({
    required this.competencyId,
    required this.formats,
    required this.language,
    this.requiredAccessibilityFeatures = const <String>{},
    this.maximumDurationSeconds,
    this.searchTags = const <String>{},
  });

  Map<String, Object?> toProviderQuery() {
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      'competency_id': competencyId,
      'formats': formats.map((format) => format.name).toList(growable: false),
      'language': language,
      'required_accessibility_features': requiredAccessibilityFeatures.toList(
        growable: false,
      ),
      if (maximumDurationSeconds != null)
        'maximum_duration_seconds': maximumDurationSeconds,
      if (searchTags.isNotEmpty)
        'search_tags': searchTags.toList(growable: false),
    });
  }
}

/// Untrusted resource metadata returned by discovery.
///
/// A candidate deliberately has no trust/review state. An external provider
/// therefore cannot assert that its own result is educator, institution, or
/// jurisdiction approved.
class LearningResourceCandidate {
  final String providerId;
  final String externalResourceId;
  final String title;
  final Set<String> competencyIds;
  final LearningResourceFormat format;
  final String language;
  final Set<String> accessibilityFeatures;
  final Set<String> contentTags;
  final LearningResourcePace pace;
  final double difficulty;
  final int? durationSeconds;
  final String sourceLocator;

  const LearningResourceCandidate({
    required this.providerId,
    required this.externalResourceId,
    required this.title,
    required this.competencyIds,
    required this.format,
    required this.language,
    required this.sourceLocator,
    this.accessibilityFeatures = const <String>{},
    this.contentTags = const <String>{},
    this.pace = LearningResourcePace.standard,
    this.difficulty = 0.5,
    this.durationSeconds,
  }) : assert(difficulty >= 0 && difficulty <= 1);
}

abstract interface class LearningResourceCatalogProvider {
  String get providerId;

  Future<List<LearningResourceCandidate>> discover(
    LearningResourceDiscoveryRequest request,
  );
}

class LearningResourceDiscoveryException implements Exception {
  final String message;

  const LearningResourceDiscoveryException(this.message);

  @override
  String toString() => 'LearningResourceDiscoveryException: $message';
}

/// Aggregates external discovery while enforcing provider identity binding.
class LearningResourceCatalog {
  final List<LearningResourceCatalogProvider> providers;

  const LearningResourceCatalog({required this.providers});

  Future<List<LearningResourceCandidate>> discover(
    LearningResourceDiscoveryRequest request,
  ) async {
    final candidates = <LearningResourceCandidate>[];

    for (final provider in providers) {
      final discovered = await provider.discover(request);
      for (final candidate in discovered) {
        if (candidate.providerId != provider.providerId) {
          throw LearningResourceDiscoveryException(
            'Provider ${provider.providerId} returned a candidate bound to '
            '${candidate.providerId}.',
          );
        }
        if (!candidate.competencyIds.contains(request.competencyId)) {
          continue;
        }
        candidates.add(candidate);
      }
    }

    return List<LearningResourceCandidate>.unmodifiable(candidates);
  }
}

/// Result of an explicit Axiom-side review/admission action.
class AdmittedLearningResource {
  final LearningResource resource;
  final Set<String> reviewEvidenceIds;

  const AdmittedLearningResource({
    required this.resource,
    required this.reviewEvidenceIds,
  });
}

class LearningResourceAdmissionException implements Exception {
  final String message;

  const LearningResourceAdmissionException(this.message);

  @override
  String toString() => 'LearningResourceAdmissionException: $message';
}

/// Converts an untrusted provider candidate into a resource only after an
/// explicit review process supplies a trust state and evidence references.
class LearningResourceAdmissionService {
  const LearningResourceAdmissionService();

  AdmittedLearningResource admit({
    required LearningResourceCandidate candidate,
    required LearningResourceTrustState assignedTrustState,
    required Set<String> reviewEvidenceIds,
  }) {
    if (reviewEvidenceIds.isEmpty) {
      throw const LearningResourceAdmissionException(
        'External learning-resource admission requires review evidence.',
      );
    }
    if (assignedTrustState == LearningResourceTrustState.discovered) {
      throw const LearningResourceAdmissionException(
        'Admission must represent an actual Axiom review step.',
      );
    }

    final resource = LearningResource(
      resourceId: '${candidate.providerId}:${candidate.externalResourceId}',
      providerId: candidate.providerId,
      title: candidate.title,
      competencyIds: Set<String>.unmodifiable(candidate.competencyIds),
      format: candidate.format,
      trustState: assignedTrustState,
      language: candidate.language,
      accessibilityFeatures: Set<String>.unmodifiable(
        candidate.accessibilityFeatures,
      ),
      contentTags: Set<String>.unmodifiable(candidate.contentTags),
      pace: candidate.pace,
      difficulty: candidate.difficulty,
      durationSeconds: candidate.durationSeconds,
      sourceLocator: candidate.sourceLocator,
      isExternal: true,
    );

    return AdmittedLearningResource(
      resource: resource,
      reviewEvidenceIds: Set<String>.unmodifiable(reviewEvidenceIds),
    );
  }
}
