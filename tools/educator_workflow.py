#!/usr/bin/env python3
"""Verify digest-chained educator workflow events and project them to axiom.education v1.

This module defines workflow semantics only. It does not persist learner data, establish
actor authority, infer mastery, or award grades/credits.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW_CONTRACT_PATH = ROOT / "contracts" / "axiom-education-educator-workflow.v1.json"
PARENT_CONTRACT_PATH = ROOT / "contracts" / "axiom-education.v1.json"
EXPECTED_PARENT_SHA256 = "a20e191a05308ef85bdc1cc74bfa0d54b98a176818f8030a172b4c3709a28fa2"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
EVENT_FIELDS = {
    "schema",
    "workflow_id",
    "assignment_id",
    "subject_id",
    "learning_context_id",
    "course_code",
    "expectation_ids",
    "event_id",
    "event_type",
    "actor_role",
    "occurred_at",
    "previous_event_digest",
    "artifact_digest",
    "feedback_digest",
    "reason_digest",
    "review_state",
    "payload_digest",
}
DIGEST_FIELDS = {"artifact_digest", "feedback_digest", "reason_digest"}


class EducatorWorkflowError(RuntimeError):
    """Raised when workflow semantics or AXIOM projection fail closed."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EducatorWorkflowError(message)


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise EducatorWorkflowError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise EducatorWorkflowError(f"invalid JSON in {path}: {error}") from error


def canonical_digest(value: Any) -> str:
    encoded = json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def event_digest(event: dict[str, Any]) -> str:
    payload = dict(event)
    payload.pop("payload_digest", None)
    return canonical_digest(payload)


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_contract() -> dict[str, Any]:
    contract = load_json(WORKFLOW_CONTRACT_PATH)
    require(isinstance(contract, dict), "workflow contract must be an object")
    require(
        contract.get("schema") == "axiom-education-educator-workflow-contract.v1",
        "unsupported educator workflow contract",
    )
    parent = contract.get("parent_contract")
    require(isinstance(parent, dict), "parent contract binding missing")
    require(parent.get("contract_id") == "axiom.education", "parent contract id mismatch")
    require(parent.get("contract_version") == "1.0.0", "parent contract version mismatch")
    require(parent.get("contract_sha256") == EXPECTED_PARENT_SHA256, "parent contract digest declaration mismatch")
    require(file_sha256(PARENT_CONTRACT_PATH) == EXPECTED_PARENT_SHA256, "pinned axiom.education v1 bytes changed")
    return contract


