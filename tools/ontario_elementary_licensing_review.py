#!/usr/bin/env python3
"""Build Ontario Elementary licensing-review targets and verify human evidence.

Licensing review is separate from source identity review and C1 capture. Public availability
never counts as redistribution permission. Each decision is content-addressed to the exact
current source-review target and C1 lock. This verifier records a reviewer decision; it does
not itself establish that the legal conclusion is correct.
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
REVIEW_DIR = ROOT / "curriculum" / "licensing" / "ontario-elementary" / "reviews"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ALLOWED_DECISIONS = {
    "verbatim-redistribution-permitted",
    "reference-only-use-permitted",
    "external-reference-only",
    "prohibited",
    "unresolved",
}
ALLOWED_DISPOSITIONS = {"open", "resolved", "accepted-with-rationale", "not-applicable"}
REQUIRED_CONFIRMATIONS = {
    "source_lock_binding_confirmed",
    "rights_holder_or_authority_identified",
    "licence_or_terms_basis_recorded",
    "redistribution_scope_decided",
    "conditions_recorded",
}
RESOLVED_DECISIONS = ALLOWED_DECISIONS - {"unresolved"}

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_lock import canonical_json_digest  # noqa: E402
from tools.ontario_elementary_source_review import build_plan as build_source_review_plan  # noqa: E402


class ElementaryLicensingReviewError(RuntimeError):
    """Raised when licensing-review evidence is unsupported, stale, or ambiguous."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ElementaryLicensingReviewError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ElementaryLicensingReviewError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise ElementaryLicensingReviewError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def target_digest(target: dict[str, Any]) -> str:
    value = dict(target)
    value.pop("target_sha256", None)
    return canonical_json_digest(value)


def build_plan() -> dict[str, Any]:
    source_plan = build_source_review_plan()
    source_targets = source_plan.get("targets")
    require(isinstance(source_targets, list) and len(source_targets) == 16, "licensing review requires 16 current source targets")

    targets: list[dict[str, Any]] = []
    for source in source_targets:
        require(isinstance(source, dict), "source-review target must be an object")
        target: dict[str, Any] = {
            "source_id": source["source_id"],
            "source_review_target_sha256": source["target_sha256"],
            "source_lock_sha256": source["source_lock_sha256"],
            "upstream_document_sha256": source["upstream_document_sha256"],
            "official_locator": source["official_locator"],
            "media_type": source["media_type"],
            "current_redistribution_status": source["redistribution_status"],
            "required_review_type": "licensing-and-redistribution",
        }
        require(target["current_redistribution_status"] == "review-required", f"unexpected pre-review redistribution status: {target['source_id']}")
        target["target_sha256"] = target_digest(target)
        targets.append(target)

    return {
        "schema": "axiom-education-ontario-elementary-licensing-review-plan.v1",
        "jurisdiction_id": source_plan["jurisdiction_id"],
        "target_count": len(targets),
        "claim_boundary": (
            "This plan creates content-addressed human licensing-review targets only. Public availability is not redistribution permission. "
            "A reviewer decision does not itself prove the legal conclusion correct and does not establish curriculum correctness, C2 promotion, accessibility, pack activation, or Ministry endorsement."
        ),
        "targets": targets,
    }


def plan_index(plan: dict[str, Any]) -> dict[str, dict[str, Any]]:
    targets = plan.get("targets")
    require(isinstance(targets, list), "licensing-review targets are required")
    index: dict[str, dict[str, Any]] = {}
    for target in targets:
        require(isinstance(target, dict), "licensing-review target must be an object")
        source_id = target.get("source_id")
        require(isinstance(source_id, str) and source_id, "licensing target source_id is required")
        require(source_id not in index, f"duplicate licensing target: {source_id}")
        require(target.get("target_sha256") == target_digest(target), f"licensing target digest mismatch: {source_id}")
        index[source_id] = target
    return index


