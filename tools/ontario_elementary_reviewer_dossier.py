#!/usr/bin/env python3
"""Build a deterministic Ontario Elementary source-review dossier.

The dossier packages current C1 metadata, content-addressed human-review targets,
monitoring/readiness context, blank attestation templates, and already-submitted review
provenance. It never packages captured Ontario curriculum source bytes and creates no
approval, licensing permission, curriculum correctness, or activation authority.
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
DEFAULT_OUTPUT = ROOT / "build" / "ontario-elementary-source-reviewer-dossier"
LOCK_DIR = ROOT / "curriculum" / "ontario-elementary" / "source-locks"
REVIEW_DIR = ROOT / "curriculum" / "reviews" / "ontario-elementary" / "sources"
MONITORING_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-monitoring.v1.json"
TARGETS_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-capture-targets.v1.json"
EXPECTED_SOURCES = 16

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.check_curriculum_source_monitoring import verify_policy  # noqa: E402
from tools.ontario_elementary_readiness import build_readiness, verify_readiness  # noqa: E402
from tools.ontario_elementary_source_review import (  # noqa: E402
    REQUIRED_CONFIRMATIONS,
    build_plan,
    verify_directory as verify_source_reviews,
)
from tools.remote_curriculum_source_capture import validate_target_registry  # noqa: E402


class ElementaryReviewerDossierError(RuntimeError):
    """Raised when dossier inputs or deterministic packaging are inconsistent."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ElementaryReviewerDossierError(message)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_json_bytes(value: Any) -> bytes:
    return (
        json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
    ).encode("utf-8")


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(canonical_json_bytes(value))


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ElementaryReviewerDossierError(f"missing dossier input: {path}") from error
    except json.JSONDecodeError as error:
        raise ElementaryReviewerDossierError(f"invalid JSON dossier input {path}: {error}") from error
    require(isinstance(value, dict), f"dossier JSON root must be an object: {path}")
    return value


def copy_json_files(source: Path, destination: Path) -> list[str]:
    destination.mkdir(parents=True, exist_ok=True)
    copied: list[str] = []
    if not source.exists():
        return copied
    for path in sorted(source.glob("*.json")):
        target = destination / path.name
        target.write_bytes(path.read_bytes())
        copied.append(path.name)
    return copied


def review_template(target: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema": "axiom-education-ontario-elementary-source-review.v1",
        "review_id": "",
        "review_type": "source-identity-and-scope",
        "source_id": target["source_id"],
        "target_sha256": target["target_sha256"],
        "reviewer": {"name": "", "qualification": ""},
        "reviewed_at": "",
        "decision": "",
        "confirmations": {key: False for key in sorted(REQUIRED_CONFIRMATIONS)},
        "findings": [],
        "scope_limitations": [
            "Source identity and scope only; no licensing or curriculum-content approval."
        ],
        "attestation_type": "human-review",
    }


def build_review_guide(
    plan: dict[str, Any],
    review_summary: dict[str, Any],
    readiness: dict[str, Any],
) -> bytes:
    summary = readiness["summary"]
    lines = [
        "# Ontario Elementary source reviewer dossier",
        "",
        "This directory is a deterministic package for qualified human review of the current Ontario Elementary source identities and scopes. It contains **review inputs, not approval**.",
        "",
        "## Current evidence boundary",
        "",
        f"- Content-addressed source-review targets: **{plan['target_count']}**",
        f"- Submitted source-review records: **{review_summary['reviews']}**",
        f"- Approved current source reviews: **{review_summary['approved_sources']} / {plan['target_count']}**",
        f"- C1 source snapshots: **{summary['c1_snapshot_sources']} / {summary['confirmed_discovery_sources']}**",
        f"- Monitoring split: **{summary['strict_exact_byte_monitored_sources']} strict PDF / {summary['observational_response_surface_sources']} observational HTML**",
        f"- Canonical C2 records: **{summary['canonical_c2_records']}**",
        "- Captured Ontario curriculum source bytes are not included in this dossier.",
        "- Redistribution remains review-required for every current C1 source.",
        "",
        "## What this review decides",
        "",
        "For the exact target digest, a reviewer may attest whether the source is an official Ontario Ministry source, the source identity is correct, the policy version is correctly represented, the grade scope is correct, and the recorded official locator is appropriate.",
        "",
        "This review does **not** decide licensing/redistribution rights, normalized curriculum correctness, pedagogy, accessibility, assessment validity, pack activation, Ministry endorsement, or school equivalency.",
        "",
        "## Suggested review order",
        "",
        "1. Read `current-readiness.json` and `source-monitoring.json` for the current evidence boundary.",
        "2. Select a source from `source-review-plan.json`. The target SHA-256 binds the composed source entry and exact C1 metadata lock.",
        "3. Inspect the corresponding metadata lock under `source-locks/` and the official locator named in the target. The source bytes themselves are intentionally not packaged here.",
        "4. Copy the matching file from `review-templates/`, fill in reviewer identity/qualification, timestamp, decision, confirmations, findings, and limitations, then save it under `curriculum/reviews/ontario-elementary/sources/` in the repository.",
        "5. Verify the completed attestation with `python tools/ontario_elementary_source_review.py verify path/to/review.json`.",
        "6. Preserve `changes-required` and `rejected` evidence rather than deleting it. Version 1 permits only one current attestation per source; duplicate current records fail closed.",
        "7. After source review, handle licensing and C2 normalization through their separate gates. Source approval alone must not promote either one.",
        "",
        "## Template warning",
        "",
        "Files in `review-templates/` are intentionally incomplete and will fail the review verifier until a qualified human fills them out. Their `target_sha256` values are the only pre-bound approval target; no decision is preselected.",
        "",
        "## Non-claims",
        "",
        "This dossier does not establish curriculum correctness, copyright permission, AODA/WCAG conformance, educator approval of instruction, learner mastery, grades, credits, Ministry approval, deployment readiness, or activation authority.",
    ]
    return ("\n".join(lines).rstrip() + "\n").encode("utf-8")


