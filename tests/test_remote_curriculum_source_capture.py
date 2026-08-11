from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.remote_curriculum_source_capture import (
    RemoteCaptureError,
    TARGETS_PATH,
    validate_target_registry,
)


class RemoteCurriculumSourceCaptureTests(unittest.TestCase):
    def mutation(self, mutate) -> Path:
        payload = json.loads(TARGETS_PATH.read_text(encoding="utf-8"))
        mutate(payload)
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "targets.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_current_target_registry_is_bounded(self):
        targets = validate_target_registry()
        self.assertEqual(
            set(targets),
            {"ontario-health-physical-education-grades-1-8-2019"},
        )
        target = targets["ontario-health-physical-education-grades-1-8-2019"]
        self.assertEqual(target["allowed_hosts"], ["www.edu.gov.on.ca"])
        self.assertEqual(target["expected_media_type"], "application/pdf")
        self.assertEqual(target["redistribution_status"], "review-required")

    def test_arbitrary_non_government_host_is_rejected(self):
        path = self.mutation(
            lambda payload: payload["targets"][0].update(
                {
                    "download_url": "https://example.com/curriculum.pdf",
                    "allowed_hosts": ["example.com"],
                }
            )
        )
        with self.assertRaisesRegex(RemoteCaptureError, "non-Ontario-government host"):
            validate_target_registry(path)

    def test_source_locator_must_already_exist_in_discovery(self):
        path = self.mutation(
            lambda payload: payload["targets"][0].update(
                {"source_locator": "https://www.ontario.ca/not-recorded"}
            )
        )
        with self.assertRaisesRegex(RemoteCaptureError, "recorded in C0 discovery"):
            validate_target_registry(path)

    def test_remote_capture_cannot_preapprove_redistribution(self):
        path = self.mutation(
            lambda payload: payload["targets"][0].update(
                {"redistribution_status": "redistributable-reviewed"}
            )
        )
        with self.assertRaisesRegex(RemoteCaptureError, "cannot pre-approve redistribution"):
            validate_target_registry(path)

    def test_oversized_capture_limit_is_rejected(self):
        path = self.mutation(
            lambda payload: payload["targets"][0].update(
                {"maximum_bytes": 300 * 1024 * 1024}
            )
        )
        with self.assertRaisesRegex(RemoteCaptureError, "safe range"):
            validate_target_registry(path)

    def test_duplicate_source_target_is_rejected(self):
        def duplicate(payload):
            payload["targets"].append(dict(payload["targets"][0]))

        path = self.mutation(duplicate)
        with self.assertRaisesRegex(RemoteCaptureError, "duplicate capture target"):
            validate_target_registry(path)


if __name__ == "__main__":
    unittest.main()
