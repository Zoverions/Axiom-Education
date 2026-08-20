from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.ontario_elementary_reviewer_dossier import build, verify_determinism


class OntarioElementaryReviewerDossierTests(unittest.TestCase):
    def test_current_dossier_packages_review_inputs_without_source_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "dossier"
            manifest = build(root)
            self.assertEqual(manifest["source_target_count"], 16)
            self.assertEqual(manifest["c1_source_lock_count"], 16)
            self.assertEqual(manifest["strict_exact_byte_source_count"], 5)
            self.assertEqual(manifest["observational_response_surface_count"], 11)
            self.assertEqual(manifest["submitted_review_count"], 0)
            self.assertEqual(manifest["approved_source_count"], 0)
            self.assertEqual(manifest["canonical_c2_record_count"], 0)
            self.assertFalse(manifest["source_bytes_packaged"])
            self.assertEqual(manifest["review_template_count"], 16)

            plan = json.loads((root / "source-review-plan.json").read_text(encoding="utf-8"))
            self.assertEqual(plan["target_count"], 16)
            templates = sorted((root / "review-templates").glob("*.json"))
            self.assertEqual(len(templates), 16)
            locks = sorted((root / "source-locks").glob("*.json"))
            self.assertEqual(len(locks), 16)
            self.assertTrue((root / "REVIEW-GUIDE.md").is_file())

    def test_blank_templates_are_not_preapproved(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "dossier"
            build(root)
            for path in sorted((root / "review-templates").glob("*.json")):
                template = json.loads(path.read_text(encoding="utf-8"))
                with self.subTest(path=path.name):
                    self.assertEqual(template["decision"], "")
                    self.assertEqual(template["review_id"], "")
                    self.assertEqual(template["reviewer"]["name"], "")
                    self.assertEqual(template["reviewer"]["qualification"], "")
                    self.assertEqual(template["reviewed_at"], "")
                    self.assertTrue(template["target_sha256"])
                    self.assertTrue(all(value is False for value in template["confirmations"].values()))
                    self.assertEqual(template["attestation_type"], "human-review")

    def test_dossier_is_byte_deterministic(self) -> None:
        manifest = verify_determinism()
        self.assertEqual(manifest["source_target_count"], 16)
        self.assertFalse(manifest["source_bytes_packaged"])


if __name__ == "__main__":
    unittest.main()
