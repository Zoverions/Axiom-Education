enum CompetencyEdgeType { prerequisite, supports, partOf, extendsTo }

enum CompetencyEvidenceState { unknown, attempted, emerging, demonstrated }

class CompetencyNode {
  final String competencyId;
  final String title;
  final Set<String> tags;

  const CompetencyNode({
    required this.competencyId,
    required this.title,
    this.tags = const <String>{},
  });
}

class CompetencyEdge {
  final String fromCompetencyId;
  final String toCompetencyId;
  final CompetencyEdgeType type;

  const CompetencyEdge({
    required this.fromCompetencyId,
    required this.toCompetencyId,
    required this.type,
  });
}

class CompetencyEvidence {
  final String learnerSubjectId;
  final String competencyId;
  final CompetencyEvidenceState state;
  final double confidence;
  final String evidenceId;
  final DateTime observedAt;

  const CompetencyEvidence({
    required this.learnerSubjectId,
    required this.competencyId,
    required this.state,
    required this.confidence,
    required this.evidenceId,
    required this.observedAt,
  }) : assert(confidence >= 0 && confidence <= 1);
}

class CompetencyGraphException implements Exception {
  final String message;

  const CompetencyGraphException(this.message);

  @override
  String toString() => 'CompetencyGraphException: $message';
}

class CompetencyGraph {
  final Map<String, CompetencyNode> nodes;
  final List<CompetencyEdge> edges;

  CompetencyGraph({
    required Iterable<CompetencyNode> nodes,
    required Iterable<CompetencyEdge> edges,
  }) : nodes = Map<String, CompetencyNode>.unmodifiable({
         for (final node in nodes) node.competencyId: node,
       }),
       edges = List<CompetencyEdge>.unmodifiable(edges) {
    final nodeList = nodes.toList(growable: false);
    if (this.nodes.length != nodeList.length) {
      throw const CompetencyGraphException('Competency IDs must be unique.');
    }
    _validateEdges();
    _validatePrerequisiteAcyclic();
  }

  void _validateEdges() {
    for (final edge in edges) {
      if (!nodes.containsKey(edge.fromCompetencyId) ||
          !nodes.containsKey(edge.toCompetencyId)) {
        throw const CompetencyGraphException(
          'Every competency edge endpoint must exist in the graph.',
        );
      }
      if (edge.fromCompetencyId == edge.toCompetencyId) {
        throw const CompetencyGraphException('Self edges are not allowed.');
      }
    }
  }

  void _validatePrerequisiteAcyclic() {
    final adjacency = <String, List<String>>{};
    for (final edge in edges.where(
      (edge) => edge.type == CompetencyEdgeType.prerequisite,
    )) {
      adjacency
          .putIfAbsent(edge.fromCompetencyId, () => <String>[])
          .add(edge.toCompetencyId);
    }

    final visiting = <String>{};
    final visited = <String>{};

    void visit(String nodeId) {
      if (visiting.contains(nodeId)) {
        throw const CompetencyGraphException(
          'Prerequisite relationships must be acyclic.',
        );
      }
      if (!visited.add(nodeId)) return;
      visiting.add(nodeId);
      for (final next in adjacency[nodeId] ?? const <String>[]) {
        visit(next);
      }
      visiting.remove(nodeId);
    }

    for (final nodeId in nodes.keys) {
      visit(nodeId);
    }
  }

  List<String> prerequisitesOf(String competencyId) {
    if (!nodes.containsKey(competencyId)) {
      throw CompetencyGraphException('Unknown competency $competencyId.');
    }
    return edges
        .where(
          (edge) =>
              edge.type == CompetencyEdgeType.prerequisite &&
              edge.toCompetencyId == competencyId,
        )
        .map((edge) => edge.fromCompetencyId)
        .toList(growable: false);
  }
}

class EntryDiagnosticPlan {
  final String targetCompetencyId;
  final List<String> competencyIdsToProbe;
  final int itemBudget;

  const EntryDiagnosticPlan({
    required this.targetCompetencyId,
    required this.competencyIdsToProbe,
    required this.itemBudget,
  });

  bool get isEmpty => competencyIdsToProbe.isEmpty;
}

/// Builds a bounded diagnostic path from demonstrated evidence rather than age
/// or grade placement. The returned plan is a probe order, not a mastery,
/// promotion, grade, credit, or placement decision.
class EntryDiagnosticPlanner {
  const EntryDiagnosticPlanner();

  EntryDiagnosticPlan plan({
    required CompetencyGraph graph,
    required String targetCompetencyId,
    required Iterable<CompetencyEvidence> evidence,
    int itemBudget = 8,
  }) {
    if (itemBudget <= 0) {
      throw const CompetencyGraphException(
        'Diagnostic item budget must be positive.',
      );
    }
    if (!graph.nodes.containsKey(targetCompetencyId)) {
      throw CompetencyGraphException(
        'Unknown target competency $targetCompetencyId.',
      );
    }

    final bestEvidence = <String, CompetencyEvidence>{};
    for (final item in evidence) {
      final current = bestEvidence[item.competencyId];
      if (current == null ||
          item.state.index > current.state.index ||
          (item.state == current.state &&
              item.observedAt.isAfter(current.observedAt))) {
        bestEvidence[item.competencyId] = item;
      }
    }

    bool sufficientlyDemonstrated(String competencyId) {
      final item = bestEvidence[competencyId];
      return item != null &&
          item.state == CompetencyEvidenceState.demonstrated &&
          item.confidence >= 0.7;
    }

    if (sufficientlyDemonstrated(targetCompetencyId)) {
      return EntryDiagnosticPlan(
        targetCompetencyId: targetCompetencyId,
        competencyIdsToProbe: const <String>[],
        itemBudget: itemBudget,
      );
    }

    final ordered = <String>[];
    final visited = <String>{};

    void addPrerequisites(String competencyId) {
      if (!visited.add(competencyId)) return;
      for (final prerequisite in graph.prerequisitesOf(competencyId)) {
        addPrerequisites(prerequisite);
        if (!sufficientlyDemonstrated(prerequisite) &&
            !ordered.contains(prerequisite) &&
            ordered.length < itemBudget) {
          ordered.add(prerequisite);
        }
      }
    }

    addPrerequisites(targetCompetencyId);
    if (ordered.length < itemBudget) {
      ordered.add(targetCompetencyId);
    }

    return EntryDiagnosticPlan(
      targetCompetencyId: targetCompetencyId,
      competencyIdsToProbe: List<String>.unmodifiable(ordered),
      itemBudget: itemBudget,
    );
  }
}
