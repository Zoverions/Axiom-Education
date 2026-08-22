from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.curriculum_crosswalk import (
    CrosswalkError,
    canonical_crosswalk_digest,
    seal,
    verify_crosswalk,
)
from tools.curriculum_source_lock import (
    DEFAULT_DISCOVERY,
    canonical_json_digest,
    create_lock,
)
from tools.curriculum_standard_record import canonical_record_digest


SOURCE_ID = "ontario-mathematics-grades-1-8-2020"
SOURCE_LOCATOR = (
    "https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-mathematics"
)


class CurriculumCrosswalkTests(unittest.TestCase):
    def make_record(self, root: Path) -> tuple[Path, dict]:
        source_file = root / "captured-source.pdf"
        source_file.write_bytes(b"crosswalk provenance fixture")
        lock = create_lock(
            source_id=SOURCE_ID,
            input_path=source_file,
            source_locator=SOURCE_LOCATOR,
            resolved_locator=SOURCE_LOCATOR,
            media_type="application/pdf",
            discovery_path=DEFAULT_DISCOVERY,
            redistribution_status="review-required",
            retained_path=None,
            notes="crosswalk test fixture",
        )
        lock_dir = root / "curriculum" / "ontario-elementary" / "source-locks"
        lock_dir.mkdir(parents=True)
        (lock_dir / f"{SOURCE_ID}.v1.json").write_text(
            json.dumps(lock),
            encoding="utf-8",
        )
        record = {
            "schema": "axiom-curriculum-standard-record.v2",
            "stage": "C2-normalized",
            "record_id": "ca:on:test:grade-1:x1-1",
            "jurisdiction_id": "ca:on",
            "authority_id": "gov:ontario:ministry-of-education",
            "language": "en",
            "education_context": {
                "program_family": "english-language-schools",
                "level": "elementary",
                "grade_or_level": "1",
                "subject_id": "test-subject",
                "subject_name": "Test Subject",
                "course_code": None,
                "course_name": None,
            },
            "standard": {
                "official_id": "X1.1",
                "kind": "specific",
                "parent_official_id": "X1",
                "strand_id": "X",
                "strand_name": "Test Strand",
                "content": {
                    "mode": "reference-only",
                    "text": None,
                    "official_text_sha256": None,
                },
            },
            "source": {
                "source_id": SOURCE_ID,
                "source_lock_sha256": canonical_json_digest(lock),
                "upstream_document_sha256": lock["sha256"],
                "official_locator": SOURCE_LOCATOR,
                "official_recognition": True,
                "effective_from": "2026-09",
                "effective_to": None,
            },
            "provenance": {
                "normalization_method": "test-reference-only",
                "normalized_at": "2026-08-11T22:00:00Z",
                "human_source_review_status": "required",
            },
            "axiom_metadata": {
                "namespace": "org.axiom.education",
                "tags": ["test"],
            },
            "content_digest": "",
        }
        record["content_digest"] = canonical_record_digest(record)
        path = root / "records" / "standard.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(record), encoding="utf-8")
        return path, record

    def make_crosswalk(
        self,
        root: Path,
        *,
        relationship="supports",
        coverage_level="supporting",
        review_status="required",
    ) -> tuple[Path, dict]:
        record_path, record = self.make_record(root)
        reviewed = review_status != "required"
        payload = {
            "schema": "axiom-curriculum-crosswalk.v1",
            "crosswalk_id": "test-crosswalk",
            "crosswalk_version": "1.0.0",
            "source_competency_namespace": "org.axiom.test.competencies",
            "target_jurisdiction_id": "ca:on",
            "claim_boundary": "Derived test mapping only; no global curriculum coverage or mastery claim.",
            "global_official_coverage_claim_allowed": False,
            "learner_mastery_claim_allowed": False,
            "mappings": [
                {
                    "mapping_id": "map-001",
                    "competency_id": "test.competency.1",
                    "target_record_path": record_path.relative_to(root).as_posix(),
                    "target_source_lock_path": (
                        Path("curriculum")
                        / "ontario-elementary"
                        / "source-locks"
                        / f"{SOURCE_ID}.v1.json"
                    ).as_posix(),
                    "target_record_id": record["record_id"],
                    "target_official_id": record["standard"]["official_id"],
                    "target_content_digest": record["content_digest"],
                    "relationship": relationship,
                    "coverage_level": coverage_level,
                    "rationale": "The competency and standard share the bounded skill relationship under review.",
                    "evidence_refs": ["review:test-evidence"] if reviewed else [],
                    "review": {
                        "status": review_status,
                        "reviewer": (
                            {
                                "name": "Qualified Reviewer",
                                "qualification": "curriculum reviewer",
                                "organization": None,
                            }
                            if reviewed
                            else None
                        ),
                        "reviewed_at": "2026-08-11T22:30:00Z" if reviewed else None,
                        "findings": [],
                    },
                }
            ],
            "crosswalk_digest": "",
        }
        payload["crosswalk_digest"] = canonical_crosswalk_digest(payload)
        path = root / "crosswalk.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path, payload

    def test_proposed_supporting_mapping_can_verify_without_coverage_claim(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, _ = self.make_crosswalk(root)
            result = verify_crosswalk(path, root)
            self.assertEqual(result["mappings"], 1)
            self.assertEqual(result["approved_mappings"], 0)
            self.assertEqual(result["direct_coverage_mappings"], 0)
            self.assertFalse(result["global_official_coverage_claim_allowed"])
            self.assertFalse(result["learner_mastery_claim_allowed"])

    def test_direct_coverage_requires_equivalent_and_human_approved(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, _ = self.make_crosswalk(
                root,
                relationship="equivalent",
                coverage_level="direct",
                review_status="approved",
            )
            result = verify_crosswalk(path, root)
            self.assertEqual(result["approved_mappings"], 1)
            self.assertEqual(result["direct_coverage_mappings"], 1)

    def test_unreviewed_mapping_cannot_claim_direct_coverage(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, _ = self.make_crosswalk(
                root,
                relationship="equivalent",
                coverage_level="direct",
                review_status="required",
            )
            with self.assertRaisesRegex(CrosswalkError, "cannot claim direct"):
                verify_crosswalk(path, root)

    def test_supports_relationship_cannot_claim_direct_coverage(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, _ = self.make_crosswalk(
                root,
                relationship="supports",
                coverage_level="direct",
                review_status="approved",
            )
            with self.assertRaisesRegex(CrosswalkError, "equivalent relationship"):
                verify_crosswalk(path, root)

    def test_target_record_change_stales_mapping(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, payload = self.make_crosswalk(root)
            payload["mappings"][0]["target_content_digest"] = "0" * 64
            payload["crosswalk_digest"] = canonical_crosswalk_digest(payload)
            path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(CrosswalkError, "target record changed"):
                verify_crosswalk(path, root)

    def test_crosswalk_digest_tampering_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, payload = self.make_crosswalk(root)
            payload["mappings"][0]["rationale"] = "Changed after sealing."
            path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(CrosswalkError, "digest mismatch"):
                verify_crosswalk(path, root)

    def test_target_record_must_revalidate_its_c1_source_lock(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, payload = self.make_crosswalk(root)
            lock_path = root / payload["mappings"][0]["target_source_lock_path"]
            lock_path.unlink()
            with self.assertRaisesRegex(
                CrosswalkError,
                "target record provenance verification failed",
            ):
                verify_crosswalk(path, root)

    def test_schema_rejects_unadvertised_crosswalk_fields(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, payload = self.make_crosswalk(root)
            payload["unreviewed_extension"] = True
            payload["crosswalk_digest"] = canonical_crosswalk_digest(payload)
            path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(CrosswalkError, "Additional properties"):
                verify_crosswalk(path, root)

    def test_target_path_cannot_escape_repository_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, payload = self.make_crosswalk(root)
            payload["mappings"][0]["target_record_path"] = "../outside.json"
            payload["crosswalk_digest"] = canonical_crosswalk_digest(payload)
            path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(CrosswalkError, "cannot escape"):
                verify_crosswalk(path, root)

    def test_source_lock_path_cannot_escape_repository_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, payload = self.make_crosswalk(root)
            payload["mappings"][0]["target_source_lock_path"] = "../outside.json"
            payload["crosswalk_digest"] = canonical_crosswalk_digest(payload)
            path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(CrosswalkError, "target_source_lock_path cannot escape"):
                verify_crosswalk(path, root)

    def test_global_coverage_and_mastery_claims_are_always_forbidden(self) -> None:
        for field, message in (
            ("global_official_coverage_claim_allowed", "global_official_coverage_claim_allowed"),
            ("learner_mastery_claim_allowed", "learner_mastery_claim_allowed"),
        ):
            with self.subTest(field=field), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                path, payload = self.make_crosswalk(root)
                payload[field] = True
                payload["crosswalk_digest"] = canonical_crosswalk_digest(payload)
                path.write_text(json.dumps(payload), encoding="utf-8")
                with self.assertRaisesRegex(CrosswalkError, message):
                    verify_crosswalk(path, root)

    def test_approved_mapping_requires_evidence_refs_and_closed_findings(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, payload = self.make_crosswalk(
                root,
                relationship="equivalent",
                coverage_level="direct",
                review_status="approved",
            )
            payload["mappings"][0]["evidence_refs"] = []
            payload["crosswalk_digest"] = canonical_crosswalk_digest(payload)
            path.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(CrosswalkError, "requires review evidence refs"):
                verify_crosswalk(path, root)

    def test_seal_writes_current_digest_and_verifies(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            input_path, payload = self.make_crosswalk(root)
            payload["crosswalk_digest"] = ""
            input_path.write_text(json.dumps(payload), encoding="utf-8")
            output = root / "sealed.json"
            sealed = seal(input_path, output, root)
            self.assertEqual(sealed["crosswalk_digest"], canonical_crosswalk_digest(sealed))
            verify_crosswalk(output, root)


if __name__ == "__main__":
    unittest.main()
