#!/usr/bin/env python3
"""Generate deterministic, deliberately non-valid human-review templates for MTH1W.

Templates prefill exact machine evidence such as lesson/source-use digests but use a
separate template schema. They cannot be submitted as review evidence until a human
completes the required judgement fields and converts them to the real evidence schema.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "build" / "mth1w-review-templates"
LESSON_EVIDENCE_SCHEMA = "axiom-education-content-review-evidence.v1"
LICENCE_EVIDENCE_SCHEMA = "axiom-education-source-licence-review.v1"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_review_evidence import build_plan  # noqa: E402
from tools.mth1w_source_use_inventory import build_inventory  # noqa: E402


class ReviewTemplateError(RuntimeError):
    """Raised when current review targets cannot be represented safely."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReviewTemplateError(message)


def safe_name(value: str) -> str:
    normalized = re.sub(r"[^a-zA-Z0-9._-]+", "-", value).strip("-.")
    require(bool(normalized), "template filename component is empty")
    return normalized.lower()


def canonical_bytes(value: Any) -> bytes:
    return (
        json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        + "\n"
    ).encode("utf-8")


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def target_digest(target: dict[str, Any]) -> str:
    for key in (
        "target_sha256",
        "lesson_sha256",
        "content_sha256",
        "lesson_content_sha256",
    ):
        value = target.get(key)
        if isinstance(value, str) and len(value) == 64:
            return value
    raise ReviewTemplateError(
        f"review target {target.get('lesson_id')!r} has no recognized content digest"
    )


def review_types(target: dict[str, Any]) -> list[str]:
    for key in ("required_review_types", "review_types"):
        value = target.get(key)
        if isinstance(value, list) and value and all(
            isinstance(item, str) and item for item in value
        ):
            require(
                len(value) == len(set(value)),
                f"{target.get('lesson_id')}: duplicate review types",
            )
            return list(value)
    raise ReviewTemplateError(
        f"review target {target.get('lesson_id')!r} has no required review types"
    )


def lesson_template(target: dict[str, Any], review_type: str) -> dict[str, Any]:
    lesson_id = target.get("lesson_id")
    unit_id = target.get("unit_id")
    require(isinstance(lesson_id, str) and lesson_id, "lesson review target missing lesson_id")
    require(isinstance(unit_id, str) and unit_id, f"{lesson_id}: unit_id missing")
    digest = target_digest(target)
    return {
        "schema": "axiom-education-content-review-template.v1",
        "template_only": True,
        "evidence_schema_required": LESSON_EVIDENCE_SCHEMA,
        "course_code": "MTH1W",
        "review_type": review_type,
        "target": {
            "unit_id": unit_id,
            "lesson_id": lesson_id,
            "target_sha256": digest,
        },
        "prefilled_machine_evidence": {
            "source_target": target,
            "digest_binding_required": True,
            "stale_if_target_digest_changes": True,
        },
        "human_completion_required": {
            "review_id": "",
            "reviewer_name": "",
            "reviewer_qualification": "",
            "reviewer_organization": None,
            "reviewed_at": "",
            "decision": "",
            "confirmations": {},
            "findings": [],
            "scope_limitations": [],
            "attestation_type": "human-review",
        },
        "instructions": [
            "This file is a template, not review evidence.",
            "Do not change the target digest to reuse a review after lesson content changes.",
            "Complete the judgement fields from an actual human review.",
            f"Convert the completed review to schema {LESSON_EVIDENCE_SCHEMA} and verify it with tools/mth1w_review_evidence.py.",
            "Preserve changes-required and rejected findings as provenance rather than deleting them.",
        ],
    }


def licence_template(source: dict[str, Any]) -> dict[str, Any]:
    url = source.get("url")
    digest = source.get("source_use_sha256")
    require(isinstance(url, str) and url.startswith("https://"), "source-use URL missing")
    require(isinstance(digest, str) and len(digest) == 64, f"{url}: source-use digest missing")
    return {
        "schema": "axiom-education-source-licence-review-template.v1",
        "template_only": True,
        "evidence_schema_required": LICENCE_EVIDENCE_SCHEMA,
        "course_code": "MTH1W",
        "source": {
            "url": url,
            "title": source.get("title"),
            "publisher": source.get("publisher"),
            "source_use_sha256": digest,
            "uses": source.get("uses"),
        },
        "prefilled_machine_evidence": {
            "digest_binding_required": True,
            "stale_if_source_use_changes": True,
        },
        "human_completion_required": {
            "review_id": "",
            "reviewer_name": "",
            "reviewer_qualification": "",
            "reviewer_organization": None,
            "reviewed_at": "",
            "decision": "",
            "redistribution_allowed_as_used": False,
            "evidence_locators": [],
            "findings": [],
            "scope_limitations": [],
            "attestation_type": "human-licensing-review",
        },
        "instructions": [
            "This file is a template, not a copyright or licensing decision.",
            "Public availability does not establish redistribution permission.",
            "Do not change source_use_sha256 to reuse an earlier review after source use changes.",
            f"Convert the completed review to schema {LICENCE_EVIDENCE_SCHEMA} and verify it with tools/mth1w_source_use_inventory.py.",
        ],
    }


