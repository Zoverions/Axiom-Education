#!/usr/bin/env python3
"""Gate Ontario Elementary C2 candidate intake against current human evidence.

This tool does not extract curriculum, create canonical records, or promote C2. It answers
whether an exact current source is eligible for a narrow reference-only normalization
candidate and verifies that operator-supplied source bytes match the historical C1 digest.
Candidate verification remains blocked until source identity review and compatible licensing
evidence exist. Paraphrase and verbatim modes are intentionally out of scope for this v1
intake even if a future licensing review would permit them.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SOURCE_REVIEW_DIR = ROOT / "curriculum" / "reviews" / "ontario-elementary" / "sources"
LICENSING_REVIEW_DIR = ROOT / "curriculum" / "licensing" / "ontario-elementary" / "reviews"
LOCK_DIR = ROOT / "curriculum" / "ontario-elementary" / "source-locks"
CANONICAL_RECORD_DIR = ROOT / "curriculum" / "ontario-elementary" / "records-v2"
ALLOWED_REFERENCE_LICENSING = {
    "reference-only-use-permitted",
    "verbatim-redistribution-permitted",
}
EXPECTED_SOURCES = 16

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_lock import canonical_json_digest, verify_lock  # noqa: E402
from tools.curriculum_standard_record import verify_record  # noqa: E402
from tools.ontario_elementary_licensing_review import (  # noqa: E402
    build_plan as build_licensing_plan,
    plan_index as licensing_plan_index,
    verify_directory as verify_licensing_directory,
    verify_review as verify_licensing_review,
)
from tools.ontario_elementary_source_review import (  # noqa: E402
    build_plan as build_source_plan,
    plan_index as source_plan_index,
    verify_directory as verify_source_directory,
    verify_review as verify_source_review,
)


class ElementaryC2IntakeError(RuntimeError):
    """Raised when C2 intake would outrun current source or licensing evidence."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ElementaryC2IntakeError(message)


def sha256_file(path: Path) -> tuple[str, int]:
    digest = hashlib.sha256()
    length = 0
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
            length += len(chunk)
    return digest.hexdigest(), length


def current_source_decisions() -> dict[str, str]:
    plan = build_source_plan()
    verify_source_directory(SOURCE_REVIEW_DIR)
    decisions: dict[str, str] = {}
    if SOURCE_REVIEW_DIR.exists():
        for path in sorted(SOURCE_REVIEW_DIR.glob("*.json")):
            review = verify_source_review(path, plan)
            source_id = str(review["source_id"])
            require(source_id not in decisions, f"multiple current source-review attestations: {source_id}")
            decisions[source_id] = str(review["decision"])
    return decisions


def current_licensing_decisions() -> dict[str, str]:
    plan = build_licensing_plan()
    verify_licensing_directory(LICENSING_REVIEW_DIR)
    decisions: dict[str, str] = {}
    if LICENSING_REVIEW_DIR.exists():
        for path in sorted(LICENSING_REVIEW_DIR.glob("*.json")):
            review = verify_licensing_review(path, plan)
            source_id = str(review["source_id"])
            require(source_id not in decisions, f"multiple current licensing-review attestations: {source_id}")
            decisions[source_id] = str(review["decision"])
    return decisions


def lock_index() -> dict[str, tuple[Path, dict[str, Any]]]:
    index: dict[str, tuple[Path, dict[str, Any]]] = {}
    for path in sorted(LOCK_DIR.glob("*.json")):
        lock = verify_lock(path)
        source_id = lock.get("source_id")
        require(isinstance(source_id, str) and source_id, f"C1 lock missing source_id: {path}")
        require(source_id not in index, f"duplicate C1 lock: {source_id}")
        index[source_id] = (path, lock)
    return index


def build_plan() -> dict[str, Any]:
    source_plan = build_source_plan()
    licensing_plan = build_licensing_plan()
    sources = source_plan_index(source_plan)
    licensing_targets = licensing_plan_index(licensing_plan)
    locks = lock_index()
    source_decisions = current_source_decisions()
    licensing_decisions = current_licensing_decisions()

    require(set(sources) == set(licensing_targets) == set(locks), "C2 intake source/licensing/C1 target sets differ")
    require(len(sources) == EXPECTED_SOURCES, f"expected {EXPECTED_SOURCES} current sources")

    targets: list[dict[str, Any]] = []
    eligible = 0
    for source_id in sorted(sources):
        source_target = sources[source_id]
        licensing_target = licensing_targets[source_id]
        lock_path, lock = locks[source_id]
        source_decision = source_decisions.get(source_id)
        licensing_decision = licensing_decisions.get(source_id)
        source_approved = source_decision == "approved"
        reference_licensed = licensing_decision in ALLOWED_REFERENCE_LICENSING
        is_eligible = source_approved and reference_licensed
        if is_eligible:
            eligible += 1
            blocker = None
        elif not source_approved:
            blocker = "current human source identity/scope approval required"
        else:
            blocker = "current licensing decision must permit reference-only use"
        targets.append(
            {
                "source_id": source_id,
                "source_review_target_sha256": source_target["target_sha256"],
                "source_review_decision": source_decision,
                "licensing_target_sha256": licensing_target["target_sha256"],
                "licensing_decision": licensing_decision,
                "source_lock_path": lock_path.resolve().relative_to(ROOT.resolve()).as_posix(),
                "source_lock_sha256": canonical_json_digest(lock),
                "upstream_document_sha256": lock["sha256"],
                "upstream_byte_length": lock["byte_length"],
                "official_locator": lock["resolved_locator"],
                "candidate_content_modes": ["reference-only"] if is_eligible else [],
                "eligible_for_reference_only_candidate_intake": is_eligible,
                "blocker": blocker,
            }
        )

    return {
        "schema": "axiom-education-ontario-elementary-c2-intake-plan.v1",
        "jurisdiction_id": source_plan["jurisdiction_id"],
        "target_count": len(targets),
        "eligible_source_count": eligible,
        "canonical_c2_record_count": len(list(CANONICAL_RECORD_DIR.glob("*.json"))) if CANONICAL_RECORD_DIR.exists() else 0,
        "claim_boundary": (
            "This plan gates reference-only C2 candidate intake. Eligibility requires an approved current human source identity/scope review and a current licensing decision permitting reference-only use. "
            "An operator must separately supply exact source bytes matching the C1 SHA-256. Eligibility does not create a candidate, prove extraction correctness, satisfy human normalization review, promote a canonical C2 record, or authorize pack activation. "
            "Paraphrase and verbatim candidate modes are deliberately unsupported by this v1 gate."
        ),
        "targets": targets,
    }


