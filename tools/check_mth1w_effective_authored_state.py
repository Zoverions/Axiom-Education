#!/usr/bin/env python3
"""Verify the effective MTH1W authored state across base and split artifacts.

The large course JSON is a planning baseline. Units 1-7 currently carry their authored
content directly through the baseline declaration, while Units 8-9 are independently
materialized from split manifests. Effective authored state must therefore compose both
surfaces instead of treating stale planning-only status labels as stronger evidence than
verified split content.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.check_mth1w_course_blueprint import (  # noqa: E402
    BLUEPRINT_PATH,
    EXPECTED_UNIT_IDS,
    load_blueprint,
)
from tools.check_mth1w_split_unit_content import (  # noqa: E402
    MANIFEST_PATHS,
    materialize_manifest,
    verify_split_manifest,
)

EXPECTED_DIRECT_UNIT_IDS = {f"mth1w-u{index}" for index in range(1, 8)}
EXPECTED_SPLIT_UNIT_IDS = {"mth1w-u8", "mth1w-u9"}
EXPECTED_AUTHORING_STATUS = "machine_verified_draft"
EXPECTED_STUDENT_AVAILABILITY = "draft_preview_with_adult_review_recommended"


class EffectiveAuthoredStateError(RuntimeError):
    """Raised when effective authored evidence is inconsistent or incomplete."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EffectiveAuthoredStateError(message)


def _unit_index(blueprint: dict[str, Any]) -> dict[str, dict[str, Any]]:
    units = blueprint.get("units")
    require(isinstance(units, list), "course planning units must be an array")
    index: dict[str, dict[str, Any]] = {}
    for unit in units:
        require(isinstance(unit, dict), "course planning unit must be an object")
        unit_id = unit.get("id")
        require(isinstance(unit_id, str) and unit_id, "course planning unit id missing")
        require(unit_id not in index, f"duplicate course planning unit: {unit_id}")
        index[unit_id] = unit
    require(set(index) == set(EXPECTED_UNIT_IDS), "course planning unit set changed")
    return index


def _direct_authored_units(blueprint: dict[str, Any]) -> set[str]:
    declarations = blueprint.get("authored_unit_content")
    require(isinstance(declarations, list), "authored unit declarations must be an array")
    authored: set[str] = set()
    for declaration in declarations:
        require(isinstance(declaration, dict), "authored unit declaration must be an object")
        unit_id = declaration.get("unit_id")
        require(
            isinstance(unit_id, str) and unit_id in EXPECTED_DIRECT_UNIT_IDS,
            "direct authored declaration must reference Units 1-7",
        )
        require(unit_id not in authored, f"duplicate direct authored declaration: {unit_id}")
        authored.add(unit_id)
        require(
            declaration.get("status") == EXPECTED_AUTHORING_STATUS,
            f"{unit_id}: direct authored status must remain machine verified draft",
        )
        require(
            declaration.get("educator_review_status") == "required",
            f"{unit_id}: educator review must remain required",
        )
        require(
            declaration.get("student_availability") == EXPECTED_STUDENT_AVAILABILITY,
            f"{unit_id}: draft availability boundary changed",
        )
    require(authored == EXPECTED_DIRECT_UNIT_IDS, "direct authored Units 1-7 are incomplete")
    return authored


