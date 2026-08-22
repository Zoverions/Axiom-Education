from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.ontario_elementary_licensing_review import (
    ElementaryLicensingReviewError,
    REQUIRED_CONFIRMATIONS,
    build_plan,
    plan_index,
    verify_directory,
    verify_review,
)


class OntarioElementaryLicensingReviewTests(unittest.TestCase):
    def review_payload(
        self,
        *,
        source_id: str = "ontario-fr-francais-grades-1-8-2023",
        decision: str = "reference-only-use-permitted",
    ) -> dict[str, object]:
        target = plan_index(build_plan())[source_id]
        resolved = decision != "unresolved"
        return {
            "schema": "axiom-education-ontario-elementary-licensing-review.v1",
            "review_id": f"licensing:{source_id}",
            "review_type": "licensing-and-redistribution",
            "source_id": source_id,
            "target_sha256": target["target_sha256"],
            "reviewer": {
                "name": "Qualified Licensing Reviewer",
                "qualification": "Licensing review test fixture",
            },
            "reviewed_at": "2026-08-20T18:30:00-04:00",
            "decision": decision,
            "confirmations": {key: resolved for key in REQUIRED_CONFIRMATIONS},
            "basis": {
                "summary": "Test-only licensing basis.",
                "evidence_locators": ["https://www.ontario.ca/page/copyright-information-c-queens-printer-ontario"] if resolved else [],
            },
            "conditions": [],
            "findings": [],
            "attestation_type": "human-review",
        }

    def write_review(self, directory: Path, name: str, payload: dict[str, object]) -> Path:
        path = directory / name
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_plan_has_sixteen_content_addressed_targets(self) -> None:
        plan = build_plan()
        self.assertEqual(plan["target_count"], 16)
        for target in plan_index(plan).values():
            self.assertEqual(len(target["target_sha256"]), 64)
            self.assertEqual(len(target["source_review_target_sha256"]), 64)
            self.assertEqual(len(target["source_lock_sha256"]), 64)
            self.assertEqual(len(target["upstream_document_sha256"]), 64)
            self.assertEqual(target["current_redistribution_status"], "review-required")

    def test_empty_directory_is_zero_of_sixteen_and_incomplete(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            summary = verify_directory(Path(tmp))
        self.assertEqual(summary["targets"], 16)
        self.assertEqual(summary["reviews"], 0)
        self.assertEqual(summary["resolved_sources"], 0)
        self.assertEqual(summary["unresolved_sources"], 16)
        self.assertEqual(summary["verbatim_redistribution_permitted"], 0)
        self.assertFalse(summary["licensing_review_complete"])

    def test_reference_only_decision_is_resolved_but_not_verbatim_permission(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            path = self.write_review(directory, "review.json", self.review_payload())
            review = verify_review(path)
            self.assertEqual(review["decision"], "reference-only-use-permitted")
            summary = verify_directory(directory)
            self.assertEqual(summary["resolved_sources"], 1)
            self.assertEqual(summary["reference_only_use_permitted"], 1)
            self.assertEqual(summary["verbatim_redistribution_permitted"], 0)
            self.assertFalse(summary["licensing_review_complete"])

    def test_verbatim_permission_requires_evidence_locator(self) -> None:
        payload = self.review_payload(decision="verbatim-redistribution-permitted")
        basis = payload["basis"]
        assert isinstance(basis, dict)
        basis["evidence_locators"] = []
        with tempfile.TemporaryDirectory() as tmp:
            path = self.write_review(Path(tmp), "review.json", payload)
            with self.assertRaisesRegex(ElementaryLicensingReviewError, "evidence locator"):
                verify_review(path)

    def test_resolved_decision_requires_every_confirmation(self) -> None:
        payload = self.review_payload()
        confirmations = payload["confirmations"]
        assert isinstance(confirmations, dict)
        confirmations["redistribution_scope_decided"] = False
        with tempfile.TemporaryDirectory() as tmp:
            path = self.write_review(Path(tmp), "review.json", payload)
            with self.assertRaisesRegex(ElementaryLicensingReviewError, "every confirmation"):
                verify_review(path)

    def test_stale_target_is_rejected(self) -> None:
        payload = self.review_payload()
        payload["target_sha256"] = "0" * 64
        with tempfile.TemporaryDirectory() as tmp:
            path = self.write_review(Path(tmp), "review.json", payload)
            with self.assertRaisesRegex(ElementaryLicensingReviewError, "stale"):
                verify_review(path)

    def test_non_human_attestation_is_rejected(self) -> None:
        payload = self.review_payload()
        payload["attestation_type"] = "machine-review"
        with tempfile.TemporaryDirectory() as tmp:
            path = self.write_review(Path(tmp), "review.json", payload)
            with self.assertRaisesRegex(ElementaryLicensingReviewError, "explicit human attestation"):
                verify_review(path)

    def test_duplicate_current_attestations_for_one_source_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            first = self.review_payload()
            second = self.review_payload()
            second["review_id"] = "licensing:duplicate"
            self.write_review(directory, "a.json", first)
            self.write_review(directory, "b.json", second)
            with self.assertRaisesRegex(ElementaryLicensingReviewError, "multiple current licensing attestations"):
                verify_directory(directory)


if __name__ == "__main__":
    unittest.main()
