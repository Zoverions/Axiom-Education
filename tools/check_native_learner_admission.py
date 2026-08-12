#!/usr/bin/env python3
"""Verify the Axiom Education side of native AXIOM learner-event admission."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

try:
    from tools.learner_memory_profile import load_profile
except ModuleNotFoundError:  # Direct `python tools/...` execution.
    from learner_memory_profile import load_profile

ROOT = Path(__file__).resolve().parents[1]
DOMAIN_PATH = ROOT / "contracts" / "axiom-education.v1.json"
WORKFLOW_PATH = ROOT / "contracts" / "axiom-education-educator-workflow.v1.json"
APPEND_ACTION = "education.learner.event.append"
EXPECTED_PURPOSE = "learning-progress-recording"
EXPECTED_CONSENT_SCOPE = "learning-progress:write"
EXPECTED_GATEWAY_SCOPE = "education:learner:write"
EXPECTED_PROVIDER = "education.learner-record"


class NativeLearnerAdmissionError(RuntimeError):
    """Raised when the Education-side native admission contracts drift."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise NativeLearnerAdmissionError(message)


def load_json(path: Path) -> tuple[dict[str, Any], bytes]:
    try:
        raw = path.read_bytes()
    except OSError as error:
        raise NativeLearnerAdmissionError(f"cannot read {path.name}: {error}") from error
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as error:
        raise NativeLearnerAdmissionError(f"invalid JSON in {path.name}: {error}") from error
    require(isinstance(value, dict), f"{path.name} must contain a JSON object")
    return value, raw


