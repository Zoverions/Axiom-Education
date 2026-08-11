"""Evidence binding between jurisdiction resolution and learner-event standards projection.

This module preserves the pinned ``axiom.education`` v1 contract. The existing
learner-event ``active_pack_manifest_sha256`` remains a single selected pack for
one event. The complete ordered jurisdiction context is carried separately in a
digest-bound projection that can be included in the event payload whose digest
is already accepted by v1.

The module does not verify source signatures or crosswalk truth. It validates
that already-verified evidence is structurally exact and that a selected event
projection cannot be detached from or substituted across the full resolved
standards context.
"""

from __future__ import annotations

import hashlib
import json
import re
from typing import Any, Iterable


AUTHORITY_RANK = {
    "country": 0,
    "region": 1,
    "district": 2,
    "institution": 3,
    "program": 4,
}
ASSURANCE_RANK = {"A0": 0, "A1": 1, "A2": 2, "A3": 3, "A4": 4}
MINIMUM_ASSURANCE = "A2"
RESOLUTION_SCHEMA = "axiom-education-jurisdiction-resolution.v1"
PROJECTION_SCHEMA = "axiom-education-event-standards-projection.v1"
DIGEST_RE = re.compile(r"^[a-f0-9]{64}$")
ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.:-]{0,159}$")


class StandardsContextBindingError(ValueError):
    """Fail-closed standards-context binding error with a stable code."""

    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


def _canonical_digest(value: Any) -> str:
    encoded = json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _require_digest(value: Any, label: str) -> str:
    if not isinstance(value, str) or not DIGEST_RE.fullmatch(value):
        raise StandardsContextBindingError(
            "invalid_digest",
            f"{label} must be a lowercase SHA-256 hex digest",
        )
    return value


def _require_text(value: Any, label: str, *, identifier: bool = False) -> str:
    if not isinstance(value, str) or not value:
        raise StandardsContextBindingError("invalid_record", f"{label} is required")
    if identifier and not ID_RE.fullmatch(value):
        raise StandardsContextBindingError("invalid_record", f"{label} has invalid format")
    return value


def _require_bool(value: Any, label: str) -> bool:
    if not isinstance(value, bool):
        raise StandardsContextBindingError("invalid_record", f"{label} must be boolean")
    return value


def _canonical_expectations(values: Iterable[str]) -> list[str]:
    if isinstance(values, (str, bytes)):
        raise StandardsContextBindingError(
            "invalid_expectations",
            "expectation_ids must be an array",
        )
    items = list(values)
    if not items or len(items) > 512:
        raise StandardsContextBindingError(
            "invalid_expectations",
            "expectation_ids must contain 1-512 values",
        )
    normalized = [
        _require_text(value, f"expectation_ids[{index}]", identifier=True)
        for index, value in enumerate(items)
    ]
    if len(set(normalized)) != len(normalized):
        raise StandardsContextBindingError(
            "duplicate_expectation",
            "expectation_ids may not contain duplicates",
        )
    return sorted(normalized)


