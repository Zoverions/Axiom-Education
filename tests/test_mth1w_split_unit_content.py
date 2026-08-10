import json

import pytest

from tools.check_mth1w_split_unit_content import (
    MANIFEST_PATHS,
    SplitUnitContentError,
    materialize_manifest,
    verify_all_split,
    verify_split_manifest,
)
from tools.check_mth1w_unit_content import UnitContentError


UNIT_EIGHT_MANIFEST = MANIFEST_PATHS[0]
UNIT_NINE_MANIFEST = MANIFEST_PATHS[1]


def write_manifest(tmp_path, mutate):
    payload = json.loads(UNIT_EIGHT_MANIFEST.read_text(encoding="utf-8"))
    mutate(payload)
    path = tmp_path / "manifest.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def test_unit_eight_materializes_through_canonical_content_contract():
    materialized = materialize_manifest(UNIT_EIGHT_MANIFEST)

    assert materialized["unit_id"] == "mth1w-u8"
    assert "lesson_assets" not in materialized
    assert [lesson["id"] for lesson in materialized["lessons"]] == [
        "mth1w-u8-l1",
        "mth1w-u8-l2",
        "mth1w-u8-l3",
        "mth1w-u8-l4",
        "mth1w-u8-l5",
        "mth1w-u8-l6",
    ]
    assert [lesson["official_expectation_ids"] for lesson in materialized["lessons"]] == [
        ["E1.1"],
        ["E1.2"],
        ["E1.3"],
        ["E1.4"],
        ["E1.5"],
        ["E1.6"],
    ]


def test_unit_nine_materializes_through_canonical_content_contract():
    materialized = materialize_manifest(UNIT_NINE_MANIFEST)

    assert materialized["unit_id"] == "mth1w-u9"
    assert "lesson_assets" not in materialized
    assert [lesson["id"] for lesson in materialized["lessons"]] == [
        "mth1w-u9-l1",
        "mth1w-u9-l2",
        "mth1w-u9-l3",
        "mth1w-u9-l4",
    ]
    assert [lesson["official_expectation_ids"] for lesson in materialized["lessons"]] == [
        ["F1.1"],
        ["F1.2"],
        ["F1.3"],
        ["F1.4"],
    ]


def test_split_units_have_planned_teaching_practice_and_assessment_depth():
    assert verify_split_manifest(UNIT_EIGHT_MANIFEST) == {
        "lessons": 6,
        "worked_examples": 12,
        "practice_items": 66,
        "quiz_items": 10,
        "constructed_responses": 22,
    }
    assert verify_split_manifest(UNIT_NINE_MANIFEST) == {
        "lessons": 4,
        "worked_examples": 8,
        "practice_items": 44,
        "quiz_items": 10,
        "constructed_responses": 17,
    }
    assert verify_all_split() == {
        "lessons": 10,
        "worked_examples": 20,
        "practice_items": 110,
        "quiz_items": 20,
        "constructed_responses": 39,
        "units": 2,
    }


def test_split_manifest_rejects_duplicate_lesson_assets(tmp_path):
    path = write_manifest(
        tmp_path,
        lambda payload: payload["lesson_assets"].append(payload["lesson_assets"][0]),
    )

    with pytest.raises(SplitUnitContentError, match="must be unique"):
        materialize_manifest(path)


def test_split_manifest_rejects_repository_escape(tmp_path):
    path = write_manifest(
        tmp_path,
        lambda payload: payload["lesson_assets"].__setitem__(0, "../outside.json"),
    )

    with pytest.raises(SplitUnitContentError, match="escapes repository"):
        materialize_manifest(path)


def test_materialized_split_unit_still_fails_closed_on_canonical_drift(tmp_path):
    path = write_manifest(
        tmp_path,
        lambda payload: payload["unit_assessment"]["quiz"].update(
            {"attempt_policy": "show_answers_immediately"}
        ),
    )

    with pytest.raises(UnitContentError, match="quiz correction policy missing"):
        verify_split_manifest(path)