def parse_time(value: object) -> datetime:
    require(isinstance(value, str), "occurred_at must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise EducatorWorkflowError("occurred_at must be an ISO-8601 timestamp") from error
    require(parsed.tzinfo is not None, "occurred_at must include a timezone")
    return parsed


def validate_digest(value: object, field: str, *, required: bool) -> None:
    if value is None:
        require(not required, f"{field} is required for this event type")
        return
    require(isinstance(value, str) and SHA256_RE.fullmatch(value) is not None, f"{field} must be SHA-256")


def finalize_event(event: dict[str, Any]) -> dict[str, Any]:
    payload = dict(event)
    payload["payload_digest"] = event_digest(payload)
    return payload


def verify_event_shape(event: dict[str, Any], contract: dict[str, Any]) -> dict[str, Any]:
    require(set(event) == EVENT_FIELDS, "workflow event fields must match the bounded schema exactly")
    require(event.get("schema") == "axiom-education-educator-workflow-event.v1", "unsupported workflow event schema")
    for field in ("workflow_id", "assignment_id", "subject_id", "learning_context_id", "event_id", "event_type", "actor_role"):
        require(isinstance(event.get(field), str) and event[field].strip(), f"{field} is required")
    course_code = event.get("course_code")
    require(course_code is None or isinstance(course_code, str), "course_code must be string or null")
    expectation_ids = event.get("expectation_ids")
    require(
        isinstance(expectation_ids, list)
        and all(isinstance(item, str) and item for item in expectation_ids)
        and len(expectation_ids) == len(set(expectation_ids)),
        "expectation_ids must be unique strings",
    )
    parse_time(event.get("occurred_at"))

    event_types = contract.get("event_types")
    require(isinstance(event_types, dict), "workflow event type registry missing")
    spec = event_types.get(event["event_type"])
    require(isinstance(spec, dict), f"unsupported event_type: {event['event_type']}")
    require(event["actor_role"] in spec.get("actors", []), "actor role is not allowed for this event type")
    required_digests = set(spec.get("required_digests", []))
    for field in DIGEST_FIELDS:
        validate_digest(event.get(field), field, required=field in required_digests)
    previous = event.get("previous_event_digest")
    if previous is not None:
        require(isinstance(previous, str) and SHA256_RE.fullmatch(previous) is not None, "previous_event_digest must be SHA-256")
    payload_digest = event.get("payload_digest")
    require(isinstance(payload_digest, str) and SHA256_RE.fullmatch(payload_digest) is not None, "payload_digest must be SHA-256")
    require(payload_digest == event_digest(event), "workflow payload digest mismatch")
    require(event.get("review_state") == spec.get("to"), "review_state does not match event transition")
    return spec


def verify_workflow(events: list[dict[str, Any]]) -> dict[str, Any]:
    require(isinstance(events, list) and events, "workflow must contain at least one event")
    contract = load_contract()
    previous_event: dict[str, Any] | None = None
    current_state: str | None = None
    seen_event_ids: set[str] = set()
    invariant: dict[str, Any] | None = None
    current_artifact: str | None = None
    last_time: datetime | None = None

    for index, event in enumerate(events):
        require(isinstance(event, dict), f"workflow event {index} must be an object")
        spec = verify_event_shape(event, contract)
        event_id = str(event["event_id"])
        require(event_id not in seen_event_ids, f"duplicate workflow event_id: {event_id}")
        seen_event_ids.add(event_id)

        event_invariant = {
            "workflow_id": event["workflow_id"],
            "assignment_id": event["assignment_id"],
            "subject_id": event["subject_id"],
            "learning_context_id": event["learning_context_id"],
            "course_code": event["course_code"],
            "expectation_ids": event["expectation_ids"],
        }
        if invariant is None:
            invariant = event_invariant
        else:
            require(event_invariant == invariant, "workflow identity/context changed mid-chain")

        occurred = parse_time(event["occurred_at"])
        if last_time is not None:
            require(occurred >= last_time, "workflow timestamps must be monotonic")
        last_time = occurred

        allowed_from = spec.get("from")
        require(isinstance(allowed_from, list) and current_state in allowed_from, f"invalid transition from {current_state!r} via {event['event_type']}")
        if previous_event is None:
            require(event["previous_event_digest"] is None, "first workflow event must not name a previous digest")
        else:
            require(
                event["previous_event_digest"] == previous_event["payload_digest"],
                "previous_event_digest does not match prior event",
            )

        event_type = event["event_type"]
        artifact = event.get("artifact_digest")
        if event_type in {"submission.created", "submission.resubmitted"}:
            current_artifact = artifact
        elif event_type != "assignment.created" and artifact is not None and current_artifact is not None:
            require(artifact == current_artifact, "review event artifact digest does not match latest submission")

        current_state = str(spec["to"])
        previous_event = event

    return {
        "valid": True,
        "events": len(events),
        "final_state": current_state,
        "final_event_digest": previous_event["payload_digest"] if previous_event else None,
        "workflow_id": invariant["workflow_id"] if invariant else None,
    }


def project_to_parent_event(event: dict[str, Any], *, consent_id: str, memory_object_id: str) -> dict[str, Any]:
    contract = load_contract()
    verify_event_shape(event, contract)
    require(isinstance(consent_id, str) and consent_id, "consent_id is required")
    require(isinstance(memory_object_id, str) and memory_object_id, "memory_object_id is required")
    parent = contract["parent_contract"]
    input_payload: dict[str, Any] = {
        "contract_id": parent["contract_id"],
        "contract_version": parent["contract_version"],
        "contract_sha256": parent["contract_sha256"],
        "subject_id": event["subject_id"],
        "consent_id": consent_id,
        "purpose": parent["purpose"],
        "event_id": event["event_id"],
        "event_type": event["event_type"],
        "occurred_at": event["occurred_at"],
        "payload_digest": event["payload_digest"],
        "memory_object_id": memory_object_id,
        "expectation_ids": event["expectation_ids"],
        "review_state": event["review_state"],
    }
    if event["course_code"] is not None:
        input_payload["course_code"] = event["course_code"]
    return {"action": parent["transport_action"], "input": input_payload}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    verify = commands.add_parser("verify", help="verify an ordered JSON array of workflow events")
    verify.add_argument("workflow", type=Path)
    project = commands.add_parser("project", help="project one event to axiom.education v1 learner-event input")
    project.add_argument("event", type=Path)
    project.add_argument("--consent-id", required=True)
    project.add_argument("--memory-object-id", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "verify":
            payload = load_json(args.workflow)
            require(isinstance(payload, list), "workflow file must contain a JSON array")
            result = verify_workflow(payload)
            print(json.dumps(result, indent=2, sort_keys=True))
        else:
            event = load_json(args.event)
            require(isinstance(event, dict), "event file must contain a JSON object")
            projection = project_to_parent_event(
                event,
                consent_id=args.consent_id,
                memory_object_id=args.memory_object_id,
            )
            print(json.dumps(projection, indent=2, sort_keys=True))
    except (OSError, EducatorWorkflowError, KeyError, ValueError) as error:
        print(f"educator workflow verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