def validate_timestamp(value: object) -> None:
    require(isinstance(value, str), "reviewed_at must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ElementaryLicensingReviewError("reviewed_at must be an ISO-8601 timestamp") from error
    require(parsed.tzinfo is not None, "reviewed_at must include a timezone")


def validate_findings(findings: object, *, resolved: bool) -> None:
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
        if resolved:
            require(disposition != "open", "resolved licensing decision cannot contain open findings")
            if severity in {"major", "critical"}:
                require(disposition == "resolved", "resolved licensing decision requires major/critical findings to be resolved")


def verify_review(review_path: Path, plan: dict[str, Any] | None = None) -> dict[str, Any]:
    review = load_json(review_path)
    plan = plan or build_plan()
    targets = plan_index(plan)
    require(
        review.get("schema") == "axiom-education-ontario-elementary-licensing-review.v1",
        "unsupported Ontario Elementary licensing-review schema",
    )
    require(review.get("review_type") == "licensing-and-redistribution", "invalid licensing review type")
    review_id = review.get("review_id")
    require(isinstance(review_id, str) and review_id, "review_id is required")
    source_id = review.get("source_id")
    require(isinstance(source_id, str) and source_id in targets, "licensing review source_id is not a current target")
    target_sha = review.get("target_sha256")
    require(isinstance(target_sha, str) and SHA256_RE.fullmatch(target_sha) is not None, "invalid target_sha256")
    require(target_sha == targets[source_id]["target_sha256"], "licensing review is stale: target evidence changed")

    reviewer = review.get("reviewer")
    require(isinstance(reviewer, dict), "reviewer metadata is required")
    require(isinstance(reviewer.get("name"), str) and reviewer["name"].strip(), "reviewer name is required")
    require(isinstance(reviewer.get("qualification"), str) and reviewer["qualification"].strip(), "reviewer qualification is required")
    validate_timestamp(review.get("reviewed_at"))

    decision = review.get("decision")
    require(decision in ALLOWED_DECISIONS, "invalid licensing decision")
    confirmations = review.get("confirmations")
    require(isinstance(confirmations, dict), "licensing confirmations are required")
    require(set(confirmations) == REQUIRED_CONFIRMATIONS, "licensing confirmations are incomplete")
    require(all(isinstance(value, bool) for value in confirmations.values()), "licensing confirmations must be boolean")
    if decision in RESOLVED_DECISIONS:
        require(all(confirmations.values()), "resolved licensing decision requires every confirmation")

    basis = review.get("basis")
    require(isinstance(basis, dict), "licensing basis is required")
    require(isinstance(basis.get("summary"), str) and basis["summary"].strip(), "licensing basis summary is required")
    locators = basis.get("evidence_locators")
    require(isinstance(locators, list) and all(isinstance(item, str) and item.strip() for item in locators), "licensing evidence_locators must be strings")
    if decision == "verbatim-redistribution-permitted":
        require(bool(locators), "verbatim redistribution permission requires at least one evidence locator")

    conditions = review.get("conditions")
    require(isinstance(conditions, list) and all(isinstance(item, str) for item in conditions), "licensing conditions must be an array of strings")
    validate_findings(review.get("findings"), resolved=decision in RESOLVED_DECISIONS)
    require(review.get("attestation_type") == "human-review", "licensing review must be an explicit human attestation")
    return review


def verify_directory(directory: Path = REVIEW_DIR) -> dict[str, Any]:
    plan = build_plan()
    targets = plan_index(plan)
    paths = sorted(directory.glob("*.json")) if directory.exists() else []
    seen_review_ids: set[str] = set()
    decisions: dict[str, str] = {}
    for path in paths:
        review = verify_review(path, plan)
        review_id = str(review["review_id"])
        require(review_id not in seen_review_ids, f"duplicate review_id: {review_id}")
        seen_review_ids.add(review_id)
        source_id = str(review["source_id"])
        require(source_id not in decisions, f"multiple current licensing attestations for source: {source_id}")
        decisions[source_id] = str(review["decision"])

    resolved = sorted(source_id for source_id, decision in decisions.items() if decision in RESOLVED_DECISIONS)
    unresolved = sorted(source_id for source_id in targets if source_id not in decisions or decisions.get(source_id) == "unresolved")
    verbatim = sorted(source_id for source_id, decision in decisions.items() if decision == "verbatim-redistribution-permitted")
    reference_only = sorted(source_id for source_id, decision in decisions.items() if decision == "reference-only-use-permitted")
    external_only = sorted(source_id for source_id, decision in decisions.items() if decision == "external-reference-only")
    prohibited = sorted(source_id for source_id, decision in decisions.items() if decision == "prohibited")
    return {
        "targets": len(targets),
        "reviews": len(paths),
        "resolved_sources": len(resolved),
        "resolved_source_ids": resolved,
        "unresolved_sources": len(unresolved),
        "unresolved_source_ids": unresolved,
        "verbatim_redistribution_permitted": len(verbatim),
        "verbatim_redistribution_source_ids": verbatim,
        "reference_only_use_permitted": len(reference_only),
        "reference_only_source_ids": reference_only,
        "external_reference_only": len(external_only),
        "external_reference_only_source_ids": external_only,
        "prohibited": len(prohibited),
        "prohibited_source_ids": prohibited,
        "licensing_review_complete": len(resolved) == len(targets),
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    plan = commands.add_parser("plan", help="build the deterministic licensing-review plan")
    plan.add_argument("--output", type=Path)
    verify = commands.add_parser("verify", help="verify one human licensing-review attestation")
    verify.add_argument("review", type=Path)
    verify_dir = commands.add_parser("verify-directory", help="verify all submitted licensing reviews")
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
                print(f"Ontario Elementary licensing-review plan written: {args.output} ({plan['target_count']} targets)")
            else:
                print(rendered, end="")
        elif args.command == "verify":
            review = verify_review(args.review)
            print(f"Ontario Elementary licensing review verified: {review['review_id']} decision={review['decision']}")
        else:
            print(json.dumps(verify_directory(args.directory), indent=2, sort_keys=True))
    except (OSError, KeyError, ElementaryLicensingReviewError, ValueError) as error:
        print(f"Ontario Elementary licensing review verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
