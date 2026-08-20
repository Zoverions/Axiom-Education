from __future__ import annotations

import json
from pathlib import Path

import pytest

from tools.check_mth1w_course_blueprint import BLUEPRINT_PATH
from tools.check_mth1w_effective_authored_state import (
    EffectiveAuthoredStateError,
    verify_effective_authored_state,
)


def write_blueprint_mutation(tmp_path: Path, mutate) -> Path:
    payload = json.loads(BLUEPRINT_PATH.read_text(encoding="utf-8"))
    mutate(payload)
    path = tmp_path / "course.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def test_current_effective_state_recognizes_all_nine_authored_units() -> None:
    result = verify_effective_authored_state()
    assert result == {
        "effective_authored_units": 9,
        "direct_authored_units": 7,
        "split_authored_units": 2,
        "planning_units_shadowed_by_stronger_split_evidence": 2,
    }


def test_split_authored_evidence_must_align_with_planning_minutes(tmp_path: Path) -> None:
    def mutate(payload):
        payload["units"][7]["lessons"][0]["estimated_minutes"] = 120

    path = write_blueprint_mutation(tmp_path, mutate)
    with pytest.raises(EffectiveAuthoredStateError, match="minute mismatch"):
        verify_effective_authored_state(path)


def test_unknown_planning_status_cannot_hide_behind_split_authored_evidence(
    tmp_path: Path,
) -> None:
    def mutate(payload):
        payload["units"][8]["lessons"][0]["status"] = "production_ready"

    path = write_blueprint_mutation(tmp_path, mutate)
    with pytest.raises(EffectiveAuthoredStateError, match="unsupported planning status"):
        verify_effective_authored_state(path)


def test_direct_authored_declarations_must_still_cover_units_one_through_seven(
    tmp_path: Path,
) -> None:
    def mutate(payload):
        payload["authored_unit_content"].pop()

    path = write_blueprint_mutation(tmp_path, mutate)
    with pytest.raises(EffectiveAuthoredStateError, match="Units 1-7 are incomplete"):
        verify_effective_authored_state(path)
