from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.curriculum_source_lock import DEFAULT_DISCOVERY, canonical_json_digest, create_lock
from tools.curriculum_standard_record import (
    StandardRecordError,
    finalize_record,
    verify_record,
)


SOURCE_ID = "ontario-mathematics-grades-1-8-2020"
SOURCE_LOCATOR = "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-mathematics"


class CurriculumStandardRecordTests(unittest.TestCase):
    def make_source_lock(self, root: Path, redistribution="review-required"):
        source_file = root / "official-source.pdf"
        source_file.write_bytes(b"operator captured official curriculum fixture")
        lock = create_lock(
            source_id=SOURCE_ID,
            input_path=source_file,
            source_locator=SOURCE_LOCATOR,
            resolved_locator=SOURCE_LOCATOR,
            media_type="application/pdf",
            discovery_path=DEFAULT_DISCOVERY,
            redistribution_status=redistribution,
            retained_path=None,
            notes="test fixture",
        )
        lock_dir = root / "locks"
        lock_dir.mkdir()
        lock_path = lock_dir / f"{SOURCE_ID}.v1.json"
        lock_path.write_text(json.dumps(lock), encoding="utf-8")
        return lock_dir, lock

    def make_record(self, lock, *, mode="paraphrase"):
        text = "Represent and compare whole-number quantities using place-value reasoning."
        if mode == "reference-only":
            text = None
        return {
            "schema": "axiom-curriculum-standard-record.v2",
            "stage": "C2-normalized",
            "record_id": "ca:on:elementary:math:g1:test-1",
            "jurisdiction_id": lock["jurisdiction_id"],
            "authority_id": lock["authority_id"],
            "language": "en",
            "education_context": {
                "program_family": "english-language-schools",
                "level": "elementary",
                "grade_or_level": "1",
                "subject_id": "mathematics",
                "subject_name": "Mathematics",
                "course_code": None,
                "course_name": None,
            },
            "standard": {
                "official_id": "TEST-1",
                "kind": "specific",
                "parent_official_id": "TEST",
                "strand_id": "B",
                "strand_name": "Number",
                "content": {
                    "mode": mode,
                    "text": text,
                    "official_text_sha256": None,
                },
            },
            "source": {
                "source_id": SOURCE_ID,
                "source_lock_sha256": canonical_json_digest(lock),
                "upstream_document_sha256": lock["sha256"],
                "official_locator": SOURCE_LOCATOR,
                "official_recognition": True,
                "effective_from": "2020",
                "effective_to": None,
            },
            "provenance": {
                "normalization_method": "test-manual-normalization",
                "normalized_at": "2026-08-11T20:00:00Z",
                "human_source_review_status": "required",
            },
            "axiom_metadata": {
                "namespace": "org.axiom.education",
                "tags": ["test"],
            },
            "content_digest": "",
        }

    def write_final_record(self, root: Path, payload):
        draft = root / "draft.json"
        record = root / "record.json"
        draft.write_text(json.dumps(payload), encoding="utf-8")
        finalize_record(draft, record)
        return record

    def test_paraphrased_elementary_record_requires_and_verifies_c1_lock(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lock_dir, lock = self.make_source_lock(root)
            record_path = self.write_final_record(root, self.make_record(lock))
            record = verify_record(record_path, lock_dir)
            self.assertEqual(record["stage"], "C2-normalized")
            self.assertEqual(record["education_context"]["level"], "elementary")

    def test_c2_record_without_c1_lock_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lock_dir, lock = self.make_source_lock(root)
            record_path = self.write_final_record(root, self.make_record(lock))
            empty = root / "empty-locks"
            empty.mkdir()
            with self.assertRaisesRegex(StandardRecordError, "valid C1 source lock"):
                verify_record(record_path, empty)

    def test_elementary_record_cannot_invent_high_school_course_code(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lock_dir, lock = self.make_source_lock(root)
            payload = self.make_record(lock)
            payload["education_context"]["course_code"] = "MTH1W"
            record_path = self.write_final_record(root, payload)
            with self.assertRaisesRegex(StandardRecordError, "must not invent a course code"):
                verify_record(record_path, lock_dir)

    def test_verbatim_text_requires_reviewed_redistribution_permission(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lock_dir, lock = self.make_source_lock(root)
            record_path = self.write_final_record(root, self.make_record(lock, mode="verbatim"))
            with self.assertRaisesRegex(StandardRecordError, "redistribution permission"):
                verify_record(record_path, lock_dir)

    def test_source_lock_substitution_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lock_dir, lock = self.make_source_lock(root)
            payload = self.make_record(lock)
            payload["source"]["source_lock_sha256"] = "0" * 64
            record_path = self.write_final_record(root, payload)
            with self.assertRaisesRegex(StandardRecordError, "source lock digest mismatch"):
                verify_record(record_path, lock_dir)

    def test_machine_normalization_cannot_claim_human_review(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lock_dir, lock = self.make_source_lock(root)
            payload = self.make_record(lock)
            payload["provenance"]["human_source_review_status"] = "reviewed"
            record_path = self.write_final_record(root, payload)
            with self.assertRaisesRegex(StandardRecordError, "cannot claim human source review"):
                verify_record(record_path, lock_dir)

    def test_reference_only_record_cannot_embed_text(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lock_dir, lock = self.make_source_lock(root)
            payload = self.make_record(lock, mode="reference-only")
            payload["standard"]["content"]["text"] = "should not be embedded"
            record_path = self.write_final_record(root, payload)
            with self.assertRaisesRegex(StandardRecordError, "must not embed source text"):
                verify_record(record_path, lock_dir)


if __name__ == "__main__":
    unittest.main()
