import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/content_readiness_policy.dart';
import 'package:ontarioedai/core/services/content_readiness_policy_resolver.dart';

ContentPolicyDirective _directive({
  required String id,
  required ContentPolicySource source,
  required ContentPolicyEffect effect,
  required ContentPolicyStrength strength,
  required DateTime at,
  int priority = 10,
  Set<String> evidenceIds = const <String>{'evidence:1'},
}) {
  return ContentPolicyDirective(
    directiveId: id,
    source: source,
    effect: effect,
    strength: strength,
    priority: priority,
    competencyIds: const <String>{'health:competency:1'},
    contentTags: const <String>{'maturity:sensitive'},
    evidenceIds: evidenceIds,
    validFrom: at.subtract(const Duration(days: 1)),
  );
}

void main() {
  const resolver = ContentReadinessPolicyResolver();
  final now = DateTime.utc(2026, 8, 21, 20);

  test('guardian advisory deferral changes sequence but is not a hard denial', () {
    final decision = resolver.resolve(
      competencyId: 'health:competency:1',
      contentTags: const <String>{'maturity:sensitive'},
      directives: <ContentPolicyDirective>[
        _directive(
          id: 'guardian:defer',
          source: ContentPolicySource.guardianPreference,
          effect: ContentPolicyEffect.defer,
          strength: ContentPolicyStrength.advisory,
          at: now,
        ),
      ],
      at: now,
    );

    expect(decision.status, ContentReadinessStatus.deferred);
    expect(decision.sequenceAdjustment, -1);
    expect(decision.evidenceIds, contains('evidence:1'));
  });

  test('binding allow outranks advisory guardian deferral without erasing it', () {
    final decision = resolver.resolve(
      competencyId: 'health:competency:1',
      contentTags: const <String>{'maturity:sensitive'},
      directives: <ContentPolicyDirective>[
        _directive(
          id: 'guardian:defer',
          source: ContentPolicySource.guardianPreference,
          effect: ContentPolicyEffect.defer,
          strength: ContentPolicyStrength.advisory,
          at: now,
        ),
        _directive(
          id: 'jurisdiction:allow',
          source: ContentPolicySource.jurisdictionPolicy,
          effect: ContentPolicyEffect.allow,
          strength: ContentPolicyStrength.required,
          priority: 20,
          at: now,
        ),
      ],
      at: now,
    );

    expect(decision.status, ContentReadinessStatus.allowed);
    expect(decision.permitsPresentation, isTrue);
    expect(decision.sequenceAdjustment, -1);
    expect(decision.directiveIds, contains('jurisdiction:allow'));
  });

  test('strongest binding denial fails closed', () {
    final decision = resolver.resolve(
      competencyId: 'health:competency:1',
      contentTags: const <String>{'maturity:sensitive'},
      directives: <ContentPolicyDirective>[
        _directive(
          id: 'institution:allow',
          source: ContentPolicySource.institutionPolicy,
          effect: ContentPolicyEffect.allow,
          strength: ContentPolicyStrength.required,
          priority: 50,
          at: now,
        ),
        _directive(
          id: 'safeguarding:deny',
          source: ContentPolicySource.safeguarding,
          effect: ContentPolicyEffect.deny,
          strength: ContentPolicyStrength.nonWaivable,
          priority: 1,
          at: now,
        ),
      ],
      at: now,
    );

    expect(decision.status, ContentReadinessStatus.denied);
    expect(decision.permitsPresentation, isFalse);
    expect(decision.directiveIds, contains('safeguarding:deny'));
  });

  test('equal binding conflict requires review rather than guessing', () {
    final decision = resolver.resolve(
      competencyId: 'health:competency:1',
      contentTags: const <String>{'maturity:sensitive'},
      directives: <ContentPolicyDirective>[
        _directive(
          id: 'policy:defer',
          source: ContentPolicySource.institutionPolicy,
          effect: ContentPolicyEffect.defer,
          strength: ContentPolicyStrength.required,
          priority: 30,
          at: now,
        ),
        _directive(
          id: 'policy:prioritize',
          source: ContentPolicySource.jurisdictionPolicy,
          effect: ContentPolicyEffect.prioritize,
          strength: ContentPolicyStrength.required,
          priority: 30,
          at: now,
        ),
      ],
      at: now,
    );

    expect(decision.status, ContentReadinessStatus.reviewRequired);
    expect(decision.permitsPresentation, isFalse);
  });

  test('unevidenced policy input is ignored', () {
    final decision = resolver.resolve(
      competencyId: 'health:competency:1',
      contentTags: const <String>{'maturity:sensitive'},
      directives: <ContentPolicyDirective>[
        _directive(
          id: 'self-asserted:deny',
          source: ContentPolicySource.guardianPreference,
          effect: ContentPolicyEffect.deny,
          strength: ContentPolicyStrength.nonWaivable,
          evidenceIds: const <String>{},
          at: now,
        ),
      ],
      at: now,
    );

    expect(decision.status, ContentReadinessStatus.allowed);
    expect(decision.directiveIds, isEmpty);
  });
}
