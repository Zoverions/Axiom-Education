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

    @staticmethod
    def source(payload: dict[str, object], source_id: str) -> dict[str, object]:
        rows = payload["sources"]
        if not isinstance(rows, list):
            raise AssertionError("monitoring sources must be a list")
        for row in rows:
            if isinstance(row, dict) and row.get("source_id") == source_id:
                return row
        raise AssertionError(f"missing monitoring source: {source_id}")

    def test_current_policy_accounts_for_twelve_locks_and_four_pending_targets(self) -> None:
        result = verify_policy()
        self.assertEqual(result["sources"], 12)
        self.assertEqual(result["capture_targets"], 16)
        self.assertEqual(
            set(result["pending_capture_targets"]),
            {
                "ontario-fr-francais-grades-1-8-2023",
                "ontario-fr-mathematics-grades-1-8-2020",
                "ontario-fr-health-physical-education-grades-1-8-2019",
                "ontario-fr-arts-grades-1-8-2009",
            },
        )
        self.assertEqual(
            set(result["strict_exact_byte"]),
            {
                "ontario-health-physical-education-grades-1-8-2019",
                "ontario-mathematics-grades-1-8-2020",
                "ontario-fsl-grades-1-8-2013",
                "ontario-fr-english-grades-4-8-2006",
                "ontario-fr-english-beginners-grades-4-8-2013",
            },
        )
        self.assertEqual(
            set(result["observational_response_surface"]),
            {
                "ontario-kindergarten-2026",
                "ontario-arts-grades-1-8-2009",
                "ontario-language-grades-1-8-2023",
                "ontario-science-technology-grades-1-8-2022",
                "ontario-social-studies-history-geography",
                "ontario-fr-science-technology-grades-1-8-2022",
                "ontario-fr-social-studies-history-geography",
            },
        )

    def test_monitoring_cannot_claim_semantic_curriculum_change(self) -> None:
        def mutate(payload):
            self.source(payload, "ontario-language-grades-1-8-2023").update(
                {"semantic_change_claimed": True}
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(SourceMonitoringError, "cannot claim semantic change"):
            verify_policy(path)

    def test_html_response_surface_cannot_be_promoted_to_strict_without_new_evidence(self) -> None:
        def mutate(payload):
            self.source(payload, "ontario-arts-grades-1-8-2009").update(
                {"monitoring_mode": "strict-exact-byte"}
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(SourceMonitoringError, "requires document-like PDF"):
            verify_policy(path)

    def test_observational_source_requires_multi_attempt_evidence(self) -> None:
        def mutate(payload):
            observation = self.source(
                payload,
                "ontario-fr-science-technology-grades-1-8-2022",
            )["observation"]
            if not isinstance(observation, dict):
                raise AssertionError("observation must be an object")
            observation.update({"attempt_count": 1})

        path = self.mutation(mutate)
        with self.assertRaisesRegex(SourceMonitoringError, "multi-attempt observation"):
            verify_policy(path)

    def test_every_committed_lock_must_remain_accounted_for(self) -> None:
        def remove_arts(payload):
            payload["sources"] = [
                source
                for source in payload["sources"]
                if source["source_id"] != "ontario-arts-grades-1-8-2009"
            ]

        path = self.mutation(remove_arts)
        with self.assertRaisesRegex(SourceMonitoringError, "every committed C1 source"):
            verify_policy(path)

    def test_additional_capture_target_may_precede_c1_lock_and_monitoring_entry(self) -> None:
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
        self.assertEqual(result["sources"], 12)
        self.assertEqual(result["capture_targets"], 17)
        self.assertEqual(
            set(result["pending_capture_targets"]),
            {
                "ontario-fr-francais-grades-1-8-2023",
                "ontario-fr-mathematics-grades-1-8-2020",
                "ontario-fr-health-physical-education-grades-1-8-2019",
                "ontario-fr-arts-grades-1-8-2009",
                "ontario-pending-source-example",
            },
        )

    def test_committed_c1_lock_cannot_lose_its_capture_target(self) -> None:
        def remove_arts(payload):
            payload["targets"] = [
                target
                for target in payload["targets"]
                if target["source_id"] != "ontario-arts-grades-1-8-2009"
            ]

        path = self.target_mutation(remove_arts)
        with self.assertRaisesRegex(SourceMonitoringError, "retain a bounded capture target"):
            verify_policy(targets_path=path)


if __name__ == "__main__":
    unittest.main()
