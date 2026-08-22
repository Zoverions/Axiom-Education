#!/usr/bin/env python3
"""Build Ontario Elementary source-review targets and verify human attestations.

This layer reviews source identity, authority, version, scope, and locator evidence. It does
not review normalized curriculum content, licensing, pedagogy, accessibility, packs, or
activation. Reviews are bound to the exact composed source entry and C1 lock so later
source changes make earlier approvals stale instead of carrying them forward silently.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DISCOVERY_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-discovery.v0.json"
LOCK_DIR = ROOT / "curriculum" / "ontario-elementary" / "source-locks"
REVIEW_DIR = ROOT / "curriculum" / "reviews" / "ontario-elementary" / "sources"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ALLOWED_DECISIONS = {"approved", "changes-required", "rejected"}
ALLOWED_DISPOSITIONS = {"open", "resolved", "accepted-with-rationale", "not-applicable"}
REQUIRED_CONFIRMATIONS = {
    "official_authority_confirmed",
    "source_identity_confirmed",
    "policy_version_confirmed",
    "grade_scope_confirmed",
    "official_locator_confirmed",
}

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_lock import (  # noqa: E402
    canonical_json_digest,
    load_discovery,
    verify_lock,
)


class ElementarySourceReviewError(RuntimeError):
    """Raised when a source-review target or attestation is unsafe or stale."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ElementarySourceReviewError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ElementarySourceReviewError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise ElementarySourceReviewError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def source_index(discovery: dict[str, Any]) -> dict[str, dict[str, Any]]:
    rows = discovery.get("confirmed_curriculum_sources")
    require(isinstance(rows, list) and rows, "confirmed curriculum sources are required")
    index: dict[str, dict[str, Any]] = {}
    for row in rows:
        require(isinstance(row, dict), "curriculum source must be an object")
        source_id = row.get("source_id")
        require(isinstance(source_id, str) and source_id, "source_id is required")
        require(source_id not in index, f"duplicate source_id: {source_id}")
        index[source_id] = row
    return index


def lock_index() -> dict[str, tuple[Path, dict[str, Any]]]:
    index: dict[str, tuple[Path, dict[str, Any]]] = {}
    for path in sorted(LOCK_DIR.glob("*.json")):
        lock = verify_lock(path, DISCOVERY_PATH)
        source_id = lock.get("source_id")
        require(isinstance(source_id, str) and source_id, f"source lock missing source_id: {path}")
        require(source_id not in index, f"duplicate source lock: {source_id}")
        index[source_id] = (path, lock)
    return index


def target_digest(target: dict[str, Any]) -> str:
    value = dict(target)
    value.pop("target_sha256", None)
    return canonical_json_digest(value)


def build_plan() -> dict[str, Any]:
    discovery = load_discovery(DISCOVERY_PATH)
    sources = source_index(discovery)
    locks = lock_index()
    require(set(sources) == set(locks), "source review requires complete C1 coverage for the current source set")

    targets: list[dict[str, Any]] = []
    for source_id in sorted(sources):
        source = sources[source_id]
        lock_path, lock = locks[source_id]
        target: dict[str, Any] = {
            "source_id": source_id,
            "subject_family": source.get("subject_family"),
            "grades": source.get("grades"),
            "policy_version": source.get("policy_version"),
            "source_entry_sha256": canonical_json_digest(source),
            "source_lock_path": lock_path.resolve().relative_to(ROOT.resolve()).as_posix(),
            "source_lock_sha256": canonical_json_digest(lock),
            "upstream_document_sha256": lock.get("sha256"),
            "official_locator": lock.get("resolved_locator"),
            "media_type": lock.get("media_type"),
            "redistribution_status": lock.get("redistribution_status"),
            "required_review_type": "source-identity-and-scope",
        }
        target["target_sha256"] = target_digest(target)
        targets.append(target)

    require(len(targets) == 16, f"expected 16 Ontario Elementary source review targets, found {len(targets)}")
    return {
        "schema": "axiom-education-ontario-elementary-source-review-plan.v1",
        "jurisdiction_id": discovery.get("jurisdiction_id"),
        "authority_id": discovery.get("authority_id"),
        "target_count": len(targets),
        "claim_boundary": (
            "This plan creates exact human-review targets for source identity, authority, policy version, grade scope, and official locator only. "
            "It contains no approval and does not establish licensing, normalized curriculum correctness, complete program coverage, accessibility, pack verification, activation, or Ministry endorsement."
        ),
        "targets": targets,
    }


def plan_index(plan: dict[str, Any]) -> dict[str, dict[str, Any]]:
    targets = plan.get("targets")
    require(isinstance(targets, list), "source-review plan targets are required")
    index: dict[str, dict[str, Any]] = {}
    for target in targets:
        require(isinstance(target, dict), "source-review target must be an object")
        source_id = target.get("source_id")
        require(isinstance(source_id, str) and source_id, "source-review target source_id is required")
        require(source_id not in index, f"duplicate source-review target: {source_id}")
        require(target.get("target_sha256") == target_digest(target), f"source-review target digest mismatch: {source_id}")
        index[source_id] = target
    return index


