import json

import pytest

from tools.check_curriculum_readiness import READINESS_PATH, ReadinessError, verify


def write_mutation(tmp_path, mutate):
    payload = json.loads(READINESS_PATH.read_text(encoding="utf-8"))
    mutate(payload)
    path = tmp_path / "curriculum-readiness.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def test_current_readiness_blocks_complete_course_claims():
    payload = verify()

    assert payload["course"]["complete_course_claim_allowed"] is False
    assert len(payload["required_gates"]) == 7


def test_complete_course_claim_fails_closed_without_evidence(tmp_path):
    path = write_mutation(
        tmp_path,
        lambda payload: payload["course"].update(
            {"complete_course_claim_allowed": True}
        ),
    )

    with pytest.raises(ReadinessError, match="fail closed"):
        verify(path)


def test_missing_source_conflict_is_rejected(tmp_path):
    path = write_mutation(
        tmp_path,
        lambda payload: payload["known_conflicts"].pop(),
    )

    with pytest.raises(ReadinessError, match="source conflicts"):
        verify(path)


def test_delivery_order_is_pinned(tmp_path):
    path = write_mutation(
        tmp_path,
        lambda payload: payload.update(
            {"delivery_sequence": ["complete-remaining-grade-9-courses"]}
        ),
    )

    with pytest.raises(ReadinessError, match="delivery sequence"):
        verify(path)
