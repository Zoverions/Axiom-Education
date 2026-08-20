from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

from tools.curriculum_source_additions import (
    DEFAULT_ADDITIONS,
    DEFAULT_DISCOVERY,
    SourceAdditionError,
    apply_additions,
    load_augmented_discovery,
    verify_additions,
)
from tools.curriculum_source_discovery import load_effective_discovery


class CurriculumSourceAdditionTests(unittest.TestCase):
    def additions(self) -> dict[str, object]:
        return json.loads(DEFAULT_ADDITIONS.read_text(encoding="utf-8"))

    def write_additions(self, payload: dict[str, object]) -> Path:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "additions.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    @staticmethod
    def addition_by_source(
        payload: dict[str, object],
        source_id: str,
    ) -> dict[str, object]:
        rows = payload["additions"]
        if not isinstance(rows, list):
            raise AssertionError("additions must be a list")
        for row in rows:
            if (
                isinstance(row, dict)
                and isinstance(row.get("source"), dict)
                and row["source"].get("source_id") == source_id
            ):
                return row
        raise AssertionError(f"missing source addition: {source_id}")

    def test_current_additions_resolve_all_eight_french_program_families(self) -> None:
        result = verify_additions()
        self.assertEqual(
            result,
            {
                "effective_sources_before_additions": 8,
                "appended_c0_sources": 8,
                "effective_sources_after_additions": 16,
                "french_program_families_with_c0_source": 8,
            },
        )

        augmented = load_augmented_discovery()
        source_ids = {
            row["source_id"] for row in augmented["confirmed_curriculum_sources"]
        }
        self.assertTrue(
            {
                "ontario-fr-francais-grades-1-8-2023",
                "ontario-fr-mathematics-grades-1-8-2020",
                "ontario-fr-health-physical-education-grades-1-8-2019",
                "ontario-fr-arts-grades-1-8-2009",
                "ontario-fr-science-technology-grades-1-8-2022",
                "ontario-fr-social-studies-history-geography",
                "ontario-fr-english-grades-4-8-2006",
                "ontario-fr-english-beginners-grades-4-8-2013",
            }.issubset(source_ids)
        )

        french = augmented["coverage_accounting"]["french_language_schools"]
        expected_bindings = {
            "french": "ontario-fr-francais-grades-1-8-2023",
            "mathematics": "ontario-fr-mathematics-grades-1-8-2020",
            "health-and-physical-education": (
                "ontario-fr-health-physical-education-grades-1-8-2019"
            ),
            "the-arts": "ontario-fr-arts-grades-1-8-2009",
            "science-and-technology": "ontario-fr-science-technology-grades-1-8-2022",
            "social-studies-grades-1-6": "ontario-fr-social-studies-history-geography",
            "history-and-geography-grades-7-8": (
                "ontario-fr-social-studies-history-geography"
            ),
        }
        for family, source_id in expected_bindings.items():
            with self.subTest(family=family):
                self.assertEqual(french[family]["source_id"], source_id)
                self.assertEqual(french[family]["status"], "source-discovered")

        english = french["english"]
        self.assertEqual(english["status"], "source-discovered")
        self.assertEqual(
            english["source_id"],
            "ontario-fr-english-grades-4-8-2006",
        )
        self.assertEqual(english["applies_to_grades"], [4, 5, 6, 7, 8])
        self.assertEqual(
            english["coverage_mode"],
            "primary-with-conditional-alternatives",
        )
        self.assertEqual(
            english["conditional_sources"],
            [
                {
                    "source_id": "ontario-fr-english-beginners-grades-4-8-2013",
                    "condition": (
                        "For students in French-language elementary schools who are "
                        "not yet able to follow the regular Anglais program."
                    ),
                    "applies_to_grades": [4, 5, 6, 7, 8],
                }
            ],
        )

    def test_historical_and_amended_sources_are_not_rewritten(self) -> None:
        effective = load_effective_discovery(DEFAULT_DISCOVERY)
        augmented = load_augmented_discovery(DEFAULT_DISCOVERY)
        before = {
            row["source_id"]: row for row in effective["confirmed_curriculum_sources"]
        }
        after = {
            row["source_id"]: row for row in augmented["confirmed_curriculum_sources"]
        }
        self.assertEqual(set(before), set(after).intersection(before))
        for source_id, source in before.items():
            with self.subTest(source_id=source_id):
                self.assertEqual(source, after[source_id])
        self.assertEqual(
            effective["coverage_accounting"]["english_language_schools"],
            augmented["coverage_accounting"]["english_language_schools"],
        )

    def test_existing_source_id_must_use_amendment_chain(self) -> None:
        additions = self.additions()
        additions["additions"][0]["source"]["source_id"] = (
            "ontario-language-grades-1-8-2023"
        )
        path = self.write_additions(additions)
        with self.assertRaisesRegex(SourceAdditionError, "must use the amendment chain"):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_addition_cannot_overwrite_existing_english_program_binding(self) -> None:
        additions = self.additions()
        additions["additions"][0]["coverage_bindings"][0] = {
            "stream": "english_language_schools",
            "program_family": "language",
            "status": "source-discovered",
        }
        path = self.write_additions(additions)
        with self.assertRaisesRegex(SourceAdditionError, "cannot be overwritten"):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_addition_cannot_bind_non_required_program_family(self) -> None:
        additions = self.additions()
        additions["additions"][0]["coverage_bindings"][0]["program_family"] = (
            "not-a-program"
        )
        path = self.write_additions(additions)
        with self.assertRaisesRegex(SourceAdditionError, "not a required program family"):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_duplicate_addition_id_is_rejected(self) -> None:
        additions = self.additions()
        additions["additions"].append(copy.deepcopy(additions["additions"][0]))
        path = self.write_additions(additions)
        with self.assertRaisesRegex(SourceAdditionError, "duplicate addition_id"):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_c0_addition_cannot_claim_upstream_digest(self) -> None:
        additions = self.additions()
        additions["additions"][0]["source"]["upstream_document_sha256"] = "0" * 64
        additions["additions"][0]["source"]["upstream_digest_status"] = "captured"
        path = self.write_additions(additions)
        with self.assertRaisesRegex(SourceAdditionError, "cannot claim an upstream digest"):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_publication_backed_addition_requires_publications_ontario(self) -> None:
        additions = self.additions()
        additions["additions"][0]["source"]["publication_catalog_url"] = (
            "https://example.invalid/CL33252"
        )
        path = self.write_additions(additions)
        with self.assertRaisesRegex(SourceAdditionError, "must use Publications Ontario"):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_dcp_only_addition_requires_exact_french_curriculum_route(self) -> None:
        additions = self.additions()
        row = self.addition_by_source(
            additions,
            "ontario-fr-science-technology-grades-1-8-2022",
        )
        row["source"]["url"] = (
            "https://www.dcp.edu.gov.on.ca/resources/fr/matiere/sciences-techno"
        )
        row["evidence"][0]["url"] = row["source"]["url"]
        path = self.write_additions(additions)
        with self.assertRaisesRegex(
            SourceAdditionError,
            "French Ontario curriculum route",
        ):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_source_without_publication_requires_supported_official_classification(self) -> None:
        additions = self.additions()
        row = self.addition_by_source(
            additions,
            "ontario-fr-science-technology-grades-1-8-2022",
        )
        row["source"]["classification"] = "official-current-overview"
        path = self.write_additions(additions)
        with self.assertRaisesRegex(
            SourceAdditionError,
            "official DCP route or Ministry curriculum PDF",
        ):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_dcp_only_addition_requires_exact_route_in_evidence(self) -> None:
        additions = self.additions()
        row = self.addition_by_source(
            additions,
            "ontario-fr-social-studies-history-geography",
        )
        row["evidence"][0]["url"] = (
            "https://www.dcp.edu.gov.on.ca/fr/curriculum/sciences-technologie"
        )
        path = self.write_additions(additions)
        with self.assertRaisesRegex(
            SourceAdditionError,
            "exact official curriculum route must be present",
        ):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_ministry_pdf_addition_requires_french_elementary_ministry_path(self) -> None:
        additions = self.additions()
        row = self.addition_by_source(
            additions,
            "ontario-fr-english-grades-4-8-2006",
        )
        row["source"]["url"] = "https://www.edu.gov.on.ca/eng/curriculum/other.pdf"
        row["evidence"][0]["url"] = row["source"]["url"]
        path = self.write_additions(additions)
        with self.assertRaisesRegex(
            SourceAdditionError,
            "French elementary Ministry PDF",
        ):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_conditional_source_requires_primary_binding_first(self) -> None:
        additions = self.additions()
        rows = additions["additions"]
        regular_index = next(
            index
            for index, row in enumerate(rows)
            if row["source"]["source_id"] == "ontario-fr-english-grades-4-8-2006"
        )
        beginner_index = next(
            index
            for index, row in enumerate(rows)
            if row["source"]["source_id"]
            == "ontario-fr-english-beginners-grades-4-8-2013"
        )
        rows[regular_index], rows[beginner_index] = rows[beginner_index], rows[regular_index]
        path = self.write_additions(additions)
        with self.assertRaisesRegex(
            SourceAdditionError,
            "requires a primary source binding first",
        ):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_conditional_source_requires_condition(self) -> None:
        additions = self.additions()
        row = self.addition_by_source(
            additions,
            "ontario-fr-english-beginners-grades-4-8-2013",
        )
        row["coverage_bindings"][0].pop("condition")
        path = self.write_additions(additions)
        with self.assertRaisesRegex(SourceAdditionError, "requires a condition"):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_conditional_source_grade_scope_must_fit_its_source(self) -> None:
        additions = self.additions()
        row = self.addition_by_source(
            additions,
            "ontario-fr-english-beginners-grades-4-8-2013",
        )
        row["coverage_bindings"][0]["applies_to_grades"] = [3, 4, 5, 6, 7, 8]
        path = self.write_additions(additions)
        with self.assertRaisesRegex(SourceAdditionError, "grade outside source scope"):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_duplicate_conditional_source_binding_is_rejected(self) -> None:
        additions = self.additions()
        row = self.addition_by_source(
            additions,
            "ontario-fr-english-beginners-grades-4-8-2013",
        )
        row["coverage_bindings"].append(copy.deepcopy(row["coverage_bindings"][0]))
        path = self.write_additions(additions)
        with self.assertRaisesRegex(
            SourceAdditionError,
            "duplicate conditional source-addition coverage binding",
        ):
            load_augmented_discovery(DEFAULT_DISCOVERY, path)

    def test_custom_discovery_does_not_implicitly_inherit_default_additions(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            custom_path = Path(directory) / "discovery.json"
            custom_path.write_text(
                DEFAULT_DISCOVERY.read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            custom = load_augmented_discovery(custom_path)
            self.assertEqual(len(custom["confirmed_curriculum_sources"]), 8)
            french = custom["coverage_accounting"]["french_language_schools"]
            self.assertTrue(all(row.get("source_id") is None for row in french.values()))

    def test_apply_additions_requires_matching_jurisdiction(self) -> None:
        additions = self.additions()
        additions["jurisdiction_id"] = "ca:xx"
        with self.assertRaisesRegex(SourceAdditionError, "jurisdiction mismatch"):
            apply_additions(load_effective_discovery(DEFAULT_DISCOVERY), additions)


if __name__ == "__main__":
    unittest.main()
