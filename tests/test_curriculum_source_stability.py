from __future__ import annotations

import unittest

from tools.probe_curriculum_source_stability import (
    SourceStabilityError,
    classify_observations,
)


class CurriculumSourceStabilityTests(unittest.TestCase):
    def observation(self, *, sha256: str, byte_length: int = 100) -> dict[str, object]:
        return {
            "source_id": "source:test",
            "sha256": sha256,
            "byte_length": byte_length,
            "media_type": "text/html",
            "resolved_locator": "https://www.dcp.edu.gov.on.ca/example",
            "source_entry_sha256": "b" * 64,
        }

    def test_identical_exact_byte_observations_are_stable(self) -> None:
        observations = [
            self.observation(sha256="a" * 64),
            self.observation(sha256="a" * 64),
        ]
        report = classify_observations("source:test", observations)
        self.assertTrue(report["exact_bytes_stable_across_attempts"])
        self.assertEqual(report["distinct_exact_byte_signatures"], 1)
        self.assertEqual(report["attempt_count"], 2)

    def test_changed_bytes_are_reported_as_observed_volatility_not_semantic_change(self) -> None:
        observations = [
            self.observation(sha256="a" * 64, byte_length=100),
            self.observation(sha256="c" * 64, byte_length=101),
        ]
        report = classify_observations("source:test", observations)
        self.assertFalse(report["exact_bytes_stable_across_attempts"])
        self.assertEqual(report["distinct_exact_byte_signatures"], 2)
        self.assertIn("do not prove curriculum content changed", report["claim_boundary"])

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
