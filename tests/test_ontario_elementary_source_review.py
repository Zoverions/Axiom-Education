from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.ontario_elementary_source_review import (
    ElementarySourceReviewError,
    REQUIRED_CONFIRMATIONS,
    build_plan,
    plan_index,
    verify_directory,
    verify_review,
)


class OntarioElementarySourceReviewTests(unittest.TestCase):
    def review_payload(
        self,
        *,
        source_id: str = "ontario-fr-francais-grades-1-8-2023",
        decision: str = "approved",
    ) -> dict[str, object]:
        plan = build_plan()
        target = plan_index(plan)[source_id]
        return {
            "schema": "axiom-education-ontario-elementary-source-review.v1",
            "review_id": f"review:{source_id}",
            "review_type": "source-identity-and-scope",
            "source_id": source_id,
            "target_sha256": target["target_sha256"],
            "reviewer": {
                "name": "Qualified Reviewer",
                "qualification": "Ontario curriculum source reviewer test fixture",
            },
            "reviewed_at": "2026-08-20T18:00:00-04:00",
            "decision": decision,
            "confirmations": {key: decision == "approved" for key in REQUIRED_CONFIRMATIONS},
            "findings": [],
            "scope_limitations": [
                "Source identity and scope only; no licensing or curriculum-content approval."
            ],
            "attestation_type": "human-review",
        }

    def write_review(self, directory: Path, payload: dict[str, object]) -> Path:
        path = directory / "review.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_plan_has_sixteen_content_addressed_sources(self) -> None:
        plan = build_plan()
        self.assertEqual(plan["target_count"], 16)
        targets = plan_index(plan)
        self.assertEqual(len(targets), 16)
        self.assertIn("ontario-kindergarten-2026", targets)
        self.assertIn("ontario-fr-francais-grades-1-8-2023", targets)
        self.assertIn("ontario-fr-english-grades-4-8-2006", targets)
        self.assertIn("ontario-fr-english-beginners-grades-4-8-2013", targets)
        for target in targets.values():
            self.assertEqual(len(target["target_sha256"]), 64)
            self.assertEqual(len(target["source_entry_sha256"]), 64)
            self.assertEqual(len(target["source_lock_sha256"]), 64)
            self.assertEqual(len(target["upstream_document_sha256"]), 64)
            self.assertEqual(target["redistribution_status"], "review-required")

    def test_empty_review_directory_is_truthfully_incomplete(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            summary = verify_directory(Path(tmp))
        self.assertEqual(summary["targets"], 16)
        self.assertEqual(summary["reviews"], 0)
        self.assertEqual(summary["approved_sources"], 0)
        self.assertEqual(summary["blocked_sources"], 0)
        self.assertEqual(summary["unreviewed_sources"], 16)
        self.assertFalse(summary["human_source_review_complete"])

    def test_approved_review_requires_exact_current_target(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            path = self.write_review(directory, self.review_payload())
            review = verify_review(path)
            self.assertEqual(review["decision"], "approved")
            summary = verify_directory(directory)
            self.assertEqual(summary["approved_sources"], 1)
            self.assertEqual(summary["unreviewed_sources"], 15)
            self.assertFalse(summary["human_source_review_complete"])

    def test_stale_target_digest_is_rejected(self) -> None:
        payload = self.review_payload()
        payload["target_sha256"] = "0" * 64
        with tempfile.TemporaryDirectory() as tmp:
            path = self.write_review(Path(tmp), payload)
            with self.assertRaisesRegex(ElementarySourceReviewError, "stale"):
                verify_review(path)

    def test_approved_review_requires_every_confirmation(self) -> None:
        payload = self.review_payload()
        confirmations = payload["confirmations"]
        assert isinstance(confirmations, dict)
        confirmations["grade_scope_confirmed"] = False
        with tempfile.TemporaryDirectory() as tmp:
            path = self.write_review(Path(tmp), payload)
            with self.assertRaisesRegex(ElementarySourceReviewError, "every confirmation"):
                verify_review(path)

    def test_approved_review_cannot_leave_open_findings(self) -> None:
        payload = self.review_payload()
        payload["findings"] = [
            {
                "id": "finding-1",
                "severity": "minor",
                "description": "Needs follow-up.",
                "disposition": "open",
            }
        ]
        with tempfile.TemporaryDirectory() as tmp:
            path = self.write_review(Path(tmp), payload)
            with self.assertRaisesRegex(ElementarySourceReviewError, "cannot contain open findings"):
                verify_review(path)

    def test_changes_required_is_valid_without_false_approval(self) -> None:
        payload = self.review_payload(decision="changes-required")
        payload["findings"] = [
            {
                "id": "finding-1",
                "severity": "major",
                "description": "Policy version needs source reconciliation.",
                "disposition": "open",
            }
        ]
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            path = self.write_review(directory, payload)
            review = verify_review(path)
            self.assertEqual(review["decision"], "changes-required")
            summary = verify_directory(directory)
            self.assertEqual(summary["approved_sources"], 0)
            self.assertEqual(summary["blocked_sources"], 1)
            self.assertFalse(summary["human_source_review_complete"])

    def test_non_human_attestation_is_rejected(self) -> None:
        payload = self.review_payload()
        payload["attestation_type"] = "machine-review"
        with tempfile.TemporaryDirectory() as tmp:
            path = self.write_review(Path(tmp), payload)
            with self.assertRaisesRegex(ElementarySourceReviewError, "explicit human attestation"):
                verify_review(path)


if __name__ == "__main__":
    unittest.main()