def validate_jurisdiction_resolution(raw: Any) -> dict[str, Any]:
    """Validate a deterministic jurisdiction resolution and its own digest."""

    if not isinstance(raw, dict):
        raise StandardsContextBindingError("invalid_resolution", "resolution must be an object")
    if raw.get("schema") != RESOLUTION_SCHEMA:
        raise StandardsContextBindingError("invalid_resolution", "resolution schema is unsupported")

    subject_id = _require_text(raw.get("subject_id"), "subject_id", identifier=True)
    grade_band = _require_text(raw.get("grade_band"), "grade_band")
    as_of = _require_text(raw.get("as_of"), "as_of")
    minimum = _require_text(raw.get("minimum_claim_assurance"), "minimum_claim_assurance")
    if minimum != MINIMUM_ASSURANCE:
        raise StandardsContextBindingError(
            "assurance_floor_mismatch",
            f"minimum_claim_assurance must remain {MINIMUM_ASSURANCE}",
        )

    layers = raw.get("layers")
    if not isinstance(layers, list) or not layers or len(layers) > 32:
        raise StandardsContextBindingError(
            "invalid_resolution",
            "resolution layers must contain 1-32 records",
        )

    normalized_layers: list[dict[str, Any]] = []
    prior_rank = -1
    claim_ids: set[str] = set()
    for index, layer in enumerate(layers):
        label = f"layers[{index}]"
        if not isinstance(layer, dict):
            raise StandardsContextBindingError("invalid_resolution", f"{label} must be an object")
        authority_level = _require_text(layer.get("authority_level"), f"{label}.authority_level")
        if authority_level not in AUTHORITY_RANK:
            raise StandardsContextBindingError(
                "invalid_authority_level",
                f"{label}.authority_level is unsupported",
            )
        rank = AUTHORITY_RANK[authority_level]
        if rank < prior_rank:
            raise StandardsContextBindingError(
                "resolution_order_mismatch",
                "resolution layers must remain broad-to-specific",
            )
        prior_rank = rank

        assurance = _require_text(layer.get("claim_assurance"), f"{label}.claim_assurance")
        if assurance not in ASSURANCE_RANK:
            raise StandardsContextBindingError(
                "invalid_assurance",
                f"{label}.claim_assurance is unsupported",
            )
        if ASSURANCE_RANK[assurance] < ASSURANCE_RANK[MINIMUM_ASSURANCE]:
            raise StandardsContextBindingError(
                "insufficient_claim_assurance",
                f"{label}.claim_assurance is below {MINIMUM_ASSURANCE}",
            )

        claim_id = _require_text(layer.get("claim_id"), f"{label}.claim_id", identifier=True)
        if claim_id in claim_ids:
            raise StandardsContextBindingError(
                "duplicate_claim",
                "resolution layers may not repeat a claim_id",
            )
        claim_ids.add(claim_id)

        normalized_layers.append(
            {
                "authority_level": authority_level,
                "authority_id": _require_text(
                    layer.get("authority_id"), f"{label}.authority_id", identifier=True
                ),
                "jurisdiction_id": _require_text(
                    layer.get("jurisdiction_id"), f"{label}.jurisdiction_id", identifier=True
                ),
                "claim_id": claim_id,
                "claim_type": _require_text(layer.get("claim_type"), f"{label}.claim_type"),
                "claim_assurance": assurance,
                "claim_evidence_digest": _require_digest(
                    layer.get("claim_evidence_digest"), f"{label}.claim_evidence_digest"
                ),
                "standards_role": _require_text(
                    layer.get("standards_role"), f"{label}.standards_role"
                ),
                "pack_id": _require_text(layer.get("pack_id"), f"{label}.pack_id", identifier=True),
                "pack_manifest_sha256": _require_digest(
                    layer.get("pack_manifest_sha256"), f"{label}.pack_manifest_sha256"
                ),
                "pack_signer_key_id": _require_text(
                    layer.get("pack_signer_key_id"), f"{label}.pack_signer_key_id", identifier=True
                ),
                "pack_effective_from": _require_text(
                    layer.get("pack_effective_from"), f"{label}.pack_effective_from"
                ),
                "replaces_parent_minimums": _require_bool(
                    layer.get("replaces_parent_minimums"), f"{label}.replaces_parent_minimums"
                ),
                "parent_replacement_delegated": _require_bool(
                    layer.get("parent_replacement_delegated"),
                    f"{label}.parent_replacement_delegated",
                ),
            }
        )

    normalized: dict[str, Any] = {
        "schema": RESOLUTION_SCHEMA,
        "subject_id": subject_id,
        "grade_band": grade_band,
        "as_of": as_of,
        "minimum_claim_assurance": minimum,
        "layers": normalized_layers,
    }
    expected_digest = _canonical_digest(normalized)
    supplied_digest = _require_digest(raw.get("resolution_digest"), "resolution_digest")
    if supplied_digest != expected_digest:
        raise StandardsContextBindingError(
            "resolution_digest_mismatch",
            "resolution_digest does not match the canonical full context",
        )
    normalized["resolution_digest"] = supplied_digest
    return normalized


