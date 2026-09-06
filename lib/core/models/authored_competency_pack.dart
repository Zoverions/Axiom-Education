import 'competency_graph.dart';

class AuthoredCompetencyPackException implements Exception {
  final String message;

  const AuthoredCompetencyPackException(this.message);

  @override
  String toString() => 'AuthoredCompetencyPackException: $message';
}

class AuthoredCompetencyPack {
  static const aiNativeFamilyId =
      'axiom.education.competency.ai-native-computational-literacy';
  static const aiNativeAssetPath =
      'assets/competencies/ai_native_computational_literacy.v1.json';

  static const _schema = 'axiom-education-authored-competency-pack.v1';
  static const _version = '1.0.0';
  static const _authorship = 'axiom-extension';
  static const _jurisdictionalAuthority = 'none';
  static const _familyTag = 'family:ai-native-computational-literacy';
  static const _authorshipTag = 'authorship:axiom-extension';
  static const _dimensions = <String>{
    'dimension:intent',
    'dimension:specification',
    'dimension:verification',
    'dimension:systems',
  };
  static const _expectedIds = <String>{
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
  static final RegExp _competencyIdPattern = RegExp(
    r'^axiom:computational-literacy:(intent|specification|verification|systems):[a-z0-9-]+$',
  );

  final String schema;
  final String familyId;
  final String familyVersion;
  final String name;
  final String authorship;
  final String jurisdictionalAuthority;
  final CompetencyGraph graph;

  AuthoredCompetencyPack._({
    required this.schema,
    required this.familyId,
    required this.familyVersion,
    required this.name,
    required this.authorship,
    required this.jurisdictionalAuthority,
    required this.graph,
  });

  factory AuthoredCompetencyPack.fromJson(Map<String, Object?> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw AuthoredCompetencyPackException(
          '$key must be a non-empty string.',
        );
      }
      return value;
    }

    final schema = requiredString('schema');
    final familyId = requiredString('family_id');
    final familyVersion = requiredString('family_version');
    final name = requiredString('name');
    final authorship = requiredString('authorship');
    final jurisdictionalAuthority = requiredString('jurisdictional_authority');

    if (schema != _schema ||
        familyId != aiNativeFamilyId ||
        familyVersion != _version ||
        authorship != _authorship ||
        jurisdictionalAuthority != _jurisdictionalAuthority) {
      throw const AuthoredCompetencyPackException(
        'Unsupported authored competency pack identity.',
      );
    }

    final rawNodes = json['nodes'];
    final rawEdges = json['edges'];
    if (rawNodes is! List<Object?> || rawEdges is! List<Object?>) {
      throw const AuthoredCompetencyPackException(
        'Pack nodes and edges must be lists.',
      );
    }
    if (rawEdges.isNotEmpty) {
      throw const AuthoredCompetencyPackException(
        'AI-Native Computational Literacy v1 requires zero edges.',
      );
    }
    if (rawNodes.length != _expectedIds.length) {
      throw const AuthoredCompetencyPackException(
        'AI-Native Computational Literacy v1 requires exactly 18 nodes.',
      );
    }

    final nodes = <CompetencyNode>[];
    final seenIds = <String>{};

    for (final rawNode in rawNodes) {
      if (rawNode is! Map) {
        throw const AuthoredCompetencyPackException(
          'Each competency node must be an object.',
        );
      }
      final node = Map<String, Object?>.from(rawNode);
      final competencyId = node['competency_id'];
      final title = node['title'];
      final rawTags = node['tags'];

      if (competencyId is! String ||
          !_competencyIdPattern.hasMatch(competencyId) ||
          !seenIds.add(competencyId) ||
          title is! String ||
          title.trim().isEmpty ||
          rawTags is! List<Object?>) {
        throw const AuthoredCompetencyPackException(
          'Invalid competency node.',
        );
      }

      final tags = <String>{};
      for (final rawTag in rawTags) {
        if (rawTag is! String || rawTag.trim().isEmpty || !tags.add(rawTag)) {
          throw const AuthoredCompetencyPackException(
            'Competency node tags must be unique non-empty strings.',
          );
        }
      }

      final dimensionTags = tags
          .where((tag) => tag.startsWith('dimension:'))
          .toSet();
      if (!tags.contains(_familyTag) ||
          !tags.contains(_authorshipTag) ||
          dimensionTags.length != 1 ||
          !_dimensions.contains(dimensionTags.single)) {
        throw const AuthoredCompetencyPackException(
          'Invalid competency node tags.',
        );
      }

      final idDimension = competencyId.split(':')[2];
      if (dimensionTags.single != 'dimension:$idDimension') {
        throw const AuthoredCompetencyPackException(
          'Competency ID dimension must match its dimension tag.',
        );
      }

      nodes.add(
        CompetencyNode(
          competencyId: competencyId,
          title: title,
          tags: Set<String>.unmodifiable(tags),
        ),
      );
    }

    if (seenIds.length != _expectedIds.length ||
        !seenIds.containsAll(_expectedIds)) {
      throw const AuthoredCompetencyPackException(
        'AI-Native Computational Literacy v1 competency IDs do not match the approved set.',
      );
    }

    return AuthoredCompetencyPack._(
      schema: schema,
      familyId: familyId,
      familyVersion: familyVersion,
      name: name,
      authorship: authorship,
      jurisdictionalAuthority: jurisdictionalAuthority,
      graph: CompetencyGraph(
        nodes: nodes,
        edges: const <CompetencyEdge>[],
      ),
    );
  }

  bool containsCompetency(String competencyId) =>
      graph.nodes.containsKey(competencyId);

  CompetencyGraph toGraph() => graph;
}
