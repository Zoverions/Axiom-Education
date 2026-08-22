from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.mth1w_reviewer_dossier import (
    EXPECTED_ACCESSIBILITY_TARGETS,
    EXPECTED_LESSONS,
    build,
    verify_determinism,
)


class Mth1wReviewerDossierTests(unittest.TestCase):
    def test_dossier_packages_all_current_review_inputs_without_approval(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "dossier"
            manifest = build(output)
            self.assertEqual(manifest["status"], "machine-generated-review-inputs-no-approval")
            self.assertEqual(manifest["lesson_target_count"], EXPECTED_LESSONS)
            self.assertEqual(
                manifest["accessibility_target_count"], EXPECTED_ACCESSIBILITY_TARGETS
            )
            self.assertEqual(
                manifest["accessibility_application_platforms"],
                ["android", "windows", "macos", "ios"],
            )
            self.assertEqual(manifest["accessible_lesson_count"], EXPECTED_LESSONS)
            self.assertGreater(manifest["source_use_count"], 0)
            self.assertTrue((output / "REVIEW-GUIDE.md").is_file())
            self.assertTrue((output / "lesson-review-plan.json").is_file())
            self.assertTrue((output / "accessibility-review-plan.json").is_file())
            self.assertTrue((output / "source-use-inventory.json").is_file())
            self.assertTrue((output / "assessment-plan.json").is_file())
            self.assertTrue((output / "current-readiness.json").is_file())
            self.assertTrue((output / "accessible-offline" / "manifest.json").is_file())
            self.assertTrue(
                (output / "accessibility-review-templates" / "manifest.json").is_file()
            )

    def test_dossier_manifest_covers_every_generated_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "dossier"
            manifest = build(output)
            listed = {entry["path"] for entry in manifest["files"]}
            actual = {
                path.relative_to(output).as_posix()
                for path in output.rglob("*")
                if path.is_file() and path.relative_to(output).as_posix() != "manifest.json"
            }
            self.assertEqual(listed, actual)
            self.assertIn("accessible-offline/manifest.json", listed)
            self.assertIn("accessibility-review-templates/manifest.json", listed)
            self.assertIn("accessibility-review-plan.json", listed)
            self.assertTrue(all(len(entry["sha256"]) == 64 for entry in manifest["files"]))

    def test_learner_exports_remain_separate_from_answer_keys(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "dossier"
            build(output)
            accessible = json.loads(
                (output / "accessible-offline" / "manifest.json").read_text(encoding="utf-8")
            )
            self.assertTrue(accessible["student_answers_separated"])
            self.assertEqual(accessible["lesson_count"], EXPECTED_LESSONS)
            for record in accessible["records"]:
                self.assertNotEqual(record["student_path"], record["answer_key_path"])

    def test_accessibility_templates_are_nonvalid_human_inputs(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "dossier"
            build(output)
            template_manifest = json.loads(
                (
                    output
                    / "accessibility-review-templates"
                    / "manifest.json"
                ).read_text(encoding="utf-8")
            )
            self.assertEqual(template_manifest["target_count"], 47)
            self.assertEqual(
                template_manifest["status"],
                "machine-generated-templates-no-human-accessibility-evidence",
            )
            first = template_manifest["templates"][0]
            first_payload = json.loads(
                (
                    output
                    / "accessibility-review-templates"
                    / first["path"]
                ).read_text(encoding="utf-8")
            )
            self.assertTrue(first_payload["template_only"])
            self.assertEqual(
                first_payload["human_completion_required"]["decision"], ""
            )
            self.assertFalse(
                any(
                    first_payload["human_completion_required"][
                        "confirmations"
                    ].values()
                )
            )

    def test_current_zero_or_partial_review_state_is_not_inflated(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "dossier"
            manifest = build(output)
            summary = json.loads(
                (output / "submitted-review-summary.json").read_text(encoding="utf-8")
            )
            self.assertEqual(
                manifest["submitted_lesson_review_count"],
                summary["lesson_reviews"]["reviews"],
            )
            self.assertEqual(
                manifest["submitted_accessibility_review_count"],
                summary["accessibility_reviews"]["reviews"],
            )
            self.assertEqual(
                manifest["submitted_licence_review_count"],
                summary["source_licensing_reviews"]["reviews"],
            )
            self.assertIn("not implied approval", summary["claim_boundary"])

    def test_dossier_is_byte_deterministic(self):
        manifest = verify_determinism()
        self.assertEqual(manifest["lesson_target_count"], EXPECTED_LESSONS)
        self.assertEqual(
            manifest["accessibility_target_count"], EXPECTED_ACCESSIBILITY_TARGETS
        )
        self.assertEqual(manifest["status"], "machine-generated-review-inputs-no-approval")


if __name__ == "__main__":
    unittest.main()
