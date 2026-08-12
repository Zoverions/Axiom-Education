from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.mth1w_assessment_review_evidence import build_plan
from tools.mth1w_assessment_review_templates import (
    EVIDENCE_SCHEMA,
    build,
    verify_determinism,
)


class Mth1wAssessmentReviewTemplateTests(unittest.TestCase):
    def test_templates_cover_all_ten_current_assessment_targets(self) -> None:
        plan = build_plan()
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            self.assertEqual(manifest["target_count"], 10)
            self.assertEqual(
                {item["target_id"] for item in manifest["templates"]},
                {target["target_id"] for target in plan["targets"]},
            )

    def test_templates_are_not_real_assessment_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            first = manifest["templates"][0]
            payload = json.loads((output / first["path"]).read_text(encoding="utf-8"))
            self.assertEqual(
                payload["schema"], "axiom-education-assessment-review-template.v1"
            )
            self.assertNotEqual(payload["schema"], EVIDENCE_SCHEMA)
            self.assertTrue(payload["template_only"])
            self.assertEqual(payload["human_completion_required"]["review_id"], "")
            self.assertEqual(payload["human_completion_required"]["decision"], "")
            self.assertFalse(
                any(payload["human_completion_required"]["confirmations"].values())
            )

    def test_prefilled_digests_match_current_review_plan(self) -> None:
        expected = {
            target["target_id"]: target["target_sha256"]
            for target in build_plan()["targets"]
        }
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            actual = {
                item["target_id"]: item["target_sha256"]
                for item in manifest["templates"]
            }
            self.assertEqual(actual, expected)

    def test_template_package_preserves_nonclaim_status(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            self.assertEqual(
                manifest["status"],
                "machine-generated-templates-no-human-assessment-evidence",
            )
            self.assertIn("cannot establish", manifest["claim_boundary"])

    def test_template_package_is_byte_deterministic(self) -> None:
        manifest = verify_determinism()
        self.assertEqual(manifest["target_count"], 10)


if __name__ == "__main__":
    unittest.main()
