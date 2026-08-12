from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.mth1w_assessment_review_evidence import (
    AssessmentReviewError,
    CONFIRMATION_KEYS,
    build_plan,
    verify_directory,
    verify_readiness_boundary,
    verify_review,
)


class Mth1wAssessmentReviewEvidenceTests(unittest.TestCase):
    def target(self, index: int = 0):
        return build_plan()["targets"][index]

    def review_payload(
        self,
        target,
        *,
        review_id="assessment-review-test-001",
        reviewed_at="2026-08-11T22:00:00Z",
        decision="approved",
    ):
        return {
            "schema": "axiom-education-assessment-review-evidence.v1",
            "review_id": review_id,
            "course_code": "MTH1W",
            "assessment_scope": target["assessment_scope"],
            "target": {
                "target_id": target["target_id"],
                "unit_id": target["unit_id"],
                "target_sha256": target["target_sha256"],
            },
            "reviewer": {
                "name": "Qualified Assessment Reviewer",
                "qualification": "Ontario mathematics educator / assessment reviewer",
                "organization": None,
            },
            "reviewed_at": reviewed_at,
            "decision": decision,
            "confirmations": {key: decision == "approved" for key in CONFIRMATION_KEYS},
            "findings": [],
            "scope_limitations": [],
            "attestation_type": "human-assessment-review",
        }

    def write_review(self, payload, directory: Path | None = None, filename="review.json"):
        if directory is None:
            temp = tempfile.TemporaryDirectory()
            self.addCleanup(temp.cleanup)
            directory = Path(temp.name)
        path = directory / filename
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_plan_has_nine_unit_targets_and_one_coursewide_target(self) -> None:
        plan = build_plan()
        self.assertEqual(plan["target_count"], 10)
        unit_targets = [
            target
            for target in plan["targets"]
            if target["assessment_scope"] == "unit-assessment-surface"
        ]
        coursewide = [
            target
            for target in plan["targets"]
            if target["assessment_scope"] == "coursewide-assessment-plan"
        ]
        self.assertEqual(len(unit_targets), 9)
        self.assertEqual(len(coursewide), 1)
        self.assertTrue(all(len(target["target_sha256"]) == 64 for target in plan["targets"]))

    def test_current_directory_has_no_implicit_human_approval(self) -> None:
        summary = verify_directory()
        self.assertEqual(summary["targets"], 10)
        self.assertEqual(summary["reviews"], 0)
        self.assertEqual(summary["latest_approved_targets"], 0)
        self.assertFalse(summary["all_current_targets_approved"])
        self.assertEqual(len(summary["unreviewed_target_ids"]), 10)

    def test_content_addressed_approved_review_can_verify(self) -> None:
        target = self.target()
        review = verify_review(self.write_review(self.review_payload(target)))
        self.assertEqual(review["decision"], "approved")
        self.assertTrue(all(review["confirmations"].values()))

    def test_stale_target_digest_is_rejected(self) -> None:
        target = self.target()
        payload = self.review_payload(target)
        payload["target"]["target_sha256"] = "0" * 64
        with self.assertRaisesRegex(AssessmentReviewError, "target content changed"):
            verify_review(self.write_review(payload))

    def test_approved_review_requires_every_confirmation(self) -> None:
        target = self.target()
        payload = self.review_payload(target)
        payload["confirmations"]["scoring_rubric_reviewed"] = False
        with self.assertRaisesRegex(AssessmentReviewError, "every confirmation"):
            verify_review(self.write_review(payload))

    def test_approved_review_cannot_hide_open_finding(self) -> None:
        target = self.target()
        payload = self.review_payload(target)
        payload["findings"] = [
            {
                "id": "assessment-finding-1",
                "severity": "major",
                "description": "Scoring guidance is incomplete.",
                "disposition": "open",
                "resolution_reference": None,
            }
        ]
        with self.assertRaisesRegex(AssessmentReviewError, "open findings"):
            verify_review(self.write_review(payload))

    def test_changes_required_is_valid_negative_provenance(self) -> None:
        target = self.target()
        payload = self.review_payload(target, decision="changes-required")
        payload["findings"] = [
            {
                "id": "assessment-finding-1",
                "severity": "major",
                "description": "Revise rubric before approval.",
                "disposition": "open",
                "resolution_reference": None,
            }
        ]
        review = verify_review(self.write_review(payload))
        self.assertEqual(review["decision"], "changes-required")

    def test_latest_review_controls_current_target_disposition(self) -> None:
        target = self.target()
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            earlier = self.review_payload(
                target,
                review_id="review-earlier",
                reviewed_at="2026-08-11T20:00:00Z",
                decision="changes-required",
            )
            earlier["findings"] = [
                {
                    "id": "finding-earlier",
                    "severity": "major",
                    "description": "Needs revision.",
                    "disposition": "open",
                    "resolution_reference": None,
                }
            ]
            later = self.review_payload(
                target,
                review_id="review-later",
                reviewed_at="2026-08-11T21:00:00Z",
                decision="approved",
            )
            self.write_review(earlier, directory, "01-earlier.json")
            self.write_review(later, directory, "02-later.json")
            summary = verify_directory(directory)
            self.assertEqual(summary["latest_approved_targets"], 1)
            self.assertNotIn(target["target_id"], summary["latest_nonapproved_target_ids"])

    def test_later_changes_required_blocks_earlier_approval(self) -> None:
        target = self.target()
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            earlier = self.review_payload(
                target,
                review_id="review-earlier",
                reviewed_at="2026-08-11T20:00:00Z",
                decision="approved",
            )
            later = self.review_payload(
                target,
                review_id="review-later",
                reviewed_at="2026-08-11T21:00:00Z",
                decision="changes-required",
            )
            later["findings"] = [
                {
                    "id": "finding-later",
                    "severity": "minor",
                    "description": "A later review found a required correction.",
                    "disposition": "open",
                    "resolution_reference": None,
                }
            ]
            self.write_review(earlier, directory, "01-earlier.json")
            self.write_review(later, directory, "02-later.json")
            summary = verify_directory(directory)
            self.assertEqual(summary["latest_approved_targets"], 0)
            self.assertIn(target["target_id"], summary["latest_nonapproved_target_ids"])

    def test_current_readiness_gate_remains_blocked_without_reviews(self) -> None:
        summary = verify_readiness_boundary()
        self.assertFalse(summary["all_current_targets_approved"])


if __name__ == "__main__":
    unittest.main()
