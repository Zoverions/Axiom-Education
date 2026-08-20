#!/usr/bin/env python3
"""Validate digest-bound amendments to append-only Ontario curriculum source additions.

The historical discovery ledger and the source-additions ledger remain immutable in
meaning. This layer may resolve newer official locators for source IDs that originally
entered through the additions ledger, but it cannot change their identity, scope,
publication lineage, or promote them beyond C0 without separate byte evidence.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from copy import deepcopy
from datetime import date
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DISCOVERY = ROOT / "curriculum" / "ontario-elementary" / "source-discovery.v0.json"
DEFAULT_ADDITIONS = ROOT / "curriculum" / "ontario-elementary" / "source-discovery-additions.v1.json"
DEFAULT_ADDITION_AMENDMENTS = (
    ROOT
    / "curriculum"
    / "ontario-elementary"
    / "source-discovery-addition-amendments.v1.json"
)
DCP_HOST = "www.dcp.edu.gov.on.ca"
DCP_FRENCH_CURRICULUM_PREFIX = "/fr/curriculum/"
IMMUTABLE_SOURCE_FIELDS = {
    "source_id",
    "subject_family",
    "grades",
    "policy_version",
    "publication_catalog_url",
    "publication_number",
}
ALLOWED_SET_FIELDS = {
    "url",
    "classification",
    "source_locator_status",
    "status_note",
    "upstream_document_sha256",
    "upstream_digest_status",
    "review_status",
}

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_additions import (  # noqa: E402
    SourceAdditionError,
    load_augmented_discovery,
)


class SourceAdditionAmendmentError(RuntimeError):
    """Raised when an amendment to an added source violates append-only provenance."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SourceAdditionAmendmentError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise SourceAdditionAmendmentError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise SourceAdditionAmendmentError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def canonical_json_digest(value: Any) -> str:
    payload = json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def _source_index(discovery: dict[str, Any]) -> dict[str, dict[str, Any]]:
    rows = discovery.get("confirmed_curriculum_sources")
    require(isinstance(rows, list), "confirmed curriculum sources must be an array")
    index: dict[str, dict[str, Any]] = {}
    for row in rows:
        require(isinstance(row, dict), "confirmed curriculum source must be an object")
        source_id = row.get("source_id")
        require(isinstance(source_id, str) and source_id, "confirmed source_id is required")
        require(source_id not in index, f"duplicate source_id: {source_id}")
        index[source_id] = row
    return index


def _addition_source_ids(additions_path: Path) -> set[str]:
    payload = load_json(additions_path)
    rows = payload.get("additions")
    require(isinstance(rows, list), "source additions must be an array")
    source_ids: set[str] = set()
    for row in rows:
        require(isinstance(row, dict), "source addition must be an object")
        source = row.get("source")
        require(isinstance(source, dict), "source addition must contain a source object")
        source_id = source.get("source_id")
        require(isinstance(source_id, str) and source_id, "added source_id is required")
        require(source_id not in source_ids, f"duplicate added source_id: {source_id}")
        source_ids.add(source_id)
    return source_ids


def _validate_dcp_route(url: object, source_id: str) -> str:
    require(isinstance(url, str) and url.startswith("https://"), f"{source_id}: amended URL must use HTTPS")
    parsed = urlparse(url)
    require(
        parsed.hostname == DCP_HOST
        and parsed.path.startswith(DCP_FRENCH_CURRICULUM_PREFIX)
        and parsed.path != DCP_FRENCH_CURRICULUM_PREFIX.rstrip("/"),
        f"{source_id}: amended URL must be an exact French Ontario curriculum route",
    )
    require(parsed.query == "" and parsed.fragment == "", f"{source_id}: amended DCP route must not use query or fragment")
    return url


