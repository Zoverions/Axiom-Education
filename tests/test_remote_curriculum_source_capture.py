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
            {
                "ontario-health-physical-education-grades-1-8-2019",
                "ontario-mathematics-grades-1-8-2020",
            },
        )
        hpe = targets["ontario-health-physical-education-grades-1-8-2019"]
        math = targets["ontario-mathematics-grades-1-8-2020"]
        self.assertEqual(hpe["host_policy"], "ontario-government")
        self.assertEqual(hpe["allowed_hosts"], ["www.edu.gov.on.ca"])
        self.assertEqual(math["host_policy"], "publications-ontario-access-cdn")
        self.assertEqual(math["allowed_hosts"], ["assets-us-01.kc-usercontent.com"])
        self.assertEqual(math["publication_number"], "CL32210")
        self.assertTrue(all(target["redistribution_status"] == "review-required" for target in targets.values()))

    def test_arbitrary_non_government_host_is_rejected_under_government_policy(self):
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

    def test_publication_cdn_policy_rejects_unapproved_cdn(self):
        path = self.mutation(
            lambda payload: payload["targets"][1].update(
                {
                    "download_url": "https://example.com/curriculum.pdf",
                    "allowed_hosts": ["example.com"],
                }
            )
        )
        with self.assertRaisesRegex(RemoteCaptureError, "not explicitly approved"):
            validate_target_registry(path)

    def test_publication_cdn_requires_publications_ontario_provenance(self):
        path = self.mutation(
            lambda payload: payload["targets"][1].update(
                {"publication_catalog_url": "https://example.com/CL32210"}
            )
        )
        with self.assertRaisesRegex(RemoteCaptureError, "must be Publications Ontario"):
            validate_target_registry(path)

    def test_publication_number_must_match_catalog_url(self):
        path = self.mutation(
            lambda payload: payload["targets"][1].update(
                {"publication_number": "WRONG"}
            )
        )
        with self.assertRaisesRegex(RemoteCaptureError, "bound into the Publications Ontario URL"):
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
