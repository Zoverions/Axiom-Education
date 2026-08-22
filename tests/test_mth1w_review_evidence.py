from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.mth1w_review_evidence import (
    ReviewEvidenceError,
    build_plan,
    review_satisfies_target,
    verify_review,
)


class Mth1wReviewEvidenceTests(unittest.TestCase):
    def target(self):
        return build_plan()["targets"][0]

    def review_payload(self, *, decision="approved"):
        target = self.target()
        return {
            "schema": "axiom-education-content-review-evidence.v1",
            "review_id": "review-test-001",
            "course_code": "MTH1W",
            "review_type": "educator-instructional",
            "target": {
                "kind": "lesson",
                "unit_id": target["unit_id"],
                "lesson_id": target["lesson_id"],
                "target_sha256": target["target_sha256"],
            },
            "reviewer": {
                "name": "Qualified Reviewer",
                "qualification": "Ontario-qualified mathematics educator",
                "organization": None,
                "jurisdiction": "Ontario, Canada",
            },
            "reviewed_at": "2026-08-11T20:00:00Z",
            "decision": decision,
            "confirmations": {
                "expectation_binding_confirmed": decision == "approved",
                "content_correctness_confirmed": decision == "approved",
                "pedagogical_suitability_confirmed": decision == "approved",
                "age_appropriateness_confirmed": decision == "approved",
            },
            "findings": [],
            "scope_limitations": [],
            "attestation_type": "human-review",
        }

    def write_review(self, payload):
        directory = tempfile.TemporaryDirectory()
        path = Path(directory.name) / "review.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        self.addCleanup(directory.cleanup)
        return path

    def test_plan_binds_all_43_lessons(self):
        first = build_plan()
        second = build_plan()
        self.assertEqual(first, second)
        self.assertEqual(first["target_count"], 43)
        ids = [target["lesson_id"] for target in first["targets"]]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertTrue(
            all("educator-instructional" in target["required_review_types"] for target in first["targets"])
        )
        self.assertTrue(
            all("accessibility" in target["required_review_types"] for target in first["targets"])
        )

    def test_approved_educator_review_verifies_for_exact_content(self):
        review = verify_review(self.write_review(self.review_payload()))
        self.assertTrue(review_satisfies_target(review))

    def test_stale_lesson_digest_is_rejected(self):
        payload = self.review_payload()
        payload["target"]["target_sha256"] = "0" * 64
        with self.assertRaisesRegex(ReviewEvidenceError, "review is stale"):
            verify_review(self.write_review(payload))

    def test_approved_review_cannot_leave_open_findings(self):
        payload = self.review_payload()
        payload["findings"] = [
            {
                "id": "finding-1",
                "severity": "major",
                "category": "mathematical-correctness",
                "description": "Worked example needs correction.",
                "disposition": "open",
                "resolution_reference": None,
            }
        ]
        with self.assertRaisesRegex(ReviewEvidenceError, "open findings"):
            verify_review(self.write_review(payload))

    def test_major_finding_requires_resolution_before_approval(self):
        payload = self.review_payload()
        payload["findings"] = [
            {
                "id": "finding-1",
                "severity": "major",
                "category": "pedagogy",
                "description": "Sequence needs revision.",
                "disposition": "accepted-with-rationale",
                "resolution_reference": "review-note-1",
            }
        ]
        with self.assertRaisesRegex(ReviewEvidenceError, "major/critical findings"):
            verify_review(self.write_review(payload))

    def test_changes_required_is_preserved_as_valid_negative_evidence(self):
        payload = self.review_payload(decision="changes-required")
        payload["findings"] = [
            {
                "id": "finding-1",
                "severity": "minor",
                "category": "clarity",
                "description": "Clarify one instruction before approval.",
                "disposition": "open",
                "resolution_reference": None,
            }
        ]
        review = verify_review(self.write_review(payload))
        self.assertFalse(review_satisfies_target(review))

    def test_reviewer_qualification_is_required(self):
        payload = self.review_payload()
        payload["reviewer"]["qualification"] = ""
        with self.assertRaisesRegex(ReviewEvidenceError, "qualification"):
            verify_review(self.write_review(payload))

    def test_unrequired_review_type_cannot_be_used_to_promote_lesson(self):
        payload = self.review_payload()
        payload["review_type"] = "assessment-validity"
        with self.assertRaisesRegex(ReviewEvidenceError, "not a required lesson review"):
            verify_review(self.write_review(payload))


if __name__ == "__main__":
    unittest.main()
