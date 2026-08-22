import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/learning_resource.dart';
import 'package:ontarioedai/core/services/learning_resource_catalog.dart';

class _Provider implements LearningResourceCatalogProvider {
  @override
  final String providerId;
  final List<LearningResourceCandidate> results;

  const _Provider({required this.providerId, required this.results});

  @override
  Future<List<LearningResourceCandidate>> discover(
    LearningResourceDiscoveryRequest request,
  ) async => results;
}

LearningResourceCandidate _candidate({
  String providerId = 'provider:youtube',
  String externalResourceId = 'video:123',
  Set<String> competencyIds = const <String>{'math:fractions:equivalence'},
}) {
  return LearningResourceCandidate(
    providerId: providerId,
    externalResourceId: externalResourceId,
    title: 'Equivalent fractions explained visually',
    competencyIds: competencyIds,
    format: LearningResourceFormat.video,
    language: 'en',
    sourceLocator: 'https://example.invalid/video/123',
    accessibilityFeatures: const <String>{'captions'},
    pace: LearningResourcePace.standard,
    difficulty: 0.45,
    durationSeconds: 240,
  );
}

void main() {
  const request = LearningResourceDiscoveryRequest(
    competencyId: 'math:fractions:equivalence',
    formats: <LearningResourceFormat>{LearningResourceFormat.video},
    language: 'en',
    requiredAccessibilityFeatures: <String>{'captions'},
    maximumDurationSeconds: 300,
  );

  test('provider query contains pedagogical need but no learner identity', () {
    final query = request.toProviderQuery();

    expect(query['competency_id'], 'math:fractions:equivalence');
    expect(query['language'], 'en');
    expect(query['maximum_duration_seconds'], 300);
    expect(query.containsKey('learner_subject_id'), isFalse);
    expect(query.containsKey('learner_id'), isFalse);
    expect(query.containsKey('guardian_id'), isFalse);
    expect(query.containsKey('institution_id'), isFalse);
    expect(query.containsKey('learner_history'), isFalse);
  });

  test('discovery candidate cannot self-assert a trust tier', () {
    final candidate = _candidate();

    // Trust is absent from LearningResourceCandidate by design. Only admission
    // creates a LearningResource with an assigned trust state.
    expect(candidate.providerId, 'provider:youtube');
    expect(candidate.externalResourceId, 'video:123');
  });

  test('catalog rejects provider identity mismatch', () async {
    final catalog = LearningResourceCatalog(
      providers: <LearningResourceCatalogProvider>[
        _Provider(
          providerId: 'provider:youtube',
          results: <LearningResourceCandidate>[
            _candidate(providerId: 'provider:impersonated'),
          ],
        ),
      ],
    );

    expect(
      () => catalog.discover(request),
      throwsA(isA<LearningResourceDiscoveryException>()),
    );
  });

  test('catalog ignores resources that do not cover requested competency', () async {
    final catalog = LearningResourceCatalog(
      providers: <LearningResourceCatalogProvider>[
        _Provider(
          providerId: 'provider:youtube',
          results: <LearningResourceCandidate>[
            _candidate(competencyIds: const <String>{'math:other'}),
          ],
        ),
      ],
    );

    expect(await catalog.discover(request), isEmpty);
  });

  test('admission requires independent review evidence and assigned trust', () {
    const admission = LearningResourceAdmissionService();
    final candidate = _candidate();

    expect(
      () => admission.admit(
        candidate: candidate,
        assignedTrustState: LearningResourceTrustState.educatorReviewed,
        reviewEvidenceIds: const <String>{},
      ),
      throwsA(isA<LearningResourceAdmissionException>()),
    );

    expect(
      () => admission.admit(
        candidate: candidate,
        assignedTrustState: LearningResourceTrustState.discovered,
        reviewEvidenceIds: const <String>{'review:1'},
      ),
      throwsA(isA<LearningResourceAdmissionException>()),
    );

    final admitted = admission.admit(
      candidate: candidate,
      assignedTrustState: LearningResourceTrustState.educatorReviewed,
      reviewEvidenceIds: const <String>{'review:educator:1'},
    );

    expect(admitted.resource.providerId, 'provider:youtube');
    expect(
      admitted.resource.trustState,
      LearningResourceTrustState.educatorReviewed,
    );
    expect(admitted.resource.isExternal, isTrue);
    expect(admitted.reviewEvidenceIds, contains('review:educator:1'));
  });
}
