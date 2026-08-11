from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.mth1w_source_use_inventory import (
    SourceUseError,
    build_inventory,
    verify_review,
    verify_reviews,
)


class Mth1wSourceUseInventoryTests(unittest.TestCase):
    def current_source(self):
        inventory = build_inventory()
        return inventory, inventory["sources"][0]

    def review_payload(self, *, decision="permitted-as-used"):
        _inventory, source = self.current_source()
        return {
            "schema": "axiom-education-source-licence-review.v1",
            "review_id": "licence-review-test-001",
            "course_code": "MTH1W",
            "source_url": source["url"],
            "source_use_sha256": source["source_use_sha256"],
            "reviewer": {
                "name": "Qualified Reviewer",
                "qualification": "copyright/licensing reviewer",
                "organization": None,
            },
            "reviewed_at": "2026-08-11T21:30:00Z",
            "decision": decision,
            "redistribution_allowed_as_used": decision == "permitted-as-used",
            "evidence_locators": ["https://example.org/licence-evidence"] if decision == "permitted-as-used" else [],
            "findings": [],
            "scope_limitations": [],
            "attestation_type": "human-licensing-review",
        }

    def write_review(self, payload):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "review.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_inventory_covers_all_nine_authored_units_and_declared_sources(self):
        inventory = build_inventory()
        self.assertEqual(inventory["course_code"], "MTH1W")
        self.assertEqual(inventory["unit_count"], 9)
        self.assertGreater(inventory["source_count"], 0)
        self.assertEqual(len(inventory["sources"]), inventory["source_count"])
        urls = {source["url"] for source in inventory["sources"]}
        self.assertIn("https://mathshistory.st-andrews.ac.uk/HistTopics/Zero/", urls)
        self.assertIn("https://www.bankofcanada.ca/rates/related/inflation-calculator/", urls)
        self.assertIn("https://www.canada.ca/en/financial-consumer-agency/services/make-budget.html", urls)
        self.assertTrue(all(source["human_licensing_review_status"] == "required" for source in inventory["sources"]))

    def test_inventory_is_deterministic(self):
        self.assertEqual(build_inventory(), build_inventory())

    def test_current_review_directory_is_machine_verifiable(self):
        summary = verify_reviews()
        self.assertEqual(summary["sources"], build_inventory()["source_count"])
        self.assertGreaterEqual(summary["reviews"], 0)
        self.assertGreaterEqual(summary["unreviewed"], 0)

    def test_content_addressed_permitted_review_can_verify(self):
        review = verify_review(self.write_review(self.review_payload()))
        self.assertEqual(review["decision"], "permitted-as-used")
        self.assertTrue(review["redistribution_allowed_as_used"])

    def test_stale_source_use_digest_is_rejected(self):
        payload = self.review_payload()
        payload["source_use_sha256"] = "0" * 64
        with self.assertRaisesRegex(SourceUseError, "source use changed"):
            verify_review(self.write_review(payload))

    def test_permitted_review_requires_evidence_locator(self):
        payload = self.review_payload()
        payload["evidence_locators"] = []
        with self.assertRaisesRegex(SourceUseError, "requires evidence locators"):
            verify_review(self.write_review(payload))

    def test_non_permitted_decision_cannot_claim_redistribution_allowed(self):
        payload = self.review_payload(decision="permission-required")
        payload["redistribution_allowed_as_used"] = True
        with self.assertRaisesRegex(SourceUseError, "cannot claim redistribution allowed"):
            verify_review(self.write_review(payload))

    def test_permitted_review_cannot_hide_open_findings(self):
        payload = self.review_payload()
        payload["findings"] = [
            {
                "id": "finding-1",
                "severity": "major",
                "description": "Terms require clarification.",
                "disposition": "open",
                "resolution_reference": None,
            }
        ]
        with self.assertRaisesRegex(SourceUseError, "open findings"):
            verify_review(self.write_review(payload))

    def test_reviewer_qualification_is_required(self):
        payload = self.review_payload()
        payload["reviewer"]["qualification"] = ""
        with self.assertRaisesRegex(SourceUseError, "qualification"):
            verify_review(self.write_review(payload))


if __name__ == "__main__":
    unittest.main()
