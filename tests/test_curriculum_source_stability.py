from __future__ import annotations

import unittest

from tools.probe_curriculum_source_stability import (
    SourceStabilityError,
    classify_observations,
)


class CurriculumSourceStabilityTests(unittest.TestCase):
    def observation(self, *, sha256: str, byte_length: int = 100) -> dict[str, object]:
        return {
            "status": "success",
            "source_id": "source:test",
            "sha256": sha256,
            "byte_length": byte_length,
            "media_type": "text/html",
            "resolved_locator": "https://www.dcp.edu.gov.on.ca/example",
            "source_entry_sha256": "b" * 64,
        }

    def error_observation(self, message: str = "HTTP Error 404") -> dict[str, object]:
        return {
            "status": "error",
            "source_id": "source:test",
            "error_type": "RemoteCaptureError",
            "error_message": message,
        }

    def test_identical_exact_byte_observations_are_stable(self) -> None:
        observations = [
            self.observation(sha256="a" * 64),
            self.observation(sha256="a" * 64),
        ]
        report = classify_observations("source:test", observations)
        self.assertTrue(report["all_attempts_succeeded"])
        self.assertTrue(report["exact_bytes_stable_across_successful_attempts"])
        self.assertTrue(report["recapturable_surface_stable"])
        self.assertEqual(report["distinct_exact_byte_signatures"], 1)
        self.assertEqual(report["attempt_count"], 2)

    def test_changed_bytes_are_reported_as_observed_volatility_not_semantic_change(self) -> None:
        observations = [
            self.observation(sha256="a" * 64, byte_length=100),
            self.observation(sha256="c" * 64, byte_length=101),
        ]
        report = classify_observations("source:test", observations)
        self.assertTrue(report["all_attempts_succeeded"])
        self.assertFalse(report["exact_bytes_stable_across_successful_attempts"])
        self.assertFalse(report["recapturable_surface_stable"])
        self.assertEqual(report["distinct_exact_byte_signatures"], 2)
        self.assertIn("do not prove curriculum content changed", report["claim_boundary"])

    def test_failed_attempt_is_preserved_and_blocks_stable_surface_claim(self) -> None:
        observations = [
            self.observation(sha256="a" * 64),
            self.error_observation(),
            self.observation(sha256="a" * 64),
        ]
        report = classify_observations("source:test", observations)
        self.assertFalse(report["all_attempts_succeeded"])
        self.assertTrue(report["exact_bytes_stable_across_successful_attempts"])
        self.assertFalse(report["recapturable_surface_stable"])
        self.assertEqual(report["successful_attempt_count"], 2)
        self.assertEqual(report["failed_attempt_count"], 1)
        self.assertEqual(report["observations"][1]["status"], "error")
        self.assertIn("404", report["observations"][1]["error_message"])

    def test_only_one_success_cannot_claim_exact_byte_stability(self) -> None:
        observations = [
            self.observation(sha256="a" * 64),
            self.error_observation(),
        ]
        report = classify_observations("source:test", observations)
        self.assertFalse(report["exact_bytes_stable_across_successful_attempts"])
        self.assertFalse(report["recapturable_surface_stable"])

    def test_source_substitution_is_rejected(self) -> None:
        observations = [
            self.observation(sha256="a" * 64),
            {**self.observation(sha256="a" * 64), "source_id": "source:other"},
        ]
        with self.assertRaisesRegex(SourceStabilityError, "source_id mismatch"):
            classify_observations("source:test", observations)

    def test_at_least_two_observations_are_required(self) -> None:
        with self.assertRaisesRegex(SourceStabilityError, "at least two"):
            classify_observations(
                "source:test", [self.observation(sha256="a" * 64)]
            )


if __name__ == "__main__":
    unittest.main()
