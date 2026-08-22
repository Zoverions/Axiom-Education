#!/usr/bin/env python3
"""Verify human normalization review and gate Ontario Elementary C2 promotion.

This layer begins only after the narrow reference-only C2 intake gate. A current
candidate remains non-canonical until a qualified human reviews the exact candidate
revision against the exact historical C1 source bytes. Promotion copies the unchanged
candidate bytes into records-v2 only after source/licensing eligibility, C1 byte match,
candidate validity, and exact human review all verify again.

Canonical C2-normalized status is not pack readiness, signing, staging, activation,
curriculum completeness, learner mastery, grade/credit authority, or Ministry approval.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CANDIDATE_DIR = ROOT / "curriculum" / "ontario-elementary" / "c2-candidates"
REVIEW_DIR = ROOT / "curriculum" / "reviews" / "ontario-elementary" / "normalization"
CANONICAL_DIR = ROOT / "curriculum" / "ontario-elementary" / "records-v2"
LOCK_DIR = ROOT / "curriculum" / "ontario-elementary" / "source-locks"
REVIEW_SCHEMA = ROOT / "schemas" / "curriculum-normalization-review-evidence.v1.schema.json"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
DECISIONS = {"approved", "changes-required", "rejected"}
FINDING_DISPOSITIONS = {
    "open",
    "resolved",
    "accepted-with-rationale",
    "not-applicable",
}
CONFIRMATION_KEYS = {
    "exact_source_bytes_reviewed",
    "official_structure_and_identifiers_reviewed",
    "education_context_reviewed",
    "hierarchy_and_relationships_reviewed",
    "reference_only_no_source_text_confirmed",
    "c1_provenance_binding_reviewed",
    "axiom_metadata_separation_reviewed",
    "no_completeness_or_activation_claim_confirmed",
}

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_lock import canonical_json_digest  # noqa: E402
from tools.curriculum_standard_record import verify_record  # noqa: E402
from tools.json_schema_validation import (  # noqa: E402
    RepositoryJsonSchemaError,
    validate_json_schema,
)
from tools.ontario_elementary_c2_intake import (  # noqa: E402
    build_plan as build_intake_plan,
    plan_index as intake_plan_index,
    verify_candidate as verify_intake_candidate,
)


class ElementaryC2PromotionError(RuntimeError):
    """Raised when normalization review or canonical promotion is unsupported."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ElementaryC2PromotionError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ElementaryC2PromotionError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise ElementaryC2PromotionError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def parse_timestamp(value: object) -> datetime:
    require(isinstance(value, str) and value, "reviewed_at must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ElementaryC2PromotionError("reviewed_at must be an ISO-8601 timestamp") from error
    require(parsed.tzinfo is not None, "reviewed_at must include a timezone")
    return parsed


def candidate_json_paths(directory: Path = CANDIDATE_DIR) -> list[Path]:
    if not directory.exists():
        return []
    return sorted(path for path in directory.glob("*.json") if path.is_file())


def canonical_json_paths(directory: Path = CANONICAL_DIR) -> list[Path]:
    if not directory.exists():
        return []
    return sorted(path for path in directory.glob("*.json") if path.is_file())


def _candidate_target(path: Path, intake: dict[str, dict[str, Any]]) -> dict[str, Any]:
    record = verify_record(path, LOCK_DIR)
    source = record.get("source")
    standard = record.get("standard")
    require(isinstance(source, dict), f"candidate source binding missing: {path}")
    require(isinstance(standard, dict), f"candidate standard missing: {path}")
    content = standard.get("content")
    require(isinstance(content, dict), f"candidate content missing: {path}")
    require(
        content.get("mode") == "reference-only",
        f"candidate promotion v1 supports reference-only mode only: {path}",
    )
    require(
        content.get("text") is None,
        f"reference-only candidate embeds source text: {path}",
    )

    source_id = source.get("source_id")
    require(isinstance(source_id, str) and source_id in intake, f"candidate source is not in current C2 intake plan: {path}")
    intake_target = intake[source_id]
    eligible = intake_target["eligible_for_reference_only_candidate_intake"] is True
    blocker = None if eligible else intake_target["blocker"]

    record_id = record.get("record_id")
    content_digest = record.get("content_digest")
    require(isinstance(record_id, str) and record_id, f"candidate record_id missing: {path}")
    require(
        isinstance(content_digest, str) and SHA256_RE.fullmatch(content_digest) is not None,
        f"candidate content digest invalid: {path}",
    )
    require(
        source.get("source_lock_sha256") == intake_target["source_lock_sha256"],
        f"candidate source-lock binding is not current: {record_id}",
    )
    require(
        source.get("upstream_document_sha256") == intake_target["upstream_document_sha256"],
        f"candidate upstream digest is not current: {record_id}",
    )

    binding = {
        "record_id": record_id,
        "content_digest": content_digest,
        "source_id": source_id,
        "source_lock_sha256": intake_target["source_lock_sha256"],
        "source_bytes_sha256": intake_target["upstream_document_sha256"],
        "source_byte_length": intake_target["upstream_byte_length"],
        "content_mode": "reference-only",
    }
    return {
        "record_id": record_id,
        "source_id": source_id,
        "candidate_path": path.resolve().relative_to(ROOT.resolve()).as_posix(),
        "content_digest": content_digest,
        "review_target_sha256": canonical_json_digest(binding),
        "source_lock_sha256": intake_target["source_lock_sha256"],
        "source_bytes_sha256": intake_target["upstream_document_sha256"],
        "source_byte_length": intake_target["upstream_byte_length"],
        "content_mode": "reference-only",
        "current_source_review_decision": intake_target["source_review_decision"],
        "current_licensing_decision": intake_target["licensing_decision"],
        "eligible_for_human_normalization_review": eligible,
        "blocker": blocker,
    }


def build_plan(candidate_dir: Path = CANDIDATE_DIR) -> dict[str, Any]:
    intake_plan = build_intake_plan()
    intake = intake_plan_index(intake_plan)
    targets: list[dict[str, Any]] = []
    seen_record_ids: set[str] = set()
    seen_paths: set[str] = set()
    for path in candidate_json_paths(candidate_dir):
        target = _candidate_target(path, intake)
        record_id = str(target["record_id"])
        candidate_path = str(target["candidate_path"])
        require(record_id not in seen_record_ids, f"duplicate current C2 candidate record_id: {record_id}")
        require(candidate_path not in seen_paths, f"duplicate current C2 candidate path: {candidate_path}")
        seen_record_ids.add(record_id)
        seen_paths.add(candidate_path)
        targets.append(target)
    targets.sort(key=lambda item: (str(item["source_id"]), str(item["record_id"])))
    eligible_count = sum(1 for target in targets if target["eligible_for_human_normalization_review"])
    return {
        "schema": "axiom-education-ontario-elementary-c2-promotion-plan.v1",
        "jurisdiction_id": "ca-on",
        "candidate_count": len(targets),
        "eligible_for_human_normalization_review": eligible_count,
        "canonical_c2_record_count": len(canonical_json_paths()),
        "claim_boundary": (
            "This plan binds future qualified-human normalization review to exact current reference-only C2 candidate revisions and exact C1 source evidence. "
            "Candidate presence or review-plan generation does not establish correctness, canonical promotion, curriculum completeness, pack readiness, signing, staging, activation, learner mastery, grade/credit authority, or Ministry approval."
        ),
        "targets": targets,
    }


def plan_index(plan: dict[str, Any] | None = None) -> dict[str, dict[str, Any]]:
    plan = plan or build_plan()
    rows = plan.get("targets")
    require(isinstance(rows, list), "C2 promotion targets missing")
    index: dict[str, dict[str, Any]] = {}
    for row in rows:
        require(isinstance(row, dict), "C2 promotion target must be an object")
        digest = row.get("review_target_sha256")
        require(isinstance(digest, str) and SHA256_RE.fullmatch(digest) is not None, "C2 promotion review target digest invalid")
        require(digest not in index, f"duplicate C2 promotion review target: {digest}")
        index[digest] = row
    return index


def record_index(plan: dict[str, Any] | None = None) -> dict[str, dict[str, Any]]:
    plan = plan or build_plan()
    rows = plan.get("targets")
    require(isinstance(rows, list), "C2 promotion targets missing")
    index: dict[str, dict[str, Any]] = {}
    for row in rows:
        require(isinstance(row, dict), "C2 promotion target must be an object")
        record_id = row.get("record_id")
        require(isinstance(record_id, str) and record_id, "C2 promotion record_id missing")
        require(record_id not in index, f"duplicate C2 promotion record_id: {record_id}")
        index[record_id] = row
    return index


def verify_review(path: Path, plan: dict[str, Any] | None = None) -> dict[str, Any]:
    review = load_json(path)
    try:
        validate_json_schema(review, REVIEW_SCHEMA, label=str(path))
    except RepositoryJsonSchemaError as error:
        raise ElementaryC2PromotionError(str(error)) from error

    require(
        review.get("schema") == "axiom-education-curriculum-normalization-review-evidence.v1",
        "unsupported curriculum normalization review schema",
    )
    require(review.get("jurisdiction_id") == "ca-on", "normalization review jurisdiction mismatch")
    review_id = review.get("review_id")
    require(isinstance(review_id, str) and review_id.strip(), "normalization review_id is required")

    candidate = review.get("candidate")
    require(isinstance(candidate, dict), "normalization review candidate binding is required")
    target_digest = candidate.get("review_target_sha256")
    require(isinstance(target_digest, str), "normalization review target digest missing")
    targets = plan_index(plan)
    require(target_digest in targets, "normalization review target is not a current candidate revision")
    target = targets[target_digest]
    require(review.get("source_id") == target["source_id"], "normalization review source_id mismatch")
    require(candidate.get("record_id") == target["record_id"], "normalization review record_id mismatch")
    require(candidate.get("content_digest") == target["content_digest"], "normalization review candidate digest mismatch")
    require(
        target["eligible_for_human_normalization_review"] is True,
        f"normalization review target is blocked by current intake evidence: {target['blocker']}",
    )

    basis = review.get("review_basis")
    require(isinstance(basis, dict), "normalization review basis is required")
    require(basis.get("source_bytes_sha256") == target["source_bytes_sha256"], "normalization review source-byte digest mismatch")
    require(basis.get("source_byte_length") == target["source_byte_length"], "normalization review source-byte length mismatch")
    require(basis.get("source_lock_sha256") == target["source_lock_sha256"], "normalization review source-lock digest mismatch")

    reviewer = review.get("reviewer")
    require(isinstance(reviewer, dict), "normalization reviewer metadata is required")
    require(isinstance(reviewer.get("name"), str) and reviewer["name"].strip(), "normalization reviewer name is required")
    require(
        isinstance(reviewer.get("qualification"), str) and reviewer["qualification"].strip(),
        "normalization reviewer qualification is required",
    )
    parse_timestamp(review.get("reviewed_at"))

    decision = review.get("decision")
    require(decision in DECISIONS, "invalid normalization review decision")
    confirmations = review.get("confirmations")
    require(isinstance(confirmations, dict), "normalization review confirmations are required")
    require(set(confirmations) == CONFIRMATION_KEYS, "normalization review confirmations are incomplete or out of scope")
    require(all(isinstance(value, bool) for value in confirmations.values()), "normalization review confirmations must be boolean")

    findings = review.get("findings")
    require(isinstance(findings, list), "normalization review findings must be an array")
    seen_findings: set[str] = set()
    open_findings = False
    unresolved_major = False
    for finding in findings:
        require(isinstance(finding, dict), "normalization finding must be an object")
        finding_id = finding.get("id")
        require(isinstance(finding_id, str) and finding_id, "normalization finding id is required")
        require(finding_id not in seen_findings, f"duplicate normalization finding id: {finding_id}")
        seen_findings.add(finding_id)
        severity = finding.get("severity")
        require(severity in {"note", "minor", "major", "critical"}, "invalid normalization finding severity")
        require(isinstance(finding.get("description"), str) and finding["description"], "normalization finding description is required")
        disposition = finding.get("disposition")
        require(disposition in FINDING_DISPOSITIONS, "invalid normalization finding disposition")
        open_findings = open_findings or disposition == "open"
        unresolved_major = unresolved_major or (
            severity in {"major", "critical"}
            and disposition not in {"resolved", "not-applicable"}
        )

    limitations = review.get("scope_limitations")
    require(isinstance(limitations, list) and all(isinstance(item, str) for item in limitations), "normalization scope_limitations must be strings")
    require(
        review.get("attestation_type") == "human-curriculum-normalization-review",
        "normalization review must be a human attestation",
    )
    if decision == "approved":
        require(all(confirmations.values()), "approved normalization review requires every confirmation")
        require(not open_findings, "approved normalization review cannot contain open findings")
        require(not unresolved_major, "approved normalization review cannot contain unresolved major/critical findings")
    return review


def verify_review_directory(
    directory: Path = REVIEW_DIR,
    plan: dict[str, Any] | None = None,
) -> dict[str, Any]:
    plan = plan or build_plan()
    targets = plan_index(plan)
    reviews_by_target: dict[str, list[tuple[datetime, dict[str, Any]]]] = {
        digest: [] for digest in targets
    }
    seen_review_ids: set[str] = set()
    paths = sorted(directory.glob("*.json")) if directory.exists() else []
    for path in paths:
        review = verify_review(path, plan)
        review_id = str(review["review_id"])
        require(review_id not in seen_review_ids, f"duplicate normalization review_id: {review_id}")
        seen_review_ids.add(review_id)
        target_digest = str(review["candidate"]["review_target_sha256"])
        reviews_by_target[target_digest].append((parse_timestamp(review["reviewed_at"]), review))

    latest: dict[str, dict[str, Any] | None] = {}
    approved_target_digests: set[str] = set()
    for digest, reviews in reviews_by_target.items():
        if not reviews:
            latest[digest] = None
            continue
        ordered = sorted(reviews, key=lambda item: (item[0], str(item[1]["review_id"])))
        latest_review = ordered[-1][1]
        latest[digest] = latest_review
        if latest_review["decision"] == "approved":
            approved_target_digests.add(digest)

    return {
        "candidate_targets": len(targets),
        "submitted_reviews": len(paths),
        "targets_with_any_review": sum(1 for review in latest.values() if review is not None),
        "latest_approved_targets": len(approved_target_digests),
        "approved_review_target_sha256": sorted(approved_target_digests),
        "unreviewed_record_ids": sorted(
            str(targets[digest]["record_id"])
            for digest, review in latest.items()
            if review is None
        ),
        "latest_nonapproved_record_ids": sorted(
            str(targets[digest]["record_id"])
            for digest, review in latest.items()
            if review is not None and review["decision"] != "approved"
        ),
    }


def verify_canonical_directory(
    canonical_dir: Path = CANONICAL_DIR,
    candidate_dir: Path = CANDIDATE_DIR,
    review_dir: Path = REVIEW_DIR,
) -> dict[str, Any]:
    plan = build_plan(candidate_dir)
    targets_by_record = record_index(plan)
    review_summary = verify_review_directory(review_dir, plan)
    approved = set(review_summary["approved_review_target_sha256"])
    seen_record_ids: set[str] = set()
    paths = canonical_json_paths(canonical_dir)
    for path in paths:
        record = verify_record(path, LOCK_DIR)
        record_id = str(record["record_id"])
        require(record_id not in seen_record_ids, f"duplicate canonical C2 record_id: {record_id}")
        seen_record_ids.add(record_id)
        require(record_id in targets_by_record, f"canonical C2 record has no retained current candidate: {record_id}")
        target = targets_by_record[record_id]
        require(
            record["content_digest"] == target["content_digest"],
            f"canonical C2 record differs from reviewed candidate: {record_id}",
        )
        require(
            target["eligible_for_human_normalization_review"] is True,
            f"canonical C2 record no longer satisfies current source/licensing gate: {record_id}",
        )
        require(
            target["review_target_sha256"] in approved,
            f"canonical C2 record lacks current approved normalization review: {record_id}",
        )
    return {
        "candidate_count": plan["candidate_count"],
        "submitted_normalization_reviews": review_summary["submitted_reviews"],
        "approved_candidate_targets": review_summary["latest_approved_targets"],
        "canonical_record_count": len(paths),
        "canonical_records_all_currently_approved": len(paths) == 0
        or all(
            targets_by_record[record_id]["review_target_sha256"] in approved
            for record_id in seen_record_ids
        ),
        "claim_boundary": (
            "Canonical-directory verification proves only that each committed C2 record exactly matches a retained current reference-only candidate with current source/licensing eligibility and an approved exact human normalization review. "
            "It does not establish curriculum completeness, pack readiness, signing, staging, activation, learner mastery, grade/credit authority, or Ministry approval."
        ),
    }


def _assert_registered_candidate(candidate_path: Path, plan: dict[str, Any]) -> dict[str, Any]:
    record = verify_record(candidate_path, LOCK_DIR)
    record_id = str(record["record_id"])
    targets = record_index(plan)
    require(record_id in targets, f"candidate is not registered in current candidate directory: {record_id}")
    target = targets[record_id]
    expected = (ROOT / target["candidate_path"]).resolve()
    require(candidate_path.resolve() == expected, "promotion candidate path does not match registered current candidate")
    require(record["content_digest"] == target["content_digest"], "promotion candidate digest does not match current plan")
    return target


def promote(
    source_id: str,
    source_bytes_path: Path,
    candidate_path: Path,
    review_path: Path,
    output_path: Path | None = None,
) -> dict[str, Any]:
    intake_result = verify_intake_candidate(source_id, source_bytes_path, candidate_path)
    require(intake_result["candidate_verified"] is True, "candidate did not pass C2 intake verification")
    plan = build_plan()
    target = _assert_registered_candidate(candidate_path, plan)
    require(target["source_id"] == source_id, "promotion source_id does not match candidate")
    review = verify_review(review_path, plan)
    require(review["decision"] == "approved", "canonical promotion requires an approved normalization review")
    require(
        review["candidate"]["review_target_sha256"] == target["review_target_sha256"],
        "normalization review does not bind the exact promotion candidate",
    )

    output = output_path or (CANONICAL_DIR / candidate_path.name)
    canonical_root = CANONICAL_DIR.resolve()
    resolved_output = output.resolve()
    require(
        resolved_output.parent == canonical_root,
        "canonical promotion output must be a direct JSON file in curriculum/ontario-elementary/records-v2",
    )
    require(resolved_output.suffix == ".json", "canonical promotion output must be JSON")
    candidate_bytes = candidate_path.read_bytes()
    if resolved_output.exists():
        require(
            resolved_output.read_bytes() == candidate_bytes,
            "canonical output already exists with different bytes",
        )
    else:
        resolved_output.parent.mkdir(parents=True, exist_ok=True)
        resolved_output.write_bytes(candidate_bytes)

    promoted = verify_record(resolved_output, LOCK_DIR)
    require(promoted["content_digest"] == target["content_digest"], "promoted canonical bytes changed candidate content")
    summary = verify_canonical_directory()
    return {
        "source_id": source_id,
        "record_id": promoted["record_id"],
        "content_digest": promoted["content_digest"],
        "canonical_path": resolved_output.relative_to(ROOT.resolve()).as_posix(),
        "promoted": True,
        "canonical_record_count": summary["canonical_record_count"],
        "claim_boundary": (
            "Promotion copies an unchanged, intake-verified, human-approved reference-only candidate into the canonical C2 directory. "
            "It does not authorize pack activation or establish curriculum completeness, learner mastery, grades, credits, school equivalency, or Ministry approval."
        ),
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    plan = commands.add_parser("plan", help="print or write current normalization-review targets")
    plan.add_argument("--output", type=Path)

    review = commands.add_parser("verify-review", help="verify one exact human normalization review")
    review.add_argument("review", type=Path)

    commands.add_parser("verify-directory", help="verify all committed normalization reviews")
    commands.add_parser("verify-canonical", help="verify canonical records against current candidate/review evidence")

    promote_parser = commands.add_parser("promote", help="promote one exact approved reference-only candidate")
    promote_parser.add_argument("--source-id", required=True)
    promote_parser.add_argument("--source-bytes", type=Path, required=True)
    promote_parser.add_argument("--candidate", type=Path, required=True)
    promote_parser.add_argument("--review", type=Path, required=True)
    promote_parser.add_argument("--output", type=Path)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "plan":
            payload = build_plan()
            rendered = json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
            if args.output:
                args.output.parent.mkdir(parents=True, exist_ok=True)
                args.output.write_text(rendered, encoding="utf-8")
                print(f"Ontario Elementary C2 promotion plan written: {args.output} candidates={payload['candidate_count']}")
            else:
                print(rendered, end="")
        elif args.command == "verify-review":
            review = verify_review(args.review)
            print(f"Ontario Elementary normalization review verified: {review['review_id']} decision={review['decision']}")
        elif args.command == "verify-directory":
            print(json.dumps(verify_review_directory(), indent=2, sort_keys=True))
        elif args.command == "verify-canonical":
            print(json.dumps(verify_canonical_directory(), indent=2, sort_keys=True))
        else:
            print(
                json.dumps(
                    promote(
                        args.source_id,
                        args.source_bytes,
                        args.candidate,
                        args.review,
                        args.output,
                    ),
                    indent=2,
                    sort_keys=True,
                )
            )
    except (
        OSError,
        KeyError,
        ElementaryC2PromotionError,
        RepositoryJsonSchemaError,
        ValueError,
    ) as error:
        print(f"Ontario Elementary C2 promotion failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
