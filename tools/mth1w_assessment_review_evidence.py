#!/usr/bin/env python3
"""Build and verify content-addressed human assessment review evidence for MTH1W.

Nine targets bind assessment review to the exact authored unit revisions that contain the
unit quiz/performance-task surfaces. A tenth target binds review to the complete current
coursewide cumulative-assessment plan. Historical negative reviews may remain in the
evidence directory; promotion uses the latest valid review for each exact current target.
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
ASSESSMENT_PATH = (
    ROOT / "curriculum" / "courses" / "ontario-mth1w-2021.assessment-plan.json"
)
REVIEW_DIR = ROOT / "curriculum" / "reviews" / "mth1w-assessment"
READINESS_PATH = ROOT / "config" / "curriculum-readiness.json"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
CONFIRMATION_KEYS = {
    "official_alignment_reviewed",
    "content_validity_reviewed",
    "scoring_rubric_reviewed",
    "constructed_response_reviewed",
    "correction_reassessment_appeal_reviewed",
    "accessibility_alternatives_reviewed",
    "no_automatic_mastery_grade_credit_confirmed",
}
DECISIONS = {"approved", "changes-required", "rejected"}
FINDING_DISPOSITIONS = {
    "open",
    "resolved",
    "accepted-with-rationale",
    "not-applicable",
}

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_review_evidence import canonical_digest, load_authored_units  # noqa: E402


class AssessmentReviewError(RuntimeError):
    """Raised when assessment review evidence is stale, incomplete, or unsafe."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssessmentReviewError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise AssessmentReviewError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise AssessmentReviewError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def build_plan() -> dict[str, Any]:
    unit_targets: list[dict[str, Any]] = []
    for _path, unit in load_authored_units():
        unit_id = unit.get("unit_id")
        require(isinstance(unit_id, str) and unit_id, "authored unit missing unit_id")
        unit_targets.append(
            {
                "target_id": f"{unit_id}-assessment-surface",
                "assessment_scope": "unit-assessment-surface",
                "unit_id": unit_id,
                "target_sha256": canonical_digest(unit),
                "binding": "complete-authored-unit-revision",
                "review_requirements": [
                    "unit quiz alignment and content validity",
                    "unit performance-task alignment and content validity",
                    "scoring/rubric quality",
                    "constructed-response handling",
                    "correction, reassessment, and appeal route",
                    "accessible/alternate response route",
                    "no automatic mastery, grade, or credit inference",
                ],
            }
        )
    unit_targets.sort(key=lambda target: target["unit_id"])
    require(len(unit_targets) == 9, f"expected 9 authored unit assessment targets, found {len(unit_targets)}")

    assessment = load_json(ASSESSMENT_PATH)
    coursewide = {
        "target_id": "mth1w-coursewide-assessment-plan",
        "assessment_scope": "coursewide-assessment-plan",
        "unit_id": None,
        "target_sha256": canonical_digest(assessment),
        "binding": ASSESSMENT_PATH.relative_to(ROOT).as_posix(),
        "review_requirements": [
            "entry diagnostic design and intended use",
            "three cumulative checkpoint designs",
            "final-assessment blueprint",
            "AA1/A1/A2 evidence expectations",
            "all 43 specific-expectation coverage structure",
            "content validity and construct representation",
            "scoring/rubric and constructed-response handling",
            "correction, reassessment, and appeal route",
            "accessibility/alternate response route",
            "no automatic mastery, grade, or credit inference",
        ],
    }
    targets = unit_targets + [coursewide]
    return {
        "schema": "axiom-education-mth1w-assessment-review-plan.v1",
        "course_code": "MTH1W",
        "status": "machine-generated-review-targets-no-human-approval",
        "target_count": len(targets),
        "claim_boundary": (
            "Targets bind future human assessment review to exact current authored units and the exact cumulative assessment plan. "
            "Generating the plan creates no assessment validity, scoring, mastery, grade, credit, or Ministry claim."
        ),
        "targets": targets,
    }