def plan_index(plan: dict[str, Any]) -> dict[str, dict[str, Any]]:
    rows = plan.get("targets")
    require(isinstance(rows, list), "C2 intake targets missing")
    index: dict[str, dict[str, Any]] = {}
    for row in rows:
        require(isinstance(row, dict), "C2 intake target must be an object")
        source_id = row.get("source_id")
        require(isinstance(source_id, str) and source_id, "C2 intake target source_id missing")
        require(source_id not in index, f"duplicate C2 intake target: {source_id}")
        index[source_id] = row
    return index


def verify_source_bytes(source_id: str, input_path: Path) -> dict[str, Any]:
    target = plan_index(build_plan()).get(source_id)
    require(target is not None, f"unknown C2 intake source: {source_id}")
    actual_sha, actual_length = sha256_file(input_path)
    require(actual_sha == target["upstream_document_sha256"], "operator-supplied source bytes do not match C1 SHA-256")
    require(actual_length == target["upstream_byte_length"], "operator-supplied source byte length does not match C1")
    return {
        "source_id": source_id,
        "sha256": actual_sha,
        "byte_length": actual_length,
        "matches_c1": True,
        "eligible_for_reference_only_candidate_intake": target["eligible_for_reference_only_candidate_intake"],
        "blocker": target["blocker"],
        "claim_boundary": "Exact-byte match proves only that the supplied operator input matches the historical C1 capture digest; it does not prove semantic extraction or review.",
    }


def verify_candidate(source_id: str, input_path: Path, record_path: Path) -> dict[str, Any]:
    source_evidence = verify_source_bytes(source_id, input_path)
    require(
        source_evidence["eligible_for_reference_only_candidate_intake"] is True,
        f"C2 candidate intake blocked: {source_evidence['blocker']}",
    )
    record = verify_record(record_path, LOCK_DIR)
    source = record.get("source")
    require(isinstance(source, dict) and source.get("source_id") == source_id, "candidate source_id does not match intake source")
    standard = record.get("standard")
    require(isinstance(standard, dict), "candidate standard missing")
    content = standard.get("content")
    require(isinstance(content, dict), "candidate content missing")
    require(content.get("mode") == "reference-only", "C2 intake v1 permits reference-only candidates only")
    provenance = record.get("provenance")
    require(isinstance(provenance, dict), "candidate provenance missing")
    require(
        provenance.get("human_source_review_status") == "required",
        "candidate intake cannot claim human normalization review",
    )
    return {
        "source_id": source_id,
        "record_id": record["record_id"],
        "content_digest": record["content_digest"],
        "content_mode": "reference-only",
        "source_bytes_match_c1": True,
        "candidate_verified": True,
        "promoted_to_canonical_records": False,
        "claim_boundary": "This is a verified reference-only C2 candidate input, not a canonical promoted record. Separate human normalization review and promotion evidence remain required.",
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    plan = commands.add_parser("plan", help="print or write the current C2 intake plan")
    plan.add_argument("--output", type=Path)
    source_bytes = commands.add_parser("verify-source-bytes", help="verify operator-supplied source bytes against C1")
    source_bytes.add_argument("--source-id", required=True)
    source_bytes.add_argument("--input", type=Path, required=True)
    candidate = commands.add_parser("verify-candidate", help="verify a blocked/eligible reference-only candidate")
    candidate.add_argument("--source-id", required=True)
    candidate.add_argument("--input", type=Path, required=True)
    candidate.add_argument("--record", type=Path, required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "plan":
            plan = build_plan()
            rendered = json.dumps(plan, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
            if args.output:
                args.output.parent.mkdir(parents=True, exist_ok=True)
                args.output.write_text(rendered, encoding="utf-8")
                print(f"Ontario Elementary C2 intake plan written: {args.output} eligible={plan['eligible_source_count']}/{plan['target_count']}")
            else:
                print(rendered, end="")
        elif args.command == "verify-source-bytes":
            print(json.dumps(verify_source_bytes(args.source_id, args.input), indent=2, sort_keys=True))
        else:
            print(json.dumps(verify_candidate(args.source_id, args.input, args.record), indent=2, sort_keys=True))
    except (OSError, KeyError, ElementaryC2IntakeError, ValueError) as error:
        print(f"Ontario Elementary C2 intake failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
