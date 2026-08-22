#!/usr/bin/env python3
"""Build MTH1W lesson review targets and verify human review evidence.

A review is valid only for the exact canonical lesson payload it names. Content changes
therefore make prior review evidence stale instead of silently carrying approval forward.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
READINESS_PATH = ROOT / "config" / "curriculum-readiness.json"
BLUEPRINT_PATH = ROOT / "curriculum" / "courses" / "ontario-mth1w-2021.course.json"
ASSESSMENT_PLAN_PATH = ROOT / "curriculum" / "courses" / "ontario-mth1w-2021.assessment-plan.json"
REVIEW_DIR = ROOT / "curriculum" / "reviews" / "mth1w"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ALLOWED_REVIEW_TYPES = {
    "educator-instructional",
    "cultural-context",
    "accessibility",
    "assessment-validity",
    "licensing",
}
ALLOWED_DECISIONS = {"approved", "changes-required", "rejected"}
ALLOWED_DISPOSITIONS = {"open", "resolved", "accepted-with-rationale", "not-applicable"}
APPROVAL_CONFIRMATIONS = {
    "expectation_binding_confirmed",
    "content_correctness_confirmed",
    "pedagogical_suitability_confirmed",
    "age_appropriateness_confirmed",
}

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.check_mth1w_split_unit_content import materialize_manifest  # noqa: E402


class ReviewEvidenceError(RuntimeError):
    """Raised when review targets or submitted review evidence are unsafe."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReviewEvidenceError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ReviewEvidenceError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise ReviewEvidenceError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def canonical_digest(value: Any) -> str:
    encoded = json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def repo_path(path: Path) -> str:
    return path.resolve().relative_to(ROOT.resolve()).as_posix()


def load_authored_units() -> list[tuple[Path, dict[str, Any]]]:
    readiness = load_json(READINESS_PATH)
    authored = readiness.get("authored_content")
    require(isinstance(authored, dict), "authored_content readiness evidence is missing")
    raw_paths = authored.get("unit_content_paths")
    require(isinstance(raw_paths, list) and raw_paths, "unit_content_paths must be non-empty")

    units: list[tuple[Path, dict[str, Any]]] = []
    seen_units: set[str] = set()
    for raw_path in raw_paths:
        require(isinstance(raw_path, str) and raw_path, "unit content path must be a repository path")
        path = (ROOT / raw_path).resolve()
        require(ROOT.resolve() in path.parents, f"unit path escapes repository: {raw_path}")
        require(path.is_file(), f"unit content is missing: {raw_path}")
        if path.name == "manifest.v1.json":
            unit = materialize_manifest(path)
        else:
            unit = load_json(path)
        unit_id = unit.get("unit_id")
        require(isinstance(unit_id, str) and unit_id, f"unit id missing: {raw_path}")
        require(unit_id not in seen_units, f"duplicate unit id: {unit_id}")
        seen_units.add(unit_id)
        units.append((path, unit))
    require(len(units) == 9, f"expected 9 authored units, found {len(units)}")
    return units


def required_review_types(unit: dict[str, Any]) -> list[str]:
    review = unit.get("review")
    require(isinstance(review, dict), f"unit {unit.get('unit_id')} review policy missing")
    types = ["educator-instructional", "accessibility"]
    if review.get("cultural_review_status") == "required":
        types.append("cultural-context")
    return types


