from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.ontario_hpe_grade1_c2_proof import (
    EXPECTED,
    HpeC2ProofError,
    SLICE_PATH,
    build,
    validate_spec,
    verify_determinism,
)


class OntarioHpeGrade1C2ProofTests(unittest.TestCase):
    def mutation(self, mutate) -> Path:
        payload = json.loads(SLICE_PATH.read_text(encoding="utf-8"))
        mutate(payload)
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "slice.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_real_c1_source_builds_eight_reference_only_c2_records(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "build"
            manifest = build(output)
            self.assertEqual(manifest["record_count"], 8)
            self.assertEqual(manifest["source_lock_sha256"], "d5effa1a696250abe75704ce46c93cde37ab1d418b94920517084c0c0843adac")
            self.assertEqual(manifest["upstream_document_sha256"], "37416922ca741b1fb32a0708442738ae8d964d974c3315d04cdcc8bd2e652622")
            self.assertEqual(manifest["content_mode"], "reference-only")
            self.assertEqual(
                manifest["reference_metadata_origin"],
                "manually-authored-not-derived-from-retained-source-bytes",
            )
            self.assertFalse(manifest["source_bytes_retained_and_parsed"])
            self.assertFalse(manifest["c1_to_c2_derivation_proven"])
            self.assertFalse(manifest["promoted_to_canonical_records"])
            self.assertEqual(
                {item["official_id"] for item in manifest["records"]},
                set(EXPECTED),
            )
            for item in manifest["records"]:
                record = json.loads((output / item["path"]).read_text(encoding="utf-8"))
                self.assertIsNone(record["standard"]["content"]["text"])
                self.assertIsNone(record["standard"]["content"]["official_text_sha256"])
                self.assertIsNone(record["education_context"]["course_code"])
                self.assertEqual(record["provenance"]["human_source_review_status"], "required")

    def test_proof_build_is_byte_deterministic(self) -> None:
        manifest = verify_determinism()
        self.assertEqual(manifest["record_count"], 8)

    def test_complete_grade_claim_is_rejected(self) -> None:
        path = self.mutation(
            lambda payload: payload.update({"complete_grade_claim_allowed": True})
        )
        with self.assertRaisesRegex(HpeC2ProofError, "complete Grade 1"):
            validate_spec(path)

    def test_complete_subject_claim_is_rejected(self) -> None:
        path = self.mutation(
            lambda payload: payload.update({"complete_subject_claim_allowed": True})
        )
        with self.assertRaisesRegex(HpeC2ProofError, "complete HPE"):
            validate_spec(path)

    def test_missing_reference_is_rejected(self) -> None:
        path = self.mutation(lambda payload: payload["records"].pop())
        with self.assertRaisesRegex(HpeC2ProofError, "exactly 8 references"):
            validate_spec(path)

    def test_source_page_drift_is_rejected(self) -> None:
        path = self.mutation(
            lambda payload: payload["records"][0].update({"official_page": 999})
        )
        with self.assertRaisesRegex(HpeC2ProofError, "official page mismatch"):
            validate_spec(path)

    def test_human_review_cannot_be_claimed_by_machine_slice(self) -> None:
        path = self.mutation(
            lambda payload: payload.update({"human_source_review_status": "reviewed"})
        )
        with self.assertRaisesRegex(HpeC2ProofError, "human source review"):
            validate_spec(path)

    def test_source_byte_derivation_cannot_be_claimed(self) -> None:
        path = self.mutation(
            lambda payload: payload.update({"c1_to_c2_derivation_proven": True})
        )
        with self.assertRaisesRegex(HpeC2ProofError, "derivation proof"):
            validate_spec(path)

    def test_retained_source_parsing_cannot_be_claimed(self) -> None:
        path = self.mutation(
            lambda payload: payload.update({"source_bytes_retained_and_parsed": True})
        )
        with self.assertRaisesRegex(HpeC2ProofError, "retained source bytes"):
            validate_spec(path)


if __name__ == "__main__":
    unittest.main()
