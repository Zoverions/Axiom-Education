import json

import pytest

from tools.check_mth1w_course_blueprint import (
    BLUEPRINT_PATH,
    BlueprintError,
    verify,
)


def write_mutation(tmp_path, mutate):
    payload = json.loads(BLUEPRINT_PATH.read_text(encoding="utf-8"))
    mutate(payload)
    path = tmp_path / "course.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def test_current_blueprint_covers_the_complete_official_course_once():
    counts = verify()

    assert counts == {
        "units": 9,
        "lessons": 43,
        "overall_expectations": 14,
        "specific_expectations": 43,
        "hours": 110,
    }


def test_missing_specific_expectation_is_rejected(tmp_path):
    def remove_expectation(payload):
        payload["units"][0]["specific_expectations"].pop()

    path = write_mutation(tmp_path, remove_expectation)

    with pytest.raises(BlueprintError, match="primary expectation is outside"):
        verify(path)


def test_lesson_without_two_method_routes_is_rejected(tmp_path):
    def remove_route(payload):
        payload["units"][0]["lessons"][0]["method_routes"].pop()

    path = write_mutation(tmp_path, remove_route)

    with pytest.raises(BlueprintError, match="method routes missing"):
        verify(path)


def test_blueprint_cannot_be_presented_as_student_ready(tmp_path):
    path = write_mutation(
        tmp_path,
        lambda payload: payload["course"].update(
            {
                "student_availability": "available",
                "content_status": "implemented",
                "complete_course_claim_allowed": True,
            }
        ),
    )

    with pytest.raises(BlueprintError, match="must not be student available"):
        verify(path)


def test_verbatim_expectation_field_is_rejected(tmp_path):
    path = write_mutation(
        tmp_path,
        lambda payload: payload["units"][0]["lessons"][0].update(
            {"expectation_text": "not allowed"}
        ),
    )

    with pytest.raises(BlueprintError, match="expectation_text"):
        verify(path)


def test_unit_hours_must_preserve_the_110_hour_course(tmp_path):
    path = write_mutation(
        tmp_path,
        lambda payload: payload["units"][0].update({"estimated_hours": 7}),
    )

    with pytest.raises(BlueprintError, match="sum to 110"):
        verify(path)


def test_each_authored_unit_declaration_is_required(tmp_path):
    path = write_mutation(
        tmp_path,
        lambda payload: payload["authored_unit_content"].pop(),
    )

    with pytest.raises(BlueprintError, match="exactly seven authored draft units"):
        verify(path)