def verify_contracts(
    domain: dict[str, Any],
    workflow: dict[str, Any],
    profile: dict[str, Any],
    *,
    domain_sha256: str,
) -> dict[str, Any]:
    actions = domain.get("actions")
    require(isinstance(actions, dict), "education domain actions are missing")
    append = actions.get(APPEND_ACTION)
    require(isinstance(append, dict), "learner append action is missing")
    require(append.get("mutation") is True, "learner append must remain a mutation")
    require(
        append.get("provider_capability") == EXPECTED_PROVIDER,
        "learner append provider capability drift",
    )
    require(
        append.get("required_scopes") == [EXPECTED_GATEWAY_SCOPE],
        "learner append Gateway scope drift",
    )
    approval = append.get("approval")
    require(isinstance(approval, dict), "learner append approval profile is missing")
    require(approval.get("confirmation") is False, "learner append unexpectedly requires confirmation")
    require(approval.get("independent") is False, "learner append unexpectedly requires independent approval")

    consent = append.get("consent")
    require(isinstance(consent, dict), "learner append consent profile is missing")
    require(consent.get("required") is True, "learner append consent must remain required")
    require(consent.get("purpose") == EXPECTED_PURPOSE, "learner append consent purpose drift")
    require(
        consent.get("data_scopes") == [EXPECTED_CONSENT_SCOPE],
        "learner append consent scope drift",
    )
    require(
        domain.get("controller") == "capsule:axiom.education",
        "education consent controller drift",
    )

    required_input = append.get("required_input")
    optional_input = append.get("optional_input")
    require(isinstance(required_input, list), "learner append required_input is invalid")
    require(isinstance(optional_input, list), "learner append optional_input is invalid")
    required_fields = set(required_input)
    optional_fields = set(optional_input)
    require(required_fields.isdisjoint(optional_fields), "learner append fields overlap required/optional")
    for field in (
        "contract_id",
        "contract_version",
        "contract_sha256",
        "subject_id",
        "consent_id",
        "purpose",
        "event_id",
        "event_type",
        "occurred_at",
        "payload_digest",
        "memory_object_id",
    ):
        require(field in required_fields, f"learner append required field missing: {field}")

    parent = workflow.get("parent_contract")
    require(isinstance(parent, dict), "educator workflow parent contract is missing")
    require(parent.get("contract_id") == domain.get("contract_id"), "workflow parent contract id drift")
    require(
        parent.get("contract_version") == domain.get("contract_version"),
        "workflow parent contract version drift",
    )
    require(
        parent.get("contract_sha256") == domain_sha256,
        "workflow parent contract digest does not match exact domain bytes",
    )
    require(parent.get("transport_action") == APPEND_ACTION, "workflow transport action drift")
    require(parent.get("purpose") == EXPECTED_PURPOSE, "workflow parent purpose drift")

    projection = workflow.get("projection")
    require(isinstance(projection, dict), "educator workflow projection is missing")
    require(projection.get("gateway_action") == APPEND_ACTION, "workflow Gateway action drift")
    projected_required = projection.get("required_parent_input")
    projected_optional = projection.get("projected_optional_parent_input")
    require(isinstance(projected_required, list), "workflow required projection is invalid")
    require(isinstance(projected_optional, list), "workflow optional projection is invalid")
    require(
        set(projected_required) == required_fields,
        "workflow required projection does not match learner append contract",
    )
    require(
        set(projected_optional).issubset(optional_fields),
        "workflow optional projection exceeds learner append contract",
    )

    boundary = workflow.get("authority_boundary")
    require(isinstance(boundary, dict), "workflow authority boundary is missing")
    require(boundary.get("governed_persistence_required") is True, "governed persistence must remain required")
    require(boundary.get("raw_student_work_in_event_payload") is False, "raw student work must remain out of events")
    require(boundary.get("raw_feedback_in_event_payload") is False, "raw feedback must remain out of events")
    require(boundary.get("automatic_grade_inference") is False, "automatic grade inference must remain disabled")
    require(boundary.get("automatic_credit_inference") is False, "automatic credit inference must remain disabled")

    workflow_events = workflow.get("event_types")
    require(isinstance(workflow_events, dict), "workflow event registry is missing")
    kind_map = profile.get("event_type_to_memory_kind")
    owner_map = profile.get("event_type_to_memory_owner")
    require(isinstance(kind_map, dict), "learner-memory kind map is missing")
    require(isinstance(owner_map, dict), "learner-memory owner map is missing")
    require(set(kind_map) == set(owner_map), "learner-memory kind/owner event sets differ")
    require(set(kind_map).issubset(workflow_events), "learner-memory profile contains unknown workflow event")

    for event_type, owner_binding in owner_map.items():
        spec = workflow_events[event_type]
        require(isinstance(spec, dict), f"workflow event spec is invalid: {event_type}")
        actors = spec.get("actors")
        require(isinstance(actors, list) and actors, f"workflow actors missing: {event_type}")
        if owner_binding == "actor":
            require(
                all(actor == "educator" for actor in actors),
                f"actor-owned memory event is not educator-only: {event_type}",
            )
        elif owner_binding == "subject":
            require(
                all(actor in {"learner", "authorized-representative"} for actor in actors),
                f"subject-owned memory event has incompatible actors: {event_type}",
            )
        else:
            raise NativeLearnerAdmissionError(
                f"unknown learner-memory owner binding for {event_type}: {owner_binding!r}"
            )

    invariants = profile.get("invariants")
    require(isinstance(invariants, dict), "learner-memory invariants are missing")
    require(invariants.get("memory_write_precedes_learner_event_for_new_content") is True, "memory-before-event ordering drift")
    require(invariants.get("content_address_required") is True, "content-addressed memory must remain required")
    require(invariants.get("memory_owner_binding_required") is True, "memory ownership binding must remain required")
    require(invariants.get("caller_selects_memory_kind") is False, "caller-selected memory kinds must remain disabled")
    require(invariants.get("raw_content_in_learner_event") is False, "raw content must remain out of learner events")
    require(invariants.get("automatic_tombstone_on_append_failure") is False, "automatic append-failure tombstones must remain disabled")

    return {
        "valid": True,
        "domain_contract_sha256": domain_sha256,
        "append_action": APPEND_ACTION,
        "provider_capability": EXPECTED_PROVIDER,
        "consent_controller": domain["controller"],
        "consent_purpose": EXPECTED_PURPOSE,
        "consent_scope": EXPECTED_CONSENT_SCOPE,
        "gateway_scope": EXPECTED_GATEWAY_SCOPE,
        "memory_action": profile.get("memory_action"),
        "memory_event_types": sorted(kind_map),
    }


def verify_native_learner_admission() -> dict[str, Any]:
    domain, domain_raw = load_json(DOMAIN_PATH)
    workflow, _ = load_json(WORKFLOW_PATH)
    profile = load_profile()
    return verify_contracts(
        domain,
        workflow,
        profile,
        domain_sha256=hashlib.sha256(domain_raw).hexdigest(),
    )


def main() -> int:
    result = verify_native_learner_admission()
    print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
