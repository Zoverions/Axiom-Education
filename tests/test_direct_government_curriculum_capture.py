from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.direct_government_curriculum_capture import (
    DirectGovernmentCaptureError,
    TARGETS_PATH,
    validate_target_registry,
)


class DirectGovernmentCurriculumCaptureTests(unittest.TestCase):
    def mutation(self, mutate) -> Path:
        payload = json.loads(TARGETS_PATH.read_text(encoding="utf-8"))
        mutate(payload)
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "targets.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_current_registry_contains_only_exact_arts_route(self) -> None:
        targets = validate_target_registry()
        self.assertEqual(set(targets), {"ontario-arts-grades-1-8-2009"})
        target = targets["ontario-arts-grades-1-8-2009"]
        self.assertEqual(target["source_locator"], target["download_url"])
        self.assertEqual(target["allowed_host"], "www.dcp.edu.gov.on.ca")
        self.assertEqual(target["expected_media_type"], "text/html")
        self.assertEqual(target["redistribution_status"], "review-required")

    def test_direct_route_cannot_leave_ontario_government_host(self) -> None:
        path = self.mutation(
            lambda payload: payload["targets"][0].update(
                {
                    "source_locator": "https://example.com/arts",
                    "download_url": "https://example.com/arts",
                    "allowed_host": "example.com",
                }
            )
        )
        with self.assertRaisesRegex(DirectGovernmentCaptureError, "Ontario government host"):
            validate_target_registry(path)

    def test_download_must_equal_discovery_source_route_exactly(self) -> None:
        path = self.mutation(
            lambda payload: payload["targets"][0].update(
                {
                    "download_url": "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-arts?alternate=true"
                }
            )
        )
        with self.assertRaisesRegex(DirectGovernmentCaptureError, "must equal source_locator exactly"):
            validate_target_registry(path)

    def test_source_locator_must_exist_in_c0_discovery(self) -> None:
        path = self.mutation(
            lambda payload: payload["targets"][0].update(
                {
                    "source_locator": "https://www.dcp.edu.gov.on.ca/en/curriculum/not-recorded",
                    "download_url": "https://www.dcp.edu.gov.on.ca/en/curriculum/not-recorded",
                }
            )
        )
        with self.assertRaisesRegex(DirectGovernmentCaptureError, "not present in C0 discovery"):
            validate_target_registry(path)

    def test_direct_capture_cannot_preapprove_redistribution(self) -> None:
        path = self.mutation(
            lambda payload: payload["targets"][0].update(
                {"redistribution_status": "redistributable-reviewed"}
            )
        )
        with self.assertRaisesRegex(DirectGovernmentCaptureError, "cannot pre-approve redistribution"):
            validate_target_registry(path)

    def test_unsupported_media_type_is_rejected(self) -> None:
        path = self.mutation(
            lambda payload: payload["targets"][0].update(
                {"expected_media_type": "application/octet-stream"}
            )
        )
        with self.assertRaisesRegex(DirectGovernmentCaptureError, "unsupported expected_media_type"):
            validate_target_registry(path)


if __name__ == "__main__":
    unittest.main()
