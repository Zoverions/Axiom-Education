from __future__ import annotations

import copy
import unittest

from tools.check_ontario_elementary_discovery import load_discovery, validate_discovery


class OntarioElementaryDiscoveryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.data = load_discovery()

    def test_current_discovery_passes(self) -> None:
        self.assertEqual(validate_discovery(self.data), [])

    def test_missing_required_family_fails(self) -> None:
        mutated = copy.deepcopy(self.data)
        del mutated["coverage_accounting"]["english_language_schools"]["mathematics"]
        errors = validate_discovery(mutated)
        self.assertTrue(any("unaccounted required families" in error for error in errors))

    def test_unknown_source_reference_fails(self) -> None:
        mutated = copy.deepcopy(self.data)
        mutated["coverage_accounting"]["english_language_schools"]["language"][
            "source_id"
        ] = "missing-source"
        errors = validate_discovery(mutated)
        self.assertTrue(any("unknown source_id" in error for error in errors))

    def test_captured_digest_requires_sha256(self) -> None:
        mutated = copy.deepcopy(self.data)
        source = mutated["confirmed_curriculum_sources"][0]
        source["upstream_digest_status"] = "captured"
        source["upstream_document_sha256"] = None
        errors = validate_discovery(mutated)
        self.assertTrue(any("captured digest requires" in error for error in errors))

    def test_digest_cannot_appear_without_captured_status(self) -> None:
        mutated = copy.deepcopy(self.data)
        source = mutated["confirmed_curriculum_sources"][0]
        source["upstream_document_sha256"] = "0" * 64
        errors = validate_discovery(mutated)
        self.assertTrue(any("digest present without captured status" in error for error in errors))

    def test_duplicate_source_id_fails(self) -> None:
        mutated = copy.deepcopy(self.data)
        mutated["confirmed_curriculum_sources"][1]["source_id"] = mutated[
            "confirmed_curriculum_sources"
        ][0]["source_id"]
        errors = validate_discovery(mutated)
        self.assertTrue(any("duplicate curriculum source ids" in error for error in errors))

    def test_v0_artifact_cannot_claim_later_stage(self) -> None:
        mutated = copy.deepcopy(self.data)
        mutated["state"] = "C1-captured"
        errors = validate_discovery(mutated)
        self.assertTrue(any("must remain C0-discovered" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
