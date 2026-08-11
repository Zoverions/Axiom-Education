#!/usr/bin/env python3
"""Verify the MTH1W cumulative assessment blueprint without promoting review claims."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
PLAN_PATH = ROOT / "curriculum" / "courses" / "ontario-mth1w-2021.assessment-plan.json"
BLUEPRINT_PATH = ROOT / "curriculum" / "courses" / "ontario-mth1w-2021.course.json"


class AssessmentPlanError(RuntimeError):
    """Raised when the course-wide assessment plan is incomplete or unsafe."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssessmentPlanError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise AssessmentPlanError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise AssessmentPlanError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def verify(
    plan_path: Path = PLAN_PATH,
    blueprint_path: Path = BLUEPRINT_PATH,
) -> dict[str, Any]:
    plan = load_json(plan_path)
    blueprint = load_json(blueprint_path)

    require(
        plan.get("schema") == "axiom-education-course-assessment-plan.v1",
        "unsupported assessment plan schema",
    )
    require(plan.get("course_code") == "MTH1W", "assessment plan must target MTH1W")
    require(
        plan.get("status") == "machine-verified-draft-plan",
        "assessment plan must remain a machine-verified draft plan",
    )
    require(
        plan.get("student_availability") == "not_grade_or_credit_evidence",
        "assessment plan must not be represented as grade or credit evidence",
    )
    require(
        plan.get("course_blueprint_path")
        == "curriculum/courses/ontario-mth1w-2021.course.json",
        "assessment plan course blueprint path mismatch",
    )
    require(
        plan.get("official_inventory_path")
        == "curriculum/official/ontario-mth1w-2021.inventory.json",
        "assessment plan official inventory path mismatch",
    )
    require(
        plan.get("coverage_model")
        == "expand-unit-specific-expectations-from-course-blueprint",
        "assessment plan coverage model mismatch",
    )

    policy = plan.get("assessment_policy")
    require(isinstance(policy, dict), "assessment policy must be an object")
    require(policy.get("mastery_inference_allowed") is False, "mastery inference must be disabled")
    require(
        policy.get("automatic_credit_or_grade_allowed") is False,
        "automatic credit or grade inference must be disabled",
    )
    for key in (
        "constructed_response_requires_human_review",
        "learner_correction_path_required",
        "learner_appeal_path_required",
        "accessible_alternative_required",
        "printable_offline_route_required",
    ):
        require(policy.get(key) is True, f"assessment policy must require {key}")

    units = blueprint.get("units")
    require(isinstance(units, list) and len(units) == 9, "MTH1W blueprint must contain 9 units")
    unit_map: dict[str, list[str]] = {}
    all_specific: set[str] = set()
    for unit in units:
        require(isinstance(unit, dict), "course unit entries must be objects")
        unit_id = unit.get("id")
        expectations = unit.get("specific_expectations")
        require(isinstance(unit_id, str) and unit_id, "course unit requires id")
        require(
            isinstance(expectations, list)
            and expectations
            and all(isinstance(item, str) and item for item in expectations),
            f"{unit_id}: specific expectations must be a non-empty string list",
        )
        require(unit_id not in unit_map, f"duplicate course unit id: {unit_id}")
        unit_map[unit_id] = list(expectations)
        for expectation_id in expectations:
            require(
                expectation_id not in all_specific,
                f"specific expectation appears in multiple primary units: {expectation_id}",
            )
            all_specific.add(expectation_id)

    require(len(all_specific) == 43, "course blueprint must expose 43 unique specific expectations")

    blueprint_coursewide = blueprint.get("coursewide_expectations")
    require(isinstance(blueprint_coursewide, dict), "coursewide expectations missing from blueprint")
    expected_coursewide = blueprint_coursewide.get("ids")
    require(
        expected_coursewide == ["AA1", "A1", "A2"],
        "coursewide expectation ids changed unexpectedly",
    )
    require(
        plan.get("coursewide_expectations_required") == expected_coursewide,
        "assessment plan coursewide expectations must match course blueprint",
    )

    stages = plan.get("stages")
    require(isinstance(stages, list) and len(stages) >= 5, "assessment plan requires diagnostic, cumulative checkpoints, and final blueprint")
    stage_ids: set[str] = set()
    sequences: list[int] = []
    assessed_specific: set[str] = set()
    final_stage: dict[str, Any] | None = None

    for stage in stages:
        require(isinstance(stage, dict), "assessment stage must be an object")
        stage_id = stage.get("id")
        sequence = stage.get("sequence")
        purpose = stage.get("purpose")
        covered_units = stage.get("covered_unit_ids")
        require(isinstance(stage_id, str) and stage_id, "assessment stage requires id")
        require(stage_id not in stage_ids, f"duplicate assessment stage id: {stage_id}")
        stage_ids.add(stage_id)
        require(isinstance(sequence, int) and sequence > 0, f"{stage_id}: invalid sequence")
        sequences.append(sequence)
        require(isinstance(purpose, str) and purpose, f"{stage_id}: purpose is required")
        require(
            isinstance(covered_units, list)
            and covered_units
            and all(isinstance(item, str) for item in covered_units),
            f"{stage_id}: covered_unit_ids must be a non-empty list",
        )
        require(
            len(covered_units) == len(set(covered_units)),
            f"{stage_id}: covered units must not repeat",
        )
        unknown_units = sorted(set(covered_units) - set(unit_map))
        require(not unknown_units, f"{stage_id}: unknown covered units: {unknown_units}")
        require(
            stage.get("coursewide_expectations") == expected_coursewide,
            f"{stage_id}: must include all coursewide expectations",
        )
        require(
            isinstance(stage.get("correction_path"), str) and stage["correction_path"].strip(),
            f"{stage_id}: correction path is required",
        )
        require(
            isinstance(stage.get("appeal_path"), str) and stage["appeal_path"].strip(),
            f"{stage_id}: appeal path is required",
        )
        require(
            isinstance(stage.get("accessible_alternative"), str)
            and stage["accessible_alternative"].strip(),
            f"{stage_id}: accessible alternative is required",
        )

        if purpose != "diagnostic":
            for unit_id in covered_units:
                assessed_specific.update(unit_map[unit_id])

        if purpose == "final-assessment-blueprint":
            require(final_stage is None, "assessment plan may contain only one final blueprint")
            final_stage = stage
            require(stage.get("summative") is True, "final assessment blueprint must be summative")
        else:
            require(stage.get("summative") is False, f"{stage_id}: only final blueprint may be summative")

    require(sequences == list(range(1, len(stages) + 1)), "assessment stage sequences must be contiguous and ordered")
    require(final_stage is not None, "final assessment blueprint is required")
    require(
        set(final_stage["covered_unit_ids"]) == set(unit_map),
        "final assessment blueprint must span all nine course units",
    )
    require(
        assessed_specific == all_specific,
        "cumulative assessment plan does not structurally cover all 43 specific expectations",
    )

    promotion_requirements = plan.get("promotion_requirements")
    require(
        isinstance(promotion_requirements, list) and len(promotion_requirements) >= 6,
        "assessment plan promotion requirements are incomplete",
    )

    return {
        "stages": len(stages),
        "units": len(unit_map),
        "specific_expectations": len(all_specific),
        "coursewide_expectations": len(expected_coursewide),
        "status": plan["status"],
    }


def main() -> int:
    try:
        summary = verify()
    except (OSError, AssessmentPlanError) as error:
        print(f"MTH1W cumulative assessment verification failed: {error}", file=sys.stderr)
        return 1

    print(
        "MTH1W cumulative assessment blueprint verified: "
        f"{summary['stages']} stages, {summary['units']} units, "
        f"{summary['specific_expectations']} specific expectations; review gate remains external"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
