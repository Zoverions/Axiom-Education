from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.check_curriculum_source_monitoring import (
    POLICY_PATH,
    TARGETS_PATH,
    SourceMonitoringError,
    verify_policy,
)


class CurriculumSourceMonitoringTests(unittest.TestCase):
    def mutation(self, mutate) -> Path:
        payload = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
        mutate(payload)
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "monitoring.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def target_mutation(self, mutate) -> Path:
        payload = json.loads(TARGETS_PATH.read_text(encoding="utf-8"))
        mutate(payload)
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "targets.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_current_policy_accounts_for_all_five_c1_sources(self) -> None:
        result = verify_policy()
        self.assertEqual(result["sources"], 5)
        self.assertEqual(result["capture_targets"], 5)
        self.assertEqual(result["pending_capture_targets"], [])
        self.assertEqual(
            set(result["strict_exact_byte"]),
            {
                "ontario-health-physical-education-grades-1-8-2019",
                "ontario-mathematics-grades-1-8-2020",
                "ontario-fsl-grades-1-8-2013",
            },
        )
        self.assertEqual(
            set(result["observational_response_surface"]),
            {
                "ontario-language-grades-1-8-2023",
                "ontario-science-technology-grades-1-8-2022",
            },
        )

    def test_monitoring_cannot_claim_semantic_curriculum_change(self) -> None:
        path = self.mutation(
            lambda payload: payload["sources"][3].update(
                {"semantic_change_claimed": True}
            )
        )
        with self.assertRaisesRegex(SourceMonitoringError, "cannot claim semantic change"):
            verify_policy(path)

    def test_html_response_surface_cannot_be_promoted_to_strict_without_new_evidence(self) -> None:
        path = self.mutation(
            lambda payload: payload["sources"][3].update(
                {"monitoring_mode": "strict-exact-byte"}
            )
        )
        with self.assertRaisesRegex(SourceMonitoringError, "requires document-like PDF"):
            verify_policy(path)

    def test_observational_source_requires_multi_attempt_evidence(self) -> None:
        path = self.mutation(
            lambda payload: payload["sources"][4]["observation"].update(
                {"attempt_count": 1}
            )
        )
        with self.assertRaisesRegex(SourceMonitoringError, "multi-attempt observation"):
            verify_policy(path)

    def test_every_committed_lock_must_remain_accounted_for(self) -> None:
        path = self.mutation(lambda payload: payload["sources"].pop())
        with self.assertRaisesRegex(SourceMonitoringError, "every committed C1 source"):
            verify_policy(path)

    def test_capture_target_may_precede_c1_lock_and_monitoring_entry(self) -> None:
        path = self.target_mutation(
            lambda payload: payload["targets"].append(
                {
                    "source_id": "ontario-pending-source-example",
                    "download_url": "https://www.dcp.edu.gov.on.ca/en/curriculum/example",
                    "expected_media_type": "text/html",
                    "host_policy": "ontario-government",
                    "max_bytes": 10485760,
                    "redistribution_status": "review-required",
                    "bytes_retained": False,
                    "notes": "Pre-C1 capture candidate used only to verify stage ordering.",
                }
            )
        )
        result = verify_policy(targets_path=path)
        self.assertEqual(result["sources"], 5)
        self.assertEqual(result["capture_targets"], 6)
        self.assertEqual(
            result["pending_capture_targets"], ["ontario-pending-source-example"]
        )

    def test_committed_c1_lock_cannot_lose_its_capture_target(self) -> None:
        path = self.target_mutation(lambda payload: payload["targets"].pop())
        with self.assertRaisesRegex(SourceMonitoringError, "retain a bounded capture target"):
            verify_policy(targets_path=path)


if __name__ == "__main__":
    unittest.main()
