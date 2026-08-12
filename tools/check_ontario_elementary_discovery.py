#!/usr/bin/env python3
"""Fail-closed validation for Ontario Elementary C0 source discovery."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-discovery.v0.json"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")


def _duplicate_values(values: list[str]) -> set[str]:
    seen: set[str] = set()
    duplicates: set[str] = set()
    for value in values:
        if value in seen:
            duplicates.add(value)
        seen.add(value)
    return duplicates


def validate_discovery(data: dict[str, Any]) -> list[str]:
    errors: list[str] = []

    if data.get("schema") != "axiom-curriculum-source-discovery.v1":
        errors.append("unexpected discovery schema")
    if data.get("state") != "C0-discovered":
        errors.append("v0 discovery artifact must remain C0-discovered")

    sources = data.get("confirmed_curriculum_sources")
    if not isinstance(sources, list) or not sources:
        return errors + ["confirmed_curriculum_sources must be a non-empty list"]

    source_ids = [source.get("source_id") for source in sources if isinstance(source, dict)]
    if any(not isinstance(source_id, str) or not source_id for source_id in source_ids):
        errors.append("every confirmed curriculum source requires a non-empty source_id")
    duplicates = _duplicate_values([source_id for source_id in source_ids if isinstance(source_id, str)])
    if duplicates:
        errors.append(f"duplicate curriculum source ids: {sorted(duplicates)}")

    source_id_set = {source_id for source_id in source_ids if isinstance(source_id, str)}
    for source in sources:
        if not isinstance(source, dict):
            errors.append("curriculum source entries must be objects")
            continue
        url = source.get("url")
        if not isinstance(url, str) or not url.startswith("https://"):
            errors.append(f"{source.get('source_id', '<unknown>')}: source url must be https")

        digest_status = source.get("upstream_digest_status")
        digest = source.get("upstream_document_sha256")
        if digest_status == "captured":
            if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
                errors.append(
                    f"{source.get('source_id', '<unknown>')}: captured digest requires lowercase SHA-256"
                )
        elif digest is not None:
            errors.append(
                f"{source.get('source_id', '<unknown>')}: digest present without captured status"
            )

    required = data.get("required_program_families")
    accounting = data.get("coverage_accounting")
    if not isinstance(required, dict) or not isinstance(accounting, dict):
        return errors + ["required_program_families and coverage_accounting are required"]

    for stream in ("english_language_schools", "french_language_schools"):
        required_families = required.get(stream)
        accounted = accounting.get(stream)
        if not isinstance(required_families, list) or not isinstance(accounted, dict):
            errors.append(f"{stream}: missing required family list or coverage accounting")
            continue

        required_set = set(required_families)
        accounted_set = set(accounted)
        if required_set != accounted_set:
            missing = sorted(required_set - accounted_set)
            extra = sorted(accounted_set - required_set)
            if missing:
                errors.append(f"{stream}: unaccounted required families: {missing}")
            if extra:
                errors.append(f"{stream}: unexpected coverage families: {extra}")

        for family, entry in accounted.items():
            if not isinstance(entry, dict) or not isinstance(entry.get("status"), str):
                errors.append(f"{stream}/{family}: coverage entry requires status")
                continue
            source_id = entry.get("source_id")
            if source_id is not None and source_id not in source_id_set:
                errors.append(f"{stream}/{family}: unknown source_id {source_id!r}")
            if entry["status"] == "source-discovered" and source_id is None:
                errors.append(f"{stream}/{family}: source-discovered requires source_id")

    overlays = data.get("policy_overlays_discovered")
    if not isinstance(overlays, list):
        errors.append("policy_overlays_discovered must be a list")
    else:
        overlay_ids = [overlay.get("policy_id") for overlay in overlays if isinstance(overlay, dict)]
        duplicate_overlays = _duplicate_values(
            [overlay_id for overlay_id in overlay_ids if isinstance(overlay_id, str)]
        )
        if duplicate_overlays:
            errors.append(f"duplicate policy overlay ids: {sorted(duplicate_overlays)}")

    unresolved = data.get("unresolved_source_work")
    if not isinstance(unresolved, list) or not unresolved:
        errors.append("C0 discovery must retain an explicit unresolved_source_work list")

    return errors


def load_discovery(path: Path = DEFAULT_PATH) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    path = Path(args[0]) if args else DEFAULT_PATH
    errors = validate_discovery(load_discovery(path))
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"Ontario Elementary discovery gate passed: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
