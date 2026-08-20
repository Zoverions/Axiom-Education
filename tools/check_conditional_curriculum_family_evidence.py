#!/usr/bin/env python3
"""Fail closed on partial C1 evidence for multi-source curriculum families.

A program family declared as ``primary-with-conditional-alternatives`` represents one
curriculum requirement whose applicable source depends on learner context. C1 evidence
for that family is therefore atomic: either none of its required source identities are
locked yet, or the primary and every declared conditional alternative are locked. This
prevents a primary-only snapshot from being counted as complete family evidence.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_lock import (  # noqa: E402
    DEFAULT_DISCOVERY,
    DEFAULT_LOCK_DIR,
    load_discovery,
    verify_lock,
)


class ConditionalFamilyEvidenceError(RuntimeError):
    """Raised when a conditional program family has partial or malformed evidence."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ConditionalFamilyEvidenceError(message)


def _verified_lock_ids(lock_dir: Path = DEFAULT_LOCK_DIR) -> set[str]:
    source_ids: set[str] = set()
    if not lock_dir.exists():
        return source_ids
    for path in sorted(lock_dir.glob("*.json")):
        lock = verify_lock(path, DEFAULT_DISCOVERY)
        source_id = lock.get("source_id")
        require(isinstance(source_id, str) and source_id, f"lock missing source_id: {path}")
        require(source_id not in source_ids, f"duplicate C1 lock source_id: {source_id}")
        source_ids.add(source_id)
    return source_ids


def verify_conditional_family_evidence(
    *,
    discovery: dict[str, Any] | None = None,
    locked_source_ids: Iterable[str] | None = None,
) -> dict[str, Any]:
    if discovery is None:
        discovery = load_discovery(DEFAULT_DISCOVERY)
    if locked_source_ids is None:
        locked = _verified_lock_ids()
    else:
        locked = set(locked_source_ids)

    required = discovery.get("required_program_families")
    accounting = discovery.get("coverage_accounting")
    require(isinstance(required, dict), "required program families are missing")
    require(isinstance(accounting, dict), "coverage accounting is missing")

    conditional_families: list[dict[str, Any]] = []
    for stream in ("english_language_schools", "french_language_schools"):
        families = required.get(stream)
        stream_accounting = accounting.get(stream)
        require(isinstance(families, list), f"{stream}: required program families missing")
        require(isinstance(stream_accounting, dict), f"{stream}: coverage accounting missing")

        for family in families:
            require(isinstance(family, str) and family, f"{stream}: invalid program family")
            entry = stream_accounting.get(family)
            require(isinstance(entry, dict), f"{stream}/{family}: accounting row missing")
            if entry.get("coverage_mode") != "primary-with-conditional-alternatives":
                continue

            primary = entry.get("source_id")
            alternatives = entry.get("conditional_sources")
            require(
                isinstance(primary, str) and primary,
                f"{stream}/{family}: conditional family requires a primary source_id",
            )
            require(
                isinstance(alternatives, list) and alternatives,
                f"{stream}/{family}: conditional family requires at least one conditional source",
            )

            alternative_ids: list[str] = []
            for alternative in alternatives:
                require(
                    isinstance(alternative, dict),
                    f"{stream}/{family}: conditional source must be an object",
                )
                source_id = alternative.get("source_id")
                require(
                    isinstance(source_id, str) and source_id,
                    f"{stream}/{family}: conditional source_id is required",
                )
                require(
                    source_id != primary,
                    f"{stream}/{family}: conditional source cannot equal primary source",
                )
                require(
                    source_id not in alternative_ids,
                    f"{stream}/{family}: duplicate conditional source_id",
                )
                require(
                    isinstance(alternative.get("condition"), str)
                    and alternative["condition"].strip(),
                    f"{stream}/{family}: conditional source requires a condition",
                )
                alternative_ids.append(source_id)

            family_sources = {primary, *alternative_ids}
            locked_family_sources = family_sources.intersection(locked)
            require(
                not locked_family_sources or locked_family_sources == family_sources,
                f"{stream}/{family}: conditional family C1 evidence must be atomic; "
                f"locked={sorted(locked_family_sources)} required={sorted(family_sources)}",
            )
            conditional_families.append(
                {
                    "stream": stream,
                    "program_family": family,
                    "primary_source_id": primary,
                    "conditional_source_ids": sorted(alternative_ids),
                    "required_source_ids": sorted(family_sources),
                    "c1_family_complete": locked_family_sources == family_sources,
                }
            )

    return {
        "valid": True,
        "conditional_family_count": len(conditional_families),
        "conditional_families": conditional_families,
    }


def main() -> int:
    try:
        result = verify_conditional_family_evidence()
    except (OSError, KeyError, ConditionalFamilyEvidenceError, TypeError, ValueError) as error:
        print(f"conditional curriculum family evidence failed: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
