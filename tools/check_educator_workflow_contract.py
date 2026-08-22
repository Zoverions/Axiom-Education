#!/usr/bin/env python3
"""Verify educator-workflow contract boundaries and pinned parent compatibility."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = ROOT / "schemas" / "educator-workflow-event.v1.schema.json"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.educator_workflow import EducatorWorkflowError, load_contract  # noqa: E402


class EducatorWorkflowContractError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EducatorWorkflowContractError(message)


def verify() -> dict[str, object]:
    contract = load_contract()
    try:
        schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise EducatorWorkflowContractError(f"cannot read educator workflow schema: {error}") from error
    require(schema.get("title") == "Axiom Education Educator Workflow Event v1", "workflow event schema title mismatch")
    boundary = contract.get("authority_boundary")
    require(isinstance(boundary, dict), "authority boundary missing")
    expected_false = {
        "installation_grants_authority",
        "self_asserted_educator_authority_allowed",
        "self_asserted_representative_authority_allowed",
        "raw_student_work_in_event_payload",
        "raw_feedback_in_event_payload",
        "automatic_grade_inference",
        "automatic_credit_inference",
    }
    for key in expected_false:
        require(boundary.get(key) is False, f"unsafe educator workflow boundary changed: {key}")
    require(boundary.get("governed_persistence_required") is True, "governed persistence must remain required")
    require(boundary.get("human_correction_and_appeal_required") is True, "human correction and appeal must remain required")

    event_types = contract.get("event_types")
    require(isinstance(event_types, dict), "event type registry missing")
    for event_type in (
        "assignment.created",
        "submission.created",
        "review.started",
        "feedback.recorded",
        "revision.requested",
        "submission.resubmitted",
        "review.finalized",
        "appeal.filed",
        "appeal.review.started",
        "correction.recorded",
    ):
        require(event_type in event_types, f"required workflow event missing: {event_type}")

    projection = contract.get("projection")
    require(isinstance(projection, dict), "parent projection missing")
    require(projection.get("gateway_action") == "education.learner.event.append", "workflow must use existing learner event action")
    return contract


def main() -> int:
    try:
        contract = verify()
    except (EducatorWorkflowError, EducatorWorkflowContractError) as error:
        print(f"educator workflow contract verification failed: {error}", file=sys.stderr)
        return 1
    print(
        "educator workflow contract verified: "
        f"{len(contract['event_types'])} event types; parent axiom.education v1 pinned"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