def artifact_manifest(root: Path) -> list[dict[str, Any]]:
    files: list[dict[str, Any]] = []
    for path in sorted(item for item in root.rglob("*") if item.is_file()):
        relative = path.relative_to(root).as_posix()
        if relative == "manifest.json":
            continue
        data = path.read_bytes()
        files.append(
            {
                "path": relative,
                "byte_length": len(data),
                "sha256": sha256_bytes(data),
            }
        )
    return files


def build(output: Path) -> dict[str, Any]:
    plan = build_plan()
    review_summary = verify_source_reviews()
    readiness = build_readiness()
    verify_readiness(readiness)
    monitoring_summary = verify_policy()
    targets = validate_target_registry(TARGETS_PATH)
    monitoring = load_json(MONITORING_PATH)
    capture_targets = load_json(TARGETS_PATH)

    require(plan.get("target_count") == EXPECTED_SOURCES, "source-review plan must contain 16 targets")
    require(review_summary.get("targets") == EXPECTED_SOURCES, "source-review summary target count mismatch")
    require(readiness["summary"]["c1_snapshot_sources"] == EXPECTED_SOURCES, "readiness must contain 16 C1 snapshots")
    require(len(targets) == EXPECTED_SOURCES, "capture target registry must contain 16 targets")
    require(monitoring_summary["sources"] == EXPECTED_SOURCES, "monitoring policy must contain 16 sources")
    require(monitoring_summary["pending_capture_targets"] == [], "review dossier requires zero pending capture targets")

    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    write_json(output / "source-review-plan.json", plan)
    write_json(output / "current-readiness.json", readiness)
    write_json(output / "source-monitoring.json", monitoring)
    write_json(output / "capture-targets.json", capture_targets)
    write_json(
        output / "submitted-review-summary.json",
        {
            "schema": "axiom-education-ontario-elementary-source-review-summary.v1",
            **review_summary,
            "claim_boundary": "Counts describe only currently committed, verifier-accepted human source-review attestations for the exact current targets. Incomplete counts remain blocked evidence, not implied approval.",
        },
    )

    copied_locks = copy_json_files(LOCK_DIR, output / "source-locks")
    copied_reviews = copy_json_files(REVIEW_DIR, output / "submitted-evidence" / "source-reviews")
    require(len(copied_locks) == EXPECTED_SOURCES, "source-lock copy count mismatch")
    require(len(copied_reviews) == review_summary["reviews"], "submitted review copy count mismatch")

    template_dir = output / "review-templates"
    for target in plan["targets"]:
        write_json(
            template_dir / f"{target['source_id']}.review-template.json",
            review_template(target),
        )

    (output / "REVIEW-GUIDE.md").write_bytes(build_review_guide(plan, review_summary, readiness))

    files = artifact_manifest(output)
    manifest = {
        "schema": "axiom-education-ontario-elementary-source-reviewer-dossier.v1",
        "jurisdiction_id": plan["jurisdiction_id"],
        "status": "machine-generated-review-inputs-no-approval",
        "source_target_count": plan["target_count"],
        "c1_source_lock_count": len(copied_locks),
        "strict_exact_byte_source_count": readiness["summary"]["strict_exact_byte_monitored_sources"],
        "observational_response_surface_count": readiness["summary"]["observational_response_surface_sources"],
        "submitted_review_count": review_summary["reviews"],
        "approved_source_count": review_summary["approved_sources"],
        "canonical_c2_record_count": readiness["summary"]["canonical_c2_records"],
        "source_bytes_packaged": False,
        "review_template_count": len(plan["targets"]),
        "claim_boundary": (
            "This dossier deterministically packages source-review inputs and submitted human-review provenance only. "
            "It packages no captured Ontario curriculum source bytes and creates no source approval, licensing permission, curriculum correctness, C2 promotion, pack activation, or Ministry endorsement."
        ),
        "files": files,
    }
    write_json(output / "manifest.json", manifest)
    return manifest


def verify_determinism() -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="axiom-elementary-review-a-") as first_dir, tempfile.TemporaryDirectory(prefix="axiom-elementary-review-b-") as second_dir:
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
        require(first_manifest["source_target_count"] == EXPECTED_SOURCES, "reviewer dossier target count drifted")
        require(first_manifest["source_bytes_packaged"] is False, "reviewer dossier must not package source bytes")
        return first_manifest


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    build_parser = commands.add_parser("build", help="materialize the current source-reviewer dossier")
    build_parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    commands.add_parser("verify", help="build the dossier twice and prove byte determinism")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "build":
            manifest = build(args.output)
            print(
                "Ontario Elementary source reviewer dossier built: "
                f"targets={manifest['source_target_count']} approvals={manifest['approved_source_count']} "
                f"-> {args.output}"
            )
        else:
            manifest = verify_determinism()
            print(
                "Ontario Elementary source reviewer dossier verified: "
                f"targets={manifest['source_target_count']} approvals={manifest['approved_source_count']} "
                f"locks={manifest['c1_source_lock_count']} source_bytes_packaged={manifest['source_bytes_packaged']}"
            )
    except (OSError, KeyError, ElementaryReviewerDossierError, ValueError) as error:
        print(f"Ontario Elementary source reviewer dossier failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
