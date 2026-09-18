import 'authored_competency_pack.dart';
import 'cross_cutting_learning_evidence.dart';

enum CrossCuttingActivityRole { introduce, practice, elicitEvidence }

enum CrossCuttingAiMode { absent, optional, partOfTask }

class CrossCuttingCompetencyHookException implements Exception {
  final String message;

  const CrossCuttingCompetencyHookException(this.message);

  @override
  String toString() => 'CrossCuttingCompetencyHookException: $message';
}

class CrossCuttingCompetencyHook {
  final String competencyId;
  final CrossCuttingActivityRole role;
  final String learnerFacingPrompt;
  final CrossCuttingAiMode aiMode;
  final Set<CrossCuttingVerifierMethod> verifierMethods;
  final bool hasNonGenerativePath;

  CrossCuttingCompetencyHook({
    required this.competencyId,
    required this.role,
    required this.learnerFacingPrompt,
    required this.aiMode,
    required Set<CrossCuttingVerifierMethod> verifierMethods,
    required this.hasNonGenerativePath,
  }) : verifierMethods = Set<CrossCuttingVerifierMethod>.unmodifiable(
         verifierMethods,
       );

  bool get createsOfficialCurriculumCoverage => false;

  bool get createsLearnerEvidence => false;

  bool get createsAuthority => false;

  bool get persistsLearnerState => false;
}

class CrossCuttingCompetencyHookValidator {
  const CrossCuttingCompetencyHookValidator();

  void validate({
    required CrossCuttingCompetencyHook hook,
    required AuthoredCompetencyPack pack,
  }) {
    if (!pack.containsCompetency(hook.competencyId)) {
      throw const CrossCuttingCompetencyHookException(
        'Cross-cutting hook must reference a competency in the authored pack.',
      );
    }
    if (hook.learnerFacingPrompt.trim().isEmpty) {
      throw const CrossCuttingCompetencyHookException(
        'Cross-cutting hook requires learner-facing wording.',
      );
    }
    if (hook.role == CrossCuttingActivityRole.elicitEvidence &&
        hook.verifierMethods.isEmpty) {
      throw const CrossCuttingCompetencyHookException(
        'Evidence-eliciting hooks require at least one verifier method.',
      );
    }
    if (hook.role == CrossCuttingActivityRole.elicitEvidence &&
        !hook.hasNonGenerativePath) {
      throw const CrossCuttingCompetencyHookException(
        'Evidence-eliciting hooks require a non-generative demonstration path.',
      );
    }
  }
}
