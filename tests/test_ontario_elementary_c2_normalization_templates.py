from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.ontario_elementary_c2_normalization_templates import (
    EVIDENCE_SCHEMA,
    build,
    template_for,
    verify_determinism,
)
from tools.ontario_elementary_c2_promotion import CONFIRMATION_KEYS


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


class OntarioElementaryC2NormalizationTemplateTests(unittest.TestCase):
    def test_current_zero_state_builds_deterministic_empty_template_package(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "templates"
            manifest = build(output)
            self.assertEqual(manifest["target_count"], 0)
            self.assertEqual(manifest["templates"], [])
            self.assertTrue((output / "manifest.json").is_file())
            self.assertTrue((output / "README.md").is_file())

    def test_template_is_deliberately_not_review_evidence(self):
        payload = template_for(dict(TARGET))
        self.assertEqual(
            payload["schema"],
            "axiom-education-curriculum-normalization-review-template.v1",
        )
        self.assertNotEqual(payload["schema"], EVIDENCE_SCHEMA)
        self.assertTrue(payload["template_only"])
        human = payload["human_completion_required"]
        self.assertEqual(human["review_id"], "")
        self.assertEqual(human["decision"], "")
        self.assertFalse(any(human["confirmations"].values()))
        self.assertEqual(set(human["confirmations"]), CONFIRMATION_KEYS)

    def test_template_preserves_exact_candidate_and_source_evidence(self):
        payload = template_for(dict(TARGET))
        self.assertEqual(payload["candidate"]["record_id"], TARGET["record_id"])
        self.assertEqual(
            payload["candidate"]["content_digest"], TARGET["content_digest"]
        )
        self.assertEqual(
            payload["candidate"]["review_target_sha256"],
            TARGET["review_target_sha256"],
        )
        self.assertEqual(
            payload["review_basis"]["source_bytes_sha256"],
            TARGET["source_bytes_sha256"],
        )
        self.assertEqual(
            payload["review_basis"]["source_byte_length"],
            TARGET["source_byte_length"],
        )
        self.assertEqual(
            payload["review_basis"]["source_lock_sha256"],
            TARGET["source_lock_sha256"],
        )

    def test_template_package_is_byte_deterministic(self):
        manifest = verify_determinism()
        self.assertEqual(manifest["target_count"], 0)
        self.assertEqual(
            manifest["status"],
            "machine-generated-templates-no-human-normalization-evidence",
        )


if __name__ == "__main__":
    unittest.main()