def validate_timestamp(value: object) -> None:
    require(isinstance(value, str), "reviewed_at must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ElementarySourceReviewError("reviewed_at must be an ISO-8601 timestamp") from error
    require(parsed.tzinfo is not None, "reviewed_at must include a timezone")


def validate_findings(findings: object, *, approved: bool) -> None:
    require(isinstance(findings, list), "findings must be an array")
    seen: set[str] = set()
    for finding in findings:
        require(isinstance(finding, dict), "finding must be an object")
        finding_id = finding.get("id")
        require(isinstance(finding_id, str) and finding_id, "finding id is required")
        require(finding_id not in seen, f"duplicate finding id: {finding_id}")
        seen.add(finding_id)
        severity = finding.get("severity")
        require(severity in {"note", "minor", "major", "critical"}, "invalid finding severity")
        require(isinstance(finding.get("description"), str) and finding["description"].strip(), "finding description is required")
        disposition = finding.get("disposition")
        require(disposition in ALLOWED_DISPOSITIONS, "invalid finding disposition")
        if approved:
            require(disposition != "open", "approved source review cannot contain open findings")
            if severity in {"major", "critical"}:
                require(disposition == "resolved", "approved source review requires major/critical findings to be resolved")


def verify_review(review_path: Path, plan: dict[str, Any] | None = None) -> dict[str, Any]:
    review = load_json(review_path)
    plan = plan or build_plan()
    targets = plan_index(plan)
    require(
        review.get("schema") == "axiom-education-ontario-elementary-source-review.v1",
        "unsupported Ontario Elementary source-review schema",
    )
    require(review.get("review_type") == "source-identity-and-scope", "invalid source review type")
    review_id = review.get("review_id")
    require(isinstance(review_id, str) and review_id, "review_id is required")
    source_id = review.get("source_id")
    require(isinstance(source_id, str) and source_id in targets, "review source_id is not a current source-review target")
    target = targets[source_id]
    target_sha = review.get("target_sha256")
    require(isinstance(target_sha, str) and SHA256_RE.fullmatch(target_sha) is not None, "invalid target_sha256")
    require(target_sha == target.get("target_sha256"), "source review is stale: target evidence changed")

    reviewer = review.get("reviewer")
    require(isinstance(reviewer, dict), "reviewer metadata is required")
    require(isinstance(reviewer.get("name"), str) and reviewer["name"].strip(), "reviewer name is required")
    require(isinstance(reviewer.get("qualification"), str) and reviewer["qualification"].strip(), "reviewer qualification is required")
    validate_timestamp(review.get("reviewed_at"))

    decision = review.get("decision")
    require(decision in ALLOWED_DECISIONS, "invalid review decision")
    confirmations = review.get("confirmations")
    require(isinstance(confirmations, dict), "source-review confirmations are required")
    require(set(confirmations) == REQUIRED_CONFIRMATIONS, "source-review confirmations are incomplete")
    require(all(isinstance(value, bool) for value in confirmations.values()), "source-review confirmations must be boolean")
    if decision == "approved":
        require(all(confirmations.values()), "approved source review requires every confirmation")

    validate_findings(review.get("findings"), approved=decision == "approved")
    limitations = review.get("scope_limitations")
    require(isinstance(limitations, list) and all(isinstance(item, str) for item in limitations), "scope_limitations must be an array of strings")
    require(review.get("attestation_type") == "human-review", "source review must be an explicit human attestation")
    return review


def verify_directory(directory: Path = REVIEW_DIR) -> dict[str, Any]:
    plan = build_plan()
    targets = plan_index(plan)
    paths = sorted(directory.glob("*.json")) if directory.exists() else []
    seen_review_ids: set[str] = set()
    decision_by_source: dict[str, str | None] = {source_id: None for source_id in targets}
    for path in paths:
        review = verify_review(path, plan)
        review_id = str(review["review_id"])
        require(review_id not in seen_review_ids, f"duplicate review_id: {review_id}")
        seen_review_ids.add(review_id)
        source_id = str(review["source_id"])
        require(
            decision_by_source[source_id] is None,
            f"multiple source-review attestations for {source_id}; v1 requires exactly one current review per source",
        )
        decision_by_source[source_id] = str(review["decision"])

    approved_sources = sorted(
        source_id
        for source_id, decision in decision_by_source.items()
        if decision == "approved"
    )
    blocked_sources = sorted(
        source_id
        for source_id, decision in decision_by_source.items()
        if decision in {"changes-required", "rejected"}
    )
    unreviewed_sources = sorted(
        source_id for source_id, decision in decision_by_source.items() if decision is None
    )
    return {
        "targets": len(targets),
        "reviews": len(paths),
        "approved_sources": len(approved_sources),
        "approved_source_ids": approved_sources,
        "blocked_sources": len(blocked_sources),
        "blocked_source_ids": blocked_sources,
        "unreviewed_sources": len(unreviewed_sources),
        "unreviewed_source_ids": unreviewed_sources,
        "human_source_review_complete": len(approved_sources) == len(targets),
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    plan = commands.add_parser("plan", help="build the deterministic source-review plan")
    plan.add_argument("--output", type=Path)
    verify = commands.add_parser("verify", help="verify one human source-review attestation")
    verify.add_argument("review", type=Path)
    verify_dir = commands.add_parser("verify-directory", help="verify all submitted source reviews")
    verify_dir.add_argument("--directory", type=Path, default=REVIEW_DIR)
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
                print(f"Ontario Elementary source-review plan written: {args.output} ({plan['target_count']} targets)")
            else:
                print(rendered, end="")
        elif args.command == "verify":
            review = verify_review(args.review)
            print(f"Ontario Elementary source review verified: {review['review_id']} decision={review['decision']}")
        else:
            print(json.dumps(verify_directory(args.directory), indent=2, sort_keys=True))
    except (OSError, KeyError, ElementarySourceReviewError, ValueError) as error:
        print(f"Ontario Elementary source review verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