def write_template(path: Path, payload: dict[str, Any]) -> dict[str, Any]:
    data = json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True).encode("utf-8") + b"\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return {
        "path": path.name,
        "byte_length": len(data),
        "sha256": sha256_bytes(data),
    }


def build(output: Path) -> dict[str, Any]:
    plan = build_plan()
    inventory = build_inventory()
    targets = plan.get("targets")
    sources = inventory.get("sources")
    require(isinstance(targets, list) and targets, "lesson review plan has no targets")
    require(isinstance(sources, list) and sources, "source-use inventory has no sources")

    if output.exists():
        shutil.rmtree(output)
    lesson_dir = output / "lesson-reviews"
    licence_dir = output / "source-licensing"
    lesson_dir.mkdir(parents=True)
    licence_dir.mkdir(parents=True)

    lesson_records: list[dict[str, Any]] = []
    seen_lesson_files: set[str] = set()
    for target in targets:
        require(isinstance(target, dict), "lesson review target must be an object")
        lesson_id = target.get("lesson_id")
        require(isinstance(lesson_id, str) and lesson_id, "lesson target missing lesson_id")
        for review_type in review_types(target):
            filename = f"{safe_name(lesson_id)}.{safe_name(review_type)}.template.json"
            require(filename not in seen_lesson_files, f"duplicate lesson review template: {filename}")
            seen_lesson_files.add(filename)
            record = write_template(
                lesson_dir / filename,
                lesson_template(target, review_type),
            )
            record.update(
                {
                    "lesson_id": lesson_id,
                    "review_type": review_type,
                    "target_sha256": target_digest(target),
                }
            )
            lesson_records.append(record)

    licence_records: list[dict[str, Any]] = []
    seen_source_files: set[str] = set()
    for index, source in enumerate(sources, start=1):
        require(isinstance(source, dict), "source-use inventory source must be an object")
        filename = f"source-{index:02d}.{safe_name(str(source.get('publisher') or 'source'))}.template.json"
        require(filename not in seen_source_files, f"duplicate source review template: {filename}")
        seen_source_files.add(filename)
        record = write_template(licence_dir / filename, licence_template(source))
        record.update(
            {
                "source_url": source["url"],
                "source_use_sha256": source["source_use_sha256"],
            }
        )
        licence_records.append(record)

    manifest = {
        "schema": "axiom-education-mth1w-review-template-package.v1",
        "status": "machine-generated-templates-no-human-evidence",
        "course_code": "MTH1W",
        "lesson_target_count": len(targets),
        "lesson_review_template_count": len(lesson_records),
        "source_use_count": len(sources),
        "source_licensing_template_count": len(licence_records),
        "claim_boundary": (
            "Templates contain digest-bound machine context only. They are deliberately not valid human review evidence and cannot satisfy any review, licensing, accessibility, assessment, mastery, grade, credit, or Ministry gate."
        ),
        "lesson_templates": lesson_records,
        "source_licensing_templates": licence_records,
    }
    (output / "manifest.json").write_bytes(canonical_bytes(manifest))
    (output / "README.md").write_text(
        "# MTH1W review templates\n\n"
        "These files are deliberately non-valid templates. Fill them from a real human review, convert the result to the required evidence schema, and run the repository verifier. Never edit a prefilled digest to carry a judgement to changed content.\n",
        encoding="utf-8",
    )
    return manifest


def verify_determinism() -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="axiom-review-templates-a-") as a, tempfile.TemporaryDirectory(prefix="axiom-review-templates-b-") as b:
        first = Path(a)
        second = Path(b)
        first_manifest = build(first)
        second_manifest = build(second)
        require(first_manifest == second_manifest, "review template manifests differ between builds")
        first_files = sorted(path.relative_to(first) for path in first.rglob("*") if path.is_file())
        second_files = sorted(path.relative_to(second) for path in second.rglob("*") if path.is_file())
        require(first_files == second_files, "review template file sets differ between builds")
        for relative in first_files:
            require((first / relative).read_bytes() == (second / relative).read_bytes(), f"review template bytes differ: {relative}")
        require(first_manifest["lesson_target_count"] == 43, "review template package must cover 43 lesson targets")
        require(first_manifest["status"] == "machine-generated-templates-no-human-evidence", "template package status drifted")
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
                "MTH1W review templates built: "
                f"{manifest['lesson_review_template_count']} lesson templates, "
                f"{manifest['source_licensing_template_count']} licensing templates -> {args.output}"
            )
        else:
            manifest = verify_determinism()
            print(
                "MTH1W review templates verified: "
                f"{manifest['lesson_review_template_count']} lesson templates; "
                f"{manifest['source_licensing_template_count']} licensing templates; "
                "no human evidence implied"
            )
    except (OSError, KeyError, ReviewTemplateError, ValueError) as error:
        print(f"MTH1W review template generation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
