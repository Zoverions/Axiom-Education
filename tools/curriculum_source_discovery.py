#!/usr/bin/env python3
"""Resolve immutable curriculum discovery plus append-only source amendments."""

from __future__ import annotations

import hashlib
import json
from copy import deepcopy
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DISCOVERY = ROOT / "curriculum" / "ontario-elementary" / "source-discovery.v0.json"
DEFAULT_AMENDMENTS = ROOT / "curriculum" / "ontario-elementary" / "source-discovery-amendments.v1.json"


class SourceDiscoveryError(RuntimeError):
    """Raised when source discovery or an append-only amendment is invalid."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SourceDiscoveryError(message)


def canonical_json_digest(value: Any) -> str:
    payload = json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise SourceDiscoveryError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise SourceDiscoveryError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def _source_index(discovery: dict[str, Any]) -> dict[str, dict[str, Any]]:
    sources = discovery.get("confirmed_curriculum_sources")
    require(isinstance(sources, list), "confirmed curriculum sources must be an array")
    index: dict[str, dict[str, Any]] = {}
    for source in sources:
        require(isinstance(source, dict), "confirmed source must be an object")
        source_id = source.get("source_id")
        require(isinstance(source_id, str) and source_id, "confirmed source_id is required")
        require(source_id not in index, f"duplicate confirmed source_id: {source_id}")
        index[source_id] = source
    return index


def load_base_discovery(path: Path = DEFAULT_DISCOVERY) -> dict[str, Any]:
    discovery = load_json(path)
    require(
        discovery.get("schema") == "axiom-curriculum-source-discovery.v1",
        "unsupported discovery schema",
    )
    require(discovery.get("state") == "C0-discovered", "source discovery must remain C0")
    _source_index(discovery)
    return discovery


def apply_amendments(
    discovery: dict[str, Any],
    amendments: dict[str, Any],
    *,
    base_discovery_path: Path = DEFAULT_DISCOVERY,
) -> dict[str, Any]:
    require(
        amendments.get("schema") == "axiom-curriculum-source-discovery-amendments.v1",
        "unsupported discovery amendment schema",
    )
    require(
        amendments.get("jurisdiction_id") == discovery.get("jurisdiction_id"),
        "discovery amendment jurisdiction mismatch",
    )
    expected_path = base_discovery_path.resolve().relative_to(ROOT.resolve()).as_posix()
    require(
        amendments.get("base_discovery_path") == expected_path,
        "discovery amendment base path mismatch",
    )
    require(
        isinstance(amendments.get("claim_boundary"), str)
        and amendments["claim_boundary"],
        "discovery amendment claim boundary is required",
    )
    rows = amendments.get("amendments")
    require(isinstance(rows, list), "discovery amendments must be an array")

    effective = deepcopy(discovery)
    index = _source_index(effective)
    amendment_ids: set[str] = set()
    amended_sources: set[str] = set()
    for row in rows:
        require(isinstance(row, dict), "discovery amendment must be an object")
        amendment_id = row.get("amendment_id")
        source_id = row.get("source_id")
        require(
            isinstance(amendment_id, str) and amendment_id,
            "discovery amendment_id is required",
        )
        require(amendment_id not in amendment_ids, f"duplicate amendment_id: {amendment_id}")
        amendment_ids.add(amendment_id)
        require(
            isinstance(source_id, str) and source_id in index,
            f"amendment references unknown source_id: {source_id}",
        )
        require(
            source_id not in amended_sources,
            f"multiple amendments for one source require a new amendment chain version: {source_id}",
        )
        amended_sources.add(source_id)
        prior = index[source_id]
        require(
            row.get("prior_source_entry_sha256") == canonical_json_digest(prior),
            f"amendment prior source digest mismatch: {source_id}",
        )
        evidence = row.get("evidence")
        require(isinstance(evidence, list) and evidence, f"amendment evidence required: {source_id}")
        for item in evidence:
            require(isinstance(item, dict), f"amendment evidence must be object: {source_id}")
            url = item.get("url")
            require(
                isinstance(url, str) and url.startswith("https://"),
                f"amendment evidence URL must use HTTPS: {source_id}",
            )
            require(
                isinstance(item.get("classification"), str)
                and item["classification"],
                f"amendment evidence classification required: {source_id}",
            )
        patch = row.get("set")
        require(isinstance(patch, dict) and patch, f"amendment set is required: {source_id}")
        require("source_id" not in patch, f"amendment cannot change source_id: {source_id}")
        require("grades" not in patch, f"amendment cannot silently change grade scope: {source_id}")
        require("subject_family" not in patch, f"amendment cannot change subject family: {source_id}")
        updated = {**prior, **deepcopy(patch)}
        require(updated.get("source_id") == source_id, f"source_id changed after amendment: {source_id}")
        index[source_id].clear()
        index[source_id].update(updated)

    return effective


def load_effective_discovery(
    path: Path = DEFAULT_DISCOVERY,
    amendments_path: Path | None = None,
) -> dict[str, Any]:
    discovery = load_base_discovery(path)
    if amendments_path is None:
        if path.resolve() != DEFAULT_DISCOVERY.resolve() or not DEFAULT_AMENDMENTS.exists():
            return discovery
        amendments_path = DEFAULT_AMENDMENTS
    if not amendments_path.exists():
        return discovery
    return apply_amendments(
        discovery,
        load_json(amendments_path),
        base_discovery_path=path,
    )
