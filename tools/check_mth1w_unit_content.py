#!/usr/bin/env python3
"""Verify authored MTH1W unit content against the official course blueprint."""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

try:
    from tools.check_mth1w_course_blueprint import (
        BLUEPRINT_PATH,
        PROHIBITED_LEARNER_LABELS,
        load_blueprint,
    )
except ModuleNotFoundError:  # Direct execution from the tools directory.
    from check_mth1w_course_blueprint import (  # type: ignore[no-redef]
        BLUEPRINT_PATH,
        PROHIBITED_LEARNER_LABELS,
        load_blueprint,
    )

ROOT = Path(__file__).resolve().parents[1]
CONTENT_ROOT = ROOT / "curriculum" / "content" / "mth1w"
CONTENT_PATHS = [
    CONTENT_ROOT / "u1-number-systems.v1.json",
    CONTENT_ROOT / "u2-powers.v1.json",
    CONTENT_ROOT / "u3-rational-applications.v1.json",
    CONTENT_ROOT / "u4-algebraic-thinking.v1.json",
    CONTENT_ROOT / "u5-coding-relationships.v1.json",
    CONTENT_ROOT / "u6-relations-linear-models.v1.json",
]
PRACTICE_MINIMUMS = {"guided": 3, "independent": 5, "retrieval": 3}
ALLOWED_RESPONSE_TYPES = {"selected", "short_text", "constructed"}


