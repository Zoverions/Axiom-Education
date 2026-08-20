from __future__ import annotations

import copy
import unittest

from tools.ontario_elementary_readiness import (
    ElementaryReadinessError,
    build_readiness,
    verify_readiness,
)


class OntarioElementaryReadinessTests(unittest.TestCase):
    def test_current_readiness_separates_snapshot_and_recapture_evidence(self) -> None:
        payload = build_readiness()
        summary = payload["summary"]
        self.assertEqual(
            payload["schema"], "axiom-education-ontario-elementary-readiness.v2"
        )
        self.assertEqual(summary["confirmed_discovery_sources"], 16)
        self.assertEqual(summary["registered_capture_targets"], 16)
        self.assertEqual(summary["c1_snapshot_sources"], 12)
        self.assertEqual(summary["strict_exact_byte_monitored_sources"], 5)
        self.assertEqual(summary["observational_response_surface_sources"], 7)
        self.assertFalse(summary["all_c1_sources_strictly_recapturable"])
        self.assertEqual(summary["canonical_c2_records"], 0)
        self.assertTrue(summary["kindergarten_c1_snapshot"])
        self.assertEqual(summary["english_program_families_with_c1_source"], 8)
        self.assertEqual(summary["french_program_families_with_c1_source"], 4)
        self.assertEqual(summary["unresolved_french_program_families"], [])
        self.assertTrue(summary["english_base_source_capture_complete"])
        self.assertFalse(summary["french_base_source_capture_complete"])
        self.assertFalse(summary["overall_base_source_capture_complete"])

    def test_arts_is_observational_c1(self) -> None:
        payload = build_readiness()
        rows = {row["source_id"]: row for row in payload["sources"]}
        arts = rows["ontario-arts-grades-1-8-2009"]
        self.assertEqual(arts["highest_evidenced_stage"], "C1-bytes-captured-digested")
        self.assertTrue(arts["capture_target_registered"])
        self.assertIsNotNone(arts["c1_snapshot"])
        self.assertEqual(arts["c1_snapshot"]["media_type"], "text/html")
        self.assertEqual(arts["monitoring"]["mode"], "observational-response-surface")
        self.assertFalse(arts["monitoring"]["strict_exact_byte_recapture"])
        self.assertFalse(arts["monitoring"]["semantic_change_claimed"])

    def test_english_sshg_current_source_is_observational_c1(self) -> None:
        payload = build_readiness()
        rows = {row["source_id"]: row for row in payload["sources"]}
        sshg = rows["ontario-social-studies-history-geography"]
        self.assertEqual(sshg["highest_evidenced_stage"], "C1-bytes-captured-digested")
        self.assertTrue(sshg["capture_target_registered"])
        self.assertIsNotNone(sshg["c1_snapshot"])
        self.assertEqual(
            sshg["monitoring"]["mode"],
            "observational-response-surface",
        )
        self.assertFalse(sshg["monitoring"]["strict_exact_byte_recapture"])
        self.assertFalse(sshg["monitoring"]["semantic_change_claimed"])

    def test_french_science_and_sshg_are_observational_c1(self) -> None:
        payload = build_readiness()
        rows = {row["source_id"]: row for row in payload["sources"]}
        for source_id in (
            "ontario-fr-science-technology-grades-1-8-2022",
            "ontario-fr-social-studies-history-geography",
        ):
            with self.subTest(source_id=source_id):
                row = rows[source_id]
                self.assertEqual(row["highest_evidenced_stage"], "C1-bytes-captured-digested")
                self.assertTrue(row["capture_target_registered"])
                self.assertIsNotNone(row["c1_snapshot"])
                self.assertEqual(
                    row["monitoring"]["mode"],
                    "observational-response-surface",
                )
                self.assertFalse(row["monitoring"]["strict_exact_byte_recapture"])
                self.assertFalse(row["monitoring"]["semantic_change_claimed"])

    def test_french_english_primary_and_conditional_alternative_are_strict_c1(self) -> None:
        payload = build_readiness()
        rows = {row["source_id"]: row for row in payload["sources"]}
        for source_id in (
            "ontario-fr-english-grades-4-8-2006",
            "ontario-fr-english-beginners-grades-4-8-2013",
        ):
            with self.subTest(source_id=source_id):
                row = rows[source_id]
                self.assertEqual(row["highest_evidenced_stage"], "C1-bytes-captured-digested")
                self.assertTrue(row["capture_target_registered"])
                self.assertIsNotNone(row["c1_snapshot"])
                self.assertEqual(row["c1_snapshot"]["media_type"], "application/pdf")
                self.assertEqual(row["monitoring"]["mode"], "strict-exact-byte")
                self.assertTrue(row["monitoring"]["strict_exact_byte_recapture"])
                self.assertFalse(row["monitoring"]["semantic_change_claimed"])

    def test_strict_sources_are_only_the_current_document_like_surfaces(self) -> None:
        payload = build_readiness()
        self.assertEqual(
            set(payload["summary"]["strict_exact_byte_source_ids"]),
            {
                "ontario-health-physical-education-grades-1-8-2019",
                "ontario-mathematics-grades-1-8-2020",
                "ontario-fsl-grades-1-8-2013",
                "ontario-fr-english-grades-4-8-2006",
                "ontario-fr-english-beginners-grades-4-8-2013",
            },
        )

    def test_dcp_html_sources_remain_valid_c1_snapshots_but_observational(self) -> None:
        payload = build_readiness()
        observational = set(
            payload["summary"]["observational_response_surface_source_ids"]
        )
        self.assertEqual(
            observational,
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
        rows = {row["source_id"]: row for row in payload["sources"]}
        for source_id in observational:
            with self.subTest(source_id=source_id):
                self.assertEqual(
                    rows[source_id]["highest_evidenced_stage"],
                    "C1-bytes-captured-digested",
                )
                self.assertIsNotNone(rows[source_id]["c1_snapshot"])
                self.assertEqual(
                    rows[source_id]["monitoring"]["mode"],
                    "observational-response-surface",
                )
                self.assertFalse(
                    rows[source_id]["monitoring"]["strict_exact_byte_recapture"]
                )
                self.assertFalse(rows[source_id]["monitoring"]["semantic_change_claimed"])
                self.assertTrue(rows[source_id]["monitoring"]["promotion_blocker"])

    def test_uncaptured_discovered_sources_remain_explicit(self) -> None:
        payload = build_readiness()
        self.assertEqual(
            set(payload["summary"]["uncaptured_discovered_source_ids"]),
            {
                "ontario-fr-francais-grades-1-8-2023",
                "ontario-fr-mathematics-grades-1-8-2020",
                "ontario-fr-health-physical-education-grades-1-8-2019",
                "ontario-fr-arts-grades-1-8-2009",
            },
        )
        rows = {row["source_id"]: row for row in payload["sources"]}
        for source_id in payload["summary"]["uncaptured_discovered_source_ids"]:
            self.assertTrue(rows[source_id]["capture_target_registered"])

    def test_english_program_family_snapshot_coverage_is_eight_of_eight(self) -> None:
        payload = build_readiness()
        rows = payload["program_families"]["english_language_schools"]
        snapshot_families = {
            row["program_family"] for row in rows if row["c1_snapshot"]
        }
        strict_families = {
            row["program_family"] for row in rows if row["strict_exact_byte_recapture"]
        }
        self.assertEqual(
            snapshot_families,
            {
                "the-arts",
                "french-as-a-second-language",
                "language",
                "health-and-physical-education",
                "mathematics",
                "science-and-technology",
                "social-studies-grades-1-6",
                "history-and-geography-grades-7-8",
            },
        )
        self.assertEqual(
            strict_families,
            {
                "french-as-a-second-language",
                "health-and-physical-education",
                "mathematics",
            },
        )

    def test_french_language_program_stages_are_explicit(self) -> None:
        payload = build_readiness()
        rows = payload["program_families"]["french_language_schools"]
        self.assertEqual(len(rows), 8)
        by_family = {row["program_family"]: row for row in rows}
        c0_only = {
            family
            for family, row in by_family.items()
            if row["highest_evidenced_stage"] == "C0-discovered"
        }
        self.assertEqual(
            c0_only,
            {
                "the-arts",
                "french",
                "health-and-physical-education",
                "mathematics",
            },
        )
        c1 = {
            family
            for family, row in by_family.items()
            if row["highest_evidenced_stage"] == "C1-bytes-captured-digested"
        }
        self.assertEqual(
            c1,
            {
                "english",
                "science-and-technology",
                "social-studies-grades-1-6",
                "history-and-geography-grades-7-8",
            },
        )
        unresolved = {
            family
            for family, row in by_family.items()
            if row["highest_evidenced_stage"] == "unresolved"
        }
        self.assertEqual(unresolved, set())
        self.assertEqual(
            set(payload["summary"]["unresolved_french_program_families"]),
            unresolved,
        )
        self.assertEqual(
            by_family["english"]["source_id"],
            "ontario-fr-english-grades-4-8-2006",
        )
        self.assertEqual(
            by_family["english"]["highest_evidenced_stage"],
            "C1-bytes-captured-digested",
        )
        self.assertTrue(by_family["english"]["strict_exact_byte_recapture"])

    def test_c1_snapshots_preserve_no_bytes_and_review_required_licensing(self) -> None:
        payload = build_readiness()
        locked_rows = [
            row for row in payload["sources"] if row["c1_snapshot"] is not None
        ]
        self.assertEqual(len(locked_rows), 12)
        for row in locked_rows:
            self.assertFalse(row["c1_snapshot"]["bytes_retained"])
            self.assertEqual(
                row["c1_snapshot"]["redistribution_status"], "review-required"
            )
            self.assertEqual(len(row["c1_snapshot"]["sha256"]), 64)
            self.assertGreater(row["c1_snapshot"]["byte_length"], 0)

    def test_machine_view_cannot_relabel_observational_sources_as_strict(self) -> None:
        payload = build_readiness()
        mutated = copy.deepcopy(payload)
        mutated["summary"]["strict_exact_byte_monitored_sources"] = 12
        mutated["summary"]["observational_response_surface_sources"] = 0
        mutated["summary"]["all_c1_sources_strictly_recapturable"] = True
        with self.assertRaisesRegex(
            ElementaryReadinessError, "forbids claiming all C1 sources"
        ):
            verify_readiness(mutated)

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
