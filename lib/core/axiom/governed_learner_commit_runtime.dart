import 'education_client.dart';
import 'educator_workflow_runtime.dart';
import 'governed_memory_runtime.dart';

/// Orders governed learner content storage before learner-event recording.
///
/// The coordinator creates no local persistence and performs no compensating
/// delete when the learner-event append fails. A confirmed AXIOM memory object
/// may already be referenced by a remotely accepted idempotent append whose
/// response was lost, so automatic tombstoning would be unsafe.
class GovernedLearnerCommitCoordinator {
  final GovernedEducationMemoryWriter memoryWriter;
  final GovernedLearnerEventWriter learnerEventWriter;

  const GovernedLearnerCommitCoordinator({
    required this.memoryWriter,
    required this.learnerEventWriter,
  });

  Future<GovernedLearnerCommitReceipt> storeAndAppend({
    required List<EducatorWorkflowEvent> workflow,
    required String consentId,
    required Map<String, Object?> content,
  }) async {
    final chain = EducatorWorkflowRuntime.verifyWorkflow(workflow);
    final event = workflow.last;

    final memoryReceipt = await memoryWriter.storeForEvent(
      event: event,
      content: content,
    );
    if (memoryReceipt.workflowPayloadDigest != event.payloadDigest) {
      throw const GovernedLearnerCommitProtocolException(
        'Governed memory receipt is not bound to the workflow event digest.',
      );
    }

    try {
      final learnerEventReceipt = await learnerEventWriter.append(
        workflow: workflow,
        consentId: consentId,
        memoryObjectId: memoryReceipt.objectId,
      );
      return GovernedLearnerCommitReceipt(
        workflowId: chain.workflowId,
        memoryReceipt: memoryReceipt,
        learnerEventReceipt: learnerEventReceipt,
      );
    } on AxiomEducationException catch (error) {
      throw GovernedLearnerCommitAppendException(
        memoryReceipt: memoryReceipt,
        cause: error,
      );
    }
  }
}

class GovernedLearnerCommitReceipt {
  final String workflowId;
  final GovernedEducationMemoryReceipt memoryReceipt;
  final GovernedLearnerEventReceipt learnerEventReceipt;

  const GovernedLearnerCommitReceipt({
    required this.workflowId,
    required this.memoryReceipt,
    required this.learnerEventReceipt,
  });
}

sealed class GovernedLearnerCommitException implements Exception {
  final String message;
  final Object? cause;

  const GovernedLearnerCommitException(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message';
}

class GovernedLearnerCommitProtocolException
    extends GovernedLearnerCommitException {
  const GovernedLearnerCommitProtocolException(super.message);
}

class GovernedLearnerCommitAppendException
    extends GovernedLearnerCommitException {
  final GovernedEducationMemoryReceipt memoryReceipt;

  const GovernedLearnerCommitAppendException({
    required this.memoryReceipt,
    required Object cause,
  }) : super(
         'Governed memory was confirmed, but learner-event append did not '
         'return success. The memory reference is preserved for safe retry; '
         'no automatic tombstone was issued.',
         cause: cause,
       );
}