def build_plan() -> dict[str, Any]:
    blueprint = load_json(BLUEPRINT_PATH)
    course = blueprint.get("course")
    require(isinstance(course, dict) and course.get("code") == "MTH1W", "MTH1W blueprint required")

    targets: list[dict[str, Any]] = []
    seen_lessons: set[str] = set()
    for source_path, unit in load_authored_units():
        unit_id = unit["unit_id"]
        lessons = unit.get("lessons")
        require(isinstance(lessons, list) and lessons, f"{unit_id}: lessons must be non-empty")
        review_types = required_review_types(unit)
        for lesson in lessons:
            require(isinstance(lesson, dict), f"{unit_id}: lesson must be an object")
            lesson_id = lesson.get("id")
            require(isinstance(lesson_id, str) and lesson_id, f"{unit_id}: lesson id missing")
            require(lesson_id not in seen_lessons, f"duplicate lesson id: {lesson_id}")
            seen_lessons.add(lesson_id)
            expectation_ids = lesson.get("official_expectation_ids")
            require(
                isinstance(expectation_ids, list)
                and expectation_ids
                and all(isinstance(item, str) and item for item in expectation_ids),
                f"{lesson_id}: official expectation ids missing",
            )
            targets.append(
                {
                    "kind": "lesson",
                    "unit_id": unit_id,
                    "lesson_id": lesson_id,
                    "artifact_path": repo_path(source_path),
                    "target_sha256": canonical_digest(lesson),
                    "official_expectation_ids": expectation_ids,
                    "required_review_types": review_types,
                }
            )

    require(len(targets) == 43, f"expected 43 lesson review targets, found {len(targets)}")
    return {
        "schema": "axiom-education-review-plan.v1",
        "course_code": "MTH1W",
        "claim_boundary": (
            "This plan identifies exact content-addressed human-review targets only. "
            "It contains no approval and does not promote curriculum readiness gates."
        ),
        "source_inventory_records_sha256": blueprint["source_inventory"]["records_sha256"],
        "course_blueprint_path": repo_path(BLUEPRINT_PATH),
        "course_blueprint_sha256": file_sha256(BLUEPRINT_PATH),
        "assessment_plan_path": repo_path(ASSESSMENT_PLAN_PATH),
        "assessment_plan_sha256": file_sha256(ASSESSMENT_PLAN_PATH),
        "target_count": len(targets),
        "targets": targets,
    }


def target_index(plan: dict[str, Any]) -> dict[str, dict[str, Any]]:
    targets = plan.get("targets")
    require(isinstance(targets, list), "review plan targets missing")
    index: dict[str, dict[str, Any]] = {}
    for target in targets:
        require(isinstance(target, dict), "review target must be an object")
        lesson_id = target.get("lesson_id")
        require(isinstance(lesson_id, str) and lesson_id, "review target lesson_id missing")
        require(lesson_id not in index, f"duplicate review target: {lesson_id}")
        index[lesson_id] = target
    return index


