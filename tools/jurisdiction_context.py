"""Deterministic jurisdiction/standards resolution for Axiom Education.

This module is intentionally transport- and identity-provider agnostic. It consumes
already-attested education-context claims and verified standards-pack metadata and
returns the exact ordered pack stack that a learner event should bind to.

It does not verify signatures itself and it does not grant authority. Those remain
separate AXIOM / curriculum-pack responsibilities.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
import re
from typing import Any, Iterable


ASSURANCE_RANK = {"A0": 0, "A1": 1, "A2": 2, "A3": 3, "A4": 4}
AUTHORITY_RANK = {
    "country": 0,
    "region": 1,
    "district": 2,
    "institution": 3,
    "program": 4,
}
MINIMUM_ASSURANCE = "A2"
DIGEST_RE = re.compile(r"^[a-f0-9]{64}$")


class JurisdictionResolutionError(ValueError):
    """Fail-closed resolution error with a stable machine-readable code."""

    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


@dataclass(frozen=True)
class _ActiveClaim:
    raw: dict[str, Any]
    level_rank: int


def _parse_time(value: str, label: str) -> datetime:
    if not isinstance(value, str) or not value:
        raise JurisdictionResolutionError("invalid_time", f"{label} must be an ISO-8601 string")
    normalized = value[:-1] + "+00:00" if value.endswith("Z") else value
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError as exc:
        raise JurisdictionResolutionError("invalid_time", f"{label} is not valid ISO-8601") from exc
    if parsed.tzinfo is None:
        raise JurisdictionResolutionError("invalid_time", f"{label} must include a timezone")
    return parsed.astimezone(timezone.utc)


def _is_active(record: dict[str, Any], as_of: datetime, label: str) -> bool:
    start = _parse_time(record["effective_from"], f"{label}.effective_from")
    end_raw = record.get("effective_until")
    end = _parse_time(end_raw, f"{label}.effective_until") if end_raw else None
    return start <= as_of and (end is None or as_of < end)


def _require_digest(value: Any, label: str) -> str:
    if not isinstance(value, str) or not DIGEST_RE.fullmatch(value):
        raise JurisdictionResolutionError("invalid_digest", f"{label} must be a lowercase SHA-256 hex digest")
    return value


def _require_text(record: dict[str, Any], field: str, label: str) -> str:
    value = record.get(field)
    if not isinstance(value, str) or not value.strip():
        raise JurisdictionResolutionError("invalid_record", f"{label}.{field} is required")
    return value


def _validate_claim(subject_id: str, claim: dict[str, Any], as_of: datetime, index: int) -> _ActiveClaim | None:
    label = f"claims[{index}]"
    if _require_text(claim, "subject_id", label) != subject_id:
        return None
    _require_text(claim, "claim_id", label)
    _require_text(claim, "claim_type", label)
    _require_text(claim, "authority_id", label)
    _require_text(claim, "jurisdiction_id", label)
    level = _require_text(claim, "authority_level", label)
    if level not in AUTHORITY_RANK:
        raise JurisdictionResolutionError("invalid_authority_level", f"{label}.authority_level is unsupported")
    assurance = _require_text(claim, "assurance", label)
    if assurance not in ASSURANCE_RANK:
        raise JurisdictionResolutionError("invalid_assurance", f"{label}.assurance is unsupported")
    _require_digest(claim.get("evidence_digest"), f"{label}.evidence_digest")
    if ASSURANCE_RANK[assurance] < ASSURANCE_RANK[MINIMUM_ASSURANCE]:
        raise JurisdictionResolutionError(
            "insufficient_claim_assurance",
            f"{label} has {assurance}; mandatory standards resolution requires at least {MINIMUM_ASSURANCE}",
        )
    if not _is_active(claim, as_of, label):
        return None
    return _ActiveClaim(raw=claim, level_rank=AUTHORITY_RANK[level])


def _validate_pack(pack: dict[str, Any], as_of: datetime, grade_band: str, index: int) -> bool:
    label = f"packs[{index}]"
    _require_text(pack, "pack_id", label)
    _require_text(pack, "authority_id", label)
    _require_text(pack, "jurisdiction_id", label)
    _require_text(pack, "signer_key_id", label)
    _require_digest(pack.get("manifest_sha256"), f"{label}.manifest_sha256")
    grade_bands = pack.get("grade_bands")
    if not isinstance(grade_bands, list) or not grade_bands or any(not isinstance(x, str) or not x for x in grade_bands):
        raise JurisdictionResolutionError("invalid_pack", f"{label}.grade_bands must be a non-empty string array")
    return grade_band in grade_bands and _is_active(pack, as_of, label)


def _select_pack(claim: dict[str, Any], packs: list[dict[str, Any]], as_of: datetime, grade_band: str) -> dict[str, Any] | None:
    candidates: list[dict[str, Any]] = []
    for index, pack in enumerate(packs):
        if pack.get("authority_id") != claim["authority_id"]:
            continue
        if pack.get("jurisdiction_id") != claim["jurisdiction_id"]:
            continue
        if _validate_pack(pack, as_of, grade_band, index):
            candidates.append(pack)

    if not candidates:
        return None

    candidates.sort(
        key=lambda item: _parse_time(item["effective_from"], f"pack:{item['pack_id']}.effective_from"),
        reverse=True,
    )
    newest_time = _parse_time(candidates[0]["effective_from"], "selected_pack.effective_from")
    newest = [
        item
        for item in candidates
        if _parse_time(item["effective_from"], f"pack:{item['pack_id']}.effective_from") == newest_time
    ]
    if len(newest) != 1:
        raise JurisdictionResolutionError(
            "ambiguous_pack",
            f"Multiple active packs have the same newest effective time for authority {claim['authority_id']}",
        )
    return newest[0]


def _canonical_digest(value: dict[str, Any]) -> str:
    encoded = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def resolve_jurisdiction_context(
    *,
    subject_id: str,
    grade_band: str,
    claims: Iterable[dict[str, Any]],
    packs: Iterable[dict[str, Any]],
    as_of: str,
) -> dict[str, Any]:
    """Resolve the exact active jurisdictional standards stack.

    Rules:
    - only active claims for ``subject_id`` participate;
    - participating claims require at least A2 assurance;
    - each mandatory claim requires one unambiguous active grade-compatible pack;
    - packs are ordered country -> region -> district -> institution -> program;
    - lower-authority parent replacement is rejected without explicit delegation;
    - the returned digest is stable for the same normalized resolution.
    """

    if not isinstance(subject_id, str) or not subject_id:
        raise JurisdictionResolutionError("invalid_subject", "subject_id is required")
    if not isinstance(grade_band, str) or not grade_band:
        raise JurisdictionResolutionError("invalid_grade_band", "grade_band is required")

    resolved_at = _parse_time(as_of, "as_of")
    claim_list = list(claims)
    pack_list = list(packs)

    active_claims: list[_ActiveClaim] = []
    for index, claim in enumerate(claim_list):
        if not isinstance(claim, dict):
            raise JurisdictionResolutionError("invalid_record", f"claims[{index}] must be an object")
        active = _validate_claim(subject_id, claim, resolved_at, index)
        if active is not None:
            active_claims.append(active)

    # Stable broad-to-specific ordering; authority/claim IDs make ties deterministic.
    active_claims.sort(
        key=lambda item: (
            item.level_rank,
            item.raw["authority_id"],
            item.raw["claim_id"],
        )
    )

    layers: list[dict[str, Any]] = []
    for active in active_claims:
        claim = active.raw
        pack = _select_pack(claim, pack_list, resolved_at, grade_band)
        mandatory = claim.get("standards_role", "mandatory") == "mandatory"
        if pack is None:
            if mandatory:
                raise JurisdictionResolutionError(
                    "required_pack_missing",
                    f"No active standards pack matches mandatory claim {claim['claim_id']}",
                )
            continue

        replaces_parent = bool(pack.get("replaces_parent_minimums", False))
        delegated = bool(claim.get("parent_replacement_delegated", False))
        if replaces_parent and not delegated:
            raise JurisdictionResolutionError(
                "parent_replacement_not_delegated",
                f"Pack {pack['pack_id']} attempts to replace parent minimums without an explicit delegation",
            )

        layers.append(
            {
                "authority_level": claim["authority_level"],
                "authority_id": claim["authority_id"],
                "jurisdiction_id": claim["jurisdiction_id"],
                "claim_id": claim["claim_id"],
                "claim_type": claim["claim_type"],
                "claim_assurance": claim["assurance"],
                "claim_evidence_digest": claim["evidence_digest"],
                "standards_role": claim.get("standards_role", "mandatory"),
                "pack_id": pack["pack_id"],
                "pack_manifest_sha256": pack["manifest_sha256"],
                "pack_signer_key_id": pack["signer_key_id"],
                "pack_effective_from": pack["effective_from"],
                "replaces_parent_minimums": replaces_parent,
                "parent_replacement_delegated": delegated,
            }
        )

    if not layers:
        raise JurisdictionResolutionError(
            "no_standards_context",
            "No active, sufficiently assured jurisdiction standards context could be resolved",
        )

    result: dict[str, Any] = {
        "schema": "axiom-education-jurisdiction-resolution.v1",
        "subject_id": subject_id,
        "grade_band": grade_band,
        "as_of": resolved_at.isoformat().replace("+00:00", "Z"),
        "minimum_claim_assurance": MINIMUM_ASSURANCE,
        "layers": layers,
    }
    result["resolution_digest"] = _canonical_digest(result)
    return result
