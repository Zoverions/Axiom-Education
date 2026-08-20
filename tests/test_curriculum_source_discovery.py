from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

from tools.curriculum_source_discovery import (
    DEFAULT_AMENDMENTS,
    DEFAULT_DISCOVERY,
    SourceDiscoveryError,
    apply_amendments,
    canonical_json_digest,
    load_base_discovery,
    load_effective_discovery,
)
from tools.curriculum_source_lock import find_source, verify_directory


class CurriculumSourceDiscoveryTests(unittest.TestCase):
    def amendments(self) -> dict[str, object]:
        return json.loads(DEFAULT_AMENDMENTS.read_text(encoding="utf-8"))

    def test_arts_amendment_is_bound_to_exact_historical_entry(self) -> None:
        base = load_base_discovery(DEFAULT_DISCOVERY)
        arts = find_source(base, "ontario-arts-grades-1-8-2009")
        self.assertEqual(
            canonical_json_digest(arts),
            "b945185ecfc1283adaf197e3c0e3d3e2062f771d2c09e5321eb08ea4b29946ff",
        )
        amendment = self.amendments()["amendments"][0]
        self.assertEqual(
            amendment["prior_source_entry_sha256"],
            canonical_json_digest(arts),
        )

    def test_kindergarten_amendment_is_bound_to_exact_historical_entry(self) -> None:
        base = load_base_discovery(DEFAULT_DISCOVERY)
        kindergarten = find_source(base, "ontario-kindergarten-2026")
        self.assertEqual(
            canonical_json_digest(kindergarten),
            "a59001b6d59c5511536f0419b04bf5b06da2566ee9ed2253de49a9769954b88d",
        )
        amendment = self.amendments()["amendments"][1]
        self.assertEqual(
            amendment["prior_source_entry_sha256"],
            canonical_json_digest(kindergarten),
        )

    def test_sshg_amendment_is_bound_to_exact_historical_entry(self) -> None:
        base = load_base_discovery(DEFAULT_DISCOVERY)
        sshg = find_source(base, "ontario-social-studies-history-geography")
        self.assertEqual(
            canonical_json_digest(sshg),
            "1259ce3379e69edae3d366e821794b912002efcc99017a39a27e3e8bef72888b",
        )
        amendment = self.amendments()["amendments"][2]
        self.assertEqual(
            amendment["prior_source_entry_sha256"],
            canonical_json_digest(sshg),
        )

    def test_effective_arts_source_adds_current_dcp_route_without_rewriting_base(self) -> None:
        base = load_base_discovery(DEFAULT_DISCOVERY)
        effective = load_effective_discovery(DEFAULT_DISCOVERY)
        base_arts = find_source(base, "ontario-arts-grades-1-8-2009")
        effective_arts = find_source(effective, "ontario-arts-grades-1-8-2009")

        self.assertEqual(
            base_arts["url"],
            "https://www.publications.gov.on.ca/the-arts-ontario-curriculum-grades-1-8",
        )
        self.assertEqual(
            effective_arts["url"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-arts",
        )
        self.assertEqual(
            effective_arts["publication_catalog_url"],
            "https://www.publications.gov.on.ca/the-arts-ontario-curriculum-grades-1-8",
        )
        self.assertEqual(effective_arts["policy_version"], "2009")
        self.assertEqual(effective_arts["grades"], [1, 2, 3, 4, 5, 6, 7, 8])
        self.assertEqual(
            canonical_json_digest(effective_arts),
            "b9e68fe1d34a8c8f3dc949a09f676e95dd083d61e720878b024638f713d43daa",
        )

    def test_effective_kindergarten_source_adds_current_dcp_route_without_rewriting_base(self) -> None:
        base = load_base_discovery(DEFAULT_DISCOVERY)
        effective = load_effective_discovery(DEFAULT_DISCOVERY)
        base_kindergarten = find_source(base, "ontario-kindergarten-2026")
        effective_kindergarten = find_source(effective, "ontario-kindergarten-2026")

        self.assertEqual(
            base_kindergarten["url"],
            "https://www.ontario.ca/page/kindergarten",
        )
        self.assertEqual(
            effective_kindergarten["url"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/kindergarten",
        )
        self.assertEqual(
            effective_kindergarten["overview_url"],
            "https://www.ontario.ca/page/kindergarten",
        )
        self.assertEqual(
            effective_kindergarten["publication_catalog_url"],
            "https://www.publications.gov.on.ca/CL34638",
        )
        self.assertEqual(effective_kindergarten["publication_number"], "CL34638")
        self.assertEqual(effective_kindergarten["policy_version"], "2026")
        self.assertEqual(effective_kindergarten["grades"], ["K1", "K2"])
        self.assertEqual(
            canonical_json_digest(effective_kindergarten),
            "2478300fca9258fd8c32d3605e3be6f2018254868b1e3821e8bafa18f68f7b07",
        )

    def test_effective_sshg_source_resolves_2018_lineage_and_2026_history_update(self) -> None:
        base = load_base_discovery(DEFAULT_DISCOVERY)
        effective = load_effective_discovery(DEFAULT_DISCOVERY)
        base_sshg = find_source(base, "ontario-social-studies-history-geography")
        effective_sshg = find_source(effective, "ontario-social-studies-history-geography")

        self.assertEqual(
            base_sshg["url"],
            "https://www.ontario.ca/page/indigenous-education-ontario",
        )
        self.assertEqual(
            effective_sshg["url"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-sshg",
        )
        self.assertEqual(effective_sshg["publication_number"], "233531")
        self.assertEqual(
            effective_sshg["policy_version"],
            "2018-revised-with-2026-history-updates",
        )
        self.assertEqual(effective_sshg["effective_context"], "2026-2027 school year")
        self.assertEqual(effective_sshg["grades"], [1, 2, 3, 4, 5, 6, 7, 8])
        self.assertEqual(
            canonical_json_digest(effective_sshg),
            "4fe7e3c26d685d61e576d108d9339858fdebc58c6aed1c8666c268f10bf71935",
        )

    def test_current_source_locks_verify_against_composed_discovery(self) -> None:
        base = load_base_discovery(DEFAULT_DISCOVERY)
        effective = load_effective_discovery(DEFAULT_DISCOVERY)
        for source_id in (
            "ontario-health-physical-education-grades-1-8-2019",
            "ontario-mathematics-grades-1-8-2020",
            "ontario-language-grades-1-8-2023",
            "ontario-science-technology-grades-1-8-2022",
            "ontario-fsl-grades-1-8-2013",
        ):
            with self.subTest(source_id=source_id):
                self.assertEqual(
                    canonical_json_digest(find_source(base, source_id)),
                    canonical_json_digest(find_source(effective, source_id)),
                )
        self.assertEqual(
            verify_directory(
                DEFAULT_DISCOVERY.parent / "source-locks",
                DEFAULT_DISCOVERY,
                allow_empty=False,
            ),
            11,
        )

    def test_prior_digest_mismatch_rejects_amendment(self) -> None:
        amendments = self.amendments()
        amendments["amendments"][0]["prior_source_entry_sha256"] = "0" * 64
        with self.assertRaisesRegex(SourceDiscoveryError, "prior source digest mismatch"):
            apply_amendments(load_base_discovery(DEFAULT_DISCOVERY), amendments)

    def test_amendment_cannot_change_source_identity_or_scope(self) -> None:
        for field, value, message in (
            ("source_id", "ontario-other", "cannot change source_id"),
            ("grades", [1], "cannot silently change grade scope"),
            ("subject_family", "other", "cannot change subject family"),
        ):
            with self.subTest(field=field):
                amendments = self.amendments()
                amendments["amendments"][0]["set"][field] = value
                with self.assertRaisesRegex(SourceDiscoveryError, message):
                    apply_amendments(load_base_discovery(DEFAULT_DISCOVERY), amendments)

    def test_duplicate_amendment_id_is_rejected(self) -> None:
        amendments = self.amendments()
        amendments["amendments"].append(copy.deepcopy(amendments["amendments"][0]))
        with self.assertRaisesRegex(SourceDiscoveryError, "duplicate amendment_id"):
            apply_amendments(load_base_discovery(DEFAULT_DISCOVERY), amendments)

    def test_custom_discovery_does_not_implicitly_inherit_ontario_amendments(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "discovery.json"
            path.write_text(
                DEFAULT_DISCOVERY.read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            custom = load_effective_discovery(path)
            arts = find_source(custom, "ontario-arts-grades-1-8-2009")
            self.assertEqual(
                arts["url"],
                "https://www.publications.gov.on.ca/the-arts-ontario-curriculum-grades-1-8",
            )
            kindergarten = find_source(custom, "ontario-kindergarten-2026")
            self.assertEqual(
                kindergarten["url"],
                "https://www.ontario.ca/page/kindergarten",
            )
            sshg = find_source(custom, "ontario-social-studies-history-geography")
            self.assertEqual(
                sshg["url"],
                "https://www.ontario.ca/page/indigenous-education-ontario",
            )


if __name__ == "__main__":
    unittest.main()
