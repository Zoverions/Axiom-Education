#!/usr/bin/env python3
"""Validate and compose append-only additions to Ontario curriculum source discovery.

The historical discovery ledger remains immutable. Existing source identities may be
updated only through the separate amendment chain; this layer is only for source IDs
that did not exist in the historical ledger. Added sources remain C0 until later bounded
capture, digest, review, licensing, and pack gates provide stronger evidence.
"""

from __future__ import annotations

import argparse
import json
import sys
from copy import deepcopy
from datetime import date
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DISCOVERY = ROOT / "curriculum" / "ontario-elementary" / "source-discovery.v0.json"
DEFAULT_ADDITIONS = ROOT / "curriculum" / "ontario-elementary" / "source-discovery-additions.v1.json"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_discovery import (  # noqa: E402
    load_effective_discovery,
)


class SourceAdditionError(RuntimeError):
    """Raised when an append-only source addition would violate discovery provenance."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SourceAdditionError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise SourceAdditionError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise SourceAdditionError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


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


def _validate_https(value: object, message: str) -> str:
    require(isinstance(value, str) and value.startswith("https://"), message)
    return value


def _validate_source(source: dict[str, Any], addition_id: str) -> str:
    source_id = source.get("source_id")
    require(isinstance(source_id, str) and source_id, f"{addition_id}: source_id is required")
    require(
        isinstance(source.get("subject_family"), str) and source["subject_family"],
        f"{source_id}: subject_family is required",
    )
    grades = source.get("grades")
    require(isinstance(grades, list) and grades, f"{source_id}: grades are required")
    require(
        isinstance(source.get("policy_version"), str) and source["policy_version"],
        f"{source_id}: policy_version is required",
    )
    source_url = _validate_https(source.get("url"), f"{source_id}: official source URL must use HTTPS")
    publication_url = _validate_https(
        source.get("publication_catalog_url"),
        f"{source_id}: publication catalogue URL must use HTTPS",
    )
    require(
        "publications.gov.on.ca" in publication_url,
        f"{source_id}: initial French-school additions require Publications Ontario provenance",
    )
    publication_number = source.get("publication_number")
    require(
        isinstance(publication_number, str) and publication_number,
        f"{source_id}: publication_number is required",
    )
    require(
        isinstance(source.get("classification"), str) and source["classification"],
        f"{source_id}: classification is required",
    )
    require(
        isinstance(source.get("source_locator_status"), str)
        and source["source_locator_status"],
        f"{source_id}: source_locator_status is required",
    )
    require(
        isinstance(source.get("status_note"), str) and source["status_note"],
        f"{source_id}: status_note is required",
    )
    require(
        source.get("upstream_document_sha256") is None,
        f"{source_id}: C0 addition cannot claim an upstream digest",
    )
    require(
        source.get("upstream_digest_status") == "not-captured",
        f"{source_id}: C0 addition must keep digest status not-captured",
    )
    require(
        isinstance(source.get("review_status"), str) and source["review_status"],
        f"{source_id}: review_status is required",
    )
    require(
        source_url == publication_url or source_url.startswith("https://www.dcp.edu.gov.on.ca/"),
        f"{source_id}: source URL must be its official publication record or DCP route",
    )
    return source_id


def apply_additions(
    discovery: dict[str, Any],
    additions: dict[str, Any],
    *,
    base_discovery_path: Path = DEFAULT_DISCOVERY,
) -> dict[str, Any]:
    require(
        additions.get("schema") == "axiom-curriculum-source-discovery-additions.v1",
        "unsupported source-additions schema",
    )
    require(
        additions.get("jurisdiction_id") == discovery.get("jurisdiction_id"),
        "source-additions jurisdiction mismatch",
    )
    expected_path = base_discovery_path.resolve().relative_to(ROOT.resolve()).as_posix()
    require(
        additions.get("base_discovery_path") == expected_path,
        "source-additions base discovery path mismatch",
    )
    require(
        isinstance(additions.get("claim_boundary"), str) and additions["claim_boundary"],
        "source-additions claim boundary is required",
    )
    rows = additions.get("additions")
    require(isinstance(rows, list), "source additions must be an array")

    effective = deepcopy(discovery)
    sources = effective.get("confirmed_curriculum_sources")
    require(isinstance(sources, list), "confirmed curriculum sources must be an array")
    index = _source_index(effective)
    required = effective.get("required_program_families")
    accounting = effective.get("coverage_accounting")
    require(isinstance(required, dict), "required program families are missing")
    require(isinstance(accounting, dict), "coverage accounting is missing")

    addition_ids: set[str] = set()
    bound_pairs: set[tuple[str, str]] = set()
    for row in rows:
        require(isinstance(row, dict), "source addition must be an object")
        addition_id = row.get("addition_id")
        require(isinstance(addition_id, str) and addition_id, "addition_id is required")
        require(addition_id not in addition_ids, f"duplicate addition_id: {addition_id}")
        addition_ids.add(addition_id)

        discovered_on = row.get("discovered_on")
        require(isinstance(discovered_on, str), f"{addition_id}: discovered_on is required")
        try:
            date.fromisoformat(discovered_on)
        except ValueError as error:
            raise SourceAdditionError(f"{addition_id}: discovered_on must be YYYY-MM-DD") from error

        source = row.get("source")
        require(isinstance(source, dict), f"{addition_id}: source must be an object")
        source_id = _validate_source(source, addition_id)
        require(
            source_id not in index,
            f"{addition_id}: source_id already exists and must use the amendment chain instead: {source_id}",
        )

        evidence = row.get("evidence")
        require(isinstance(evidence, list) and evidence, f"{source_id}: evidence is required")
        evidence_urls: set[str] = set()
        for item in evidence:
            require(isinstance(item, dict), f"{source_id}: evidence item must be an object")
            url = _validate_https(item.get("url"), f"{source_id}: evidence URL must use HTTPS")
            evidence_urls.add(url)
            require(
                isinstance(item.get("classification"), str) and item["classification"],
                f"{source_id}: evidence classification is required",
            )
        require(
            source["publication_catalog_url"] in evidence_urls,
            f"{source_id}: publication catalogue must be present in evidence",
        )

        bindings = row.get("coverage_bindings")
        require(isinstance(bindings, list) and bindings, f"{source_id}: coverage binding is required")
        for binding in bindings:
            require(isinstance(binding, dict), f"{source_id}: coverage binding must be an object")
            stream = binding.get("stream")
            family = binding.get("program_family")
            require(
                stream in {"english_language_schools", "french_language_schools"},
                f"{source_id}: unsupported coverage stream",
            )
            required_families = required.get(stream)
            stream_accounting = accounting.get(stream)
            require(isinstance(required_families, list), f"{stream}: required families missing")
            require(isinstance(stream_accounting, dict), f"{stream}: coverage accounting missing")
            require(
                isinstance(family, str) and family in required_families,
                f"{source_id}: coverage binding is not a required program family",
            )
            pair = (stream, family)
            require(pair not in bound_pairs, f"duplicate source-addition coverage binding: {stream}/{family}")
            bound_pairs.add(pair)
            current = stream_accounting.get(family)
            require(isinstance(current, dict), f"{stream}/{family}: accounting row missing")
            require(
                current.get("source_id") is None,
                f"{stream}/{family}: existing source binding cannot be overwritten by an addition",
            )
            require(
                binding.get("status") == "source-discovered",
                f"{stream}/{family}: C0 addition coverage status must be source-discovered",
            )
            stream_accounting[family] = {
                "status": "source-discovered",
                "source_id": source_id,
            }

        copied = deepcopy(source)
        sources.append(copied)
        index[source_id] = copied

    _source_index(effective)
    return effective


def load_augmented_discovery(
    path: Path = DEFAULT_DISCOVERY,
    additions_path: Path | None = None,
) -> dict[str, Any]:
    effective = load_effective_discovery(path)
    if additions_path is None:
        if path.resolve() != DEFAULT_DISCOVERY.resolve() or not DEFAULT_ADDITIONS.exists():
            return effective
        additions_path = DEFAULT_ADDITIONS
    if not additions_path.exists():
        return effective
    return apply_additions(
        effective,
        load_json(additions_path),
        base_discovery_path=path,
    )


def verify_additions(
    discovery_path: Path = DEFAULT_DISCOVERY,
    additions_path: Path = DEFAULT_ADDITIONS,
) -> dict[str, int]:
    before = load_effective_discovery(discovery_path)
    after = load_augmented_discovery(discovery_path, additions_path)
    before_count = len(_source_index(before))
    after_count = len(_source_index(after))
    additions = load_json(additions_path).get("additions")
    require(isinstance(additions, list), "source additions must be an array")
    require(
        after_count == before_count + len(additions),
        "augmented discovery count does not equal base-effective sources plus additions",
    )
    french_accounting = after["coverage_accounting"]["french_language_schools"]
    discovered_french = sum(
        1
        for row in french_accounting.values()
        if isinstance(row, dict) and isinstance(row.get("source_id"), str)
    )
    return {
        "effective_sources_before_additions": before_count,
        "appended_c0_sources": len(additions),
        "effective_sources_after_additions": after_count,
        "french_program_families_with_c0_source": discovered_french,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--discovery", type=Path, default=DEFAULT_DISCOVERY)
    parser.add_argument("--additions", type=Path, default=DEFAULT_ADDITIONS)
    args = parser.parse_args()
    try:
        result = verify_additions(args.discovery, args.additions)
    except (OSError, KeyError, SourceAdditionError, TypeError, ValueError) as error:
        print(f"curriculum source additions failed: {error}", file=sys.stderr)
        return 1
    print(json.dumps({"valid": True, **result}, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
