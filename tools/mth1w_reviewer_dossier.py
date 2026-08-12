#!/usr/bin/env python3
"""Build a deterministic MTH1W reviewer dossier from current evidence and draft content.

The dossier reduces reviewer friction without manufacturing approval. It packages exact
content-addressed review targets, source-use inventory, cumulative assessment evidence,
accessible/offline lesson exports, current readiness blockers, and any already-submitted
review provenance into a reproducible directory.
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
DEFAULT_OUTPUT = ROOT / "build" / "mth1w-reviewer-dossier"
READINESS_PATH = ROOT / "config" / "curriculum-readiness.json"
ASSESSMENT_PATH = ROOT / "curriculum" / "courses" / "ontario-mth1w-2021.assessment-plan.json"
LESSON_REVIEW_DIR = ROOT / "curriculum" / "reviews" / "mth1w"
LICENCE_REVIEW_DIR = ROOT / "curriculum" / "licensing" / "mth1w" / "reviews"
EXPECTED_LESSONS = 43

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_accessible_export import build_package as build_accessible_package  # noqa: E402
from tools.mth1w_review_evidence import build_plan, verify_directory as verify_lesson_reviews  # noqa: E402
from tools.mth1w_source_use_inventory import build_inventory, verify_reviews as verify_licence_reviews  # noqa: E402


class ReviewerDossierError(RuntimeError):
    """Raised when reviewer inputs or dossier bytes are incomplete or inconsistent."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReviewerDossierError(message)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def file_sha256(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def canonical_json_bytes(value: Any, *, pretty: bool = True) -> bytes:
    if pretty:
        rendered = json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True)
    else:
        rendered = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return (rendered + "\n").encode("utf-8")


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(canonical_json_bytes(value))


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ReviewerDossierError(f"missing required dossier input: {path}") from error
    except json.JSONDecodeError as error:
        raise ReviewerDossierError(f"invalid JSON dossier input {path}: {error}") from error


def copy_verified_review_records(source_dir: Path, destination: Path) -> list[str]:
    destination.mkdir(parents=True, exist_ok=True)
    copied: list[str] = []
    if not source_dir.exists():
        return copied
    for path in sorted(source_dir.glob("*.json")):
        target = destination / path.name
        target.write_bytes(path.read_bytes())
        copied.append(path.name)
    return copied


def build_review_guide(
    review_plan: dict[str, Any],
    source_inventory: dict[str, Any],
    lesson_summary: dict[str, int],
    licence_summary: dict[str, int],
) -> bytes:
    lines = [
        "# MTH1W reviewer dossier",
        "",
        "This directory is a deterministic review package for the current authored MTH1W draft. It contains **review inputs, not approval**.",
        "",
        "## Current evidence boundary",
        "",
        f"- Content-addressed lesson targets: **{review_plan['target_count']}**",
        f"- Submitted lesson review records: **{lesson_summary['reviews']}**",
        f"- Approved submitted lesson reviews: **{lesson_summary['approvals']}**",
        f"- Declared external source uses: **{source_inventory['source_count']}** distinct sources across **{source_inventory['unit_count']}** units",
        f"- Submitted source-licensing reviews: **{licence_summary['reviews']}**",
        f"- Source uses permitted-as-used by submitted reviews: **{licence_summary['permitted_as_used']}**",
        "- Human educator/source, cultural/context, licensing, assessment-validity, and accessibility/usability gates remain governed independently.",
        "",
        "## Suggested review order",
        "",
        "1. Read `current-readiness.json` and `assessment-plan.json` to understand what the project currently claims and what remains blocked.",
        "2. Use `lesson-review-plan.json` to select an exact lesson target. Every target has a canonical lesson SHA-256; an edit changes the digest and makes older review evidence stale.",
        "3. Read the matching learner lesson and answer/review copy under `accessible-offline/lessons/`. These are deterministic text alternatives generated from the same authored lesson object.",
        "4. Record instructional/cultural/accessibility findings against the exact target digest using the repository's review-evidence schema and verifier; do not edit a review to point at a new digest after content changes.",
        "5. Use `source-use-inventory.json` for licensing review. A licensing decision must bind to the exact `source_use_sha256`; public availability alone is not redistribution permission.",
        "6. Review cumulative assessment design separately. Lesson approval does not establish assessment validity, mastery, grade, or credit.",
        "7. Preserve negative findings (`changes-required`, `rejected`, restricted/unresolved licensing decisions) as provenance rather than deleting them.",
        "",
        "## Submission commands",
        "",
        "Lesson review evidence:",
        "",
        "```bash",
        "python tools/mth1w_review_evidence.py verify path/to/review.json",
        "```",
        "",
        "Source licensing review evidence:",
        "",
        "```bash",
        "python tools/mth1w_source_use_inventory.py verify-review path/to/licence-review.json",
        "```",
        "",
        "After adding evidence, run the canonical repository verifier. Readiness claims must continue to match the actual evidence directories.",
        "",
        "## Non-claims",
        "",
        "This dossier does not make Axiom Education a school, grant Ontario course credit, establish Ministry approval, prove learner mastery, decide copyright law, or establish WCAG/AODA conformance. It is a reproducible evidence package for qualified human review.",
    ]
    return ("\n".join(lines).rstrip() + "\n").encode("utf-8")


