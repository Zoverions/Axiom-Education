#!/usr/bin/env python3
"""Verify the cross-repository governed learner-memory profile."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
PROFILE_PATH = ROOT / "contracts" / "axiom-education-learner-memory.v1.json"
EXPECTED_SHA256 = "9289753c2db2eaa4c18653526f248c5b87c83dc2ab1337ef82b46cf8b23af59d"
EXPECTED_EVENT_MEMORY_KINDS = {
    "assignment.created": "education.assignment-artifact",
    "submission.created": "education.learner-submission",
    "submission.resubmitted": "education.learner-submission",
    "feedback.recorded": "education.educator-feedback",
    "revision.requested": "education.educator-feedback",
    "appeal.filed": "education.appeal-reason",
    "correction.recorded": "education.correction-evidence",
}
EXPECTED_METADATA_FIELDS = [
    "schema",
    "workflow_id",
    "assignment_id",
    "event_id",
    "event_type",
    "workflow_payload_digest",
]


class LearnerMemoryProfileError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise LearnerMemoryProfileError(message)


def load_profile(path: Path = PROFILE_PATH) -> dict[str, Any]:
    try:
        raw = path.read_bytes()
    except OSError as error:
        raise LearnerMemoryProfileError(f"cannot read learner-memory profile: {error}") from error
    require(hashlib.sha256(raw).hexdigest() == EXPECTED_SHA256, "learner-memory profile digest drift")
    try:
        profile = json.loads(raw)
    except json.JSONDecodeError as error:
        raise LearnerMemoryProfileError(f"invalid learner-memory profile JSON: {error}") from error
    require(isinstance(profile, dict), "learner-memory profile must be an object")
    require(profile.get("schema") == "axiom-education-memory-profile.v1", "learner-memory profile schema mismatch")
    require(profile.get("profile_id") == "axiom.education.learner-memory", "learner-memory profile id mismatch")
    require(profile.get("profile_version") == "1.0.0", "learner-memory profile version mismatch")
    require(profile.get("memory_action") == "memory.put", "learner-memory profile memory action mismatch")
    require(profile.get("object_id_pattern") == r"^memory_[a-f0-9]{64}$", "learner-memory object id pattern mismatch")
    require(profile.get("metadata_schema") == "axiom-education-governed-memory-ref.v1", "learner-memory metadata schema mismatch")
    require(profile.get("metadata_fields") == EXPECTED_METADATA_FIELDS, "learner-memory metadata fields mismatch")
    require(profile.get("event_type_to_memory_kind") == EXPECTED_EVENT_MEMORY_KINDS, "learner-memory event-kind mapping mismatch")
    invariants = profile.get("invariants")
    require(isinstance(invariants, dict), "learner-memory invariants missing")
    require(invariants.get("automatic_tombstone_on_append_failure") is False, "automatic tombstone must remain disabled")
    require(invariants.get("caller_selects_memory_kind") is False, "caller-selected memory kinds must remain disabled")
    require(invariants.get("content_address_required") is True, "content addressing must remain required")
    require(invariants.get("memory_write_precedes_learner_event_for_new_content") is True, "memory write ordering changed")
    require(invariants.get("raw_content_in_learner_event") is False, "raw learner content must not enter learner events")
    return profile
