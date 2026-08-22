enum ClawLocalEvidenceRoute { satisfied, insufficient }

class ClawExperienceChoicePresentation {
  final String choiceId;
  final String label;
  final ClawLocalEvidenceRoute? evidenceRoute;

  const ClawExperienceChoicePresentation({
    required this.choiceId,
    required this.label,
    this.evidenceRoute,
  });
}

class ClawExperiencePresentation {
  final String nodeId;
  final String title;
  final String body;
  final String? eyebrow;
  final String? supportingText;
  final List<String> bullets;
  final List<ClawExperienceChoicePresentation> choices;
  final String continueLabel;

  const ClawExperiencePresentation({
    required this.nodeId,
    required this.title,
    required this.body,
    this.eyebrow,
    this.supportingText,
    this.bullets = const <String>[],
    this.choices = const <ClawExperienceChoicePresentation>[],
    this.continueLabel = 'Continue',
  });
}

class ClawLocalEvidenceCandidate {
  final String nodeId;
  final String choiceId;
  final ClawLocalEvidenceRoute route;

  const ClawLocalEvidenceCandidate({
    required this.nodeId,
    required this.choiceId,
    required this.route,
  });

  bool get createsMasteryClaim => false;

  bool get createsGrade => false;

  bool get persistsLearnerRecord => false;
}
