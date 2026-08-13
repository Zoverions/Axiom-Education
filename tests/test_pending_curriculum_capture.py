from __future__ import annotations

import unittest

from tools.attempt_pending_curriculum_capture import (
    PendingCaptureError,
    build_report,
)


class PendingCurriculumCaptureTests(unittest.TestCase):
    def target(self) -> dict[str, object]:
        return {
            "source_id": "source:test",
            "source_locator": "https://www.dcp.edu.gov.on.ca/example",
            "download_url": "https://www.dcp.edu.gov.on.ca/example",
            "expected_media_type": "text/html",
        }

    def test_candidate_produced_is_not_c1_promotion(self) -> None:
        report = build_report(
            source_id="source:test",
            target=self.target(),
            attempts=3,
            errors=[RuntimeError("first attempt unavailable")],
            candidate_produced=True,
        )
        self.assertEqual(report["status"], "candidate-produced")
        self.assertTrue(report["candidate_produced"])
        self.assertEqual(report["failed_attempt_count"], 1)
        self.assertIn("does not promote C1", report["claim_boundary"])

    def test_all_bounded_failures_become_capture_unavailable_evidence(self) -> None:
        report = build_report(
            source_id="source:test",
            target=self.target(),
            attempts=3,
            errors=[
                RuntimeError("HTTP 404"),
                RuntimeError("HTTP 404"),
                RuntimeError("HTTP 404"),
            ],
            candidate_produced=False,
        )
        self.assertEqual(report["status"], "capture-unavailable")
        self.assertFalse(report["candidate_produced"])
        self.assertEqual(report["failed_attempt_count"], 3)
        self.assertEqual(len(report["failures"]), 3)
        self.assertIn("does not prove", report["claim_boundary"])

    def test_unavailable_report_must_account_for_every_attempt(self) -> None:
        with self.assertRaisesRegex(PendingCaptureError, "account for every failed"):
            build_report(
                source_id="source:test",
                target=self.target(),
                attempts=3,
                errors=[RuntimeError("one failure")],
                candidate_produced=False,
            )

    def test_attempt_bound_is_fail_closed(self) -> None:
        with self.assertRaisesRegex(PendingCaptureError, "between 1 and 5"):
            build_report(
                source_id="source:test",
                target=self.target(),
                attempts=0,
                errors=[],
                candidate_produced=False,
            )


if __name__ == "__main__":
    unittest.main()
