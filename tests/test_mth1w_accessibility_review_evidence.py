from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.mth1w_accessibility_review_evidence import (
    AccessibilityReviewError,
    APPLICATION_CONFIRMATION_KEYS,
    APPLICATION_PLATFORMS,
    LESSON_CONFIRMATION_KEYS,
    build_plan,
    verify_directory,
    verify_readiness_boundary,
    verify_review,
)


class Mth1wAccessibilityReviewEvidenceTests(unittest.TestCase):
    def target(self, index: int = 0):
        return build_plan()["targets"][index]

    def review_payload(
        self,
        target,
        *,
        review_id="accessibility-review-test-001",
        reviewed_at="2026-08-21T01:00:00Z",
        decision="approved",
    ):
        keys = (
            LESSON_CONFIRMATION_KEYS
            if target["review_scope"] == "lesson-alternative"
            else APPLICATION_CONFIRMATION_KEYS
        )
        return {
            "schema": "axiom-education-accessibility-review-evidence.v1",
            "review_id": review_id,
            "course_code": "MTH1W",
            "review_scope": target["review_scope"],
            "target": {
                "target_id": target["target_id"],
                "lesson_id": target["lesson_id"],
                "unit_id": target["unit_id"],
                "platform": target["platform"],
                "target_sha256": target["target_sha256"],
            },
            "reviewer": {
                "name": "Qualified Accessibility Reviewer",
                "qualification": "Accessibility and assistive-technology reviewer",
                "organization": None,
            },
            "reviewed_at": reviewed_at,
            "decision": decision,
            "tested_environments": ["human-reviewed test environment"],
            "confirmations": {key: decision == "approved" for key in keys},
            "findings": [],
            "scope_limitations": [],
            "attestation_type": "human-accessibility-usability-review",
        }

    def write_review(self, payload, directory: Path | None = None, filename="review.json"):
        if directory is None:
            temp = tempfile.TemporaryDirectory()
            self.addCleanup(temp.cleanup)
            directory = Path(temp.name)
        path = directory / filename
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_plan_has_43_lesson_targets_and_four_platform_application_targets(self) -> None:
        plan = build_plan()
        self.assertEqual(plan["target_count"], 47)
        self.assertEqual(plan["lesson_alternative_targets"], 43)
        self.assertEqual(plan["application_surface_targets"], 4)
        self.assertEqual(plan["application_platforms"], list(APPLICATION_PLATFORMS))
        lesson_targets = [
            target
            for target in plan["targets"]
            if target["review_scope"] == "lesson-alternative"
        ]
        app_targets = [
            target
            for target in plan["targets"]
            if target["review_scope"] == "learner-application-surface"
        ]
        self.assertEqual(len(lesson_targets), 43)
        self.assertEqual(len(app_targets), 4)
        self.assertTrue(all(target["platform"] is None for target in lesson_targets))
        self.assertEqual(
            {target["platform"] for target in app_targets}, set(APPLICATION_PLATFORMS)
        )
        self.assertTrue(all(len(target["target_sha256"]) == 64 for target in plan["targets"]))
        self.assertTrue(all(len(target["binding"]["files"]) == 10 for target in app_targets))

    def test_current_directory_has_no_implicit_human_approval(self) -> None:
        summary = verify_directory()
        self.assertEqual(summary["targets"], 47)
        self.assertEqual(summary["reviews"], 0)
        self.assertEqual(summary["latest_approved_targets"], 0)
        self.assertEqual(summary["latest_approved_application_platforms"], [])
        self.assertFalse(summary["all_current_targets_approved"])
        self.assertEqual(len(summary["unreviewed_target_ids"]), 47)

    def test_content_addressed_lesson_review_can_verify(self) -> None:
        target = self.target()
        review = verify_review(self.write_review(self.review_payload(target)))
        self.assertEqual(review["decision"], "approved")
        self.assertIsNone(review["target"]["platform"])
        self.assertEqual(set(review["confirmations"]), LESSON_CONFIRMATION_KEYS)

    def test_each_platform_application_review_can_verify_independently(self) -> None:
        app_targets = build_plan()["targets"][-4:]
        self.assertEqual(
            {target["platform"] for target in app_targets}, set(APPLICATION_PLATFORMS)
        )
        for index, target in enumerate(app_targets):
            payload = self.review_payload(
                target, review_id=f"accessibility-app-{target['platform']}-{index}"
            )
            review = verify_review(self.write_review(payload, filename=f"{index}.json"))
            self.assertEqual(review["target"]["platform"], target["platform"])
            self.assertEqual(set(review["confirmations"]), APPLICATION_CONFIRMATION_KEYS)

    def test_stale_target_digest_is_rejected(self) -> None:
        target = self.target()
        payload = self.review_payload(target)
        payload["target"]["target_sha256"] = "0" * 64
        with self.assertRaisesRegex(AccessibilityReviewError, "target content changed"):
            verify_review(self.write_review(payload))

    def test_application_platform_substitution_is_rejected(self) -> None:
        target = build_plan()["targets"][-1]
        payload = self.review_payload(target)
        payload["target"]["platform"] = "android"
        with self.assertRaisesRegex(AccessibilityReviewError, "platform binding mismatch"):
            verify_review(self.write_review(payload))

    def test_scope_specific_confirmation_set_is_required(self) -> None:
        target = self.target()
        payload = self.review_payload(target)
        payload["confirmations"]["keyboard_navigation_reviewed"] = True
        with self.assertRaisesRegex(AccessibilityReviewError, "incomplete or out of scope"):
            verify_review(self.write_review(payload))

    def test_approved_review_requires_every_confirmation(self) -> None:
        target = build_plan()["targets"][-1]
        payload = self.review_payload(target)
        payload["confirmations"]["screen_reader_navigation_reviewed"] = False
        with self.assertRaisesRegex(AccessibilityReviewError, "every in-scope confirmation"):
            verify_review(self.write_review(payload))

    def test_human_test_environment_is_required(self) -> None:
        target = self.target()
        payload = self.review_payload(target)
        payload["tested_environments"] = []
        with self.assertRaisesRegex(AccessibilityReviewError, "human-tested environment"):
            verify_review(self.write_review(payload))

    def test_approved_review_cannot_hide_open_finding(self) -> None:
        target = self.target()
        payload = self.review_payload(target)
        payload["findings"] = [
            {
                "id": "accessibility-finding-1",
                "severity": "major",
                "description": "Nonvisual route is incomplete.",
                "disposition": "open",
                "resolution_reference": None,
            }
        ]
        with self.assertRaisesRegex(AccessibilityReviewError, "open findings"):
            verify_review(self.write_review(payload))

    def test_changes_required_is_valid_negative_provenance(self) -> None:
        target = build_plan()["targets"][-1]
        payload = self.review_payload(target, decision="changes-required")
        payload["findings"] = [
            {
                "id": "accessibility-finding-1",
                "severity": "major",
                "description": "Focus order requires correction.",
                "disposition": "open",
                "resolution_reference": None,
            }
        ]
        review = verify_review(self.write_review(payload))
        self.assertEqual(review["decision"], "changes-required")

    def test_latest_review_controls_current_target_disposition(self) -> None:
        target = self.target()
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            earlier = self.review_payload(
                target,
                review_id="review-earlier",
                reviewed_at="2026-08-21T01:00:00Z",
                decision="changes-required",
            )
            earlier["findings"] = [
                {
                    "id": "finding-earlier",
                    "severity": "minor",
                    "description": "Needs revision.",
                    "disposition": "open",
                    "resolution_reference": None,
                }
            ]
            later = self.review_payload(
                target,
                review_id="review-later",
                reviewed_at="2026-08-21T02:00:00Z",
                decision="approved",
            )
            self.write_review(earlier, directory, "01-earlier.json")
            self.write_review(later, directory, "02-later.json")
            summary = verify_directory(directory)
            self.assertEqual(summary["latest_approved_targets"], 1)
            self.assertNotIn(target["target_id"], summary["latest_nonapproved_target_ids"])

    def test_later_negative_review_blocks_earlier_approval(self) -> None:
        target = build_plan()["targets"][-1]
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            earlier = self.review_payload(
                target,
                review_id="review-earlier",
                reviewed_at="2026-08-21T01:00:00Z",
                decision="approved",
            )
            later = self.review_payload(
                target,
                review_id="review-later",
                reviewed_at="2026-08-21T02:00:00Z",
                decision="changes-required",
            )
            later["findings"] = [
                {
                    "id": "finding-later",
                    "severity": "major",
                    "description": "Later assistive-technology review found a blocker.",
                    "disposition": "open",
                    "resolution_reference": None,
                }
            ]
            self.write_review(earlier, directory, "01-earlier.json")
            self.write_review(later, directory, "02-later.json")
            summary = verify_directory(directory)
            self.assertEqual(summary["latest_approved_targets"], 0)
            self.assertIn(target["target_id"], summary["latest_nonapproved_target_ids"])

    def test_one_platform_approval_cannot_satisfy_cross_platform_gate(self) -> None:
        target = build_plan()["targets"][-1]
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            self.write_review(self.review_payload(target), directory)
            summary = verify_directory(directory)
            self.assertEqual(summary["latest_approved_application_surfaces"], 1)
            self.assertEqual(summary["latest_approved_application_platforms"], [target["platform"]])
            self.assertFalse(summary["all_current_targets_approved"])

    def test_current_readiness_gate_remains_blocked_without_reviews(self) -> None:
        summary = verify_readiness_boundary()
        self.assertFalse(summary["all_current_targets_approved"])


if __name__ == "__main__":
    unittest.main()
