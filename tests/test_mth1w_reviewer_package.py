from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.mth1w_reviewer_package import build, verify_determinism


class Mth1wReviewerPackageTests(unittest.TestCase):
    def test_package_combines_dossier_and_non_evidence_templates(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "package"
            manifest = build(output)
            self.assertEqual(
                manifest["status"],
                "machine-generated-review-package-no-human-evidence",
            )
            self.assertEqual(manifest["lesson_target_count"], 43)
            self.assertGreater(manifest["lesson_review_template_count"], 0)
            self.assertGreater(manifest["source_licensing_template_count"], 0)
            self.assertTrue((output / "dossier" / "manifest.json").is_file())
            self.assertTrue((output / "templates" / "manifest.json").is_file())
            self.assertTrue((output / "README.md").is_file())

    def test_nested_component_statuses_cannot_imply_human_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "package"
            build(output)
            dossier = json.loads(
                (output / "dossier" / "manifest.json").read_text(encoding="utf-8")
            )
            templates = json.loads(
                (output / "templates" / "manifest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(
                dossier["status"], "machine-generated-review-inputs-no-approval"
            )
            self.assertEqual(
                templates["status"], "machine-generated-templates-no-human-evidence"
            )

    def test_package_manifest_covers_nested_manifests_and_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "package"
            manifest = build(output)
            listed = {item["path"] for item in manifest["files"]}
            actual = {
                path.relative_to(output).as_posix()
                for path in output.rglob("*")
                if path.is_file() and path.relative_to(output).as_posix() != "manifest.json"
            }
            self.assertEqual(listed, actual)
            self.assertIn("dossier/manifest.json", listed)
            self.assertIn("templates/manifest.json", listed)

    def test_package_preserves_current_submitted_review_counts(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "package"
            manifest = build(output)
            dossier = json.loads(
                (output / "dossier" / "manifest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(
                manifest["submitted_lesson_review_count"],
                dossier["submitted_lesson_review_count"],
            )
            self.assertEqual(
                manifest["submitted_licence_review_count"],
                dossier["submitted_licence_review_count"],
            )

    def test_package_is_byte_deterministic(self) -> None:
        manifest = verify_determinism()
        self.assertEqual(manifest["lesson_target_count"], 43)
        self.assertEqual(
            manifest["status"],
            "machine-generated-review-package-no-human-evidence",
        )


if __name__ == "__main__":
    unittest.main()
