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

    @staticmethod
    def target(payload: dict[str, object], source_id: str) -> dict[str, object]:
        targets = payload["targets"]
        if not isinstance(targets, list):
            raise AssertionError("capture targets must be a list")
        for target in targets:
            if isinstance(target, dict) and target.get("source_id") == source_id:
                return target
        raise AssertionError(f"missing target: {source_id}")

    def test_current_target_registry_is_bounded(self):
        targets = validate_target_registry()
        self.assertEqual(
            set(targets),
            {
                "ontario-kindergarten-2026",
                "ontario-health-physical-education-grades-1-8-2019",
                "ontario-mathematics-grades-1-8-2020",
                "ontario-language-grades-1-8-2023",
                "ontario-science-technology-grades-1-8-2022",
                "ontario-fsl-grades-1-8-2013",
                "ontario-arts-grades-1-8-2009",
                "ontario-social-studies-history-geography",
            },
        )
        kindergarten = targets["ontario-kindergarten-2026"]
        hpe = targets["ontario-health-physical-education-grades-1-8-2019"]
        math = targets["ontario-mathematics-grades-1-8-2020"]
        language = targets["ontario-language-grades-1-8-2023"]
        science = targets["ontario-science-technology-grades-1-8-2022"]
        fsl = targets["ontario-fsl-grades-1-8-2013"]
        arts = targets["ontario-arts-grades-1-8-2009"]
        sshg = targets["ontario-social-studies-history-geography"]
        self.assertEqual(kindergarten["publication_number"], "CL34638")
        self.assertEqual(kindergarten["host_policy"], "ontario-government")
        self.assertEqual(kindergarten["expected_media_type"], "text/html")
        self.assertEqual(
            kindergarten["source_locator"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/kindergarten",
        )
        self.assertEqual(hpe["host_policy"], "ontario-government")
        self.assertEqual(hpe["allowed_hosts"], ["www.edu.gov.on.ca"])
        self.assertEqual(math["host_policy"], "publications-ontario-access-cdn")
        self.assertEqual(math["allowed_hosts"], ["assets-us-01.kc-usercontent.com"])
        self.assertEqual(math["publication_number"], "CL32210")
        self.assertEqual(language["expected_media_type"], "text/html")
        self.assertEqual(language["allowed_hosts"], ["www.dcp.edu.gov.on.ca"])
        self.assertEqual(science["expected_media_type"], "text/html")
        self.assertEqual(science["allowed_hosts"], ["www.dcp.edu.gov.on.ca"])
        self.assertEqual(fsl["expected_media_type"], "application/pdf")
        self.assertEqual(fsl["publication_number"], "232944")
        self.assertEqual(arts["host_policy"], "ontario-government")
        self.assertEqual(arts["expected_media_type"], "text/html")
        self.assertEqual(
            arts["source_locator"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-arts",
        )
        self.assertEqual(
            arts["source_resolution_status"],
            "official-current-structured-source-resolved-pending-c1",
        )
        self.assertEqual(sshg["host_policy"], "ontario-government")
        self.assertEqual(sshg["expected_media_type"], "text/html")
        self.assertEqual(
            sshg["source_locator"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-sshg",
        )
        self.assertEqual(
            sshg["source_resolution_status"],
            "official-current-structured-source-resolved-pending-c1",
        )
        self.assertNotIn("publication_number", sshg)
        self.assertNotIn("publication_catalog_url", sshg)
        self.assertTrue(
            all(
                target["redistribution_status"] == "review-required"
                for target in targets.values()
            )
        )

    def test_arbitrary_non_government_host_is_rejected_under_government_policy(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-health-physical-education-grades-1-8-2019",
            ).update(
                {
                    "download_url": "https://example.com/curriculum.pdf",
                    "allowed_hosts": ["example.com"],
                }
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "non-Ontario-government host"):
            validate_target_registry(path)

    def test_publication_cdn_policy_rejects_unapproved_cdn(self):
        def mutate(payload):
            self.target(payload, "ontario-mathematics-grades-1-8-2020").update(
                {
                    "download_url": "https://example.com/curriculum.pdf",
                    "allowed_hosts": ["example.com"],
                }
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "not explicitly approved"):
            validate_target_registry(path)

    def test_publication_cdn_requires_publications_ontario_provenance(self):
        def mutate(payload):
            self.target(payload, "ontario-mathematics-grades-1-8-2020").update(
                {"publication_catalog_url": "https://example.com/CL32210"}
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "must be Publications Ontario"):
            validate_target_registry(path)

    def test_publication_number_must_match_catalog_url(self):
        def mutate(payload):
            self.target(payload, "ontario-mathematics-grades-1-8-2020").update(
                {"publication_number": "WRONG"}
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(
            RemoteCaptureError,
            "bound into the Publications Ontario URL",
        ):
            validate_target_registry(path)

    def test_dcp_structured_source_remains_under_government_host_policy(self):
        def mutate(payload):
            self.target(payload, "ontario-language-grades-1-8-2023").update(
                {
                    "download_url": "https://example.com/language",
                    "allowed_hosts": ["example.com"],
                }
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "non-Ontario-government host"):
            validate_target_registry(path)

    def test_source_locator_must_already_exist_in_effective_discovery(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-health-physical-education-grades-1-8-2019",
            ).update({"source_locator": "https://www.ontario.ca/not-recorded"})

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "recorded in C0 discovery"):
            validate_target_registry(path)

    def test_arts_locator_is_resolved_by_append_only_discovery_amendment(self):
        targets = validate_target_registry()
        arts = targets["ontario-arts-grades-1-8-2009"]
        self.assertEqual(
            arts["download_url"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-arts",
        )

    def test_kindergarten_locator_is_resolved_by_append_only_discovery_amendment(self):
        targets = validate_target_registry()
        kindergarten = targets["ontario-kindergarten-2026"]
        self.assertEqual(
            kindergarten["download_url"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/kindergarten",
        )
        self.assertEqual(
            kindergarten["publication_catalog_url"],
            "https://www.publications.gov.on.ca/CL34638",
        )

    def test_sshg_locator_is_resolved_by_append_only_discovery_amendment(self):
        targets = validate_target_registry()
        sshg = targets["ontario-social-studies-history-geography"]
        self.assertEqual(
            sshg["download_url"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-sshg",
        )

    def test_remote_capture_cannot_preapprove_redistribution(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-health-physical-education-grades-1-8-2019",
            ).update({"redistribution_status": "redistributable-reviewed"})

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "cannot pre-approve redistribution"):
            validate_target_registry(path)

    def test_oversized_capture_limit_is_rejected(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-health-physical-education-grades-1-8-2019",
            ).update({"maximum_bytes": 300 * 1024 * 1024})

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "safe range"):
            validate_target_registry(path)

    def test_duplicate_source_target_is_rejected(self):
        def duplicate(payload):
            target = dict(
                self.target(
                    payload,
                    "ontario-health-physical-education-grades-1-8-2019",
                )
            )
            payload["targets"].append(target)

        path = self.mutation(duplicate)
        with self.assertRaisesRegex(RemoteCaptureError, "duplicate capture target"):
            validate_target_registry(path)


if __name__ == "__main__":
    unittest.main()
