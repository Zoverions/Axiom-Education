#!/usr/bin/env python3
"""Seal and verify derived competency-to-curriculum crosswalks.

Crosswalks are Axiom-authored metadata. They never modify official curriculum records,
never imply learner mastery, and never create a whole-curriculum coverage claim. Every
mapping is bound to the exact content digest of a canonical curriculum record so record
changes stale the mapping instead of silently inheriting it.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
RELATIONSHIPS = {"equivalent", "supports", "partial", "prerequisite", "contextual"}
COVERAGE_LEVELS = {"none", "supporting", "direct"}
REVIEW_STATUSES = {"required", "approved", "changes-required", "rejected"}
FINDING_DISPOSITIONS = {"open", "resolved", "accepted-with-rationale", "not-applicable"}

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_standard_record import canonical_record_digest  # noqa: E402


class CrosswalkError(RuntimeError):
    """Raised when a crosswalk is stale, overclaims coverage, or is malformed."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise CrosswalkError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise CrosswalkError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise CrosswalkError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def canonical_crosswalk_digest(payload: dict[str, Any]) -> str:
    unsigned = dict(payload)
    unsigned.pop("crosswalk_digest", None)
    canonical = json.dumps(
        unsigned,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


def parse_timestamp(value: object) -> None:
    require(isinstance(value, str) and value, "reviewed_at must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise CrosswalkError("reviewed_at must be an ISO-8601 timestamp") from error
    require(parsed.tzinfo is not None, "reviewed_at must include a timezone")


def resolve_record_path(path_value: object, repository_root: Path) -> Path:
    require(isinstance(path_value, str) and path_value, "target_record_path is required")
    relative = Path(path_value)
    require(not relative.is_absolute(), "target_record_path must be repository-relative")
    require(".." not in relative.parts, "target_record_path cannot escape the repository")
    resolved_root = repository_root.resolve()
    resolved = (resolved_root / relative).resolve()
    try:
        resolved.relative_to(resolved_root)
    except ValueError as error:
        raise CrosswalkError("target_record_path escapes the repository") from error
    return resolved


def verify_target_record(
    mapping: dict[str, Any],
    target_jurisdiction_id: str,
    repository_root: Path,
) -> dict[str, Any]:
    record_path = resolve_record_path(mapping.get("target_record_path"), repository_root)
    record = load_json(record_path)
    require(
        record.get("schema") == "axiom-curriculum-standard-record.v2",
        f"{record_path}: target is not a curriculum-standard-record v2",
    )
    require(record.get("stage") == "C2-normalized", f"{record_path}: target record is not C2-normalized")
    require(
        record.get("jurisdiction_id") == target_jurisdiction_id,
        f"{record_path}: target jurisdiction mismatch",
    )
    source = record.get("source")
    require(isinstance(source, dict), f"{record_path}: source binding missing")
    require(source.get("official_recognition") is True, f"{record_path}: target is not an officially recognized standard record")
    standard = record.get("standard")
    require(isinstance(standard, dict), f"{record_path}: standard object missing")
    digest = record.get("content_digest")
    require(isinstance(digest, str) and len(digest) == 64, f"{record_path}: content digest missing")
    require(digest == canonical_record_digest(record), f"{record_path}: curriculum record content digest mismatch")
    require(mapping.get("target_record_id") == record.get("record_id"), "crosswalk target_record_id mismatch")
    require(mapping.get("target_official_id") == standard.get("official_id"), "crosswalk target_official_id mismatch")
    require(mapping.get("target_content_digest") == digest, "crosswalk mapping is stale: target record changed")
    return record


def verify_review(mapping: dict[str, Any]) -> None:
    review = mapping.get("review")
    require(isinstance(review, dict), "crosswalk mapping review is required")
    require(set(review) == {"status", "reviewer", "reviewed_at", "findings"}, "crosswalk mapping review fields are invalid")
    status = review.get("status")
    require(status in REVIEW_STATUSES, "invalid crosswalk review status")
    reviewer = review.get("reviewer")
    reviewed_at = review.get("reviewed_at")

    if status == "required":
        require(reviewer is None, "unreviewed mapping cannot name a reviewer")
        require(reviewed_at is None, "unreviewed mapping cannot have reviewed_at")
    else:
        require(isinstance(reviewer, dict), "reviewed mapping requires reviewer metadata")
        require(isinstance(reviewer.get("name"), str) and reviewer["name"].strip(), "crosswalk reviewer name is required")
        require(
            isinstance(reviewer.get("qualification"), str)
            and reviewer["qualification"].strip(),
            "crosswalk reviewer qualification is required",
        )
        parse_timestamp(reviewed_at)

    findings = review.get("findings")
    require(isinstance(findings, list), "crosswalk review findings must be an array")
    seen: set[str] = set()
    open_findings = False
    unresolved_major = False
    for finding in findings:
        require(isinstance(finding, dict), "crosswalk finding must be an object")
        finding_id = finding.get("id")
        require(isinstance(finding_id, str) and finding_id, "crosswalk finding id is required")
        require(finding_id not in seen, f"duplicate crosswalk finding id: {finding_id}")
        seen.add(finding_id)
        severity = finding.get("severity")
        require(severity in {"note", "minor", "major", "critical"}, "invalid crosswalk finding severity")
        require(isinstance(finding.get("description"), str) and finding["description"], "crosswalk finding description is required")
        disposition = finding.get("disposition")
        require(disposition in FINDING_DISPOSITIONS, "invalid crosswalk finding disposition")
        open_findings = open_findings or disposition == "open"
        unresolved_major = unresolved_major or (
            severity in {"major", "critical"}
            and disposition not in {"resolved", "not-applicable"}
        )

    relationship = mapping.get("relationship")
    coverage = mapping.get("coverage_level")
    evidence_refs = mapping.get("evidence_refs")
    require(relationship in RELATIONSHIPS, "invalid crosswalk relationship")
    require(coverage in COVERAGE_LEVELS, "invalid crosswalk coverage_level")
    require(
        isinstance(evidence_refs, list)
        and all(isinstance(item, str) and item for item in evidence_refs),
        "crosswalk evidence_refs must be strings",
    )

    if status != "approved":
        require(
            coverage != "direct",
            "unapproved crosswalk mapping cannot claim direct official coverage",
        )
    if status == "approved":
        require(evidence_refs, "approved crosswalk mapping requires review evidence refs")
        require(not open_findings, "approved crosswalk mapping cannot contain open findings")
        require(not unresolved_major, "approved crosswalk mapping cannot contain unresolved major/critical findings")
    if coverage == "direct":
        require(status == "approved", "direct coverage requires approved human review")
        require(
            relationship == "equivalent",
            "direct coverage requires an equivalent relationship",
        )


def verify_crosswalk(
    path: Path,
    repository_root: Path = ROOT,
) -> dict[str, Any]:
    payload = load_json(path)
    require(payload.get("schema") == "axiom-curriculum-crosswalk.v1", "unsupported crosswalk schema")
    require(isinstance(payload.get("crosswalk_id"), str) and payload["crosswalk_id"], "crosswalk_id is required")
    require(isinstance(payload.get("crosswalk_version"), str) and payload["crosswalk_version"], "crosswalk_version is required")
    require(isinstance(payload.get("source_competency_namespace"), str) and payload["source_competency_namespace"], "source competency namespace is required")
    jurisdiction = payload.get("target_jurisdiction_id")
    require(isinstance(jurisdiction, str) and jurisdiction, "target jurisdiction is required")
    require(isinstance(payload.get("claim_boundary"), str) and payload["claim_boundary"], "crosswalk claim boundary is required")
    require(
        payload.get("global_official_coverage_claim_allowed") is False,
        "crosswalk cannot make a global official curriculum coverage claim",
    )
    require(
        payload.get("learner_mastery_claim_allowed") is False,
        "crosswalk cannot infer learner mastery",
    )

    mappings = payload.get("mappings")
    require(isinstance(mappings, list) and mappings, "crosswalk must contain at least one mapping")
    seen_ids: set[str] = set()
    seen_edges: set[tuple[str, str, str]] = set()
    direct_count = 0
    reviewed_count = 0
    for mapping in mappings:
        require(isinstance(mapping, dict), "crosswalk mapping must be an object")
        mapping_id = mapping.get("mapping_id")
        competency_id = mapping.get("competency_id")
        require(isinstance(mapping_id, str) and mapping_id, "crosswalk mapping_id is required")
        require(mapping_id not in seen_ids, f"duplicate mapping_id: {mapping_id}")
        seen_ids.add(mapping_id)
        require(isinstance(competency_id, str) and competency_id, f"{mapping_id}: competency_id is required")
        require(isinstance(mapping.get("rationale"), str) and mapping["rationale"].strip(), f"{mapping_id}: rationale is required")
        verify_target_record(mapping, jurisdiction, repository_root)
        verify_review(mapping)
        edge = (competency_id, str(mapping.get("target_record_id")), str(mapping.get("relationship")))
        require(edge not in seen_edges, f"duplicate competency/target/relationship mapping: {edge}")
        seen_edges.add(edge)
        if mapping.get("coverage_level") == "direct":
            direct_count += 1
        if mapping["review"]["status"] == "approved":
            reviewed_count += 1

    digest = payload.get("crosswalk_digest")
    require(isinstance(digest, str) and len(digest) == 64, "crosswalk_digest is invalid")
    require(
        digest == canonical_crosswalk_digest(payload),
        "crosswalk digest mismatch",
    )
    return {
        "crosswalk_id": payload["crosswalk_id"],
        "mappings": len(mappings),
        "approved_mappings": reviewed_count,
        "direct_coverage_mappings": direct_count,
        "global_official_coverage_claim_allowed": False,
        "learner_mastery_claim_allowed": False,
        "crosswalk_digest": digest,
    }


def seal(input_path: Path, output_path: Path, repository_root: Path = ROOT) -> dict[str, Any]:
    payload = load_json(input_path)
    payload["crosswalk_digest"] = canonical_crosswalk_digest(payload)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    verify_crosswalk(output_path, repository_root)
    return payload


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    verify = commands.add_parser("verify")
    verify.add_argument("crosswalk", type=Path)
    seal_parser = commands.add_parser("seal")
    seal_parser.add_argument("input", type=Path)
    seal_parser.add_argument("output", type=Path)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "verify":
            result = verify_crosswalk(args.crosswalk)
            print(json.dumps(result, indent=2, sort_keys=True))
        else:
            payload = seal(args.input, args.output)
            print(
                "curriculum crosswalk sealed: "
                f"{payload['crosswalk_id']} digest={payload['crosswalk_digest']}"
            )
    except (OSError, KeyError, CrosswalkError, ValueError) as error:
        print(f"curriculum crosswalk verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
