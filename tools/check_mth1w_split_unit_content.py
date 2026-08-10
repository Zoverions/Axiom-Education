#!/usr/bin/env python3
"""Verify split MTH1W unit manifests through the canonical unit checker."""

from __future__ import annotations

import json
import tempfile
from collections import Counter
from pathlib import Path

from tools.check_mth1w_unit_content import verify_content

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATHS = [
    ROOT / "curriculum/content/mth1w/u8/manifest.v1.json",
]


class SplitUnitContentError(RuntimeError):
    """Raised when a split-unit manifest cannot be assembled safely."""


def _repo_asset(raw_path: object, manifest_path: Path) -> Path:
    if not isinstance(raw_path, str) or not raw_path.strip():
        raise SplitUnitContentError(
            f"{manifest_path}: lesson asset must be a non-empty repository path"
        )
    relative = Path(raw_path)
    if relative.is_absolute() or ".." in relative.parts:
        raise SplitUnitContentError(
            f"{manifest_path}: lesson asset escapes repository: {raw_path!r}"
        )
    resolved = (ROOT / relative).resolve()
    if not resolved.is_relative_to(ROOT.resolve()):
        raise SplitUnitContentError(
            f"{manifest_path}: lesson asset escapes repository: {raw_path!r}"
        )
    if resolved.suffix != ".json" or not resolved.is_file():
        raise SplitUnitContentError(
            f"{manifest_path}: lesson asset is unavailable: {raw_path!r}"
        )
    return resolved


def materialize_manifest(manifest_path: Path) -> dict[str, object]:
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise SplitUnitContentError(
            f"cannot read split unit manifest: {manifest_path}"
        ) from error
    if not isinstance(manifest, dict):
        raise SplitUnitContentError(f"{manifest_path}: manifest root must be an object")

    raw_assets = manifest.get("lesson_assets")
    if not isinstance(raw_assets, list) or not raw_assets:
        raise SplitUnitContentError(
            f"{manifest_path}: lesson_assets must be a non-empty array"
        )
    if len(raw_assets) != len(set(raw_assets)):
        raise SplitUnitContentError(f"{manifest_path}: lesson assets must be unique")

    lessons: list[object] = []
    for raw_path in raw_assets:
        asset_path = _repo_asset(raw_path, manifest_path)
        try:
            lesson = json.loads(asset_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise SplitUnitContentError(
                f"{manifest_path}: cannot read lesson asset {raw_path!r}"
            ) from error
        if not isinstance(lesson, dict):
            raise SplitUnitContentError(
                f"{manifest_path}: lesson asset root must be an object: {raw_path!r}"
            )
        lessons.append(lesson)

    materialized = dict(manifest)
    materialized.pop("lesson_assets", None)
    materialized["lessons"] = lessons
    return materialized


def verify_split_manifest(manifest_path: Path) -> dict[str, int]:
    materialized = materialize_manifest(manifest_path)
    with tempfile.TemporaryDirectory(prefix="axiom-mth1w-split-") as directory:
        unit_path = Path(directory) / f"{materialized.get('unit_id', 'unit')}.json"
        unit_path.write_text(
            json.dumps(materialized, ensure_ascii=False, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        return verify_content(unit_path)


def verify_all_split(paths: list[Path] = MANIFEST_PATHS) -> dict[str, int]:
    if not paths:
        raise SplitUnitContentError("no split MTH1W unit manifests are configured")
    totals: Counter[str] = Counter()
    seen_units: set[str] = set()
    for path in paths:
        materialized = materialize_manifest(path)
        unit_id = materialized.get("unit_id")
        if not isinstance(unit_id, str) or unit_id in seen_units:
            raise SplitUnitContentError(f"{path}: duplicate or invalid unit id")
        seen_units.add(unit_id)
        totals.update(verify_split_manifest(path))
    totals["units"] = len(seen_units)
    return dict(totals)


def main() -> int:
    totals = verify_all_split()
    print(json.dumps({"valid": True, **totals}, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
