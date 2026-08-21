from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.mth1w_accessibility_review_evidence import (
    APPLICATION_CONFIRMATION_KEYS,
    APPLICATION_PLATFORMS,
    LESSON_CONFIRMATION_KEYS,
    build_plan,
)
from tools.mth1w_accessibility_review_templates import (
    EVIDENCE_SCHEMA,
    build,
    verify_determinism,
)


class Mth1wAccessibilityReviewTemplateTests(unittest.TestCase):
    def test_templates_cover_all_47_current_targets(self) -> None:
        plan = build_plan()
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            self.assertEqual(manifest["target_count"], 47)
            self.assertEqual(manifest["lesson_alternative_targets"], 43)
            self.assertEqual(manifest["application_surface_targets"], 4)
            self.assertEqual(manifest["application_platforms"], list(APPLICATION_PLATFORMS))
            self.assertEqual(
                {item["target_id"] for item in manifest["templates"]},
                {target["target_id"] for target in plan["targets"]},
            )

    def test_templates_are_not_real_accessibility_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            first = manifest["templates"][0]
            payload = json.loads((output / first["path"]).read_text(encoding="utf-8"))
            self.assertEqual(
                payload["schema"], "axiom-education-accessibility-review-template.v1"
            )
            self.assertNotEqual(payload["schema"], EVIDENCE_SCHEMA)
            self.assertTrue(payload["template_only"])
            human = payload["human_completion_required"]
            self.assertEqual(human["review_id"], "")
            self.assertEqual(human["decision"], "")
            self.assertEqual(human["tested_environments"], [])
            self.assertFalse(any(human["confirmations"].values()))

    def test_confirmation_templates_match_target_scope(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            by_scope = {}
            for record in manifest["templates"]:
                payload = json.loads(
                    (output / record["path"]).read_text(encoding="utf-8")
                )
                by_scope.setdefault(payload["review_scope"], payload)
            self.assertEqual(
                set(by_scope["lesson-alternative"]["human_completion_required"]["confirmations"]),
                LESSON_CONFIRMATION_KEYS,
            )
            self.assertEqual(
                set(by_scope["learner-application-surface"]["human_completion_required"]["confirmations"]),
                APPLICATION_CONFIRMATION_KEYS,
            )

    def test_application_templates_preserve_platform_identity(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            platforms = set()
            for record in manifest["templates"]:
                if record["review_scope"] != "learner-application-surface":
                    continue
                payload = json.loads(
                    (output / record["path"]).read_text(encoding="utf-8")
                )
                platforms.add(payload["target"]["platform"])
            self.assertEqual(platforms, set(APPLICATION_PLATFORMS))

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
                "machine-generated-templates-no-human-accessibility-evidence",
            )
            self.assertIn("cannot establish", manifest["claim_boundary"])

    def test_template_package_is_byte_deterministic(self) -> None:
        manifest = verify_determinism()
        self.assertEqual(manifest["target_count"], 47)


if __name__ == "__main__":
    unittest.main()
