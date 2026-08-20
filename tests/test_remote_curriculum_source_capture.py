from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.remote_curriculum_source_capture import (
    RemoteCaptureError,
    TARGETS_PATH,
    validate_target_registry,
)


class RemoteCurriculumSourceCaptureTests(unittest.TestCase):
    def mutation(self, mutate) -> Path:
        payload = json.loads(TARGETS_PATH.read_text(encoding="utf-8"))
        mutate(payload)
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "targets.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    @staticmethod
    def target(payload: dict[str, object], source_id: str) -> dict[str, object]:
        targets = payload["targets"]
        if not isinstance(targets, list):
            raise AssertionError("capture targets must be a list")
        for target in targets:
            if isinstance(target, dict) and target.get("source_id") == source_id:
                return target
        raise AssertionError(f"missing target: {source_id}")

    def test_current_target_registry_is_bounded(self):
        targets = validate_target_registry()
        self.assertEqual(
            set(targets),
            {
                "ontario-kindergarten-2026",
                "ontario-health-physical-education-grades-1-8-2019",
                "ontario-mathematics-grades-1-8-2020",
                "ontario-language-grades-1-8-2023",
                "ontario-science-technology-grades-1-8-2022",
                "ontario-fsl-grades-1-8-2013",
                "ontario-arts-grades-1-8-2009",
                "ontario-social-studies-history-geography",
                "ontario-fr-science-technology-grades-1-8-2022",
                "ontario-fr-social-studies-history-geography",
                "ontario-fr-english-grades-4-8-2006",
                "ontario-fr-english-beginners-grades-4-8-2013",
                "ontario-fr-francais-grades-1-8-2023",
                "ontario-fr-mathematics-grades-1-8-2020",
                "ontario-fr-health-physical-education-grades-1-8-2019",
                "ontario-fr-arts-grades-1-8-2009",
            },
        )
        kindergarten = targets["ontario-kindergarten-2026"]
        hpe = targets["ontario-health-physical-education-grades-1-8-2019"]
        math = targets["ontario-mathematics-grades-1-8-2020"]
        language = targets["ontario-language-grades-1-8-2023"]
        science = targets["ontario-science-technology-grades-1-8-2022"]
        fsl = targets["ontario-fsl-grades-1-8-2013"]
        arts = targets["ontario-arts-grades-1-8-2009"]
        sshg = targets["ontario-social-studies-history-geography"]
        fr_science = targets["ontario-fr-science-technology-grades-1-8-2022"]
        fr_sshg = targets["ontario-fr-social-studies-history-geography"]
        fr_english = targets["ontario-fr-english-grades-4-8-2006"]
        fr_english_beginners = targets[
            "ontario-fr-english-beginners-grades-4-8-2013"
        ]
        pending_french = {
            "ontario-fr-francais-grades-1-8-2023": (
                "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-francais",
                "CL33252",
            ),
            "ontario-fr-mathematics-grades-1-8-2020": (
                "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-mathematiques",
                "CL32239",
            ),
            "ontario-fr-health-physical-education-grades-1-8-2019": (
                "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-education-physique-sante",
                "022579",
            ),
            "ontario-fr-arts-grades-1-8-2009": (
                "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-education-artistique",
                "231943_U",
            ),
        }
        self.assertEqual(kindergarten["publication_number"], "CL34638")
        self.assertEqual(kindergarten["host_policy"], "ontario-government")
        self.assertEqual(kindergarten["expected_media_type"], "text/html")
        self.assertEqual(
            kindergarten["source_locator"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/kindergarten",
        )
        self.assertEqual(
            kindergarten["source_resolution_status"],
            "official-current-structured-source-resolved",
        )
        self.assertEqual(hpe["host_policy"], "ontario-government")
        self.assertEqual(hpe["allowed_hosts"], ["www.edu.gov.on.ca"])
        self.assertEqual(math["host_policy"], "publications-ontario-access-cdn")
        self.assertEqual(math["allowed_hosts"], ["assets-us-01.kc-usercontent.com"])
        self.assertEqual(math["publication_number"], "CL32210")
        self.assertEqual(language["expected_media_type"], "text/html")
        self.assertEqual(language["allowed_hosts"], ["www.dcp.edu.gov.on.ca"])
        self.assertEqual(science["expected_media_type"], "text/html")
        self.assertEqual(science["allowed_hosts"], ["www.dcp.edu.gov.on.ca"])
        self.assertEqual(fsl["expected_media_type"], "application/pdf")
        self.assertEqual(fsl["publication_number"], "232944")
        self.assertEqual(arts["host_policy"], "ontario-government")
        self.assertEqual(arts["expected_media_type"], "text/html")
        self.assertEqual(
            arts["source_locator"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-arts",
        )
        self.assertEqual(
            arts["source_resolution_status"],
            "official-current-structured-source-resolved",
        )
        self.assertEqual(sshg["host_policy"], "ontario-government")
        self.assertEqual(sshg["expected_media_type"], "text/html")
        self.assertEqual(
            sshg["source_locator"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-sshg",
        )
        self.assertEqual(
            sshg["source_resolution_status"],
            "official-current-structured-source-resolved",
        )
        self.assertEqual(sshg["publication_number"], "233531")
        self.assertEqual(
            sshg["publication_catalog_url"],
            "https://www.publications.gov.on.ca/the-ontario-curriculum-social-studies-grades-1-6-history-and-geography-grades-7-8-2015-revised",
        )
        self.assertEqual(
            fr_science["source_locator"],
            "https://www.dcp.edu.gov.on.ca/fr/curriculum/sciences-technologie",
        )
        self.assertEqual(fr_science["download_url"], fr_science["source_locator"])
        self.assertNotIn("publication_catalog_url", fr_science)
        self.assertNotIn("publication_number", fr_science)
        self.assertEqual(
            fr_science["source_resolution_status"],
            "official-current-structured-source-resolved",
        )
        self.assertEqual(
            fr_sshg["source_locator"],
            "https://www.dcp.edu.gov.on.ca/fr/curriculum/etudes-sociales-histoire-geo",
        )
        self.assertEqual(fr_sshg["download_url"], fr_sshg["source_locator"])
        self.assertNotIn("publication_catalog_url", fr_sshg)
        self.assertNotIn("publication_number", fr_sshg)
        self.assertEqual(
            fr_sshg["source_resolution_status"],
            "official-current-structured-source-resolved",
        )
        self.assertEqual(
            fr_english["source_locator"],
            "https://www.edu.gov.on.ca/fre/curriculum/elementary/anglais48currb.pdf",
        )
        self.assertEqual(fr_english["download_url"], fr_english["source_locator"])
        self.assertEqual(fr_english["expected_media_type"], "application/pdf")
        self.assertNotIn("publication_catalog_url", fr_english)
        self.assertNotIn("publication_number", fr_english)
        self.assertEqual(
            fr_english_beginners["source_locator"],
            "https://www.edu.gov.on.ca/fre/curriculum/elementary/anglaispd48curr2013.pdf",
        )
        self.assertEqual(fr_english_beginners["publication_number"], "232897_U")
        self.assertEqual(fr_english_beginners["expected_media_type"], "application/pdf")
        for source_id, (route, publication_number) in pending_french.items():
            with self.subTest(source_id=source_id):
                target = targets[source_id]
                self.assertEqual(target["source_locator"], route)
                self.assertEqual(target["download_url"], route)
                self.assertEqual(target["publication_number"], publication_number)
                self.assertEqual(target["host_policy"], "ontario-government")
                self.assertEqual(target["expected_media_type"], "text/html")
                self.assertEqual(
                    target["source_resolution_status"],
                    "official-current-structured-source-resolved-pending-c1",
                )
        self.assertTrue(
            all(
                target["redistribution_status"] == "review-required"
                for target in targets.values()
            )
        )

    def test_arbitrary_non_government_host_is_rejected_under_government_policy(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-health-physical-education-grades-1-8-2019",
            ).update(
                {
                    "download_url": "https://example.com/curriculum.pdf",
                    "allowed_hosts": ["example.com"],
                }
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "non-Ontario-government host"):
            validate_target_registry(path)

    def test_publication_cdn_policy_rejects_unapproved_cdn(self):
        def mutate(payload):
            self.target(payload, "ontario-mathematics-grades-1-8-2020").update(
                {
                    "download_url": "https://example.com/curriculum.pdf",
                    "allowed_hosts": ["example.com"],
                }
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "not explicitly approved"):
            validate_target_registry(path)

    def test_publication_cdn_requires_publications_ontario_provenance(self):
        def mutate(payload):
            self.target(payload, "ontario-mathematics-grades-1-8-2020").update(
                {"publication_catalog_url": "https://example.com/CL32210"}
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "must be Publications Ontario"):
            validate_target_registry(path)

    def test_publication_number_must_match_catalog_url(self):
        def mutate(payload):
            self.target(payload, "ontario-mathematics-grades-1-8-2020").update(
                {"publication_number": "WRONG"}
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(
            RemoteCaptureError,
            "bound into the Publications Ontario URL",
        ):
            validate_target_registry(path)

    def test_non_numbered_publication_url_requires_exact_effective_discovery_binding(self):
        targets = validate_target_registry()
        sshg = targets["ontario-social-studies-history-geography"]
        self.assertEqual(sshg["publication_number"], "233531")

        def wrong_number(payload):
            self.target(payload, "ontario-social-studies-history-geography").update(
                {"publication_number": "233532"}
            )

        path = self.mutation(wrong_number)
        with self.assertRaisesRegex(
            RemoteCaptureError,
            "exactly match effective discovery provenance",
        ):
            validate_target_registry(path)

        def wrong_catalog(payload):
            self.target(payload, "ontario-social-studies-history-geography").update(
                {
                    "publication_catalog_url": "https://www.publications.gov.on.ca/the-ontario-curriculum-social-studies-grades-1-6-history-and-geography-grades-7-8"
                }
            )

        path = self.mutation(wrong_catalog)
        with self.assertRaisesRegex(
            RemoteCaptureError,
            "exactly match effective discovery provenance",
        ):
            validate_target_registry(path)

    def test_dcp_structured_source_remains_under_government_host_policy(self):
        def mutate(payload):
            self.target(payload, "ontario-language-grades-1-8-2023").update(
                {
                    "download_url": "https://example.com/language",
                    "allowed_hosts": ["example.com"],
                }
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "non-Ontario-government host"):
            validate_target_registry(path)

    def test_french_dcp_only_target_requires_exact_admitted_route(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-fr-science-technology-grades-1-8-2022",
            ).update(
                {
                    "download_url": "https://www.dcp.edu.gov.on.ca/fr/curriculum/other"
                }
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(
            RemoteCaptureError,
            "bind source_locator and download_url exactly",
        ):
            validate_target_registry(path)

    def test_french_dcp_only_target_cannot_invent_publication_provenance(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-fr-social-studies-history-geography",
            ).update(
                {
                    "publication_catalog_url": "https://www.publications.gov.on.ca/fabricated",
                    "publication_number": "fabricated",
                }
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(
            RemoteCaptureError,
            "cannot acquire publication metadata",
        ):
            validate_target_registry(path)

    def test_french_ministry_pdf_target_requires_exact_admitted_pdf(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-fr-english-grades-4-8-2006",
            ).update(
                {
                    "download_url": "https://www.edu.gov.on.ca/fre/curriculum/elementary/other.pdf"
                }
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(
            RemoteCaptureError,
            "bind source_locator and download_url exactly",
        ):
            validate_target_registry(path)

    def test_french_ministry_pdf_target_requires_pdf_media_type(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-fr-english-grades-4-8-2006",
            ).update({"expected_media_type": "text/html"})

        path = self.mutation(mutate)
        with self.assertRaisesRegex(
            RemoteCaptureError,
            "must require application/pdf",
        ):
            validate_target_registry(path)

    def test_french_ministry_pdf_target_cannot_invent_publication_provenance(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-fr-english-grades-4-8-2006",
            ).update(
                {
                    "publication_catalog_url": "https://www.publications.gov.on.ca/fabricated",
                    "publication_number": "fabricated",
                }
            )

        path = self.mutation(mutate)
        with self.assertRaisesRegex(
            RemoteCaptureError,
            "Ministry-PDF-only C0 provenance cannot acquire publication metadata",
        ):
            validate_target_registry(path)

    def test_source_locator_must_already_exist_in_effective_discovery(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-health-physical-education-grades-1-8-2019",
            ).update({"source_locator": "https://www.ontario.ca/not-recorded"})

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "recorded in C0 discovery"):
            validate_target_registry(path)

    def test_arts_locator_is_resolved_by_append_only_discovery_amendment(self):
        targets = validate_target_registry()
        arts = targets["ontario-arts-grades-1-8-2009"]
        self.assertEqual(
            arts["download_url"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-arts",
        )

    def test_kindergarten_locator_is_resolved_by_append_only_discovery_amendment(self):
        targets = validate_target_registry()
        kindergarten = targets["ontario-kindergarten-2026"]
        self.assertEqual(
            kindergarten["download_url"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/kindergarten",
        )
        self.assertEqual(
            kindergarten["publication_catalog_url"],
            "https://www.publications.gov.on.ca/CL34638",
        )

    def test_sshg_locator_is_resolved_by_append_only_discovery_amendment(self):
        targets = validate_target_registry()
        sshg = targets["ontario-social-studies-history-geography"]
        self.assertEqual(
            sshg["download_url"],
            "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-sshg",
        )
        self.assertEqual(sshg["publication_number"], "233531")

    def test_french_locators_are_resolved_by_append_only_source_layers(self):
        targets = validate_target_registry()
        expected = {
            "ontario-fr-science-technology-grades-1-8-2022": "https://www.dcp.edu.gov.on.ca/fr/curriculum/sciences-technologie",
            "ontario-fr-social-studies-history-geography": "https://www.dcp.edu.gov.on.ca/fr/curriculum/etudes-sociales-histoire-geo",
            "ontario-fr-english-grades-4-8-2006": "https://www.edu.gov.on.ca/fre/curriculum/elementary/anglais48currb.pdf",
            "ontario-fr-english-beginners-grades-4-8-2013": "https://www.edu.gov.on.ca/fre/curriculum/elementary/anglaispd48curr2013.pdf",
            "ontario-fr-francais-grades-1-8-2023": "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-francais",
            "ontario-fr-mathematics-grades-1-8-2020": "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-mathematiques",
            "ontario-fr-health-physical-education-grades-1-8-2019": "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-education-physique-sante",
            "ontario-fr-arts-grades-1-8-2009": "https://www.dcp.edu.gov.on.ca/fr/curriculum/elementaire-education-artistique",
        }
        for source_id, locator in expected.items():
            with self.subTest(source_id=source_id):
                self.assertEqual(targets[source_id]["source_locator"], locator)

    def test_remote_capture_cannot_preapprove_redistribution(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-health-physical-education-grades-1-8-2019",
            ).update({"redistribution_status": "redistributable-reviewed"})

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "cannot pre-approve redistribution"):
            validate_target_registry(path)

    def test_oversized_capture_limit_is_rejected(self):
        def mutate(payload):
            self.target(
                payload,
                "ontario-health-physical-education-grades-1-8-2019",
            ).update({"maximum_bytes": 300 * 1024 * 1024})

        path = self.mutation(mutate)
        with self.assertRaisesRegex(RemoteCaptureError, "safe range"):
            validate_target_registry(path)

    def test_duplicate_source_target_is_rejected(self):
        def duplicate(payload):
            target = dict(
                self.target(
                    payload,
                    "ontario-health-physical-education-grades-1-8-2019",
                )
            )
            payload["targets"].append(target)

        path = self.mutation(duplicate)
        with self.assertRaisesRegex(RemoteCaptureError, "duplicate capture target"):
            validate_target_registry(path)


if __name__ == "__main__":
    unittest.main()
