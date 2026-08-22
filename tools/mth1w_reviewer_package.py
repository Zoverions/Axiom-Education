#!/usr/bin/env python3
"""Build the complete deterministic MTH1W reviewer package.

The package combines the evidence/readiness dossier with deliberately non-valid review
templates. It remains review material only and creates no human judgement or approval.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "build" / "mth1w-reviewer-package"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_review_templates import build as build_templates  # noqa: E402
from tools.mth1w_reviewer_dossier import build as build_dossier  # noqa: E402


class ReviewerPackageError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReviewerPackageError(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def file_inventory(root: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for path in sorted(candidate for candidate in root.rglob("*") if candidate.is_file()):
        relative = path.relative_to(root).as_posix()
        if relative == "manifest.json":
            continue
        records.append(
            {
                "path": relative,
                "byte_length": path.stat().st_size,
                "sha256": sha256(path),
            }
        )
    return records


def build(output: Path) -> dict[str, Any]:
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    dossier_dir = output / "dossier"
    template_dir = output / "templates"
    dossier = build_dossier(dossier_dir)
    templates = build_templates(template_dir)

    require(dossier.get("lesson_target_count") == 43, "reviewer dossier lesson target count drifted")
    require(templates.get("lesson_target_count") == 43, "review template lesson target count drifted")
    require(
        dossier.get("source_use_count") == templates.get("source_use_count"),
        "dossier/template source-use count mismatch",
    )
    require(
        dossier.get("status") == "machine-generated-review-inputs-no-approval",
        "dossier status would imply approval",
    )
    require(
        templates.get("status") == "machine-generated-templates-no-human-evidence",
        "template status would imply human evidence",
    )

    guide = (
        "# MTH1W complete reviewer package\n\n"
        "This package contains two machine-generated components:\n\n"
        "- `dossier/` — exact current review inputs, readiness state, assessment plan, source-use inventory, and accessible/offline lesson copies;\n"
        "- `templates/` — digest-prefilled but deliberately non-valid human-review templates.\n\n"
        "Nothing in this package is human approval. Complete a real review, convert it to the required evidence schema, commit it to the appropriate evidence directory, and run canonical verification. Never edit a prefilled digest to carry a judgement to changed content.\n"
    )
    (output / "README.md").write_text(guide, encoding="utf-8")

    files = file_inventory(output)
    manifest = {
        "schema": "axiom-education-mth1w-reviewer-package.v1",
        "course_code": "MTH1W",
        "status": "machine-generated-review-package-no-human-evidence",
        "lesson_target_count": 43,
        "source_use_count": dossier["source_use_count"],
        "lesson_review_template_count": templates["lesson_review_template_count"],
        "source_licensing_template_count": templates["source_licensing_template_count"],
        "submitted_lesson_review_count": dossier["submitted_lesson_review_count"],
        "submitted_licence_review_count": dossier["submitted_licence_review_count"],
        "dossier_manifest_sha256": sha256(dossier_dir / "manifest.json"),
        "template_manifest_sha256": sha256(template_dir / "manifest.json"),
        "claim_boundary": (
            "This package combines machine-generated review inputs and non-evidence templates. "
            "It creates no educator, cultural/context, licensing, accessibility/usability, assessment-validity, mastery, grade, credit, school-equivalence, or Ministry approval."
        ),
        "files": files,
    }
    (output / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return manifest


def verify_determinism() -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="axiom-review-package-a-") as a, tempfile.TemporaryDirectory(prefix="axiom-review-package-b-") as b:
        first = Path(a)
        second = Path(b)
        first_manifest = build(first)
        second_manifest = build(second)
        require(first_manifest == second_manifest, "reviewer package manifests differ between builds")
        first_files = sorted(path.relative_to(first) for path in first.rglob("*") if path.is_file())
        second_files = sorted(path.relative_to(second) for path in second.rglob("*") if path.is_file())
        require(first_files == second_files, "reviewer package file sets differ between builds")
        for relative in first_files:
            require((first / relative).read_bytes() == (second / relative).read_bytes(), f"reviewer package bytes differ: {relative}")
        return first_manifest


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    build_parser = commands.add_parser("build")
    build_parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    commands.add_parser("verify")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "build":
            manifest = build(args.output)
            print(
                "MTH1W reviewer package built: "
                f"{manifest['lesson_review_template_count']} lesson review templates, "
                f"{manifest['source_licensing_template_count']} licensing templates -> {args.output}"
            )
        else:
            manifest = verify_determinism()
            print(
                "MTH1W reviewer package verified: "
                f"{manifest['lesson_target_count']} lesson targets; "
                "byte-deterministic; no human evidence implied"
            )
    except (OSError, KeyError, ReviewerPackageError, ValueError) as error:
        print(f"MTH1W reviewer package failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
