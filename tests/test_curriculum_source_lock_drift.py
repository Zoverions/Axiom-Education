from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.check_curriculum_source_lock_drift import (
    DEFAULT_LOCK_DIR,
    SourceLockDriftError,
    compare_candidate,
)


HPE_LOCK = (
    DEFAULT_LOCK_DIR
    / "ontario-health-physical-education-grades-1-8-2019.v1.json"
)


class CurriculumSourceLockDriftTests(unittest.TestCase):
    def candidate(self, mutate=None) -> Path:
        payload = json.loads(HPE_LOCK.read_text(encoding="utf-8"))
        payload["captured_at"] = "2026-08-11T23:59:59Z"
        payload["notes"] = "fresh hosted recapture for drift verification"
        if mutate is not None:
            mutate(payload)
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "candidate.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_capture_metadata_may_change_when_source_bytes_do_not(self) -> None:
        result = compare_candidate(self.candidate())
        self.assertEqual(result["status"], "matches-committed-lock")
        self.assertEqual(
            result["source_id"],
            "ontario-health-physical-education-grades-1-8-2019",
        )
        self.assertEqual(
            result["sha256"],
            "37416922ca741b1fb32a0708442738ae8d964d974c3315d04cdcc8bd2e652622",
        )

    def test_upstream_byte_digest_drift_fails_closed(self) -> None:
        path = self.candidate(lambda payload: payload.update({"sha256": "0" * 64}))
        with self.assertRaisesRegex(SourceLockDriftError, "drift detected"):
            compare_candidate(path)

    def test_byte_length_drift_fails_closed(self) -> None:
        path = self.candidate(
            lambda payload: payload.update({"byte_length": payload["byte_length"] + 1})
        )
        with self.assertRaisesRegex(SourceLockDriftError, "byte_length"):
            compare_candidate(path)

    def test_resolved_locator_drift_fails_closed(self) -> None:
        path = self.candidate(
            lambda payload: payload.update(
                {
                    "resolved_locator": "https://www.edu.gov.on.ca/eng/curriculum/elementary/changed.pdf"
                }
            )
        )
        with self.assertRaisesRegex(SourceLockDriftError, "resolved_locator"):
            compare_candidate(path)

    def test_source_entry_binding_drift_fails_before_comparison(self) -> None:
        path = self.candidate(
            lambda payload: payload.update({"source_entry_sha256": "f" * 64})
        )
        with self.assertRaisesRegex(Exception, "source entry"):
            compare_candidate(path)

    def test_uncommitted_candidate_requires_explicit_allowance(self) -> None:
        path = self.candidate()
        with tempfile.TemporaryDirectory() as tmp:
            empty = Path(tmp)
            with self.assertRaisesRegex(SourceLockDriftError, "no committed C1 lock"):
                compare_candidate(path, empty)
            result = compare_candidate(path, empty, allow_uncommitted=True)
            self.assertEqual(result["status"], "new-uncommitted-candidate")


if __name__ == "__main__":
    unittest.main()
