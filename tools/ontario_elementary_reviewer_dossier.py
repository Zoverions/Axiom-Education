#!/usr/bin/env python3
"""Build a deterministic Ontario Elementary source and licensing reviewer dossier.

The dossier packages current C1 metadata, content-addressed human source-review and
licensing-review targets, monitoring/readiness context, blank attestation templates, and
already-submitted review provenance. It never packages captured Ontario curriculum source
bytes and creates no approval, licensing permission, curriculum correctness, or authority.
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
SOURCE_REVIEW_DIR = ROOT / "curriculum" / "reviews" / "ontario-elementary" / "sources"
LICENSING_REVIEW_DIR = ROOT / "curriculum" / "licensing" / "ontario-elementary" / "reviews"
MONITORING_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-monitoring.v1.json"
TARGETS_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-capture-targets.v1.json"
EXPECTED_SOURCES = 16

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.check_curriculum_source_monitoring import verify_policy  # noqa: E402
from tools.ontario_elementary_licensing_review import (  # noqa: E402
    REQUIRED_CONFIRMATIONS as LICENSING_CONFIRMATIONS,
    build_plan as build_licensing_plan,
    verify_directory as verify_licensing_reviews,
)
from tools.ontario_elementary_readiness import build_readiness, verify_readiness  # noqa: E402
from tools.ontario_elementary_source_review import (  # noqa: E402
    REQUIRED_CONFIRMATIONS as SOURCE_CONFIRMATIONS,
    build_plan as build_source_plan,
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


def source_review_template(target: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema": "axiom-education-ontario-elementary-source-review.v1",
        "review_id": "",
        "review_type": "source-identity-and-scope",
        "source_id": target["source_id"],
        "target_sha256": target["target_sha256"],
        "reviewer": {"name": "", "qualification": ""},
        "reviewed_at": "",
        "decision": "",
        "confirmations": {key: False for key in sorted(SOURCE_CONFIRMATIONS)},
        "findings": [],
        "scope_limitations": [
            "Source identity and scope only; no licensing or curriculum-content approval."
        ],
        "attestation_type": "human-review",
    }


def licensing_review_template(target: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema": "axiom-education-ontario-elementary-licensing-review.v1",
        "review_id": "",
        "review_type": "licensing-and-redistribution",
        "source_id": target["source_id"],
        "target_sha256": target["target_sha256"],
        "reviewer": {"name": "", "qualification": ""},
        "reviewed_at": "",
        "decision": "",
        "confirmations": {key: False for key in sorted(LICENSING_CONFIRMATIONS)},
        "basis": {"summary": "", "evidence_locators": []},
        "conditions": [],
        "findings": [],
        "attestation_type": "human-review",
    }


def build_review_guide(
    source_plan: dict[str, Any],
    source_summary: dict[str, Any],
    licensing_plan: dict[str, Any],
    licensing_summary: dict[str, Any],
    readiness: dict[str, Any],
) -> bytes:
    summary = readiness["summary"]
    lines = [
        "# Ontario Elementary source and licensing reviewer dossier",
        "",
        "This directory is a deterministic package for qualified human review of the current Ontario Elementary source identities/scopes and their licensing/redistribution status. It contains **review inputs, not approval**.",
        "",
        "## Current evidence boundary",
        "",
        f"- Content-addressed source-review targets: **{source_plan['target_count']}**",
        f"- Approved current source reviews: **{source_summary['approved_sources']} / {source_plan['target_count']}**",
        f"- Content-addressed licensing-review targets: **{licensing_plan['target_count']}**",
        f"- Resolved current licensing reviews: **{licensing_summary['resolved_sources']} / {licensing_plan['target_count']}**",
        f"- Verbatim redistribution permissions recorded: **{licensing_summary['verbatim_redistribution_permitted']}**",
        f"- C1 source snapshots: **{summary['c1_snapshot_sources']} / {summary['confirmed_discovery_sources']}**",
        f"- Monitoring split: **{summary['strict_exact_byte_monitored_sources']} strict PDF / {summary['observational_response_surface_sources']} observational HTML**",
        f"- Canonical C2 records: **{summary['canonical_c2_records']}**",
        "- Captured Ontario curriculum source bytes are not included in this dossier.",
        "- Every current C1 lock remains `review-required`; separate licensing attestations record later human decisions without rewriting historical capture evidence.",
        "",
        "## Stage 1 — source identity and scope",
        "",
        "For the exact source-review target digest, a reviewer may attest whether the source is an official Ontario Ministry source, the source identity is correct, the policy version is correctly represented, the grade scope is correct, and the recorded official locator is appropriate.",
        "",
        "Use `source-review-plan.json` and the matching file under `source-review-templates/`. Completed attestations belong under `curriculum/reviews/ontario-elementary/sources/` and verify with:",
        "",
        "```bash",
        "python tools/ontario_elementary_source_review.py verify path/to/review.json",
        "```",
        "",
        "## Stage 2 — licensing and redistribution",
        "",
        "Licensing review is independent. Public availability is not redistribution permission. The reviewer must choose a supported outcome for the exact licensing target and record the rights/terms basis, conditions, and findings.",
        "",
        "Use `licensing-review-plan.json` and the matching file under `licensing-review-templates/`. Completed attestations belong under `curriculum/licensing/ontario-elementary/reviews/` and verify with:",
        "",
        "```bash",
        "python tools/ontario_elementary_licensing_review.py verify path/to/review.json",
        "```",
        "",
        "## Review handling rules",
        "",
        "1. Read `current-readiness.json` and `source-monitoring.json` before reviewing.",
        "2. Inspect the exact target and corresponding C1 metadata lock. Source bytes are intentionally not packaged here; follow the official locator when source inspection is needed.",
        "3. Fill a template only after human review. Blank templates intentionally fail their verifier and contain no preselected decision.",
        "4. Preserve negative or unresolved evidence rather than deleting it.",
        "5. Version 1 permits only one current attestation per source in each review layer; duplicate current records fail closed.",
        "6. A source review does not grant licensing permission. A licensing review does not prove curriculum normalization correct.",
        "7. C2 normalization, accessibility, pack verification, staging, and activation remain separate later gates.",
        "",
        "## Non-claims",
        "",
        "This dossier does not establish curriculum correctness, copyright-law correctness, AODA/WCAG conformance, educator approval of instruction, learner mastery, grades, credits, Ministry approval, deployment readiness, or activation authority.",
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
    source_plan = build_source_plan()
    source_summary = verify_source_reviews()
    licensing_plan = build_licensing_plan()
    licensing_summary = verify_licensing_reviews()
    readiness = build_readiness()
    verify_readiness(readiness)
    monitoring_summary = verify_policy()
    targets = validate_target_registry(TARGETS_PATH)
    monitoring = load_json(MONITORING_PATH)
    capture_targets = load_json(TARGETS_PATH)

    require(source_plan.get("target_count") == EXPECTED_SOURCES, "source-review plan must contain 16 targets")
    require(source_summary.get("targets") == EXPECTED_SOURCES, "source-review summary target count mismatch")
    require(licensing_plan.get("target_count") == EXPECTED_SOURCES, "licensing-review plan must contain 16 targets")
    require(licensing_summary.get("targets") == EXPECTED_SOURCES, "licensing-review summary target count mismatch")
    require(readiness["summary"]["c1_snapshot_sources"] == EXPECTED_SOURCES, "readiness must contain 16 C1 snapshots")
    require(len(targets) == EXPECTED_SOURCES, "capture target registry must contain 16 targets")
    require(monitoring_summary["sources"] == EXPECTED_SOURCES, "monitoring policy must contain 16 sources")
    require(monitoring_summary["pending_capture_targets"] == [], "review dossier requires zero pending capture targets")

    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    write_json(output / "source-review-plan.json", source_plan)
    write_json(output / "licensing-review-plan.json", licensing_plan)
    write_json(output / "current-readiness.json", readiness)
    write_json(output / "source-monitoring.json", monitoring)
    write_json(output / "capture-targets.json", capture_targets)
    write_json(
        output / "submitted-source-review-summary.json",
        {
            "schema": "axiom-education-ontario-elementary-source-review-summary.v1",
            **source_summary,
            "claim_boundary": "Counts describe only currently committed, verifier-accepted human source-review attestations for the exact current targets. Incomplete counts remain blocked evidence, not implied approval.",
        },
    )
    write_json(
        output / "submitted-licensing-review-summary.json",
        {
            "schema": "axiom-education-ontario-elementary-licensing-review-summary.v1",
            **licensing_summary,
            "claim_boundary": "Counts describe only currently committed, verifier-accepted human licensing attestations. A recorded decision does not itself prove the legal conclusion correct, and public availability is not permission.",
        },
    )

    copied_locks = copy_json_files(LOCK_DIR, output / "source-locks")
    copied_source_reviews = copy_json_files(
        SOURCE_REVIEW_DIR,
        output / "submitted-evidence" / "source-reviews",
    )
    copied_licensing_reviews = copy_json_files(
        LICENSING_REVIEW_DIR,
        output / "submitted-evidence" / "licensing-reviews",
    )
    require(len(copied_locks) == EXPECTED_SOURCES, "source-lock copy count mismatch")
    require(len(copied_source_reviews) == source_summary["reviews"], "submitted source-review copy count mismatch")
    require(len(copied_licensing_reviews) == licensing_summary["reviews"], "submitted licensing-review copy count mismatch")

    for target in source_plan["targets"]:
        write_json(
            output / "source-review-templates" / f"{target['source_id']}.review-template.json",
            source_review_template(target),
        )
    for target in licensing_plan["targets"]:
        write_json(
            output / "licensing-review-templates" / f"{target['source_id']}.licensing-template.json",
            licensing_review_template(target),
        )

    (output / "REVIEW-GUIDE.md").write_bytes(
        build_review_guide(
            source_plan,
            source_summary,
            licensing_plan,
            licensing_summary,
            readiness,
        )
    )

    files = artifact_manifest(output)
    manifest = {
        "schema": "axiom-education-ontario-elementary-reviewer-dossier.v2",
        "jurisdiction_id": source_plan["jurisdiction_id"],
        "status": "machine-generated-review-inputs-no-approval",
        "source_target_count": source_plan["target_count"],
        "licensing_target_count": licensing_plan["target_count"],
        "c1_source_lock_count": len(copied_locks),
        "strict_exact_byte_source_count": readiness["summary"]["strict_exact_byte_monitored_sources"],
        "observational_response_surface_count": readiness["summary"]["observational_response_surface_sources"],
        "submitted_source_review_count": source_summary["reviews"],
        "approved_source_count": source_summary["approved_sources"],
        "submitted_licensing_review_count": licensing_summary["reviews"],
        "resolved_licensing_source_count": licensing_summary["resolved_sources"],
        "verbatim_redistribution_permitted_source_count": licensing_summary["verbatim_redistribution_permitted"],
        "canonical_c2_record_count": readiness["summary"]["canonical_c2_records"],
        "source_bytes_packaged": False,
        "source_review_template_count": len(source_plan["targets"]),
        "licensing_review_template_count": len(licensing_plan["targets"]),
        "claim_boundary": (
            "This dossier deterministically packages source/licensing review inputs and submitted human-review provenance only. "
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
        require(first_manifest["source_target_count"] == EXPECTED_SOURCES, "reviewer dossier source target count drifted")
        require(first_manifest["licensing_target_count"] == EXPECTED_SOURCES, "reviewer dossier licensing target count drifted")
        require(first_manifest["source_bytes_packaged"] is False, "reviewer dossier must not package source bytes")
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
                "Ontario Elementary reviewer dossier built: "
                f"source_targets={manifest['source_target_count']} source_approvals={manifest['approved_source_count']} "
                f"licensing_targets={manifest['licensing_target_count']} licensing_resolved={manifest['resolved_licensing_source_count']} "
                f"-> {args.output}"
            )
        else:
            manifest = verify_determinism()
            print(
                "Ontario Elementary reviewer dossier verified: "
                f"source_targets={manifest['source_target_count']} source_approvals={manifest['approved_source_count']} "
                f"licensing_targets={manifest['licensing_target_count']} licensing_resolved={manifest['resolved_licensing_source_count']} "
                f"locks={manifest['c1_source_lock_count']} source_bytes_packaged={manifest['source_bytes_packaged']}"
            )
    except (OSError, KeyError, ElementaryReviewerDossierError, ValueError) as error:
        print(f"Ontario Elementary reviewer dossier failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())