#!/usr/bin/env python3
"""Generate deterministic, deliberately non-valid MTH1W assessment-review templates."""

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
DEFAULT_OUTPUT = ROOT / "build" / "mth1w-assessment-review-templates"
EVIDENCE_SCHEMA = "axiom-education-assessment-review-evidence.v1"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_assessment_review_evidence import build_plan  # noqa: E402


class AssessmentTemplateError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssessmentTemplateError(message)


def digest_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def template_for(target: dict[str, Any]) -> dict[str, Any]:
    target_id = target.get("target_id")
    target_sha = target.get("target_sha256")
    require(isinstance(target_id, str) and target_id, "assessment target_id missing")
    require(isinstance(target_sha, str) and len(target_sha) == 64, f"{target_id}: target digest missing")
    return {
        "schema": "axiom-education-assessment-review-template.v1",
        "template_only": True,
        "evidence_schema_required": EVIDENCE_SCHEMA,
        "course_code": "MTH1W",
        "assessment_scope": target["assessment_scope"],
        "target": {
            "target_id": target_id,
            "unit_id": target["unit_id"],
            "target_sha256": target_sha,
        },
        "review_requirements": target["review_requirements"],
        "human_completion_required": {
            "review_id": "",
            "reviewer_name": "",
            "reviewer_qualification": "",
            "reviewer_organization": None,
            "reviewed_at": "",
            "decision": "",
            "confirmations": {
                "official_alignment_reviewed": False,
                "content_validity_reviewed": False,
                "scoring_rubric_reviewed": False,
                "constructed_response_reviewed": False,
                "correction_reassessment_appeal_reviewed": False,
                "accessibility_alternatives_reviewed": False,
                "no_automatic_mastery_grade_credit_confirmed": False,
            },
            "findings": [],
            "scope_limitations": [],
            "attestation_type": "human-assessment-review",
        },
        "instructions": [
            "This is a machine-generated template, not assessment review evidence.",
            "Review the exact target revision identified by target_sha256.",
            "Do not edit target_sha256 to transfer a judgement to changed content.",
            "Complete every applicable judgement from an actual qualified human review.",
            f"Convert the completed result to {EVIDENCE_SCHEMA} and verify it with tools/mth1w_assessment_review_evidence.py.",
            "Preserve changes-required and rejected reviews as provenance.",
        ],
    }


def build(output: Path) -> dict[str, Any]:
    plan = build_plan()
    targets = plan.get("targets")
    require(isinstance(targets, list) and len(targets) == 10, "assessment review plan must contain ten targets")
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    records: list[dict[str, Any]] = []
    for index, target in enumerate(targets, start=1):
        require(isinstance(target, dict), "assessment target must be an object")
        target_id = str(target["target_id"])
        filename = f"{index:02d}-{target_id}.template.json"
        payload = template_for(target)
        data = json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True).encode("utf-8") + b"\n"
        (output / filename).write_bytes(data)
        records.append(
            {
                "path": filename,
                "target_id": target_id,
                "assessment_scope": target["assessment_scope"],
                "target_sha256": target["target_sha256"],
                "byte_length": len(data),
                "sha256": digest_bytes(data),
            }
        )

    manifest = {
        "schema": "axiom-education-mth1w-assessment-review-template-package.v1",
        "status": "machine-generated-templates-no-human-assessment-evidence",
        "course_code": "MTH1W",
        "target_count": len(records),
        "claim_boundary": (
            "Templates bind reviewer work to exact current assessment targets but are not human evidence and cannot establish validity, scoring quality, mastery, grade, credit, transcript status, or Ministry approval."
        ),
        "templates": records,
    }
    (output / "manifest.json").write_text(
        json.dumps(manifest, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (output / "README.md").write_text(
        "# MTH1W assessment review templates\n\n"
        "These files are deliberately non-valid templates. Complete a real qualified human review, convert the result to `axiom-education-assessment-review-evidence.v1`, and verify it. Never change a prefilled digest to reuse an older judgement.\n",
        encoding="utf-8",
    )
    return manifest


def verify_determinism() -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="axiom-assessment-templates-a-") as a, tempfile.TemporaryDirectory(prefix="axiom-assessment-templates-b-") as b:
        first = Path(a)
        second = Path(b)
        first_manifest = build(first)
        second_manifest = build(second)
        require(first_manifest == second_manifest, "assessment template manifests differ")
        first_files = sorted(path.relative_to(first) for path in first.rglob("*") if path.is_file())
        second_files = sorted(path.relative_to(second) for path in second.rglob("*") if path.is_file())
        require(first_files == second_files, "assessment template file sets differ")
        for relative in first_files:
            require((first / relative).read_bytes() == (second / relative).read_bytes(), f"assessment template bytes differ: {relative}")
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
            print(f"MTH1W assessment review templates built: {manifest['target_count']} -> {args.output}")
        else:
            manifest = verify_determinism()
            print(
                "MTH1W assessment review templates verified: "
                f"{manifest['target_count']} exact targets; no human assessment evidence implied"
            )
    except (OSError, KeyError, AssessmentTemplateError, ValueError) as error:
        print(f"MTH1W assessment review template generation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