def target_index(plan: dict[str, Any] | None = None) -> dict[str, dict[str, Any]]:
    plan = plan or build_plan()
    targets = plan.get("targets")
    require(isinstance(targets, list), "assessment review plan targets missing")
    index: dict[str, dict[str, Any]] = {}
    for target in targets:
        require(isinstance(target, dict), "assessment review target must be an object")
        target_id = target.get("target_id")
        require(isinstance(target_id, str) and target_id, "assessment target_id missing")
        require(target_id not in index, f"duplicate assessment target_id: {target_id}")
        index[target_id] = target
    return index


def parse_timestamp(value: object) -> datetime:
    require(isinstance(value, str) and value, "reviewed_at must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise AssessmentReviewError("reviewed_at must be an ISO-8601 timestamp") from error
    require(parsed.tzinfo is not None, "reviewed_at must include a timezone")
    return parsed


def verify_review(
    path: Path,
    plan: dict[str, Any] | None = None,
) -> dict[str, Any]:
    review = load_json(path)
    index = target_index(plan)
    require(
        review.get("schema") == "axiom-education-assessment-review-evidence.v1",
        "unsupported assessment review schema",
    )
    require(review.get("course_code") == "MTH1W", "assessment review course mismatch")
    review_id = review.get("review_id")
    require(isinstance(review_id, str) and review_id, "assessment review_id is required")
    scope = review.get("assessment_scope")
    require(
        scope in {"unit-assessment-surface", "coursewide-assessment-plan"},
        "invalid assessment review scope",
    )

    target = review.get("target")
    require(isinstance(target, dict), "assessment review target is required")
    require(set(target) == {"target_id", "unit_id", "target_sha256"}, "assessment review target fields are invalid")
    target_id = target.get("target_id")
    require(isinstance(target_id, str) and target_id in index, "assessment review target is not current")
    current = index[target_id]
    require(scope == current["assessment_scope"], "assessment review scope does not match target")
    require(target.get("unit_id") == current["unit_id"], "assessment review unit binding mismatch")
    digest = target.get("target_sha256")
    require(isinstance(digest, str) and SHA256_RE.fullmatch(digest) is not None, "assessment target digest is invalid")
    require(digest == current["target_sha256"], "assessment review is stale: target content changed")

    reviewer = review.get("reviewer")
    require(isinstance(reviewer, dict), "assessment reviewer metadata is required")
    require(isinstance(reviewer.get("name"), str) and reviewer["name"].strip(), "assessment reviewer name is required")
    require(
        isinstance(reviewer.get("qualification"), str)
        and reviewer["qualification"].strip(),
        "assessment reviewer qualification is required",
    )
    parse_timestamp(review.get("reviewed_at"))

    decision = review.get("decision")
    require(decision in DECISIONS, "invalid assessment review decision")
    confirmations = review.get("confirmations")
    require(isinstance(confirmations, dict), "assessment review confirmations are required")
    require(set(confirmations) == CONFIRMATION_KEYS, "assessment review confirmations are incomplete")
    require(
        all(isinstance(value, bool) for value in confirmations.values()),
        "assessment review confirmations must be boolean",
    )

    findings = review.get("findings")
    require(isinstance(findings, list), "assessment review findings must be an array")
    seen: set[str] = set()
    open_findings = False
    unresolved_major = False
    for finding in findings:
        require(isinstance(finding, dict), "assessment finding must be an object")
        finding_id = finding.get("id")
        require(isinstance(finding_id, str) and finding_id, "assessment finding id is required")
        require(finding_id not in seen, f"duplicate assessment finding id: {finding_id}")
        seen.add(finding_id)
        severity = finding.get("severity")
        require(severity in {"note", "minor", "major", "critical"}, "invalid assessment finding severity")
        require(isinstance(finding.get("description"), str) and finding["description"], "assessment finding description is required")
        disposition = finding.get("disposition")
        require(disposition in FINDING_DISPOSITIONS, "invalid assessment finding disposition")
        open_findings = open_findings or disposition == "open"
        unresolved_major = unresolved_major or (
            severity in {"major", "critical"}
            and disposition not in {"resolved", "not-applicable"}
        )

    limitations = review.get("scope_limitations")
    require(
        isinstance(limitations, list) and all(isinstance(item, str) for item in limitations),
        "assessment scope_limitations must be strings",
    )
    require(
        review.get("attestation_type") == "human-assessment-review",
        "assessment review must be a human attestation",
    )

    if decision == "approved":
        require(all(confirmations.values()), "approved assessment review requires every confirmation")
        require(not open_findings, "approved assessment review cannot contain open findings")
        require(not unresolved_major, "approved assessment review cannot contain unresolved major/critical findings")
    return review


def verify_directory(directory: Path = REVIEW_DIR) -> dict[str, Any]:
    plan = build_plan()
    targets = target_index(plan)
    paths = sorted(directory.glob("*.json")) if directory.exists() else []
    seen_review_ids: set[str] = set()
    reviews_by_target: dict[str, list[tuple[datetime, dict[str, Any]]]] = {
        target_id: [] for target_id in targets
    }

    for path in paths:
        review = verify_review(path, plan)
        review_id = str(review["review_id"])
        require(review_id not in seen_review_ids, f"duplicate assessment review_id: {review_id}")
        seen_review_ids.add(review_id)
        target_id = str(review["target"]["target_id"])
        reviews_by_target[target_id].append((parse_timestamp(review["reviewed_at"]), review))

    latest: dict[str, dict[str, Any] | None] = {}
    approved_targets: list[str] = []
    for target_id, reviews in reviews_by_target.items():
        if not reviews:
            latest[target_id] = None
            continue
        ordered = sorted(reviews, key=lambda item: (item[0], str(item[1]["review_id"])))
        latest_review = ordered[-1][1]
        latest[target_id] = latest_review
        if latest_review["decision"] == "approved":
            approved_targets.append(target_id)

    all_approved = len(approved_targets) == len(targets)
    return {
        "targets": len(targets),
        "reviews": len(paths),
        "targets_with_any_review": sum(1 for value in latest.values() if value is not None),
        "latest_approved_targets": len(approved_targets),
        "all_current_targets_approved": all_approved,
        "unreviewed_target_ids": sorted(
            target_id for target_id, value in latest.items() if value is None
        ),
        "latest_nonapproved_target_ids": sorted(
            target_id
            for target_id, value in latest.items()
            if value is not None and value["decision"] != "approved"
        ),
    }


def verify_readiness_boundary(readiness_path: Path = READINESS_PATH) -> dict[str, Any]:
    readiness = load_json(readiness_path)
    summary = verify_directory()
    gates = readiness.get("required_gates")
    require(isinstance(gates, list), "curriculum readiness gates missing")
    gate_status = {
        item.get("id"): item.get("status")
        for item in gates
        if isinstance(item, dict)
    }
    current = gate_status.get("assessment-and-cumulative-review")
    if summary["all_current_targets_approved"]:
        require(
            current in {"blocked", "verified"},
            "assessment readiness gate has an invalid state",
        )
    else:
        require(
            current == "blocked",
            "assessment review gate cannot open before all current assessment targets are approved",
        )
    return summary


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    plan = commands.add_parser("plan")
    plan.add_argument("--output", type=Path)
    review = commands.add_parser("verify-review")
    review.add_argument("review", type=Path)
    commands.add_parser("verify-directory")
    commands.add_parser("verify-readiness")
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
                print(f"MTH1W assessment review plan written: {payload['target_count']} targets -> {args.output}")
            else:
                print(rendered, end="")
        elif args.command == "verify-review":
            review = verify_review(args.review)
            print(f"MTH1W assessment review verified: {review['review_id']} decision={review['decision']}")
        elif args.command == "verify-directory":
            print(json.dumps(verify_directory(), indent=2, sort_keys=True))
        else:
            print(json.dumps(verify_readiness_boundary(), indent=2, sort_keys=True))
    except (OSError, KeyError, AssessmentReviewError, ValueError) as error:
        print(f"MTH1W assessment review verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