def apply_addition_amendments(
    discovery: dict[str, Any],
    amendments: dict[str, Any],
    *,
    additions_path: Path = DEFAULT_ADDITIONS,
) -> dict[str, Any]:
    require(
        amendments.get("schema") == "axiom-curriculum-source-addition-amendments.v1",
        "unsupported source-addition-amendments schema",
    )
    require(
        amendments.get("jurisdiction_id") == discovery.get("jurisdiction_id"),
        "source-addition-amendments jurisdiction mismatch",
    )
    expected_path = additions_path.resolve().relative_to(ROOT.resolve()).as_posix()
    require(
        amendments.get("base_additions_path") == expected_path,
        "source-addition-amendments base additions path mismatch",
    )
    require(
        isinstance(amendments.get("claim_boundary"), str) and amendments["claim_boundary"],
        "source-addition-amendments claim boundary is required",
    )

    rows = amendments.get("amendments")
    require(isinstance(rows, list), "source addition amendments must be an array")
    added_source_ids = _addition_source_ids(additions_path)
    effective = deepcopy(discovery)
    index = _source_index(effective)
    amendment_ids: set[str] = set()

    for row in rows:
        require(isinstance(row, dict), "source addition amendment must be an object")
        amendment_id = row.get("amendment_id")
        require(isinstance(amendment_id, str) and amendment_id, "amendment_id is required")
        require(amendment_id not in amendment_ids, f"duplicate amendment_id: {amendment_id}")
        amendment_ids.add(amendment_id)

        source_id = row.get("source_id")
        require(isinstance(source_id, str) and source_id, f"{amendment_id}: source_id is required")
        require(
            source_id in added_source_ids,
            f"{amendment_id}: only source IDs introduced by the additions ledger may use this amendment layer",
        )
        source = index.get(source_id)
        require(isinstance(source, dict), f"{amendment_id}: source_id is absent from composed additions: {source_id}")
        require(
            row.get("prior_source_entry_sha256") == canonical_json_digest(source),
            f"{amendment_id}: prior source digest mismatch",
        )

        resolved_on = row.get("resolved_on")
        require(isinstance(resolved_on, str), f"{amendment_id}: resolved_on is required")
        try:
            date.fromisoformat(resolved_on)
        except ValueError as error:
            raise SourceAdditionAmendmentError(
                f"{amendment_id}: resolved_on must be YYYY-MM-DD"
            ) from error

        evidence = row.get("evidence")
        require(isinstance(evidence, list) and evidence, f"{amendment_id}: evidence is required")
        evidence_urls: set[str] = set()
        for item in evidence:
            require(isinstance(item, dict), f"{amendment_id}: evidence item must be an object")
            url = item.get("url")
            require(isinstance(url, str) and url.startswith("https://"), f"{amendment_id}: evidence URL must use HTTPS")
            require(
                isinstance(item.get("classification"), str) and item["classification"],
                f"{amendment_id}: evidence classification is required",
            )
            evidence_urls.add(url)

        changes = row.get("set")
        require(isinstance(changes, dict) and changes, f"{amendment_id}: set must be a non-empty object")
        forbidden = set(changes).intersection(IMMUTABLE_SOURCE_FIELDS)
        require(not forbidden, f"{amendment_id}: cannot change immutable source fields: {sorted(forbidden)}")
        unsupported = set(changes).difference(ALLOWED_SET_FIELDS)
        require(not unsupported, f"{amendment_id}: unsupported amended fields: {sorted(unsupported)}")

        amended_url = changes.get("url")
        if amended_url is not None:
            amended_url = _validate_dcp_route(amended_url, source_id)
            require(
                amended_url in evidence_urls,
                f"{amendment_id}: amended DCP route must be present in evidence",
            )
            publication_url = source.get("publication_catalog_url")
            if publication_url is not None:
                require(
                    publication_url in evidence_urls,
                    f"{amendment_id}: preserved publication provenance must remain present in evidence",
                )

        require(
            changes.get("upstream_document_sha256") is None,
            f"{amendment_id}: C0 amendment cannot claim an upstream digest",
        )
        require(
            changes.get("upstream_digest_status") == "not-captured",
            f"{amendment_id}: C0 amendment must keep digest status not-captured",
        )

        for field, value in changes.items():
            source[field] = deepcopy(value)

    _source_index(effective)
    return effective


def load_composed_discovery(
    path: Path = DEFAULT_DISCOVERY,
    additions_path: Path | None = None,
    amendment_path: Path | None = None,
) -> dict[str, Any]:
    if additions_path is None:
        additions_path = DEFAULT_ADDITIONS
    augmented = load_augmented_discovery(path, additions_path if path.resolve() == DEFAULT_DISCOVERY.resolve() else None)
    if path.resolve() != DEFAULT_DISCOVERY.resolve():
        return augmented
    if amendment_path is None:
        amendment_path = DEFAULT_ADDITION_AMENDMENTS
    if not amendment_path.exists():
        return augmented
    return apply_addition_amendments(
        augmented,
        load_json(amendment_path),
        additions_path=additions_path,
    )


def verify_addition_amendments(
    discovery_path: Path = DEFAULT_DISCOVERY,
    additions_path: Path = DEFAULT_ADDITIONS,
    amendment_path: Path = DEFAULT_ADDITION_AMENDMENTS,
) -> dict[str, int]:
    before = load_augmented_discovery(discovery_path, additions_path)
    after = load_composed_discovery(discovery_path, additions_path, amendment_path)
    rows = load_json(amendment_path).get("amendments")
    require(isinstance(rows, list), "source addition amendments must be an array")
    before_index = _source_index(before)
    after_index = _source_index(after)
    require(set(before_index) == set(after_index), "source addition amendments cannot add or remove source identities")
    amended_source_ids = {row.get("source_id") for row in rows if isinstance(row, dict)}
    resolved_routes = sum(
        1
        for source_id in amended_source_ids
        if isinstance(source_id, str)
        and isinstance(after_index[source_id].get("url"), str)
        and after_index[source_id]["url"].startswith("https://www.dcp.edu.gov.on.ca/fr/curriculum/")
    )
    return {
        "effective_sources": len(after_index),
        "addition_amendments": len(rows),
        "amended_sources_with_exact_dcp_route": resolved_routes,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--discovery", type=Path, default=DEFAULT_DISCOVERY)
    parser.add_argument("--additions", type=Path, default=DEFAULT_ADDITIONS)
    parser.add_argument("--amendments", type=Path, default=DEFAULT_ADDITION_AMENDMENTS)
    args = parser.parse_args()
    try:
        result = verify_addition_amendments(args.discovery, args.additions, args.amendments)
    except (OSError, KeyError, SourceAdditionError, SourceAdditionAmendmentError, TypeError, ValueError) as error:
        print(f"curriculum source addition amendments failed: {error}", file=sys.stderr)
        return 1
    print(json.dumps({"valid": True, **result}, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
