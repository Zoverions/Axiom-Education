from __future__ import annotations

import unittest

from tools.check_conditional_curriculum_family_evidence import (
    ConditionalFamilyEvidenceError,
    verify_conditional_family_evidence,
)
from tools.curriculum_source_lock import DEFAULT_DISCOVERY, load_discovery


PRIMARY = "ontario-fr-english-grades-4-8-2006"
ALTERNATIVE = "ontario-fr-english-beginners-grades-4-8-2013"


class ConditionalCurriculumFamilyEvidenceTests(unittest.TestCase):
    def discovery(self):
        return load_discovery(DEFAULT_DISCOVERY)

    def test_current_unlocked_conditional_family_is_valid(self) -> None:
        result = verify_conditional_family_evidence(
            discovery=self.discovery(),
            locked_source_ids=set(),
        )
        self.assertEqual(result["conditional_family_count"], 1)
        family = result["conditional_families"][0]
        self.assertEqual(family["stream"], "french_language_schools")
        self.assertEqual(family["program_family"], "english")
        self.assertEqual(family["primary_source_id"], PRIMARY)
        self.assertEqual(family["conditional_source_ids"], [ALTERNATIVE])
        self.assertEqual(set(family["required_source_ids"]), {PRIMARY, ALTERNATIVE})
        self.assertFalse(family["c1_family_complete"])

    def test_primary_only_c1_is_rejected(self) -> None:
        with self.assertRaisesRegex(
            ConditionalFamilyEvidenceError,
            "conditional family C1 evidence must be atomic",
        ):
            verify_conditional_family_evidence(
                discovery=self.discovery(),
                locked_source_ids={PRIMARY},
            )

    def test_conditional_alternative_only_c1_is_rejected(self) -> None:
        with self.assertRaisesRegex(
            ConditionalFamilyEvidenceError,
            "conditional family C1 evidence must be atomic",
        ):
            verify_conditional_family_evidence(
                discovery=self.discovery(),
                locked_source_ids={ALTERNATIVE},
            )

    def test_complete_conditional_family_c1_is_valid(self) -> None:
        result = verify_conditional_family_evidence(
            discovery=self.discovery(),
            locked_source_ids={PRIMARY, ALTERNATIVE},
        )
        family = result["conditional_families"][0]
        self.assertTrue(family["c1_family_complete"])


if __name__ == "__main__":
    unittest.main()