def artifact_manifest(root: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for path in sorted(candidate for candidate in root.rglob("*") if candidate.is_file()):
        relative = path.relative_to(root).as_posix()
        if relative == "manifest.json":
            continue
        data = path.read_bytes()
        records.append(
            {
                "path": relative,
                "byte_length": len(data),
                "sha256": sha256_bytes(data),
            }
        )
    return records


def build(output: Path) -> dict[str, Any]:
    review_plan = build_plan()
    source_inventory = build_inventory()
    lesson_summary = verify_lesson_reviews()
    licence_summary = verify_licence_reviews()
    readiness = load_json(READINESS_PATH)
    assessment = load_json(ASSESSMENT_PATH)

    require(review_plan.get("target_count") == EXPECTED_LESSONS, "review plan does not contain 43 lesson targets")
    require(source_inventory.get("unit_count") == 9, "source-use inventory does not cover nine authored units")
    require(isinstance(readiness, dict), "curriculum readiness must be an object")
    require(isinstance(assessment, dict), "assessment plan must be an object")

    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    write_json(output / "lesson-review-plan.json", review_plan)
    write_json(output / "source-use-inventory.json", source_inventory)
    write_json(output / "current-readiness.json", readiness)
    write_json(output / "assessment-plan.json", assessment)
    write_json(
        output / "submitted-review-summary.json",
        {
            "schema": "axiom-education-reviewer-dossier-submitted-evidence-summary.v1",
            "lesson_reviews": lesson_summary,
            "source_licensing_reviews": licence_summary,
            "claim_boundary": "Counts reflect review records currently committed in the evidence directories. Zero or incomplete counts remain blocked evidence, not implied approval.",
        },
    )

    accessible_dir = output / "accessible-offline"
    accessible_manifest = build_accessible_package(accessible_dir)
    require(accessible_manifest.get("lesson_count") == EXPECTED_LESSONS, "accessible package does not cover 43 lessons")

    copied_lesson_reviews = copy_verified_review_records(
        LESSON_REVIEW_DIR,
        output / "submitted-evidence" / "lesson-reviews",
    )
    copied_licence_reviews = copy_verified_review_records(
        LICENCE_REVIEW_DIR,
        output / "submitted-evidence" / "source-licensing-reviews",
    )
    require(len(copied_lesson_reviews) == lesson_summary["reviews"], "lesson review copy count mismatch")
    require(len(copied_licence_reviews) == licence_summary["reviews"], "licence review copy count mismatch")

    (output / "REVIEW-GUIDE.md").write_bytes(
        build_review_guide(review_plan, source_inventory, lesson_summary, licence_summary)
    )

    files = artifact_manifest(output)
    manifest = {
        "schema": "axiom-education-mth1w-reviewer-dossier.v1",
        "course_code": "MTH1W",
        "status": "machine-generated-review-inputs-no-approval",
        "lesson_target_count": review_plan["target_count"],
        "source_use_count": source_inventory["source_count"],
        "accessible_lesson_count": accessible_manifest["lesson_count"],
        "submitted_lesson_review_count": lesson_summary["reviews"],
        "submitted_licence_review_count": licence_summary["reviews"],
        "readiness_sha256": file_sha256(output / "current-readiness.json"),
        "assessment_plan_sha256": file_sha256(output / "assessment-plan.json"),
        "lesson_review_plan_sha256": file_sha256(output / "lesson-review-plan.json"),
        "source_use_inventory_sha256": file_sha256(output / "source-use-inventory.json"),
        "claim_boundary": (
            "This dossier is a deterministic packaging of current machine evidence, draft lesson alternatives, and submitted human-review provenance. "
            "It creates no educator, cultural, licensing, accessibility, assessment, mastery, grade, credit, or Ministry approval."
        ),
        "files": files,
    }
    write_json(output / "manifest.json", manifest)
    return manifest


def verify_determinism() -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="axiom-review-dossier-a-") as first_dir, tempfile.TemporaryDirectory(prefix="axiom-review-dossier-b-") as second_dir:
        first = Path(first_dir)
        second = Path(second_dir)
        first_manifest = build(first)
        second_manifest = build(second)
        require(first_manifest == second_manifest, "reviewer dossier manifests differ between builds")
        first_files = sorted(path.relative_to(first) for path in first.rglob("*") if path.is_file())
        second_files = sorted(path.relative_to(second) for path in second.rglob("*") if path.is_file())
        require(first_files == second_files, "reviewer dossier file sets differ between builds")
        for relative in first_files:
            require((first / relative).read_bytes() == (second / relative).read_bytes(), f"reviewer dossier bytes differ: {relative}")
        require(first_manifest["lesson_target_count"] == EXPECTED_LESSONS, "reviewer dossier target count drifted")
        return first_manifest


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    build_parser = commands.add_parser("build", help="materialize the current reviewer dossier")
    build_parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    commands.add_parser("verify", help="build the dossier twice and prove byte determinism")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "build":
            manifest = build(args.output)
            print(
                "MTH1W reviewer dossier built: "
                f"{manifest['lesson_target_count']} lesson targets, "
                f"{manifest['source_use_count']} source uses -> {args.output}"
            )
        else:
            manifest = verify_determinism()
            print(
                "MTH1W reviewer dossier verified: "
                f"{manifest['lesson_target_count']} lesson targets; "
                f"{manifest['source_use_count']} source uses; "
                "byte-deterministic and no approval implied"
            )
    except (OSError, KeyError, ReviewerDossierError, ValueError) as error:
        print(f"MTH1W reviewer dossier failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
