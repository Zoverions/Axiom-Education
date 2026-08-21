#!/usr/bin/env python3
"""Generate deterministic, deliberately non-valid MTH1W accessibility-review templates."""

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
DEFAULT_OUTPUT = ROOT / "build" / "mth1w-accessibility-review-templates"
EVIDENCE_SCHEMA = "axiom-education-accessibility-review-evidence.v1"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_accessibility_review_evidence import (  # noqa: E402
    APPLICATION_CONFIRMATION_KEYS,
    EXPECTED_TARGETS,
    LESSON_CONFIRMATION_KEYS,
    build_plan,
)


class AccessibilityTemplateError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AccessibilityTemplateError(message)


def digest_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _confirmation_template(scope: str) -> dict[str, bool]:
    if scope == "lesson-alternative":
        keys = LESSON_CONFIRMATION_KEYS
    elif scope == "learner-application-surface":
        keys = APPLICATION_CONFIRMATION_KEYS
    else:
        raise AccessibilityTemplateError(f"unsupported accessibility template scope: {scope}")
    return {key: False for key in sorted(keys)}


def template_for(target: dict[str, Any]) -> dict[str, Any]:
    target_id = target.get("target_id")
    target_sha = target.get("target_sha256")
    scope = target.get("review_scope")
    require(isinstance(target_id, str) and target_id, "accessibility target_id missing")
    require(
        isinstance(target_sha, str) and len(target_sha) == 64,
        f"{target_id}: target digest missing",
    )
    require(
        scope in {"lesson-alternative", "learner-application-surface"},
        f"{target_id}: invalid review scope",
    )
    return {
        "schema": "axiom-education-accessibility-review-template.v1",
        "template_only": True,
        "evidence_schema_required": EVIDENCE_SCHEMA,
        "course_code": "MTH1W",
        "review_scope": scope,
        "target": {
            "target_id": target_id,
            "lesson_id": target["lesson_id"],
            "unit_id": target["unit_id"],
            "platform": target["platform"],
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
            "tested_environments": [],
            "confirmations": _confirmation_template(str(scope)),
            "findings": [],
            "scope_limitations": [],
            "attestation_type": "human-accessibility-usability-review",
        },
        "instructions": [
            "This is a machine-generated template, not accessibility review evidence.",
            "Review the exact target revision and platform, when present, identified above.",
            "Do not edit target_sha256 or platform to transfer a judgement to changed content or another platform.",
            "Record the actual assistive technologies, devices, operating systems, themes/scaling settings, or document tools used.",
            "Complete every in-scope judgement from an actual qualified human review.",
            f"Convert the completed result to {EVIDENCE_SCHEMA} and verify it with tools/mth1w_accessibility_review_evidence.py.",
            "Preserve changes-required and rejected reviews as provenance.",
        ],
    }


def build(output: Path) -> dict[str, Any]:
    plan = build_plan()
    targets = plan.get("targets")
    require(
        isinstance(targets, list) and len(targets) == EXPECTED_TARGETS,
        f"accessibility review plan must contain {EXPECTED_TARGETS} targets",
    )
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    records: list[dict[str, Any]] = []
    for index, target in enumerate(targets, start=1):
        require(isinstance(target, dict), "accessibility target must be an object")
        target_id = str(target["target_id"])
        filename = f"{index:02d}-{target_id}.template.json"
        payload = template_for(target)
        data = json.dumps(
            payload, indent=2, ensure_ascii=False, sort_keys=True
        ).encode("utf-8") + b"\n"
        (output / filename).write_bytes(data)
        records.append(
            {
                "path": filename,
                "target_id": target_id,
                "review_scope": target["review_scope"],
                "platform": target["platform"],
                "target_sha256": target["target_sha256"],
                "byte_length": len(data),
                "sha256": digest_bytes(data),
            }
        )

    manifest = {
        "schema": "axiom-education-mth1w-accessibility-review-template-package.v1",
        "status": "machine-generated-templates-no-human-accessibility-evidence",
        "course_code": "MTH1W",
        "target_count": len(records),
        "lesson_alternative_targets": plan["lesson_alternative_targets"],
        "application_surface_targets": plan["application_surface_targets"],
        "application_platforms": plan["application_platforms"],
        "claim_boundary": (
            "Templates bind reviewer work to exact current accessibility targets but are not human evidence and cannot establish WCAG, AODA, assistive-technology usability, platform production support, course completion, credit, or Ministry approval."
        ),
        "templates": records,
    }
    (output / "manifest.json").write_text(
        json.dumps(
            manifest, sort_keys=True, separators=(",", ":"), ensure_ascii=False
        )
        + "\n",
        encoding="utf-8",
    )
    (output / "README.md").write_text(
        "# MTH1W accessibility review templates\n\n"
        "These files are deliberately non-valid templates. Complete a real qualified human review, convert the result to `axiom-education-accessibility-review-evidence.v1`, and verify it. Never change a prefilled digest or platform to reuse an older judgement.\n",
        encoding="utf-8",
    )
    return manifest


def verify_determinism() -> dict[str, Any]:
    with tempfile.TemporaryDirectory(
        prefix="axiom-accessibility-templates-a-"
    ) as a, tempfile.TemporaryDirectory(
        prefix="axiom-accessibility-templates-b-"
    ) as b:
        first = Path(a)
        second = Path(b)
        first_manifest = build(first)
        second_manifest = build(second)
        require(first_manifest == second_manifest, "accessibility template manifests differ")
        first_files = sorted(
            path.relative_to(first) for path in first.rglob("*") if path.is_file()
        )
        second_files = sorted(
            path.relative_to(second) for path in second.rglob("*") if path.is_file()
        )
        require(first_files == second_files, "accessibility template file sets differ")
        for relative in first_files:
            require(
                (first / relative).read_bytes() == (second / relative).read_bytes(),
                f"accessibility template bytes differ: {relative}",
            )
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
                f"MTH1W accessibility review templates built: {manifest['target_count']} -> {args.output}"
            )
        else:
            manifest = verify_determinism()
            print(
                "MTH1W accessibility review templates verified: "
                f"{manifest['target_count']} exact targets; no human accessibility evidence implied"
            )
    except (OSError, KeyError, AccessibilityTemplateError, ValueError) as error:
        print(
            f"MTH1W accessibility review template generation failed: {error}",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