def build_event_standards_projection(
    *,
    resolution: dict[str, Any],
    selected_pack_manifest_sha256: str,
    course_code: str,
    expectation_ids: Iterable[str],
    crosswalk_manifest_sha256: str,
    crosswalk_verification_digest: str,
) -> dict[str, Any]:
    """Build the canonical event projection while preserving the full pack stack."""

    context = validate_jurisdiction_resolution(resolution)
    selected_pack = _require_digest(
        selected_pack_manifest_sha256,
        "selected_pack_manifest_sha256",
    )
    context_packs = [layer["pack_manifest_sha256"] for layer in context["layers"]]
    if selected_pack not in context_packs:
        raise StandardsContextBindingError(
            "selected_pack_outside_context",
            "selected event pack is not present in the resolved jurisdiction context",
        )

    projection: dict[str, Any] = {
        "schema": PROJECTION_SCHEMA,
        "subject_id": context["subject_id"],
        "resolution_digest": context["resolution_digest"],
        "resolution_as_of": context["as_of"],
        "context_pack_manifest_sha256s": context_packs,
        "selected_pack_manifest_sha256": selected_pack,
        "course_code": _require_text(course_code, "course_code", identifier=True),
        "expectation_ids": _canonical_expectations(expectation_ids),
        "crosswalk_manifest_sha256": _require_digest(
            crosswalk_manifest_sha256,
            "crosswalk_manifest_sha256",
        ),
        "crosswalk_verification_digest": _require_digest(
            crosswalk_verification_digest,
            "crosswalk_verification_digest",
        ),
    }
    projection["projection_digest"] = _canonical_digest(projection)
    return projection


def validate_event_standards_projection(
    *,
    resolution: dict[str, Any],
    projection: dict[str, Any],
    event_input: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Validate a projection against the full context and optional v1 event input."""

    if not isinstance(projection, dict) or projection.get("schema") != PROJECTION_SCHEMA:
        raise StandardsContextBindingError("invalid_projection", "projection schema is unsupported")

    supplied_digest = _require_digest(projection.get("projection_digest"), "projection_digest")
    body = dict(projection)
    del body["projection_digest"]
    if _canonical_digest(body) != supplied_digest:
        raise StandardsContextBindingError(
            "projection_digest_mismatch",
            "projection_digest does not match the canonical projection",
        )

    rebuilt = build_event_standards_projection(
        resolution=resolution,
        selected_pack_manifest_sha256=projection.get("selected_pack_manifest_sha256"),
        course_code=projection.get("course_code"),
        expectation_ids=projection.get("expectation_ids", []),
        crosswalk_manifest_sha256=projection.get("crosswalk_manifest_sha256"),
        crosswalk_verification_digest=projection.get("crosswalk_verification_digest"),
    )
    if rebuilt != projection:
        raise StandardsContextBindingError(
            "projection_context_mismatch",
            "projection does not exactly match the current supplied resolution",
        )

    if event_input is not None:
        if not isinstance(event_input, dict):
            raise StandardsContextBindingError("invalid_event", "event_input must be an object")
        if event_input.get("subject_id") != rebuilt["subject_id"]:
            raise StandardsContextBindingError(
                "event_subject_mismatch",
                "event subject does not match the jurisdiction projection subject",
            )
        if event_input.get("active_pack_manifest_sha256") != rebuilt["selected_pack_manifest_sha256"]:
            raise StandardsContextBindingError(
                "event_pack_mismatch",
                "event selected pack does not match the standards projection",
            )
        if event_input.get("course_code") != rebuilt["course_code"]:
            raise StandardsContextBindingError(
                "event_course_mismatch",
                "event course does not match the standards projection",
            )
        if event_input.get("expectation_ids") != rebuilt["expectation_ids"]:
            raise StandardsContextBindingError(
                "event_expectations_mismatch",
                "event expectations do not match the standards projection",
            )
    return rebuilt


def bind_projection_to_event_payload(
    *,
    event_payload: dict[str, Any],
    projection: dict[str, Any],
) -> dict[str, Any]:
    """Return a payload whose v1 ``payload_digest`` cryptographically binds the projection.

    The returned payload is intended to stay in the governed application/memory
    evidence layer; the v1 learner event carries only its digest/reference.
    """

    if not isinstance(event_payload, dict):
        raise StandardsContextBindingError("invalid_payload", "event_payload must be an object")
    if "standards_projection" in event_payload:
        raise StandardsContextBindingError(
            "projection_already_present",
            "event_payload may not pre-populate standards_projection",
        )
    if not isinstance(projection, dict) or projection.get("schema") != PROJECTION_SCHEMA:
        raise StandardsContextBindingError("invalid_projection", "projection schema is unsupported")
    body = dict(event_payload)
    body["standards_projection"] = projection
    return {
        "payload": body,
        "payload_digest": _canonical_digest(body),
        "standards_projection_digest": projection.get("projection_digest"),
    }
