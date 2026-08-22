import 'education_client.dart';
import 'education_contract.dart';
import 'educator_workflow_runtime.dart';

/// Consent-bound read access to the governed learner-record provider.
///
/// The pinned `axiom.education` v1 contract defines the request surface for
/// `education.learner.progress.read`, but it does not define a provider response
/// schema. This runtime therefore returns the successful gateway body as an
/// opaque, immutable map and deliberately exposes no mastery, completion, grade,
/// credit, transcript, or event-persistence interpretation.
class GovernedLearnerProgressReader {
  static const purpose = 'learning-progress-review';

  final AxiomEducationClient client;

  const GovernedLearnerProgressReader({required this.client});

  Future<GovernedLearnerProgressEnvelope> read({
    required String subjectId,
    required String consentId,
    required String courseCode,
    List<String> expectationIds = const [],
    String? asOf,
  }) async {
    _requireText(subjectId, 'subject_id');
    _requireText(consentId, 'consent_id');
    _requireText(courseCode, 'course_code');
    if (expectationIds.any((id) => id.trim().isEmpty) ||
        expectationIds.length != expectationIds.toSet().length) {
      throw const LearnerProgressValidationException(
        'expectation_ids must contain unique non-empty strings.',
      );
    }
    if (asOf != null) _validateTimestamp(asOf);

    final input = <String, Object?>{
      'subject_id': subjectId,
      'consent_id': consentId,
      'purpose': purpose,
      'course_code': courseCode,
    };
    if (expectationIds.isNotEmpty) {
      input['expectation_ids'] = List<String>.unmodifiable(expectationIds);
    }
    if (asOf != null) input['as_of'] = asOf;

    final requestDigest = EducatorWorkflowRuntime.canonicalDigest({
      'action': AxiomEducationContract.learnerProgressRead,
      'input': input,
    });
    final response = await client.submit(
      action: AxiomEducationContract.learnerProgressRead,
      input: input,
      idempotencyKey: 'education-progress-read:$requestDigest',
    );

    return GovernedLearnerProgressEnvelope(
      subjectId: subjectId,
      courseCode: courseCode,
      requestDigest: requestDigest,
      rawGatewayResponse: response,
    );
  }

  static void _requireText(String value, String field) {
    if (value.trim().isEmpty) {
      throw LearnerProgressValidationException('$field is required.');
    }
  }

  static void _validateTimestamp(String value) {
    final hasZone = RegExp(r'(?:Z|[+-]\d{2}:\d{2})$').hasMatch(value);
    if (!hasZone || DateTime.tryParse(value) == null) {
      throw const LearnerProgressValidationException(
        'as_of must be an ISO-8601 timestamp with a timezone.',
      );
    }
  }
}

class GovernedLearnerProgressEnvelope {
  final String subjectId;
  final String courseCode;
  final String requestDigest;
  final Map<String, Object?> rawGatewayResponse;

  const GovernedLearnerProgressEnvelope({
    required this.subjectId,
    required this.courseCode,
    required this.requestDigest,
    required this.rawGatewayResponse,
  });

  /// The v1 domain contract has no standardized progress response schema yet.
  bool get responseSchemaDefinedByContract => false;
}

class LearnerProgressValidationException implements Exception {
  final String message;

  const LearnerProgressValidationException(this.message);

  @override
  String toString() => 'LearnerProgressValidationException: $message';
}
