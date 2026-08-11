from __future__ import annotations

import copy
import unittest

from tools.educator_workflow import (
    EXPECTED_PARENT_SHA256,
    EducatorWorkflowError,
    finalize_event,
    load_contract,
    project_to_parent_event,
    verify_workflow,
)


D_ASSIGN = "1" * 64
D_SUBMISSION = "2" * 64
D_RESUBMISSION = "3" * 64
D_FEEDBACK = "4" * 64
D_CORRECTION = "5" * 64
D_REASON = "6" * 64


class EducatorWorkflowTests(unittest.TestCase):
    def event(
        self,
        event_type,
        actor_role,
        review_state,
        occurred_at,
        *,
        previous=None,
        artifact=None,
        feedback=None,
        reason=None,
        event_id=None,
    ):
        payload = {
            "schema": "axiom-education-educator-workflow-event.v1",
            "workflow_id": "workflow-mth1w-u1-task",
            "assignment_id": "assignment-mth1w-u1-task",
            "subject_id": "subject-test-001",
            "learning_context_id": "ontario-secondary-mth1w",
            "course_code": "MTH1W",
            "expectation_ids": ["B1.1"],
            "event_id": event_id or f"event-{event_type}-{occurred_at}",
            "event_type": event_type,
            "actor_role": actor_role,
            "occurred_at": occurred_at,
            "previous_event_digest": previous,
            "artifact_digest": artifact,
            "feedback_digest": feedback,
            "reason_digest": reason,
            "review_state": review_state,
            "payload_digest": "",
        }
        return finalize_event(payload)

    def standard_sequence(self):
        assignment = self.event(
            "assignment.created",
            "educator",
            "assigned",
            "2026-08-11T12:00:00Z",
            artifact=D_ASSIGN,
        )
        submission = self.event(
            "submission.created",
            "learner",
            "submitted",
            "2026-08-11T12:10:00Z",
            previous=assignment["payload_digest"],
            artifact=D_SUBMISSION,
        )
        review = self.event(
            "review.started",
            "educator",
            "under-review",
            "2026-08-11T12:20:00Z",
            previous=submission["payload_digest"],
            artifact=D_SUBMISSION,
        )
        feedback = self.event(
            "feedback.recorded",
            "educator",
            "feedback-available",
            "2026-08-11T12:30:00Z",
            previous=review["payload_digest"],
            artifact=D_SUBMISSION,
            feedback=D_FEEDBACK,
        )
        finalized = self.event(
            "review.finalized",
            "educator",
            "finalized",
            "2026-08-11T12:40:00Z",
            previous=feedback["payload_digest"],
            artifact=D_SUBMISSION,
        )
        return [assignment, submission, review, feedback, finalized]

    def test_parent_contract_bytes_remain_pinned(self):
        contract = load_contract()
        self.assertEqual(
            contract["parent_contract"]["contract_sha256"],
            EXPECTED_PARENT_SHA256,
        )

    def test_standard_assignment_review_finalization_chain(self):
        result = verify_workflow(self.standard_sequence())
        self.assertTrue(result["valid"])
        self.assertEqual(result["events"], 5)
        self.assertEqual(result["final_state"], "finalized")

    def test_revision_and_resubmission_chain(self):
        events = self.standard_sequence()[:-1]
        feedback = events[-1]
        revision = self.event(
            "revision.requested",
            "educator",
            "revision-requested",
            "2026-08-11T12:40:00Z",
            previous=feedback["payload_digest"],
            artifact=D_SUBMISSION,
            feedback=D_FEEDBACK,
        )
        resubmission = self.event(
            "submission.resubmitted",
            "learner",
            "submitted",
            "2026-08-11T12:50:00Z",
            previous=revision["payload_digest"],
            artifact=D_RESUBMISSION,
        )
        review = self.event(
            "review.started",
            "educator",
            "under-review",
            "2026-08-11T13:00:00Z",
            previous=resubmission["payload_digest"],
            artifact=D_RESUBMISSION,
        )
        finalized = self.event(
            "review.finalized",
            "educator",
            "finalized",
            "2026-08-11T13:10:00Z",
            previous=review["payload_digest"],
            artifact=D_RESUBMISSION,
        )
        result = verify_workflow(events + [revision, resubmission, review, finalized])
        self.assertEqual(result["final_state"], "finalized")

    def test_appeal_and_correction_chain(self):
        events = self.standard_sequence()
        finalized = events[-1]
        appeal = self.event(
            "appeal.filed",
            "learner",
            "appealed",
            "2026-08-11T12:50:00Z",
            previous=finalized["payload_digest"],
            artifact=D_SUBMISSION,
            reason=D_REASON,
        )
        appeal_review = self.event(
            "appeal.review.started",
            "educator",
            "under-review",
            "2026-08-11T13:00:00Z",
            previous=appeal["payload_digest"],
            artifact=D_SUBMISSION,
        )
        correction = self.event(
            "correction.recorded",
            "educator",
            "corrected",
            "2026-08-11T13:10:00Z",
            previous=appeal_review["payload_digest"],
            artifact=D_SUBMISSION,
            feedback=D_CORRECTION,
        )
        refinalized = self.event(
            "review.finalized",
            "educator",
            "finalized",
            "2026-08-11T13:20:00Z",
            previous=correction["payload_digest"],
            artifact=D_SUBMISSION,
        )
        result = verify_workflow(events + [appeal, appeal_review, correction, refinalized])
        self.assertEqual(result["final_state"], "finalized")
        self.assertEqual(result["events"], 9)

    def test_previous_event_substitution_is_rejected(self):
        events = self.standard_sequence()
        events[2]["previous_event_digest"] = "0" * 64
        events[2] = finalize_event(events[2])
        with self.assertRaisesRegex(EducatorWorkflowError, "previous_event_digest"):
            verify_workflow(events)

    def test_review_must_bind_latest_submission_artifact(self):
        events = self.standard_sequence()
        events[2]["artifact_digest"] = "9" * 64
        events[2] = finalize_event(events[2])
        events[3]["previous_event_digest"] = events[2]["payload_digest"]
        events[3] = finalize_event(events[3])
        events[4]["previous_event_digest"] = events[3]["payload_digest"]
        events[4] = finalize_event(events[4])
        with self.assertRaisesRegex(EducatorWorkflowError, "latest submission"):
            verify_workflow(events)

    def test_raw_student_work_or_grade_fields_are_rejected(self):
        for field in ("raw_student_work", "grade", "credit_awarded"):
            with self.subTest(field=field):
                events = self.standard_sequence()
                events[1][field] = "forbidden"
                events[1]["payload_digest"] = finalize_event(events[1])["payload_digest"]
                with self.assertRaisesRegex(EducatorWorkflowError, "bounded schema exactly"):
                    verify_workflow(events)

    def test_actor_role_is_transition_bounded(self):
        events = self.standard_sequence()
        events[2]["actor_role"] = "learner"
        events[2] = finalize_event(events[2])
        events[3]["previous_event_digest"] = events[2]["payload_digest"]
        events[3] = finalize_event(events[3])
        events[4]["previous_event_digest"] = events[3]["payload_digest"]
        events[4] = finalize_event(events[4])
        with self.assertRaisesRegex(EducatorWorkflowError, "actor role"):
            verify_workflow(events)

    def test_projection_uses_existing_consent_bound_parent_action(self):
        event = self.standard_sequence()[1]
        projection = project_to_parent_event(
            event,
            consent_id="consent-test-1",
            memory_object_id="memory-object-test-1",
        )
        self.assertEqual(projection["action"], "education.learner.event.append")
        self.assertEqual(projection["input"]["purpose"], "learning-progress-recording")
        self.assertEqual(projection["input"]["contract_sha256"], EXPECTED_PARENT_SHA256)
        self.assertEqual(projection["input"]["payload_digest"], event["payload_digest"])
        self.assertEqual(projection["input"]["review_state"], "submitted")
        self.assertNotIn("artifact_digest", projection["input"])
        self.assertNotIn("feedback_digest", projection["input"])


if __name__ == "__main__":
    unittest.main()