def _verify_split_alignment(
    planning_unit: dict[str, Any],
    materialized: dict[str, Any],
    manifest_path: Path,
) -> bool:
    unit_id = materialized.get("unit_id")
    require(unit_id == planning_unit.get("id"), f"{manifest_path}: split unit id mismatch")
    require(materialized.get("course_code") == "MTH1W", f"{unit_id}: course code mismatch")

    review = materialized.get("review")
    require(isinstance(review, dict), f"{unit_id}: split review boundary missing")
    require(
        review.get("authoring_status") == EXPECTED_AUTHORING_STATUS,
        f"{unit_id}: split content is not machine verified draft",
    )
    require(
        review.get("educator_review_status") == "required",
        f"{unit_id}: educator review must remain required",
    )
    require(
        review.get("cultural_review_status") == "required",
        f"{unit_id}: cultural review must remain required",
    )
    require(
        review.get("student_availability") == EXPECTED_STUDENT_AVAILABILITY,
        f"{unit_id}: split draft availability boundary changed",
    )
    require(
        review.get("complete_course_claim_allowed") is False,
        f"{unit_id}: split content cannot authorize a complete-course claim",
    )

    planning_lessons = planning_unit.get("lessons")
    split_lessons = materialized.get("lessons")
    require(isinstance(planning_lessons, list), f"{unit_id}: planning lessons missing")
    require(isinstance(split_lessons, list), f"{unit_id}: split lessons missing")
    require(len(planning_lessons) == len(split_lessons), f"{unit_id}: lesson count mismatch")

    planning_status_shadowed = False
    for planning, authored in zip(planning_lessons, split_lessons, strict=True):
        require(isinstance(planning, dict), f"{unit_id}: invalid planning lesson")
        require(isinstance(authored, dict), f"{unit_id}: invalid authored lesson")
        lesson_id = planning.get("id")
        require(authored.get("id") == lesson_id, f"{unit_id}: authored lesson order/id mismatch")
        require(
            authored.get("estimated_minutes") == planning.get("estimated_minutes"),
            f"{lesson_id}: authored/planning minute mismatch",
        )
        require(
            authored.get("official_expectation_ids") == planning.get("primary_expectations"),
            f"{lesson_id}: authored/planning expectation mismatch",
        )
        planning_status = planning.get("status")
        require(
            planning_status in {"specified_not_implemented", EXPECTED_AUTHORING_STATUS},
            f"{lesson_id}: unsupported planning status",
        )
        planning_status_shadowed = (
            planning_status_shadowed or planning_status != EXPECTED_AUTHORING_STATUS
        )

    assessment = planning_unit.get("assessment")
    unit_assessment = materialized.get("unit_assessment")
    require(isinstance(assessment, dict), f"{unit_id}: planning assessment missing")
    require(isinstance(unit_assessment, dict), f"{unit_id}: authored assessment missing")
    quiz = unit_assessment.get("quiz")
    task = unit_assessment.get("performance_task")
    require(isinstance(quiz, dict), f"{unit_id}: authored quiz missing")
    require(isinstance(task, dict), f"{unit_id}: authored performance task missing")
    require(quiz.get("id") == assessment.get("quiz_id"), f"{unit_id}: quiz id mismatch")
    require(
        task.get("id") == assessment.get("performance_task_id"),
        f"{unit_id}: performance task id mismatch",
    )
    require(
        task.get("official_expectation_ids") == assessment.get("expectation_ids"),
        f"{unit_id}: performance-task expectation coverage mismatch",
    )
    planning_assessment_status = assessment.get("status")
    require(
        planning_assessment_status in {"specified_not_implemented", EXPECTED_AUTHORING_STATUS},
        f"{unit_id}: unsupported planning assessment status",
    )
    planning_status_shadowed = (
        planning_status_shadowed
        or planning_assessment_status != EXPECTED_AUTHORING_STATUS
    )
    return planning_status_shadowed


def verify_effective_authored_state(
    blueprint_path: Path = BLUEPRINT_PATH,
    manifest_paths: list[Path] = MANIFEST_PATHS,
) -> dict[str, int]:
    blueprint = load_blueprint(blueprint_path)
    planning_units = _unit_index(blueprint)
    direct_units = _direct_authored_units(blueprint)

    require(len(manifest_paths) == 2, "exactly two split authored manifests are required")
    split_units: set[str] = set()
    shadowed_units = 0
    for manifest_path in manifest_paths:
        verify_split_manifest(manifest_path)
        materialized = materialize_manifest(manifest_path)
        unit_id = materialized.get("unit_id")
        require(
            isinstance(unit_id, str) and unit_id in EXPECTED_SPLIT_UNIT_IDS,
            f"{manifest_path}: unexpected split authored unit",
        )
        require(unit_id not in split_units, f"duplicate split authored unit: {unit_id}")
        split_units.add(unit_id)
        if _verify_split_alignment(planning_units[unit_id], materialized, manifest_path):
            shadowed_units += 1

    require(split_units == EXPECTED_SPLIT_UNIT_IDS, "split authored Units 8-9 are incomplete")
    effective_units = direct_units | split_units
    require(
        effective_units == set(EXPECTED_UNIT_IDS),
        "effective MTH1W authored unit evidence must cover all nine planned units",
    )

    return {
        "effective_authored_units": len(effective_units),
        "direct_authored_units": len(direct_units),
        "split_authored_units": len(split_units),
        "planning_units_shadowed_by_stronger_split_evidence": shadowed_units,
    }


def main() -> int:
    result = verify_effective_authored_state()
    print(json.dumps({"valid": True, **result}, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
