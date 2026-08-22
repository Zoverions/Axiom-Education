from __future__ import annotations

import json

import pytest

from tools.check_mth1w_cumulative_assessment import (
    AssessmentPlanError,
    BLUEPRINT_PATH,
    PLAN_PATH,
    verify,
)


def write_mutation(tmp_path, mutate):
    payload = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    mutate(payload)
    path = tmp_path / "assessment-plan.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def test_current_plan_covers_entire_course_without_promotion():
    summary = verify()
    assert summary == {
        "stages": 5,
        "units": 9,
        "specific_expectations": 43,
        "coursewide_expectations": 3,
        "status": "machine-verified-draft-plan",
    }


def test_mastery_inference_is_rejected(tmp_path):
    path = write_mutation(
        tmp_path,
        lambda payload: payload["assessment_policy"].update(
            {"mastery_inference_allowed": True}
        ),
    )
    with pytest.raises(AssessmentPlanError, match="mastery inference"):
        verify(path, BLUEPRINT_PATH)


def test_final_must_span_all_units(tmp_path):
    def remove_unit(payload):
        payload["stages"][-1]["covered_unit_ids"].pop()

    path = write_mutation(tmp_path, remove_unit)
    with pytest.raises(AssessmentPlanError, match="span all nine"):
        verify(path, BLUEPRINT_PATH)


def test_unknown_unit_is_rejected(tmp_path):
    def inject_unknown(payload):
        payload["stages"][1]["covered_unit_ids"].append("mth1w-u10")

    path = write_mutation(tmp_path, inject_unknown)
    with pytest.raises(AssessmentPlanError, match="unknown covered units"):
        verify(path, BLUEPRINT_PATH)


def test_appeal_path_is_mandatory(tmp_path):
    def remove_appeal(payload):
        payload["stages"][2]["appeal_path"] = ""

    path = write_mutation(tmp_path, remove_appeal)
    with pytest.raises(AssessmentPlanError, match="appeal path"):
        verify(path, BLUEPRINT_PATH)


def test_only_final_stage_may_be_summative(tmp_path):
    def promote_checkpoint(payload):
        payload["stages"][1]["summative"] = True

    path = write_mutation(tmp_path, promote_checkpoint)
    with pytest.raises(AssessmentPlanError, match="only final blueprint"):
        verify(path, BLUEPRINT_PATH)


def test_final_blueprint_must_remain_summative(tmp_path):
    def demote_final(payload):
        payload["stages"][-1]["summative"] = False

    path = write_mutation(tmp_path, demote_final)
    with pytest.raises(AssessmentPlanError, match="must be summative"):
        verify(path, BLUEPRINT_PATH)


def test_stage_sequence_drift_is_rejected(tmp_path):
    def drift_sequence(payload):
        payload["stages"][2]["sequence"] = 9

    path = write_mutation(tmp_path, drift_sequence)
    with pytest.raises(AssessmentPlanError, match="contiguous and ordered"):
        verify(path, BLUEPRINT_PATH)
