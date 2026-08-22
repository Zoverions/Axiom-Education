from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.ontario_elementary_c2_intake import (
    ElementaryC2IntakeError,
    build_plan,
    plan_index,
    verify_source_bytes,
)


SOURCE_ID = "ontario-fr-francais-grades-1-8-2023"


class OntarioElementaryC2IntakeTests(unittest.TestCase):
    def test_current_plan_is_zero_of_sixteen_eligible(self) -> None:
        plan = build_plan()
        self.assertEqual(plan["target_count"], 16)
        self.assertEqual(plan["eligible_source_count"], 0)
        self.assertEqual(plan["canonical_c2_record_count"], 0)
        targets = plan_index(plan)
        self.assertEqual(len(targets), 16)
        for target in targets.values():
            self.assertFalse(target["eligible_for_reference_only_candidate_intake"])
            self.assertEqual(target["candidate_content_modes"], [])
            self.assertTrue(target["blocker"])
            self.assertEqual(len(target["source_lock_sha256"]), 64)
            self.assertEqual(len(target["upstream_document_sha256"]), 64)
            self.assertGreater(target["upstream_byte_length"], 0)

    def test_approved_source_and_reference_only_licensing_unlock_only_reference_mode(self) -> None:
        with patch(
            "tools.ontario_elementary_c2_intake.current_source_decisions",
            return_value={SOURCE_ID: "approved"},
        ), patch(
            "tools.ontario_elementary_c2_intake.current_licensing_decisions",
            return_value={SOURCE_ID: "reference-only-use-permitted"},
        ):
            plan = build_plan()
        target = plan_index(plan)[SOURCE_ID]
        self.assertEqual(plan["eligible_source_count"], 1)
        self.assertTrue(target["eligible_for_reference_only_candidate_intake"])
        self.assertEqual(target["candidate_content_modes"], ["reference-only"])
        self.assertIsNone(target["blocker"])

    def test_verbatim_licensing_still_unlocks_only_reference_mode_in_v1(self) -> None:
        with patch(
            "tools.ontario_elementary_c2_intake.current_source_decisions",
            return_value={SOURCE_ID: "approved"},
        ), patch(
            "tools.ontario_elementary_c2_intake.current_licensing_decisions",
            return_value={SOURCE_ID: "verbatim-redistribution-permitted"},
        ):
            target = plan_index(build_plan())[SOURCE_ID]
        self.assertTrue(target["eligible_for_reference_only_candidate_intake"])
        self.assertEqual(target["candidate_content_modes"], ["reference-only"])

    def test_external_reference_only_does_not_unlock_candidate_intake(self) -> None:
        with patch(
            "tools.ontario_elementary_c2_intake.current_source_decisions",
            return_value={SOURCE_ID: "approved"},
        ), patch(
            "tools.ontario_elementary_c2_intake.current_licensing_decisions",
            return_value={SOURCE_ID: "external-reference-only"},
        ):
            target = plan_index(build_plan())[SOURCE_ID]
        self.assertFalse(target["eligible_for_reference_only_candidate_intake"])
        self.assertEqual(target["candidate_content_modes"], [])
        self.assertIn("licensing", target["blocker"])

    def test_licensing_without_source_approval_remains_blocked(self) -> None:
        with patch(
            "tools.ontario_elementary_c2_intake.current_source_decisions",
            return_value={SOURCE_ID: "changes-required"},
        ), patch(
            "tools.ontario_elementary_c2_intake.current_licensing_decisions",
            return_value={SOURCE_ID: "reference-only-use-permitted"},
        ):
            target = plan_index(build_plan())[SOURCE_ID]
        self.assertFalse(target["eligible_for_reference_only_candidate_intake"])
        self.assertIn("source identity/scope approval", target["blocker"])

    def test_operator_source_bytes_must_match_c1_exactly(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "wrong-source.bin"
            path.write_bytes(b"not the official captured source bytes")
            with self.assertRaisesRegex(ElementaryC2IntakeError, "do not match C1 SHA-256"):
                verify_source_bytes(SOURCE_ID, path)

    def test_plan_is_deterministic(self) -> None:
        self.assertEqual(build_plan(), build_plan())


if __name__ == "__main__":
    unittest.main()
