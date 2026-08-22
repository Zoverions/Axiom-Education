#!/usr/bin/env python3
"""Generate deterministic, deliberately non-valid Ontario Elementary C2 normalization-review templates."""

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
DEFAULT_OUTPUT = ROOT / "build" / "ontario-elementary-c2-normalization-templates"
EVIDENCE_SCHEMA = "axiom-education-curriculum-normalization-review-evidence.v1"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.ontario_elementary_c2_promotion import (  # noqa: E402
    CONFIRMATION_KEYS,
    build_plan,
)


class NormalizationTemplateError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise NormalizationTemplateError(message)


def digest_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def template_for(target: dict[str, Any]) -> dict[str, Any]:
    record_id = target.get("record_id")
    review_target_sha256 = target.get("review_target_sha256")
    require(isinstance(record_id, str) and record_id, "normalization template record_id missing")
    require(
        isinstance(review_target_sha256, str) and len(review_target_sha256) == 64,
        f"{record_id}: normalization review target digest missing",
    )
    return {
        "schema": "axiom-education-curriculum-normalization-review-template.v1",
        "template_only": True,
        "evidence_schema_required": EVIDENCE_SCHEMA,
        "jurisdiction_id": "ca-on",
        "source_id": target["source_id"],
        "candidate": {
            "record_id": record_id,
            "content_digest": target["content_digest"],
            "review_target_sha256": review_target_sha256,
        },
        "review_basis": {
            "source_bytes_sha256": target["source_bytes_sha256"],
            "source_byte_length": target["source_byte_length"],
            "source_lock_sha256": target["source_lock_sha256"],
        },
        "candidate_path": target["candidate_path"],
        "current_upstream_evidence": {
            "source_review_decision": target["current_source_review_decision"],
            "licensing_decision": target["current_licensing_decision"],
            "eligible_for_human_normalization_review": target[
                "eligible_for_human_normalization_review"
            ],
            "blocker": target["blocker"],
        },
        "human_completion_required": {
            "review_id": "",
            "reviewer_name": "",
            "reviewer_qualification": "",
            "reviewer_organization": None,
            "reviewed_at": "",
            "decision": "",
            "confirmations": {key: False for key in sorted(CONFIRMATION_KEYS)},
            "findings": [],
            "scope_limitations": [],
            "attestation_type": "human-curriculum-normalization-review",
        },
        "instructions": [
            "This is a machine-generated template, not normalization review evidence.",
            "Review the exact candidate revision and exact C1 source evidence identified above.",
            "Do not edit candidate, source-lock, or source-byte digests to transfer an older judgement to changed evidence.",
            "Complete every confirmation from an actual qualified human comparison of the candidate against the exact C1 source bytes.",
            f"Convert the completed result to {EVIDENCE_SCHEMA} and verify it with tools/ontario_elementary_c2_promotion.py verify-review.",
            "Preserve changes-required and rejected reviews as provenance.",
        ],
    }


def build(output: Path) -> dict[str, Any]:
    plan = build_plan()
    targets = plan.get("targets")
    require(isinstance(targets, list), "normalization review plan targets missing")
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    records: list[dict[str, Any]] = []
    for index, target in enumerate(targets, start=1):
        require(isinstance(target, dict), "normalization review target must be an object")
        record_id = str(target["record_id"])
        filename = f"{index:04d}-{record_id}.template.json"
        payload = template_for(target)
        data = json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True).encode("utf-8") + b"\n"
        (output / filename).write_bytes(data)
        records.append(
            {
                "path": filename,
                "record_id": record_id,
                "source_id": target["source_id"],
                "review_target_sha256": target["review_target_sha256"],
                "byte_length": len(data),
                "sha256": digest_bytes(data),
            }
        )

    manifest = {
        "schema": "axiom-education-ontario-elementary-c2-normalization-template-package.v1",
        "status": "machine-generated-templates-no-human-normalization-evidence",
        "jurisdiction_id": "ca-on",
        "target_count": len(records),
        "claim_boundary": (
            "Templates bind future qualified-human normalization review to exact current candidate and C1 evidence. "
            "They contain no human identity, decision, or approval and cannot establish canonical promotion, curriculum correctness, completeness, pack readiness, activation, grade/credit authority, or Ministry approval."
        ),
        "templates": records,
    }
    (output / "manifest.json").write_text(
        json.dumps(manifest, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (output / "README.md").write_text(
        "# Ontario Elementary C2 normalization review templates\n\n"
        "These files are deliberately non-valid templates generated from the exact current candidate plan. Complete a real qualified-human review, convert it to `axiom-education-curriculum-normalization-review-evidence.v1`, and verify it. Never change a prefilled digest to reuse an older judgement.\n",
        encoding="utf-8",
    )
    return manifest


def verify_determinism() -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="axiom-c2-normalization-templates-a-") as a, tempfile.TemporaryDirectory(prefix="axiom-c2-normalization-templates-b-") as b:
        first = Path(a)
        second = Path(b)
        first_manifest = build(first)
        second_manifest = build(second)
        require(first_manifest == second_manifest, "normalization template manifests differ")
        first_files = sorted(path.relative_to(first) for path in first.rglob("*") if path.is_file())
        second_files = sorted(path.relative_to(second) for path in second.rglob("*") if path.is_file())
        require(first_files == second_files, "normalization template file sets differ")
        for relative in first_files:
            require(
                (first / relative).read_bytes() == (second / relative).read_bytes(),
                f"normalization template bytes differ: {relative}",
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
                f"Ontario Elementary C2 normalization templates built: {manifest['target_count']} -> {args.output}"
            )
        else:
            manifest = verify_determinism()
            print(
                "Ontario Elementary C2 normalization templates verified: "
                f"{manifest['target_count']} exact targets; no human normalization evidence implied"
            )
    except (OSError, KeyError, NormalizationTemplateError, ValueError) as error:
        print(f"Ontario Elementary C2 normalization template generation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
