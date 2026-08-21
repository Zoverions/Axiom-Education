#!/usr/bin/env python3
"""Bind MTH1W accessibility readiness to deterministic alternatives and human evidence."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
READINESS_PATH = ROOT / "config" / "curriculum-readiness.json"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_accessible_export import EXPECTED_LESSONS, verify_determinism  # noqa: E402
from tools.mth1w_accessibility_review_evidence import (  # noqa: E402
    APPLICATION_PLATFORMS,
    EXPECTED_APPLICATION_TARGETS,
    EXPECTED_LESSON_TARGETS,
    EXPECTED_TARGETS,
    verify_directory,
)


class AccessibilityReadinessError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AccessibilityReadinessError(message)


def verify(path: Path = READINESS_PATH) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise AccessibilityReadinessError(f"cannot read curriculum readiness: {error}") from error
    require(isinstance(payload, dict), "curriculum readiness root must be an object")

    evidence = payload.get("accessible_offline_delivery")
    require(isinstance(evidence, dict), "accessible_offline_delivery evidence is required")
    require(
        evidence.get("verification_tool") == "tools/mth1w_accessible_export.py",
        "accessibility verification tool mismatch",
    )
    require(
        evidence.get("verification_status") == "machine-verified-draft-alternative",
        "accessible delivery evidence must remain draft",
    )
    require(evidence.get("lesson_exports") == EXPECTED_LESSONS, "accessibility lesson coverage claim mismatch")
    require(evidence.get("student_and_answer_key_separated") is True, "student/answer-key separation claim missing")
    require(evidence.get("format") == "text/markdown; charset=utf-8", "accessible export format mismatch")
    require(evidence.get("deterministic_build") is True, "accessible export must be deterministic")
    require(evidence.get("printable_equivalent_required") is True, "printable-equivalent requirement missing")
    require(evidence.get("nonvisual_route_required") is True, "nonvisual-route requirement missing")
    require(
        evidence.get("representation_text_alternatives_required") is True,
        "representation text-alternative requirement missing",
    )
    require(
        evidence.get("human_accessibility_review_status") in {"required", "completed"},
        "human accessibility review status is invalid",
    )

    manifest = verify_determinism()
    require(manifest.get("lesson_count") == EXPECTED_LESSONS, "deterministic export coverage does not match readiness")
    require(manifest.get("human_accessibility_review_status") == "required", "export manifest must preserve human review requirement")

    review_summary = verify_directory()
    require(review_summary["targets"] == EXPECTED_TARGETS, "accessibility review target count mismatch")
    require(
        review_summary["lesson_alternative_targets"] == EXPECTED_LESSON_TARGETS,
        "accessibility lesson-review target count mismatch",
    )
    require(
        review_summary["application_surface_targets"] == EXPECTED_APPLICATION_TARGETS,
        "accessibility app-surface target count mismatch",
    )
    require(
        review_summary["application_platforms"] == list(APPLICATION_PLATFORMS),
        "accessibility application platform matrix mismatch",
    )

    human = evidence.get("human_review_evidence")
    require(isinstance(human, dict), "accessibility human review evidence declaration missing")
    require(
        human.get("schema_path") == "schemas/accessibility-review-evidence.v1.schema.json",
        "accessibility human review schema path mismatch",
    )
    require(
        human.get("verification_tool") == "tools/mth1w_accessibility_review_evidence.py",
        "accessibility human review tool mismatch",
    )
    require(
        human.get("verification_status") == "machine-verified-review-contract",
        "accessibility human review contract status mismatch",
    )
    require(human.get("content_addressed_targets") == EXPECTED_TARGETS, "accessibility human target claim mismatch")
    require(
        human.get("lesson_alternative_targets") == EXPECTED_LESSON_TARGETS,
        "accessibility lesson target claim mismatch",
    )
    require(
        human.get("application_surface_targets") == EXPECTED_APPLICATION_TARGETS,
        "accessibility app target claim mismatch",
    )
    require(
        human.get("application_platforms") == list(APPLICATION_PLATFORMS),
        "accessibility app platform claim mismatch",
    )
    require(
        human.get("submitted_review_records") == review_summary["reviews"],
        "accessibility submitted review claim mismatch",
    )
    require(
        human.get("approved_current_targets") == review_summary["latest_approved_targets"],
        "accessibility approved target claim mismatch",
    )
    require(
        human.get("all_current_targets_approved") is review_summary["all_current_targets_approved"],
        "accessibility approval state claim mismatch",
    )

    gates = payload.get("required_gates")
    require(isinstance(gates, list), "required_gates must be an array")
    gate_status = {
        item.get("id"): item.get("status")
        for item in gates
        if isinstance(item, dict)
    }
    accessibility_gate = gate_status.get("accessible-alternatives")
    gate_satisfied = evidence.get("accessibility_gate_satisfied")
    require(isinstance(gate_satisfied, bool), "accessibility_gate_satisfied must be boolean")

    if gate_satisfied:
        require(
            review_summary["all_current_targets_approved"],
            "accessibility gate cannot be satisfied without all current human approvals",
        )
        require(
            set(review_summary["latest_approved_application_platforms"])
            == set(APPLICATION_PLATFORMS),
            "accessibility gate cannot be satisfied without current approval on every supported learner platform",
        )
        require(
            evidence.get("human_accessibility_review_status") == "completed",
            "satisfied accessibility gate requires completed human review status",
        )
        require(accessibility_gate == "verified", "satisfied accessibility gate must be verified")
    else:
        require(
            accessibility_gate == "blocked",
            "accessibility gate must remain blocked until explicitly satisfied",
        )
        require(
            evidence.get("human_accessibility_review_status") == "required",
            "blocked accessibility gate must preserve required human review status",
        )

    return payload


def main() -> int:
    try:
        payload = verify()
    except AccessibilityReadinessError as error:
        print(f"MTH1W accessibility readiness verification failed: {error}", file=sys.stderr)
        return 1
    evidence = payload["accessible_offline_delivery"]
    human = evidence["human_review_evidence"]
    print(
        "MTH1W accessibility readiness verified: "
        f"{evidence['lesson_exports']} deterministic lesson alternatives; "
        f"{human['approved_current_targets']}/{human['content_addressed_targets']} current human accessibility targets approved across "
        + ", ".join(human["application_platforms"])
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
