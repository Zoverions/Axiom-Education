#!/usr/bin/env python3
"""Verify the complete, non-verbatim MTH1W production course blueprint."""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

try:
    from tools.mth1w_official_inventory import (
        DEFAULT_INVENTORY_PATH,
        OVERALL_IDS,
        load_inventory,
        verify_inventory,
    )
except ModuleNotFoundError:  # Direct execution from the tools directory.
    from mth1w_official_inventory import (  # type: ignore[no-redef]
        DEFAULT_INVENTORY_PATH,
        OVERALL_IDS,
        load_inventory,
        verify_inventory,
    )

ROOT = Path(__file__).resolve().parents[1]
BLUEPRINT_PATH = ROOT / "curriculum" / "courses" / "ontario-mth1w-2021.course.json"
EXPECTED_UNIT_IDS = [f"mth1w-u{index}" for index in range(1, 10)]
COURSEWIDE_IDS = {"AA1", "A1", "A2"}
REQUIRED_PRACTICE_PHASES = {"guided", "independent", "retrieval"}
PROHIBITED_LEARNER_LABELS = {
    "visual learner",
    "auditory learner",
    "kinaesthetic learner",
    "kinesthetic learner",
    "learning style type",
}


class BlueprintError(RuntimeError):
    """Raised when the production blueprint is incomplete or unsafe."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise BlueprintError(message)


def load_blueprint(path: Path = BLUEPRINT_PATH) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise BlueprintError(f"course blueprint is missing: {path}") from error
    except json.JSONDecodeError as error:
        raise BlueprintError(f"invalid course blueprint JSON: {error}") from error
    require(isinstance(payload, dict), "course blueprint root must be an object")
    return payload


def walk(value: object):
    yield value
    if isinstance(value, dict):
        for key, child in value.items():
            yield key
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def require_string(value: object, message: str, minimum: int = 1) -> str:
    require(
        isinstance(value, str) and len(value.strip()) >= minimum,
        message,
    )
    return value


def require_string_list(
    value: object,
    message: str,
    *,
    minimum_items: int = 1,
) -> list[str]:
    require(isinstance(value, list), message)
    require(len(value) >= minimum_items, message)
    require(all(isinstance(item, str) and item.strip() for item in value), message)
    require(len(value) == len(set(value)), f"{message}: duplicate values")
    return value


def verify(
    blueprint_path: Path = BLUEPRINT_PATH,
    inventory_path: Path = DEFAULT_INVENTORY_PATH,
) -> dict[str, int]:
    blueprint = load_blueprint(blueprint_path)
    inventory = load_inventory(inventory_path)
    verify_inventory(inventory)

    require(
        blueprint.get("schema") == "axiom-education-course-blueprint.v1",
        "unsupported course blueprint schema",
    )
    course = blueprint.get("course")
    require(isinstance(course, dict), "course metadata must be an object")
    require(course.get("code") == "MTH1W", "course code must be MTH1W")
    require(course.get("estimated_hours_total") == 110, "course must allocate 110 hours")
    require(
        course.get("student_availability") == "not_available_course_in_build",
        "course in build must not be student available",
    )
    require(
        course.get("content_status") == "partial_machine_verified_draft",
        "course content status must remain a partial draft",
    )
    require(
        course.get("complete_course_claim_allowed") is False,
        "course-complete claim must fail closed",
    )

    source = blueprint.get("source_inventory")
    require(isinstance(source, dict), "source inventory binding must be an object")
    require(
        source.get("path")
        == "curriculum/official/ontario-mth1w-2021.inventory.json",
        "source inventory path mismatch",
    )
    require(
        source.get("records_sha256") == inventory.get("records_sha256"),
        "source inventory records digest mismatch",
    )
    require(
        source.get("verbatim_expectation_text_included") is False,
        "blueprint must not redistribute verbatim expectation descriptions",
    )

    for item in walk(blueprint):
        if isinstance(item, str):
            require(
                item != "expectation_text",
                "blueprint must not contain an expectation_text field",
            )
            normalized = item.casefold()
            require(
                not any(label in normalized for label in PROHIBITED_LEARNER_LABELS),
                "blueprint contains a prohibited fixed learning-style label",
            )

    coursewide = blueprint.get("coursewide_expectations")
    require(isinstance(coursewide, dict), "coursewide expectations must be an object")
    coursewide_ids = require_string_list(
        coursewide.get("ids"), "coursewide expectation IDs are incomplete", minimum_items=3
    )
    require(set(coursewide_ids) == COURSEWIDE_IDS, "coursewide expectation IDs changed")
    require(
        coursewide.get("delivery") == "embedded_in_every_unit",
        "coursewide expectations must be embedded in every unit",
    )

    policy = blueprint.get("instructional_policy")
    require(isinstance(policy, dict), "instructional policy must be an object")
    require(
        policy.get("minimum_method_routes_per_lesson") == 2,
        "two method routes per lesson are required",
    )
    require(
        policy.get("minimum_representations_per_lesson") == 2,
        "two representations per lesson are required",
    )
    require(
        policy.get("fixed_learning_style_labels_allowed") is False,
        "fixed learning-style labels must be prohibited",
    )
    require(
        set(require_string_list(policy.get("required_practice_phases"), "practice phases missing"))
        == REQUIRED_PRACTICE_PHASES,
        "guided, independent, and retrieval practice are required",
    )

    authored_content = blueprint.get("authored_unit_content")
    expected_authored_paths = {
        "mth1w-u1": "curriculum/content/mth1w/u1-number-systems.v1.json",
        "mth1w-u2": "curriculum/content/mth1w/u2-powers.v1.json",
        "mth1w-u3": "curriculum/content/mth1w/u3-rational-applications.v1.json",
        "mth1w-u4": "curriculum/content/mth1w/u4-algebraic-thinking.v1.json",
        "mth1w-u5": "curriculum/content/mth1w/u5-coding-relationships.v1.json",
        "mth1w-u6": "curriculum/content/mth1w/u6-relations-linear-models.v1.json",
    }
    require(
        isinstance(authored_content, list) and len(authored_content) == 6,
        "exactly six authored draft units must be declared at this milestone",
    )
    authored_unit_ids: set[str] = set()
    for authored_unit in authored_content:
        require(isinstance(authored_unit, dict), "authored unit declaration invalid")
        unit_id = authored_unit.get("unit_id")
        require(unit_id in expected_authored_paths, "authored unit ID mismatch")
        require(unit_id not in authored_unit_ids, "authored unit ID duplicate")
        authored_unit_ids.add(unit_id)
        require(
            authored_unit.get("path") == expected_authored_paths[unit_id],
            "authored unit content path mismatch",
        )
        require(
            authored_unit.get("status") == "machine_verified_draft",
            "authored unit status must remain draft",
        )
        require(
            authored_unit.get("educator_review_status") == "required",
            "authored unit must still require educator review",
        )
        require(
            authored_unit.get("student_availability")
            == "draft_preview_with_adult_review_recommended",
            "authored unit availability must remain a clearly labelled draft preview",
        )
    require(
        authored_unit_ids == set(expected_authored_paths),
        "authored unit declarations are incomplete",
    )

    official_records = inventory.get("records")
    require(isinstance(official_records, list), "official inventory records missing")
    official_specific = {
        record["id"]
        for record in official_records
        if isinstance(record, dict) and record.get("kind") == "specific"
    }

    units = blueprint.get("units")
    require(isinstance(units, list), "course units must be an array")
    require(len(units) == 9, "MTH1W blueprint must contain nine units")
    require(
        [unit.get("id") for unit in units if isinstance(unit, dict)] == EXPECTED_UNIT_IDS,
        "unit IDs or order changed",
    )

    all_overall: list[str] = list(coursewide_ids)
    all_specific: list[str] = []
    lesson_primary: list[str] = []
    lesson_ids: list[str] = []
    assessment_ids: list[str] = []
    total_hours = 0

    for unit_index, unit in enumerate(units, start=1):
        require(isinstance(unit, dict), f"unit {unit_index} must be an object")
        unit_id = unit["id"]
        require(unit.get("sequence") == unit_index, f"{unit_id}: sequence mismatch")
        require_string(unit.get("title"), f"{unit_id}: title missing", 8)
        hours = unit.get("estimated_hours")
        require(isinstance(hours, int) and hours > 0, f"{unit_id}: hours invalid")
        total_hours += hours

        overall_ids = require_string_list(
            unit.get("overall_expectations"), f"{unit_id}: overall expectations missing"
        )
        specific_ids = require_string_list(
            unit.get("specific_expectations"), f"{unit_id}: specific expectations missing"
        )
        require(
            set(overall_ids).issubset(OVERALL_IDS - COURSEWIDE_IDS),
            f"{unit_id}: unknown or coursewide overall expectation",
        )
        require(
            set(specific_ids).issubset(official_specific),
            f"{unit_id}: unknown specific expectation",
        )
        all_overall.extend(overall_ids)
        all_specific.extend(specific_ids)

        lessons = unit.get("lessons")
        require(isinstance(lessons, list) and lessons, f"{unit_id}: lessons missing")
        require(
            [lesson.get("sequence") for lesson in lessons if isinstance(lesson, dict)]
            == list(range(1, len(lessons) + 1)),
            f"{unit_id}: lesson sequence mismatch",
        )
        unit_primary: list[str] = []
        for lesson in lessons:
            require(isinstance(lesson, dict), f"{unit_id}: lesson must be an object")
            lesson_id = require_string(lesson.get("id"), f"{unit_id}: lesson ID missing")
            lesson_ids.append(lesson_id)
            require_string(lesson.get("title"), f"{lesson_id}: title missing", 8)
            minutes = lesson.get("estimated_minutes")
            require(
                isinstance(minutes, int) and 45 <= minutes <= 180,
                f"{lesson_id}: estimated minutes invalid",
            )
            primary = require_string_list(
                lesson.get("primary_expectations"),
                f"{lesson_id}: primary expectations missing",
            )
            require(
                set(primary).issubset(specific_ids),
                f"{lesson_id}: primary expectation is outside its unit",
            )
            unit_primary.extend(primary)
            lesson_primary.extend(primary)
            require_string(lesson.get("outcome"), f"{lesson_id}: outcome missing", 30)
            require_string_list(
                lesson.get("prerequisites"),
                f"{lesson_id}: prerequisites missing",
                minimum_items=2,
            )
            require_string_list(
                lesson.get("method_routes"),
                f"{lesson_id}: method routes missing",
                minimum_items=2,
            )
            require_string_list(
                lesson.get("representations"),
                f"{lesson_id}: representations missing",
                minimum_items=2,
            )
            practice = lesson.get("practice")
            require(isinstance(practice, dict), f"{lesson_id}: practice plan missing")
            require(
                set(practice) == REQUIRED_PRACTICE_PHASES,
                f"{lesson_id}: practice phases incomplete",
            )
            for phase, description in practice.items():
                require_string(
                    description,
                    f"{lesson_id}: {phase} practice description missing",
                    20,
                )
            expected_lesson_status = (
                "machine_verified_draft"
                if unit_id in authored_unit_ids
                else "specified_not_implemented"
            )
            require(
                lesson.get("status") == expected_lesson_status,
                f"{lesson_id}: lesson status does not match authored evidence",
            )

        require(
            Counter(unit_primary) == Counter(specific_ids),
            f"{unit_id}: every specific expectation needs one primary lesson",
        )

        assessment = unit.get("assessment")
        require(isinstance(assessment, dict), f"{unit_id}: assessment plan missing")
        quiz_id = require_string(
            assessment.get("quiz_id"), f"{unit_id}: quiz ID missing"
        )
        performance_id = require_string(
            assessment.get("performance_task_id"),
            f"{unit_id}: performance-task ID missing",
        )
        assessment_ids.extend([quiz_id, performance_id])
        assessed = require_string_list(
            assessment.get("expectation_ids"),
            f"{unit_id}: assessment coverage missing",
        )
        require(
            Counter(assessed) == Counter(specific_ids),
            f"{unit_id}: assessment coverage differs from unit coverage",
        )
        expected_assessment_status = (
            "machine_verified_draft"
            if unit_id in authored_unit_ids
            else "specified_not_implemented"
        )
        require(
            assessment.get("status") == expected_assessment_status,
            f"{unit_id}: assessment status does not match authored evidence",
        )

    require(total_hours == 110, "unit hours must sum to 110")
    require(
        Counter(all_overall) == Counter(OVERALL_IDS),
        "overall expectation coverage is incomplete or duplicated",
    )
    require(
        Counter(all_specific) == Counter(official_specific),
        "specific expectation unit coverage is incomplete or duplicated",
    )
    require(
        Counter(lesson_primary) == Counter(official_specific),
        "specific expectation lesson coverage is incomplete or duplicated",
    )
    require(len(lesson_ids) == len(set(lesson_ids)), "lesson IDs must be unique")
    require(
        len(assessment_ids) == len(set(assessment_ids)),
        "unit assessment IDs must be unique",
    )

    cumulative = blueprint.get("cumulative_assessment_plan")
    require(isinstance(cumulative, dict), "cumulative assessment plan missing")
    diagnostic = cumulative.get("diagnostic")
    require(isinstance(diagnostic, dict), "course diagnostic plan missing")
    require(
        diagnostic.get("grading_use") == "planning_only_not_a_grade",
        "diagnostic must not become a grade",
    )
    checkpoints = cumulative.get("checkpoints")
    require(
        isinstance(checkpoints, list) and len(checkpoints) == 2,
        "two cumulative checkpoints are required",
    )
    checkpoint_ids = []
    for checkpoint in checkpoints:
        require(isinstance(checkpoint, dict), "checkpoint must be an object")
        checkpoint_ids.extend(
            require_string_list(
                checkpoint.get("expectation_ids"),
                "checkpoint expectation coverage missing",
            )
        )
        require(
            checkpoint.get("status") == "specified_not_implemented",
            "checkpoint must not claim implementation",
        )
    require(
        set(checkpoint_ids).issubset(official_specific),
        "checkpoint contains an unknown specific expectation",
    )
    final_written = cumulative.get("final_written_assessment")
    require(isinstance(final_written, dict), "final written assessment plan missing")
    require(
        final_written.get("expectation_scope") == "all_specific_expectations",
        "final written assessment must cover the full course",
    )
    final_task = cumulative.get("final_performance_task")
    require(isinstance(final_task, dict), "final performance task plan missing")
    require(
        final_task.get("expectation_scope")
        == "cross_strand_sample_with_coursewide_processes",
        "final performance task scope mismatch",
    )

    accessibility = blueprint.get("accessibility_and_offline_plan")
    require(isinstance(accessibility, dict), "accessibility and offline plan missing")
    require_string_list(
        accessibility.get("requirements"),
        "accessibility and offline requirements incomplete",
        minimum_items=8,
    )
    require(
        accessibility.get("status") == "specified_not_implemented",
        "accessibility plan must not claim implementation",
    )

    return {
        "units": len(units),
        "lessons": len(lesson_ids),
        "overall_expectations": len(OVERALL_IDS),
        "specific_expectations": len(official_specific),
        "hours": total_hours,
    }


def main() -> int:
    try:
        counts = verify()
    except (BlueprintError, OSError) as error:
        print(f"MTH1W course blueprint verification failed: {error}", file=sys.stderr)
        return 1

    print(
        "MTH1W course blueprint verified: "
        f"{counts['units']} units, {counts['lessons']} lessons, "
        f"{counts['overall_expectations']} overall and "
        f"{counts['specific_expectations']} specific expectations, "
        f"{counts['hours']} hours specified; student availability blocked"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
