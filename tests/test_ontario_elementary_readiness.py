from __future__ import annotations

import copy
import unittest

from tools.ontario_elementary_readiness import (
    ElementaryReadinessError,
    build_readiness,
    verify_readiness,
)


class OntarioElementaryReadinessTests(unittest.TestCase):
    def test_current_evidence_reports_five_c1_sources_without_completion_claim(self) -> None:
        payload = build_readiness()
        summary = payload["summary"]
        self.assertEqual(summary["confirmed_discovery_sources"], 8)
        self.assertEqual(summary["registered_capture_targets"], 5)
        self.assertEqual(summary["c1_locked_sources"], 5)
        self.assertEqual(summary["canonical_c2_records"], 0)
        self.assertFalse(summary["kindergarten_c1_locked"])
        self.assertEqual(summary["english_required_program_families"], 8)
        self.assertEqual(summary["english_program_families_with_c1_source"], 5)
        self.assertEqual(summary["french_required_program_families"], 8)
        self.assertEqual(summary["french_program_families_with_c1_source"], 0)
        self.assertFalse(summary["overall_base_source_capture_complete"])
        self.assertFalse(summary["human_source_review_complete"])
        self.assertFalse(summary["licensing_review_complete"])
        self.assertFalse(summary["governed_activation_available"])

    def test_uncaptured_discovered_sources_remain_explicit(self) -> None:
        payload = build_readiness()
        uncaptured = set(payload["summary"]["uncaptured_discovered_source_ids"])
        self.assertEqual(
            uncaptured,
            {
                "ontario-kindergarten-2026",
                "ontario-arts-grades-1-8-2009",
                "ontario-social-studies-history-geography",
            },
        )

    def test_english_program_family_coverage_is_exactly_five_of_eight(self) -> None:
        payload = build_readiness()
        rows = payload["program_families"]["english_language_schools"]
        locked = {
            row["program_family"]
            for row in rows
            if row["highest_evidenced_stage"] == "C1-bytes-captured-digested"
        }
        self.assertEqual(
            locked,
            {
                "french-as-a-second-language",
                "language",
                "health-and-physical-education",
                "mathematics",
                "science-and-technology",
            },
        )
        self.assertNotIn("the-arts", locked)
        self.assertNotIn("social-studies-grades-1-6", locked)
        self.assertNotIn("history-and-geography-grades-7-8", locked)

    def test_french_language_program_gaps_remain_explicit(self) -> None:
        payload = build_readiness()
        rows = payload["program_families"]["french_language_schools"]
        self.assertEqual(len(rows), 8)
        self.assertTrue(all(row["highest_evidenced_stage"] == "unresolved" for row in rows))
        self.assertEqual(
            set(payload["summary"]["unresolved_french_program_families"]),
            {row["program_family"] for row in rows},
        )

    def test_c1_rows_preserve_no-retained-bytes_and_review_required_licensing(self) -> None:
        payload = build_readiness()
        locked_rows = [row for row in payload["sources"] if row["c1"] is not None]
        self.assertEqual(len(locked_rows), 5)
        for row in locked_rows:
            self.assertFalse(row["c1"]["bytes_retained"])
            self.assertEqual(row["c1"]["redistribution_status"], "review-required")
            self.assertEqual(len(row["c1"]["sha256"]), 64)
            self.assertGreater(row["c1"]["byte_length"], 0)

    def test_machine_view_cannot_be_mutated_into_complete_readiness(self) -> None:
        payload = build_readiness()
        mutated = copy.deepcopy(payload)
        mutated["summary"]["overall_base_source_capture_complete"] = True
        with self.assertRaisesRegex(ElementaryReadinessError, "must not claim complete"):
            verify_readiness(mutated)

    def test_machine_view_cannot_claim_human_or_licensing_review(self) -> None:
        for field, message in (
            ("human_source_review_complete", "human source review"),
            ("licensing_review_complete", "licensing completion"),
            ("governed_activation_available", "governed activation"),
        ):
            with self.subTest(field=field):
                payload = build_readiness()
                payload["summary"][field] = True
                with self.assertRaisesRegex(ElementaryReadinessError, message):
                    verify_readiness(payload)

    def test_readiness_derivation_is_deterministic(self) -> None:
        self.assertEqual(build_readiness(), build_readiness())


if __name__ == "__main__":
    unittest.main()
