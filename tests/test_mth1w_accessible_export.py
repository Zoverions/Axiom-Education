from __future__ import annotations

import copy
import tempfile
import unittest
from pathlib import Path

from tools.mth1w_accessible_export import (
    AccessibleExportError,
    EXPECTED_LESSONS,
    build_package,
    render_lesson,
    verify_determinism,
)
from tools.mth1w_review_evidence import load_authored_units


class Mth1wAccessibleExportTests(unittest.TestCase):
    def first_lesson(self):
        _path, unit = load_authored_units()[0]
        lesson = unit["lessons"][0]
        return unit, lesson

    def test_all_43_lessons_build_student_and_answer_key_exports(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp)
            manifest = build_package(output)
            self.assertEqual(manifest["lesson_count"], EXPECTED_LESSONS)
            self.assertEqual(len(manifest["records"]), EXPECTED_LESSONS)
            for record in manifest["records"]:
                self.assertTrue((output / record["student_path"]).is_file())
                self.assertTrue((output / record["answer_key_path"]).is_file())
                self.assertTrue(record["printable_equivalent"])
                self.assertTrue(record["nonvisual_route_included"])

    def test_export_is_byte_deterministic(self):
        manifest = verify_determinism()
        self.assertEqual(manifest["lesson_count"], EXPECTED_LESSONS)

    def test_student_export_separates_answer_key_material(self):
        unit, lesson = self.first_lesson()
        student = render_lesson(unit, lesson, include_answers=False).decode("utf-8")
        key = render_lesson(unit, lesson, include_answers=True).decode("utf-8")
        self.assertNotIn("Accepted answers:", student)
        self.assertNotIn("Review required: yes", student)
        self.assertIn("Answer:", key)
        self.assertIn("Rationale:", key)

    def test_missing_representation_text_alternative_fails_closed(self):
        unit, lesson = self.first_lesson()
        mutated = copy.deepcopy(lesson)
        mutated["representations"][0]["text_alternative"] = ""
        with self.assertRaisesRegex(AccessibleExportError, "text alternative missing"):
            render_lesson(unit, mutated, include_answers=False)

    def test_missing_nonvisual_route_fails_closed(self):
        unit, lesson = self.first_lesson()
        mutated = copy.deepcopy(lesson)
        mutated["accessibility"]["nonvisual_route"] = ""
        with self.assertRaisesRegex(AccessibleExportError, "nonvisual route missing"):
            render_lesson(unit, mutated, include_answers=False)

    def test_printable_equivalent_must_be_explicit(self):
        unit, lesson = self.first_lesson()
        mutated = copy.deepcopy(lesson)
        mutated["accessibility"]["printable_equivalent"] = False
        with self.assertRaisesRegex(AccessibleExportError, "printable equivalent"):
            render_lesson(unit, mutated, include_answers=False)

    def test_exports_preserve_draft_claim_boundary(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp)
            manifest = build_package(output)
            self.assertEqual(manifest["status"], "machine-verified-draft-alternative")
            self.assertEqual(manifest["human_accessibility_review_status"], "required")
            self.assertIn("do not establish", manifest["claim_boundary"])


if __name__ == "__main__":
    unittest.main()
