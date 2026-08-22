from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.ontario_elementary_c2_promotion import (
    CONFIRMATION_KEYS,
    ElementaryC2PromotionError,
    build_plan,
    verify_canonical_directory,
    verify_review,
    verify_review_directory,
)


TARGET = {
    "record_id": "ca-on-test-record-001",
    "source_id": "ontario-test-source",
    "candidate_path": "curriculum/ontario-elementary/c2-candidates/test.json",
    "content_digest": "1" * 64,
    "review_target_sha256": "2" * 64,
    "source_lock_sha256": "3" * 64,
    "source_bytes_sha256": "4" * 64,
    "source_byte_length": 1234,
    "content_mode": "reference-only",
    "current_source_review_decision": "approved",
    "current_licensing_decision": "reference-only-use-permitted",
    "eligible_for_human_normalization_review": True,
    "blocker": None,
}


def synthetic_plan():
    return {
        "schema": "axiom-education-ontario-elementary-c2-promotion-plan.v1",
        "jurisdiction_id": "ca-on",
        "candidate_count": 1,
        "eligible_for_human_normalization_review": 1,
        "canonical_c2_record_count": 0,
        "claim_boundary": "test",
        "targets": [dict(TARGET)],
    }


def review_payload(
    *,
    review_id="normalization-review-001",
    reviewed_at="2026-08-21T05:00:00Z",
    decision="approved",
):
    return {
        "schema": "axiom-education-curriculum-normalization-review-evidence.v1",
        "review_id": review_id,
        "jurisdiction_id": "ca-on",
        "source_id": TARGET["source_id"],
        "candidate": {
            "record_id": TARGET["record_id"],
            "content_digest": TARGET["content_digest"],
            "review_target_sha256": TARGET["review_target_sha256"],
        },
        "review_basis": {
            "source_bytes_sha256": TARGET["source_bytes_sha256"],
            "source_byte_length": TARGET["source_byte_length"],
            "source_lock_sha256": TARGET["source_lock_sha256"],
        },
        "reviewer": {
            "name": "Qualified Curriculum Reviewer",
            "qualification": "Ontario curriculum normalization reviewer",
            "organization": None,
        },
        "reviewed_at": reviewed_at,
        "decision": decision,
        "confirmations": {
            key: decision == "approved" for key in sorted(CONFIRMATION_KEYS)
        },
        "findings": [],
        "scope_limitations": [],
        "attestation_type": "human-curriculum-normalization-review",
    }


class OntarioElementaryC2PromotionTests(unittest.TestCase):
    def write_review(self, payload, directory=None, filename="review.json"):
        if directory is None:
            temp = tempfile.TemporaryDirectory()
            self.addCleanup(temp.cleanup)
            directory = Path(temp.name)
        path = directory / filename
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_current_repository_has_no_candidates_or_canonical_records(self):
        plan = build_plan()
        self.assertEqual(plan["candidate_count"], 0)
        self.assertEqual(plan["eligible_for_human_normalization_review"], 0)
        self.assertEqual(plan["canonical_c2_record_count"], 0)
        summary = verify_canonical_directory()
        self.assertEqual(summary["candidate_count"], 0)
        self.assertEqual(summary["submitted_normalization_reviews"], 0)
        self.assertEqual(summary["canonical_record_count"], 0)
        self.assertTrue(summary["canonical_records_all_currently_approved"])

    def test_plan_is_deterministic_while_empty(self):
        self.assertEqual(build_plan(), build_plan())

    def test_exact_approved_human_review_can_verify(self):
        review = verify_review(self.write_review(review_payload()), synthetic_plan())
        self.assertEqual(review["decision"], "approved")
        self.assertEqual(set(review["confirmations"]), CONFIRMATION_KEYS)

    def test_stale_candidate_target_is_rejected(self):
        payload = review_payload()
        payload["candidate"]["review_target_sha256"] = "9" * 64
        with self.assertRaisesRegex(ElementaryC2PromotionError, "not a current candidate revision"):
            verify_review(self.write_review(payload), synthetic_plan())

    def test_wrong_source_byte_digest_is_rejected(self):
        payload = review_payload()
        payload["review_basis"]["source_bytes_sha256"] = "9" * 64
        with self.assertRaisesRegex(ElementaryC2PromotionError, "source-byte digest mismatch"):
            verify_review(self.write_review(payload), synthetic_plan())

    def test_wrong_source_byte_length_is_rejected(self):
        payload = review_payload()
        payload["review_basis"]["source_byte_length"] += 1
        with self.assertRaisesRegex(ElementaryC2PromotionError, "source-byte length mismatch"):
            verify_review(self.write_review(payload), synthetic_plan())

    def test_blocked_candidate_cannot_receive_valid_review(self):
        plan = synthetic_plan()
        plan["targets"][0]["eligible_for_human_normalization_review"] = False
        plan["targets"][0]["blocker"] = "source approval required"
        with self.assertRaisesRegex(ElementaryC2PromotionError, "blocked by current intake evidence"):
            verify_review(self.write_review(review_payload()), plan)

    def test_approved_review_requires_all_confirmations(self):
        payload = review_payload()
        payload["confirmations"]["education_context_reviewed"] = False
        with self.assertRaisesRegex(ElementaryC2PromotionError, "every confirmation"):
            verify_review(self.write_review(payload), synthetic_plan())

    def test_approved_review_cannot_hide_open_finding(self):
        payload = review_payload()
        payload["findings"] = [
            {
                "id": "finding-1",
                "severity": "major",
                "description": "Grade scope does not match the official source.",
                "disposition": "open",
                "resolution_reference": None,
            }
        ]
        with self.assertRaisesRegex(ElementaryC2PromotionError, "open findings"):
            verify_review(self.write_review(payload), synthetic_plan())

    def test_changes_required_is_valid_negative_provenance(self):
        payload = review_payload(decision="changes-required")
        payload["findings"] = [
            {
                "id": "finding-1",
                "severity": "major",
                "description": "Hierarchy requires correction.",
                "disposition": "open",
                "resolution_reference": None,
            }
        ]
        review = verify_review(self.write_review(payload), synthetic_plan())
        self.assertEqual(review["decision"], "changes-required")

    def test_latest_review_controls_candidate_disposition(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            earlier = review_payload(
                review_id="review-earlier",
                reviewed_at="2026-08-21T05:00:00Z",
                decision="approved",
            )
            later = review_payload(
                review_id="review-later",
                reviewed_at="2026-08-21T06:00:00Z",
                decision="changes-required",
            )
            later["findings"] = [
                {
                    "id": "finding-later",
                    "severity": "major",
                    "description": "A later source comparison found a mismatch.",
                    "disposition": "open",
                    "resolution_reference": None,
                }
            ]
            self.write_review(earlier, directory, "01-earlier.json")
            self.write_review(later, directory, "02-later.json")
            summary = verify_review_directory(directory, synthetic_plan())
            self.assertEqual(summary["latest_approved_targets"], 0)
            self.assertEqual(
                summary["latest_nonapproved_record_ids"], [TARGET["record_id"]]
            )


if __name__ == "__main__":
    unittest.main()
