import json

import pytest

from tools.check_mth1w_unit_content import (
    CONTENT_PATHS,
    UnitContentError,
    verify_all,
    verify_content,
)


CONTENT_PATH = CONTENT_PATHS[0]


def write_mutation(tmp_path, mutate):
    payload = json.loads(CONTENT_PATH.read_text(encoding="utf-8"))
    mutate(payload)
    path = tmp_path / "unit.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def test_current_unit_has_teaching_practice_and_assessment_depth():
    counts = verify_all()

    assert counts == {
        "lessons": 18,
        "worked_examples": 36,
        "practice_items": 198,
        "quiz_items": 50,
        "constructed_responses": 72,
    }


def test_missing_item_rationale_is_rejected(tmp_path):
    def remove_rationale(payload):
        payload["lessons"][0]["practice_sets"]["guided"][0].pop("rationale")

    path = write_mutation(tmp_path, remove_rationale)

    with pytest.raises(UnitContentError, match="rationale missing"):
        verify_content(path)


def test_selected_answer_must_be_one_of_the_options(tmp_path):
    def change_answer(payload):
        payload["lessons"][0]["practice_sets"]["guided"][0]["response"][
            "correct_answer"
        ] = "not an option"

    path = write_mutation(tmp_path, change_answer)

    with pytest.raises(UnitContentError, match="not an option"):
        verify_content(path)


def test_official_lesson_binding_must_match_the_blueprint(tmp_path):
    path = write_mutation(
        tmp_path,
        lambda payload: payload["lessons"][0].update(
            {"official_expectation_ids": ["B1.2"]}
        ),
    )

    with pytest.raises(UnitContentError, match="differs from blueprint"):
        verify_content(path)


def test_unreviewed_unit_cannot_be_student_available(tmp_path):
    path = write_mutation(
        tmp_path,
        lambda payload: payload["review"].update(
            {"student_availability": "available"}
        ),
    )

    with pytest.raises(UnitContentError, match="clearly labelled draft preview"):
        verify_content(path)


def test_constructed_response_requires_educator_review(tmp_path):
    def remove_review(payload):
        payload["lessons"][0]["practice_sets"]["guided"][2]["response"][
            "educator_review_required"
        ] = False

    path = write_mutation(tmp_path, remove_review)

    with pytest.raises(UnitContentError, match="must require educator review"):
        verify_content(path)


def test_every_representation_requires_a_text_alternative(tmp_path):
    def remove_alternative(payload):
        payload["lessons"][0]["representations"][0].pop("text_alternative")

    path = write_mutation(tmp_path, remove_alternative)

    with pytest.raises(UnitContentError, match="text alternative missing"):
        verify_content(path)


def test_performance_task_requires_a_bounded_time(tmp_path):
    def remove_time(payload):
        payload["unit_assessment"]["performance_task"].pop("estimated_minutes")

    path = write_mutation(tmp_path, remove_time)

    with pytest.raises(UnitContentError, match="performance-task time invalid"):
        verify_content(path)
