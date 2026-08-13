from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.curriculum_source_lock import (
    DEFAULT_DISCOVERY,
    SourceLockError,
    create_lock,
    verify_directory,
    verify_lock,
)


SOURCE_ID = "ontario-mathematics-grades-1-8-2020"
SOURCE_LOCATOR = "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-mathematics"


class CurriculumSourceLockTests(unittest.TestCase):
    def make_lock(self, directory: Path) -> Path:
        captured = directory / "captured-source.pdf"
        captured.write_bytes(b"fixture bytes representing an operator-captured official source")
        payload = create_lock(
            source_id=SOURCE_ID,
            input_path=captured,
            source_locator=SOURCE_LOCATOR,
            resolved_locator=SOURCE_LOCATOR,
            media_type="application/pdf",
            discovery_path=DEFAULT_DISCOVERY,
            redistribution_status="review-required",
            retained_path=None,
            notes="test fixture only",
        )
        lock_path = directory / "source-lock.json"
        lock_path.write_text(json.dumps(payload), encoding="utf-8")
        return lock_path

    def test_non_retained_capture_verifies_without_claiming_redistribution(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            lock_path = self.make_lock(Path(tmp))
            lock = verify_lock(lock_path)
            self.assertEqual(lock["claim_state"], "C1-bytes-captured-digested")
            self.assertFalse(lock["bytes_retained"])
            self.assertEqual(lock["redistribution_status"], "review-required")
            self.assertIsNone(lock["retained_path"])

    def test_invalid_digest_shape_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            lock_path = self.make_lock(Path(tmp))
            payload = json.loads(lock_path.read_text(encoding="utf-8"))
            payload["sha256"] = "not-a-sha256"
            lock_path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(SourceLockError, "sha256|does not match"):
                verify_lock(lock_path)

    def test_published_schema_rejects_unadvertised_lock_fields(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            lock_path = self.make_lock(Path(tmp))
            payload = json.loads(lock_path.read_text(encoding="utf-8"))
            payload["unreviewed_extension"] = True
            lock_path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(SourceLockError, "Additional properties"):
                verify_lock(lock_path)

    def test_source_entry_binding_rejects_stale_or_fabricated_lock(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            lock_path = self.make_lock(Path(tmp))
            payload = json.loads(lock_path.read_text(encoding="utf-8"))
            payload["source_entry_sha256"] = "0" * 64
            lock_path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(SourceLockError, "source entry changed"):
                verify_lock(lock_path)

    def test_unrecorded_locator_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            captured = Path(tmp) / "captured-source.pdf"
            captured.write_bytes(b"fixture")
            with self.assertRaisesRegex(SourceLockError, "not recorded in discovery"):
                create_lock(
                    source_id=SOURCE_ID,
                    input_path=captured,
                    source_locator="https://example.invalid/not-official",
                    resolved_locator="https://example.invalid/not-official",
                    media_type="application/pdf",
                    discovery_path=DEFAULT_DISCOVERY,
                    redistribution_status="review-required",
                    retained_path=None,
                    notes=None,
                )

    def test_duplicate_source_locks_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            first = self.make_lock(directory)
            second = directory / "second.json"
            second.write_text(first.read_text(encoding="utf-8"), encoding="utf-8")
            with self.assertRaisesRegex(SourceLockError, "duplicate source lock"):
                verify_directory(directory, DEFAULT_DISCOVERY, allow_empty=False)

    def test_empty_lock_directory_requires_explicit_allow_empty(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            with self.assertRaisesRegex(SourceLockError, "no source locks"):
                verify_directory(directory, DEFAULT_DISCOVERY, allow_empty=False)
            self.assertEqual(verify_directory(directory, DEFAULT_DISCOVERY, allow_empty=True), 0)


if __name__ == "__main__":
    unittest.main()
