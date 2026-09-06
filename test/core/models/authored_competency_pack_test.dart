import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/authored_competency_pack.dart';

void main() {
  const expectedIds = <String>{
    'axiom:computational-literacy:intent:problem-framing',
    'axiom:computational-literacy:intent:goal-definition',
    'axiom:computational-literacy:intent:constraint-recognition',
    'axiom:computational-literacy:intent:non-goal-recognition',
    'axiom:computational-literacy:specification:requirements',
    'axiom:computational-literacy:specification:invariants',
    'axiom:computational-literacy:specification:examples-and-counterexamples',
    'axiom:computational-literacy:specification:edge-cases',
    'axiom:computational-literacy:verification:method-selection',
    'axiom:computational-literacy:verification:test-design',
    'axiom:computational-literacy:verification:source-and-evidence-checking',
    'axiom:computational-literacy:verification:adversarial-checking',
    'axiom:computational-literacy:verification:correction-and-retest',
    'axiom:computational-literacy:systems:components-and-boundaries',
    'axiom:computational-literacy:systems:state-and-flow',
    'axiom:computational-literacy:systems:dependencies-and-causality',
    'axiom:computational-literacy:systems:failure-modes',
    'axiom:computational-literacy:systems:tradeoffs-and-effects',
  };

  Map<String, Object?> canonicalFixture() {
    Map<String, Object?> node(String id, String title, String dimension) =>
        <String, Object?>{
          'competency_id': id,
          'title': title,
          'tags': <String>[
            'family:ai-native-computational-literacy',
            'dimension:$dimension',
            'authorship:axiom-extension',
          ],
        };

    return <String, Object?>{
      'schema': 'axiom-education-authored-competency-pack.v1',
      'family_id':
          'axiom.education.competency.ai-native-computational-literacy',
      'family_version': '1.0.0',
      'name': 'AI-Native Computational Literacy',
      'authorship': 'axiom-extension',
      'jurisdictional_authority': 'none',
      'nodes': <Map<String, Object?>>[
        node(expectedIds.elementAt(0), 'Frame the actual problem', 'intent'),
        node(expectedIds.elementAt(1), 'Define the desired outcome', 'intent'),
        node(expectedIds.elementAt(2), 'Recognize constraints', 'intent'),
        node(expectedIds.elementAt(3), 'Recognize non-goals', 'intent'),
        node(expectedIds.elementAt(4), 'State requirements', 'specification'),
        node(expectedIds.elementAt(5), 'State invariants', 'specification'),
        node(
          expectedIds.elementAt(6),
          'Use examples and counterexamples',
          'specification',
        ),
        node(expectedIds.elementAt(7), 'Identify edge cases', 'specification'),
        node(
          expectedIds.elementAt(8),
          'Choose a verification method',
          'verification',
        ),
        node(expectedIds.elementAt(9), 'Design a test', 'verification'),
        node(
          expectedIds.elementAt(10),
          'Check sources and evidence',
          'verification',
        ),
        node(expectedIds.elementAt(11), 'Check adversarially', 'verification'),
        node(expectedIds.elementAt(12), 'Correct and retest', 'verification'),
        node(
          expectedIds.elementAt(13),
          'Identify components and boundaries',
          'systems',
        ),
        node(expectedIds.elementAt(14), 'Trace state and flow', 'systems'),
        node(
          expectedIds.elementAt(15),
          'Reason about dependencies and causality',
          'systems',
        ),
        node(expectedIds.elementAt(16), 'Anticipate failure modes', 'systems'),
        node(
          expectedIds.elementAt(17),
          'Reason about trade-offs and effects',
          'systems',
        ),
      ],
      'edges': <Object?>[],
    };
  }

  Map<String, Object?> copy(Map<String, Object?> source) =>
      jsonDecode(jsonEncode(source)) as Map<String, Object?>;

  test('canonical pack is exactly the approved 18-node extension', () {
    final pack = AuthoredCompetencyPack.fromJson(canonicalFixture());

    expect(pack.schema, 'axiom-education-authored-competency-pack.v1');
    expect(pack.familyId, AuthoredCompetencyPack.aiNativeFamilyId);
    expect(pack.familyVersion, '1.0.0');
    expect(pack.authorship, 'axiom-extension');
    expect(pack.jurisdictionalAuthority, 'none');
    expect(pack.graph.nodes.keys.toSet(), expectedIds);
    expect(pack.graph.edges, isEmpty);
    expect(pack.toGraph(), same(pack.graph));
    expect(
      pack.containsCompetency(
        'axiom:computational-literacy:verification:method-selection',
      ),
      isTrue,
    );
  });

  test('unsupported schema or family version fails closed', () {
    final badSchema = copy(canonicalFixture())
      ..['schema'] = 'axiom-education-authored-competency-pack.v2';
    final badVersion = copy(canonicalFixture())..['family_version'] = '2.0.0';

    expect(
      () => AuthoredCompetencyPack.fromJson(badSchema),
      throwsA(isA<AuthoredCompetencyPackException>()),
    );
    expect(
      () => AuthoredCompetencyPack.fromJson(badVersion),
      throwsA(isA<AuthoredCompetencyPackException>()),
    );
  });

  test('wrong family, authorship, or jurisdictional authority fails closed', () {
    final wrongFamily = copy(canonicalFixture())..['family_id'] = 'other';
    final wrongAuthorship = copy(canonicalFixture())..['authorship'] = 'ontario';
    final wrongAuthority = copy(canonicalFixture())
      ..['jurisdictional_authority'] = 'ontario';

    for (final fixture in <Map<String, Object?>>[
      wrongFamily,
      wrongAuthorship,
      wrongAuthority,
    ]) {
      expect(
        () => AuthoredCompetencyPack.fromJson(fixture),
        throwsA(isA<AuthoredCompetencyPackException>()),
      );
    }
  });

  test('duplicate or malformed competency IDs fail closed', () {
    final duplicate = copy(canonicalFixture());
    final duplicateNodes = duplicate['nodes']! as List<Object?>;
    duplicateNodes[1] = copy(duplicateNodes.first! as Map<String, Object?>);

    final malformed = copy(canonicalFixture());
    final malformedNodes = malformed['nodes']! as List<Object?>;
    (malformedNodes.first! as Map<String, Object?>)['competency_id'] =
        'prompt-engineering:problem-framing';

    expect(
      () => AuthoredCompetencyPack.fromJson(duplicate),
      throwsA(isA<AuthoredCompetencyPackException>()),
    );
    expect(
      () => AuthoredCompetencyPack.fromJson(malformed),
      throwsA(isA<AuthoredCompetencyPackException>()),
    );
  });

  test('family, authorship, and exactly one known dimension tag are required', () {
    final missingFamily = copy(canonicalFixture());
    final missingFamilyTags = ((missingFamily['nodes']! as List<Object?>).first!
        as Map<String, Object?>)['tags']! as List<Object?>;
    missingFamilyTags.remove('family:ai-native-computational-literacy');

    final missingAuthorship = copy(canonicalFixture());
    final missingAuthorshipTags =
        ((missingAuthorship['nodes']! as List<Object?>).first!
            as Map<String, Object?>)['tags']! as List<Object?>;
    missingAuthorshipTags.remove('authorship:axiom-extension');

    final multipleDimensions = copy(canonicalFixture());
    final multipleDimensionTags =
        ((multipleDimensions['nodes']! as List<Object?>).first!
            as Map<String, Object?>)['tags']! as List<Object?>;
    multipleDimensionTags.add('dimension:systems');

    final unknownDimension = copy(canonicalFixture());
    final unknownDimensionTags =
        ((unknownDimension['nodes']! as List<Object?>).first!
            as Map<String, Object?>)['tags']! as List<Object?>;
    unknownDimensionTags[1] = 'dimension:prompting';

    for (final fixture in <Map<String, Object?>>[
      missingFamily,
      missingAuthorship,
      multipleDimensions,
      unknownDimension,
    ]) {
      expect(
        () => AuthoredCompetencyPack.fromJson(fixture),
        throwsA(isA<AuthoredCompetencyPackException>()),
      );
    }
  });

  test('future edge definitions still obey existing graph endpoint checks', () {
    final fixture = copy(canonicalFixture());
    fixture['edges'] = <Object?>[
      <String, Object?>{
        'from_competency_id':
            'axiom:computational-literacy:intent:problem-framing',
        'to_competency_id': 'axiom:computational-literacy:missing',
        'type': 'supports',
      },
    ];

    expect(
      () => AuthoredCompetencyPack.fromJson(fixture),
      throwsA(isA<AuthoredCompetencyPackException>()),
    );
  });
}
