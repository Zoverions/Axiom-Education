from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.mth1w_review_evidence import build_plan
from tools.mth1w_review_templates import (
    LESSON_EVIDENCE_SCHEMA,
    LICENCE_EVIDENCE_SCHEMA,
    build,
    review_types,
    target_digest,
    verify_determinism,
)
from tools.mth1w_source_use_inventory import build_inventory


class Mth1wReviewTemplateTests(unittest.TestCase):
    def test_templates_cover_every_current_required_review_type(self) -> None:
        plan = build_plan()
        expected = sum(review_types(target) for target in []) if False else sum(
            len(review_types(target)) for target in plan["targets"]
        )
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            self.assertEqual(manifest["lesson_target_count"], 43)
            self.assertEqual(manifest["lesson_review_template_count"], expected)
            self.assertEqual(
                manifest["source_licensing_template_count"],
                build_inventory()["source_count"],
            )

    def test_lesson_templates_are_deliberately_not_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            first = manifest["lesson_templates"][0]
            payload = json.loads(
                (output / "lesson-reviews" / first["path"]).read_text(encoding="utf-8")
            )
            self.assertEqual(payload["schema"], "axiom-education-content-review-template.v1")
            self.assertNotEqual(payload["schema"], LESSON_EVIDENCE_SCHEMA)
            self.assertTrue(payload["template_only"])
            self.assertEqual(payload["human_completion_required"]["reviewer_name"], "")
            self.assertEqual(payload["human_completion_required"]["decision"], "")

    def test_source_templates_are_deliberately_not_licensing_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            first = manifest["source_licensing_templates"][0]
            payload = json.loads(
                (output / "source-licensing" / first["path"]).read_text(encoding="utf-8")
            )
            self.assertEqual(
                payload["schema"],
                "axiom-education-source-licence-review-template.v1",
            )
            self.assertNotEqual(payload["schema"], LICENCE_EVIDENCE_SCHEMA)
            self.assertTrue(payload["template_only"])
            self.assertFalse(
                payload["human_completion_required"]["redistribution_allowed_as_used"]
            )

    def test_prefilled_lesson_digests_match_current_review_plan(self) -> None:
        plan = build_plan()
        expected = {
            (target["lesson_id"], review_type): target_digest(target)
            for target in plan["targets"]
            for review_type in review_types(target)
        }
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            actual = {
                (item["lesson_id"], item["review_type"]): item["target_sha256"]
                for item in manifest["lesson_templates"]
            }
            self.assertEqual(actual, expected)

    def test_prefilled_source_use_digests_match_current_inventory(self) -> None:
        inventory = build_inventory()
        expected = {
            source["url"]: source["source_use_sha256"]
            for source in inventory["sources"]
        }
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            actual = {
                item["source_url"]: item["source_use_sha256"]
                for item in manifest["source_licensing_templates"]
            }
            self.assertEqual(actual, expected)

    def test_template_package_is_byte_deterministic(self) -> None:
        manifest = verify_determinism()
        self.assertEqual(manifest["lesson_target_count"], 43)
        self.assertEqual(
            manifest["status"], "machine-generated-templates-no-human-evidence"
        )


if __name__ == "__main__":
    unittest.main()