def validate_timestamp(value: object) -> None:
    require(isinstance(value, str), "reviewed_at must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ReviewEvidenceError("reviewed_at must be an ISO-8601 timestamp") from error
    require(parsed.tzinfo is not None, "reviewed_at must include a timezone")


def validate_findings(findings: object, *, approved: bool) -> list[dict[str, Any]]:
    require(isinstance(findings, list), "findings must be an array")
    seen_ids: set[str] = set()
    normalized: list[dict[str, Any]] = []
    for finding in findings:
        require(isinstance(finding, dict), "finding must be an object")
        finding_id = finding.get("id")
        require(isinstance(finding_id, str) and finding_id, "finding id is required")
        require(finding_id not in seen_ids, f"duplicate finding id: {finding_id}")
        seen_ids.add(finding_id)
        require(finding.get("severity") in {"note", "minor", "major", "critical"}, "invalid finding severity")
        require(isinstance(finding.get("category"), str) and finding["category"], "finding category required")
        require(isinstance(finding.get("description"), str) and finding["description"], "finding description required")
        disposition = finding.get("disposition")
        require(disposition in ALLOWED_DISPOSITIONS, "invalid finding disposition")
        if approved:
            require(disposition != "open", "approved review cannot contain open findings")
            if finding.get("severity") in {"major", "critical"}:
                require(
                    disposition == "resolved",
                    "approved review requires major/critical findings to be resolved",
                )
        normalized.append(finding)
    return normalized


def verify_review(review_path: Path, plan: dict[str, Any] | None = None) -> dict[str, Any]:
    review = load_json(review_path)
    plan = plan or build_plan()
    require(review.get("schema") == "axiom-education-content-review-evidence.v1", "unsupported review schema")
    require(review.get("course_code") == "MTH1W", "review course must be MTH1W")
    review_id = review.get("review_id")
    require(isinstance(review_id, str) and review_id, "review_id is required")
    review_type = review.get("review_type")
    require(review_type in ALLOWED_REVIEW_TYPES, "invalid review_type")

    target = review.get("target")
    require(isinstance(target, dict) and target.get("kind") == "lesson", "review target must be a lesson")
    lesson_id = target.get("lesson_id")
    require(isinstance(lesson_id, str) and lesson_id, "target lesson_id is required")
    current = target_index(plan).get(lesson_id)
    require(current is not None, f"review target is not in current MTH1W plan: {lesson_id}")
    require(target.get("unit_id") == current.get("unit_id"), "review target unit mismatch")
    target_sha = target.get("target_sha256")
    require(isinstance(target_sha, str) and SHA256_RE.fullmatch(target_sha) is not None, "invalid target digest")
    require(target_sha == current.get("target_sha256"), "review is stale: lesson content digest changed")
    require(
        review_type in current.get("required_review_types", []),
        f"review type is not a required lesson review for {lesson_id}",
    )

    reviewer = review.get("reviewer")
    require(isinstance(reviewer, dict), "reviewer metadata is required")
    require(isinstance(reviewer.get("name"), str) and reviewer["name"].strip(), "reviewer name is required")
    require(
        isinstance(reviewer.get("qualification"), str) and reviewer["qualification"].strip(),
        "reviewer qualification is required",
    )
    validate_timestamp(review.get("reviewed_at"))
    decision = review.get("decision")
    require(decision in ALLOWED_DECISIONS, "invalid review decision")

    confirmations = review.get("confirmations")
    require(isinstance(confirmations, dict), "review confirmations are required")
    require(set(confirmations) == APPROVAL_CONFIRMATIONS, "review confirmations are incomplete")
    require(all(isinstance(value, bool) for value in confirmations.values()), "review confirmations must be boolean")
    if decision == "approved" and review_type == "educator-instructional":
        require(all(confirmations.values()), "educator approval requires every instructional confirmation")

    validate_findings(review.get("findings"), approved=decision == "approved")
    limitations = review.get("scope_limitations")
    require(
        isinstance(limitations, list) and all(isinstance(item, str) for item in limitations),
        "scope_limitations must be an array of strings",
    )
    require(review.get("attestation_type") == "human-review", "review must be a human attestation")
    return review


def review_satisfies_target(review: dict[str, Any]) -> bool:
    return review.get("decision") == "approved"


def verify_directory(directory: Path = REVIEW_DIR) -> dict[str, int]:
    plan = build_plan()
    paths = sorted(path for path in directory.glob("*.json") if path.is_file()) if directory.exists() else []
    seen_review_ids: set[str] = set()
    approvals = 0
    negative = 0
    for path in paths:
        review = verify_review(path, plan)
        review_id = str(review["review_id"])
        require(review_id not in seen_review_ids, f"duplicate review_id: {review_id}")
        seen_review_ids.add(review_id)
        if review_satisfies_target(review):
            approvals += 1
        else:
            negative += 1
    return {"reviews": len(paths), "approvals": approvals, "negative_or_changes_required": negative}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    plan = subparsers.add_parser("plan", help="build the current deterministic lesson review plan")
    plan.add_argument("--output", type=Path)
    verify = subparsers.add_parser("verify", help="verify one submitted review")
    verify.add_argument("review", type=Path)
    verify_dir = subparsers.add_parser("verify-directory", help="verify submitted review records")
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
                print(f"review plan written: {args.output} ({plan['target_count']} lesson targets)")
            else:
                print(rendered, end="")
        elif args.command == "verify":
            review = verify_review(args.review)
            print(f"review verified: {review['review_id']} decision={review['decision']}")
        else:
            summary = verify_directory(args.directory)
            print(json.dumps(summary, indent=2, sort_keys=True))
    except (OSError, ReviewEvidenceError, KeyError, ValueError) as error:
        print(f"MTH1W review evidence verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