class UnitContentError(RuntimeError):
    """Raised when authored unit content is incomplete, unsafe, or unbound."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise UnitContentError(message)


def require_string(value: object, message: str, minimum: int = 1) -> str:
    require(
        isinstance(value, str) and len(value.strip()) >= minimum,
        message,
    )
    return value


def require_list(
    value: object,
    message: str,
    *,
    minimum_items: int = 1,
) -> list[object]:
    require(isinstance(value, list) and len(value) >= minimum_items, message)
    return value


def require_string_list(
    value: object,
    message: str,
    *,
    minimum_items: int = 1,
) -> list[str]:
    items = require_list(value, message, minimum_items=minimum_items)
    require(all(isinstance(item, str) and item.strip() for item in items), message)
    require(len(items) == len(set(items)), f"{message}: duplicate values")
    return items  # type: ignore[return-value]


def load_content(path: Path) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise UnitContentError(f"unit content is missing: {path}") from error
    except json.JSONDecodeError as error:
        raise UnitContentError(f"invalid unit content JSON: {error}") from error
    require(isinstance(payload, dict), "unit content root must be an object")
    return payload


def walk_strings(value: object):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for key, child in value.items():
            yield key
            yield from walk_strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_strings(child)


def verify_response(response: object, item_id: str) -> str:
    require(isinstance(response, dict), f"{item_id}: response contract missing")
    response_type = response.get("type")
    require(
        response_type in ALLOWED_RESPONSE_TYPES,
        f"{item_id}: unsupported response type",
    )
    if response_type == "selected":
        options = require_string_list(
            response.get("options"), f"{item_id}: selected options missing", minimum_items=3
        )
        answer = require_string(
            response.get("correct_answer"), f"{item_id}: selected answer missing"
        )
        require(answer in options, f"{item_id}: selected answer is not an option")
    elif response_type == "short_text":
        require_string_list(
            response.get("accepted_answers"),
            f"{item_id}: accepted answers missing",
        )
        require(
            response.get("case_sensitive") is False,
            f"{item_id}: short-text checking must disclose case handling",
        )
    else:
        require_string_list(
            response.get("criteria"),
            f"{item_id}: constructed-response criteria missing",
            minimum_items=2,
        )
        require_string(
            response.get("sample_response"),
            f"{item_id}: constructed sample response missing",
            40,
        )
        require(
            response.get("educator_review_required") is True,
            f"{item_id}: constructed response must require educator review",
        )
    return response_type


def verify_item(
    item: object,
    *,
    allowed_expectations: set[str] | None = None,
) -> tuple[str, str]:
    require(isinstance(item, dict), "practice or assessment item must be an object")
    item_id = require_string(item.get("id"), "item ID missing")
    require_string(item.get("prompt"), f"{item_id}: prompt missing", 12)
    if allowed_expectations is not None:
        expectation_ids = require_string_list(
            item.get("official_expectation_ids"),
            f"{item_id}: official expectation binding missing",
        )
        require(
            set(expectation_ids).issubset(allowed_expectations),
            f"{item_id}: official expectation binding is outside the unit",
        )
    response_type = verify_response(item.get("response"), item_id)
    require_string(item.get("rationale"), f"{item_id}: rationale missing", 20)
    return item_id, response_type


def verify_content(
    path: Path,
    *,
    blueprint_path: Path = BLUEPRINT_PATH,
) -> dict[str, int]:
    content = load_content(path)
    blueprint = load_blueprint(blueprint_path)

    require(
        content.get("schema") == "axiom-education-unit-content.v1",
        "unsupported unit content schema",
    )
    require(content.get("course_code") == "MTH1W", "unit course must be MTH1W")
    unit_id = require_string(content.get("unit_id"), "unit content ID missing")
    require_string(content.get("title"), f"{unit_id}: unit title missing", 12)

    source = blueprint.get("source_inventory")
    require(isinstance(source, dict), "blueprint source binding missing")
    require(
        content.get("source_inventory_records_sha256")
        == source.get("records_sha256"),
        f"{unit_id}: source inventory digest mismatch",
    )

    units = blueprint.get("units")
    require(isinstance(units, list), "blueprint units missing")
    blueprint_unit = next(
        (
            unit
            for unit in units
            if isinstance(unit, dict) and unit.get("id") == unit_id
        ),
        None,
    )
    require(isinstance(blueprint_unit, dict), f"{unit_id}: not found in blueprint")

    review = content.get("review")
    require(isinstance(review, dict), f"{unit_id}: review boundary missing")
    require(
        review.get("authoring_status") == "machine_verified_draft",
        f"{unit_id}: authoring status must remain draft",
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
        review.get("student_availability")
        == "draft_preview_with_adult_review_recommended",
        f"{unit_id}: unreviewed content must remain a clearly labelled draft preview",
    )
    require(
        review.get("complete_course_claim_allowed") is False,
        f"{unit_id}: complete-course claim must fail closed",
    )

    for text in walk_strings(content):
        require(text != "expectation_text", "unit content must not copy expectation text")
        normalized = text.casefold()
        require(
            not any(label in normalized for label in PROHIBITED_LEARNER_LABELS),
            "unit content contains a prohibited fixed learning-style label",
        )

    sources = require_list(
        content.get("source_notes"), f"{unit_id}: source notes missing", minimum_items=2
    )
    for index, note in enumerate(sources, start=1):
        require(isinstance(note, dict), f"{unit_id}: source note {index} invalid")
        require_string(note.get("title"), f"{unit_id}: source note title missing")
        require_string(note.get("publisher"), f"{unit_id}: source publisher missing")
        url = require_string(note.get("url"), f"{unit_id}: source URL missing")
        require(url.startswith("https://"), f"{unit_id}: source URL must use HTTPS")
        require_string(note.get("use"), f"{unit_id}: source use note missing", 30)

    blueprint_lessons = blueprint_unit.get("lessons")
    require(isinstance(blueprint_lessons, list), f"{unit_id}: blueprint lessons missing")
    expected_lessons = {
        lesson["id"]: lesson
        for lesson in blueprint_lessons
        if isinstance(lesson, dict) and isinstance(lesson.get("id"), str)
    }
    lessons = content.get("lessons")
    require(isinstance(lessons, list), f"{unit_id}: authored lessons missing")
    require(
        [lesson.get("id") for lesson in lessons if isinstance(lesson, dict)]
        == list(expected_lessons),
        f"{unit_id}: authored lesson IDs or order differ from blueprint",
    )

    lesson_ids: list[str] = []
    worked_ids: list[str] = []
    practice_ids: list[str] = []
    response_counts: Counter[str] = Counter()

    for lesson in lessons:
        require(isinstance(lesson, dict), f"{unit_id}: lesson must be an object")
        lesson_id = lesson["id"]
        lesson_ids.append(lesson_id)
        planned = expected_lessons[lesson_id]
        require(lesson.get("title") == planned.get("title"), f"{lesson_id}: title mismatch")
        require(
            lesson.get("estimated_minutes") == planned.get("estimated_minutes"),
            f"{lesson_id}: estimated minutes mismatch",
        )
        expectation_ids = require_string_list(
            lesson.get("official_expectation_ids"),
            f"{lesson_id}: official expectation binding missing",
        )
        require(
            Counter(expectation_ids) == Counter(planned.get("primary_expectations")),
            f"{lesson_id}: official expectation binding differs from blueprint",
        )
        require_string_list(
            lesson.get("learning_goals"),
            f"{lesson_id}: learning goals incomplete",
            minimum_items=3,
        )
        require_string_list(
            lesson.get("success_criteria"),
            f"{lesson_id}: success criteria incomplete",
            minimum_items=3,
        )
        vocabulary = require_list(
            lesson.get("vocabulary"),
            f"{lesson_id}: vocabulary incomplete",
            minimum_items=4,
        )
        for entry in vocabulary:
            require(isinstance(entry, dict), f"{lesson_id}: vocabulary entry invalid")
            require_string(entry.get("term"), f"{lesson_id}: vocabulary term missing")
            require_string(
                entry.get("meaning"), f"{lesson_id}: vocabulary meaning missing", 20
            )
        require_string(
            lesson.get("why_it_matters"), f"{lesson_id}: relevance statement missing", 80
        )

        instruction = require_list(
            lesson.get("direct_instruction"),
            f"{lesson_id}: direct instruction incomplete",
            minimum_items=3,
        )
        for block in instruction:
            require(isinstance(block, dict), f"{lesson_id}: instruction block invalid")
            require_string(block.get("heading"), f"{lesson_id}: heading missing", 6)
            require_string(block.get("body"), f"{lesson_id}: instruction body missing", 100)

        methods = require_list(
            lesson.get("method_routes"),
            f"{lesson_id}: method routes incomplete",
            minimum_items=2,
        )
        method_ids = []
        for method in methods:
            require(isinstance(method, dict), f"{lesson_id}: method route invalid")
            method_id = require_string(method.get("id"), f"{lesson_id}: method ID missing")
            method_ids.append(method_id)
            require_string(method.get("title"), f"{method_id}: method title missing")
            require_string_list(
                method.get("steps"), f"{method_id}: method steps incomplete", minimum_items=4
            )
            require_string(
                method.get("when_useful"), f"{method_id}: use guidance missing", 40
            )
            require_string(method.get("check"), f"{method_id}: method check missing", 30)
        require(len(method_ids) == len(set(method_ids)), f"{lesson_id}: method IDs duplicate")

        representations = require_list(
            lesson.get("representations"),
            f"{lesson_id}: representations incomplete",
            minimum_items=2,
        )
        representation_ids = []
        for representation in representations:
            require(
                isinstance(representation, dict),
                f"{lesson_id}: representation invalid",
            )
            representation_id = require_string(
                representation.get("id"), f"{lesson_id}: representation ID missing"
            )
            representation_ids.append(representation_id)
            require_string(
                representation.get("label"), f"{representation_id}: label missing"
            )
            require_string(
                representation.get("description"),
                f"{representation_id}: description missing",
                40,
            )
            require_string(
                representation.get("text_alternative"),
                f"{representation_id}: text alternative missing",
                40,
            )
        require(
            len(representation_ids) == len(set(representation_ids)),
            f"{lesson_id}: representation IDs duplicate",
        )

        examples = require_list(
            lesson.get("worked_examples"),
            f"{lesson_id}: worked examples incomplete",
            minimum_items=2,
        )
        for example in examples:
            require(isinstance(example, dict), f"{lesson_id}: worked example invalid")
            example_id = require_string(
                example.get("id"), f"{lesson_id}: worked example ID missing"
            )
            worked_ids.append(example_id)
            require_string(example.get("prompt"), f"{example_id}: prompt missing", 20)
            require(
                example.get("method_route_id") in method_ids,
                f"{example_id}: method route binding invalid",
            )
            steps = require_list(
                example.get("steps"), f"{example_id}: steps incomplete", minimum_items=3
            )
            for step in steps:
                require(isinstance(step, dict), f"{example_id}: worked step invalid")
                require_string(step.get("label"), f"{example_id}: step label missing")
                require_string(
                    step.get("explanation"),
                    f"{example_id}: step explanation missing",
                    25,
                )
            require_string(example.get("answer"), f"{example_id}: answer missing", 20)
            require_string(
                example.get("verification"),
                f"{example_id}: verification missing",
                25,
            )

        misconceptions = require_list(
            lesson.get("misconceptions"),
            f"{lesson_id}: misconception checks incomplete",
            minimum_items=3,
        )
        for misconception in misconceptions:
            require(
                isinstance(misconception, dict),
                f"{lesson_id}: misconception entry invalid",
            )
            require_string(
                misconception.get("claim"), f"{lesson_id}: misconception claim missing"
            )
            require_string(
                misconception.get("correction"),
                f"{lesson_id}: misconception correction missing",
                20,
            )

        practice = lesson.get("practice_sets")
        require(isinstance(practice, dict), f"{lesson_id}: practice sets missing")
        require(
            set(practice) == set(PRACTICE_MINIMUMS),
            f"{lesson_id}: practice phases incomplete",
        )
        for phase, minimum in PRACTICE_MINIMUMS.items():
            items = require_list(
                practice.get(phase),
                f"{lesson_id}: {phase} practice incomplete",
                minimum_items=minimum,
            )
            phase_types: Counter[str] = Counter()
            for item in items:
                item_id, response_type = verify_item(item)
                practice_ids.append(item_id)
                response_counts[response_type] += 1
                phase_types[response_type] += 1
            require(
                phase_types["constructed"] >= 1,
                f"{lesson_id}: {phase} practice needs an educator-reviewable explanation",
            )

        require_string(
            lesson.get("reflection_prompt"),
            f"{lesson_id}: reflection prompt missing",
            30,
        )
        accessibility = lesson.get("accessibility")
        require(isinstance(accessibility, dict), f"{lesson_id}: accessibility plan missing")
        require(
            accessibility.get("printable_equivalent") is True,
            f"{lesson_id}: printable equivalent missing",
        )
        require_string(
            accessibility.get("nonvisual_route"),
            f"{lesson_id}: nonvisual route missing",
            40,
        )
        require_string_list(
            accessibility.get("response_options"),
            f"{lesson_id}: response options incomplete",
            minimum_items=3,
        )

    require(len(lesson_ids) == len(set(lesson_ids)), f"{unit_id}: lesson IDs duplicate")
    require(len(worked_ids) == len(set(worked_ids)), f"{unit_id}: worked example IDs duplicate")
    require(len(practice_ids) == len(set(practice_ids)), f"{unit_id}: practice item IDs duplicate")

    assessment = content.get("unit_assessment")
    require(isinstance(assessment, dict), f"{unit_id}: unit assessment missing")
    planned_assessment = blueprint_unit.get("assessment")
    require(isinstance(planned_assessment, dict), f"{unit_id}: blueprint assessment missing")
    allowed_expectations = set(blueprint_unit.get("specific_expectations", []))

    quiz = assessment.get("quiz")
    require(isinstance(quiz, dict), f"{unit_id}: quiz missing")
    require(quiz.get("id") == planned_assessment.get("quiz_id"), f"{unit_id}: quiz ID mismatch")
    require_string(quiz.get("title"), f"{unit_id}: quiz title missing", 8)
    require(
        isinstance(quiz.get("estimated_minutes"), int)
        and 15 <= quiz["estimated_minutes"] <= 90,
        f"{unit_id}: quiz time invalid",
    )
    require(
        quiz.get("attempt_policy") == "feedback_after_submission_then_correction_attempt",
        f"{unit_id}: quiz correction policy missing",
    )
    quiz_items = require_list(
        quiz.get("items"), f"{unit_id}: quiz items incomplete", minimum_items=10
    )
    quiz_ids = []
    quiz_coverage: list[str] = []
    for item in quiz_items:
        item_id, response_type = verify_item(item, allowed_expectations=allowed_expectations)
        quiz_ids.append(item_id)
        response_counts[response_type] += 1
        quiz_coverage.extend(item["official_expectation_ids"])
    require(len(quiz_ids) == len(set(quiz_ids)), f"{unit_id}: quiz IDs duplicate")
    require(
        allowed_expectations.issubset(quiz_coverage),
        f"{unit_id}: quiz does not sample every specific expectation",
    )

    task = assessment.get("performance_task")
    require(isinstance(task, dict), f"{unit_id}: performance task missing")
    require(
        task.get("id") == planned_assessment.get("performance_task_id"),
        f"{unit_id}: performance-task ID mismatch",
    )
    require(
        isinstance(task.get("estimated_minutes"), int)
        and 60 <= task["estimated_minutes"] <= 300,
        f"{unit_id}: performance-task time invalid",
    )
    task_expectations = require_string_list(
        task.get("official_expectation_ids"),
        f"{unit_id}: performance-task binding missing",
        minimum_items=3,
    )
    require(
        allowed_expectations.issubset(task_expectations),
        f"{unit_id}: performance task must cover every unit expectation",
    )
    require_string(task.get("prompt"), f"{unit_id}: performance prompt missing", 80)
    require_string_list(
        task.get("required_components"),
        f"{unit_id}: performance requirements incomplete",
        minimum_items=6,
    )
    rubric = require_list(
        task.get("rubric"), f"{unit_id}: rubric incomplete", minimum_items=4
    )
    for dimension in rubric:
        require(isinstance(dimension, dict), f"{unit_id}: rubric dimension invalid")
        require_string(dimension.get("dimension"), f"{unit_id}: rubric name missing")
        require_string(
            dimension.get("criteria"), f"{unit_id}: rubric criteria missing", 30
        )
    require(
        task.get("educator_review_required") is True,
        f"{unit_id}: performance task must require educator review",
    )
    require(
        task.get("status") == "machine_verified_draft",
        f"{unit_id}: performance task status must remain draft",
    )

    return {
        "lessons": len(lesson_ids),
        "worked_examples": len(worked_ids),
        "practice_items": len(practice_ids),
        "quiz_items": len(quiz_ids),
        "constructed_responses": response_counts["constructed"],
    }


def verify_all(paths: list[Path] = CONTENT_PATHS) -> dict[str, int]:
    require(paths, "no MTH1W unit content files are configured")
    totals: Counter[str] = Counter()
    seen_units: set[str] = set()
    for path in paths:
        content = load_content(path)
        unit_id = require_string(content.get("unit_id"), f"{path}: unit ID missing")
        require(unit_id not in seen_units, f"duplicate unit content package: {unit_id}")
        seen_units.add(unit_id)
        totals.update(verify_content(path))
    return dict(totals)


def main() -> int:
    try:
        counts = verify_all()
    except (OSError, UnitContentError) as error:
        print(f"MTH1W unit content verification failed: {error}", file=sys.stderr)
        return 1

    print(
        "MTH1W authored unit content verified: "
        f"{counts['lessons']} lessons, {counts['worked_examples']} worked examples, "
        f"{counts['practice_items']} practice items, {counts['quiz_items']} quiz items; "
        "draft preview only; educator review and full-course availability blocked"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
