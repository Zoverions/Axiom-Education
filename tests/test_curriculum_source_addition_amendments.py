from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

from tools.curriculum_source_addition_amendments import (
    DEFAULT_ADDITION_AMENDMENTS,
    DEFAULT_ADDITIONS,
    DEFAULT_DISCOVERY,
    SourceAdditionAmendmentError,
    apply_addition_amendments,
    canonical_json_digest,
    load_composed_discovery,
    verify_addition_amendments,
)
from tools.curriculum_source_additions import load_augmented_discovery


EXPECTED_ROUTES = {
    "ontario-fr-francais-grades-1-8-2023": (
        "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-francais"
    ),
    "ontario-fr-mathematics-grades-1-8-2020": (
        "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-mathematiques"
    ),
    "ontario-fr-health-physical-education-grades-1-8-2019": (
        "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-education-physique-sante"
    ),
    "ontario-fr-arts-grades-1-8-2009": (
        "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-education-artistique"
    ),
}


class CurriculumSourceAdditionAmendmentTests(unittest.TestCase):
    def amendments(self) -> dict[str, object]:
        return json.loads(DEFAULT_ADDITION_AMENDMENTS.read_text(encoding="utf-8"))

    def write_amendments(self, payload: dict[str, object]) -> Path:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "addition-amendments.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    @staticmethod
    def source_index(discovery: dict[str, object]) -> dict[str, dict[str, object]]:
        rows = discovery["confirmed_curriculum_sources"]
        if not isinstance(rows, list):
            raise AssertionError("confirmed curriculum sources must be a list")
        return {
            row["source_id"]: row
            for row in rows
            if isinstance(row, dict) and isinstance(row.get("source_id"), str)
        }

    def test_current_amendments_resolve_four_added_sources_without_adding_ids(self) -> None:
        self.assertEqual(
            verify_addition_amendments(),
            {
                "effective_sources": 16,
                "addition_amendments": 4,
                "amended_sources_with_exact_dcp_route": 4,
            },
        )
        raw = self.source_index(load_augmented_discovery())
        composed = self.source_index(load_composed_discovery())
        self.assertEqual(set(raw), set(composed))
        for source_id, route in EXPECTED_ROUTES.items():
            with self.subTest(source_id=source_id):
                self.assertNotEqual(raw[source_id]["url"], route)
                self.assertEqual(composed[source_id]["url"], route)
                self.assertEqual(
                    composed[source_id]["classification"],
                    "official-current-curriculum-portal",
                )
                self.assertIsNone(composed[source_id]["upstream_document_sha256"])
                self.assertEqual(
                    composed[source_id]["upstream_digest_status"],
                    "not-captured",
                )

    def test_original_addition_source_digests_are_pinned_before_amendment(self) -> None:
        raw = self.source_index(load_augmented_discovery())
        expected = {
            "ontario-fr-francais-grades-1-8-2023": "4aee64a86f3d01539f33421a76ab750652f0633ddff632ac6096a00c7966282d",
            "ontario-fr-mathematics-grades-1-8-2020": "bbc4e1bac625c4f1bd2afe0977be1707bdc6aa23d3463224069d59d549b8cd98",
            "ontario-fr-health-physical-education-grades-1-8-2019": "0ddb1fad1793c3fec097da15e7cfad32e459674ee27f5018b1bcdc32666cc9ed",
            "ontario-fr-arts-grades-1-8-2009": "2b7265f6c6f0395c03e35b49636156f4e6c06c112de6c34168e7a6fcb14fc645",
        }
        for source_id, digest in expected.items():
            with self.subTest(source_id=source_id):
                self.assertEqual(canonical_json_digest(raw[source_id]), digest)

    def test_publication_identity_is_preserved_across_route_resolution(self) -> None:
        raw = self.source_index(load_augmented_discovery())
        composed = self.source_index(load_composed_discovery())
        for source_id in EXPECTED_ROUTES:
            with self.subTest(source_id=source_id):
                self.assertEqual(
                    composed[source_id].get("publication_catalog_url"),
                    raw[source_id].get("publication_catalog_url"),
                )
                self.assertEqual(
                    composed[source_id].get("publication_number"),
                    raw[source_id].get("publication_number"),
                )
                self.assertEqual(composed[source_id]["grades"], raw[source_id]["grades"])
                self.assertEqual(
                    composed[source_id]["policy_version"],
                    raw[source_id]["policy_version"],
                )

    def test_prior_digest_mismatch_is_rejected(self) -> None:
        payload = self.amendments()
        payload["amendments"][0]["prior_source_entry_sha256"] = "0" * 64
        path = self.write_amendments(payload)
        with self.assertRaisesRegex(SourceAdditionAmendmentError, "prior source digest mismatch"):
            load_composed_discovery(DEFAULT_DISCOVERY, DEFAULT_ADDITIONS, path)

    def test_amendment_cannot_change_identity_scope_or_publication_lineage(self) -> None:
        for field, value in (
            ("source_id", "other"),
            ("subject_family", "other"),
            ("grades", [1]),
            ("policy_version", "other"),
            ("publication_number", "other"),
            ("publication_catalog_url", "https://www.publications.gov.on.ca/other"),
        ):
            with self.subTest(field=field):
                payload = self.amendments()
                payload["amendments"][0]["set"][field] = value
                path = self.write_amendments(payload)
                with self.assertRaisesRegex(SourceAdditionAmendmentError, "cannot change immutable source fields"):
                    load_composed_discovery(DEFAULT_DISCOVERY, DEFAULT_ADDITIONS, path)

    def test_amended_route_must_be_exact_french_dcp_curriculum_route(self) -> None:
        payload = self.amendments()
        payload["amendments"][0]["set"]["url"] = (
            "https://www.dcp.edu.gov.on.ca/resources/fr/matiere/francais"
        )
        payload["amendments"][0]["evidence"][0]["url"] = (
            "https://www.dcp.edu.gov.on.ca/resources/fr/matiere/francais"
        )
        path = self.write_amendments(payload)
        with self.assertRaisesRegex(SourceAdditionAmendmentError, "exact French Ontario curriculum route"):
            load_composed_discovery(DEFAULT_DISCOVERY, DEFAULT_ADDITIONS, path)

    def test_amended_route_and_preserved_publication_must_both_be_evidence(self) -> None:
        for remove_index, message in (
            (0, "amended DCP route must be present"),
            (1, "preserved publication provenance must remain present"),
        ):
            with self.subTest(remove_index=remove_index):
                payload = self.amendments()
                payload["amendments"][0]["evidence"].pop(remove_index)
                path = self.write_amendments(payload)
                with self.assertRaisesRegex(SourceAdditionAmendmentError, message):
                    load_composed_discovery(DEFAULT_DISCOVERY, DEFAULT_ADDITIONS, path)

    def test_c0_amendment_cannot_claim_digest(self) -> None:
        payload = self.amendments()
        payload["amendments"][0]["set"]["upstream_document_sha256"] = "0" * 64
        payload["amendments"][0]["set"]["upstream_digest_status"] = "captured"
        path = self.write_amendments(payload)
        with self.assertRaisesRegex(SourceAdditionAmendmentError, "cannot claim an upstream digest"):
            load_composed_discovery(DEFAULT_DISCOVERY, DEFAULT_ADDITIONS, path)

    def test_historical_source_id_cannot_use_addition_amendment_layer(self) -> None:
        payload = self.amendments()
        payload["amendments"][0]["source_id"] = "ontario-language-grades-1-8-2023"
        path = self.write_amendments(payload)
        with self.assertRaisesRegex(SourceAdditionAmendmentError, "only source IDs introduced by the additions ledger"):
            load_composed_discovery(DEFAULT_DISCOVERY, DEFAULT_ADDITIONS, path)

    def test_custom_discovery_does_not_inherit_ontario_additions_or_amendments(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            custom_path = Path(directory) / "discovery.json"
            custom_path.write_text(DEFAULT_DISCOVERY.read_text(encoding="utf-8"), encoding="utf-8")
            composed = load_composed_discovery(custom_path)
            self.assertEqual(len(composed["confirmed_curriculum_sources"]), 8)


if __name__ == "__main__":
    unittest.main()
