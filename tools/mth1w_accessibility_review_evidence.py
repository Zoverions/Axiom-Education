#!/usr/bin/env python3
"""Build and verify content-addressed human accessibility review evidence for MTH1W.

The plan separates 43 deterministic lesson-alternative targets from four learner-
application targets: Android, Windows, macOS, and iOS. Machine-generated
alternatives, software tests, and platform builds never constitute human
accessibility/usability approval. Historical negative reviews remain provenance,
and the latest valid review controls the current disposition for each exact target
revision.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
REVIEW_DIR = ROOT / "curriculum" / "reviews" / "mth1w-accessibility"
READINESS_PATH = ROOT / "config" / "curriculum-readiness.json"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
EXPECTED_LESSON_TARGETS = 43
APPLICATION_PLATFORMS = ("android", "windows", "macos", "ios")
EXPECTED_APPLICATION_TARGETS = len(APPLICATION_PLATFORMS)
EXPECTED_TARGETS = EXPECTED_LESSON_TARGETS + EXPECTED_APPLICATION_TARGETS
DECISIONS = {"approved", "changes-required", "rejected"}
FINDING_DISPOSITIONS = {
    "open",
    "resolved",
    "accepted-with-rationale",
    "not-applicable",
}
LESSON_CONFIRMATION_KEYS = {
    "assistive_document_compatibility_reviewed",
    "printable_offline_usability_reviewed",
    "nonvisual_equivalence_reviewed",
    "alternate_response_routes_reviewed",
    "cognitive_usability_reviewed",
}
APPLICATION_CONFIRMATION_KEYS = {
    "keyboard_navigation_reviewed",
    "screen_reader_navigation_reviewed",
    "text_scaling_reflow_reviewed",
    "contrast_and_noncolor_cues_reviewed",
    "motion_independence_reviewed",
    "focus_order_and_labels_reviewed",
    "cognitive_usability_reviewed",
}
APPLICATION_SURFACE_FILES = (
    "lib/main.dart",
    "lib/features/home/learner_home_screen.dart",
    "lib/features/curriculum/curriculum_library_screen.dart",
    "lib/features/curriculum/curriculum_course_reference_screen.dart",
    "lib/features/learning/home_learning_guide_screen.dart",
    "lib/features/learning/mth1w_course_screen.dart",
    "lib/features/learning/mth1w_learning_hub_screen.dart",
    "lib/features/learning/mth1w_draft_unit_screen.dart",
    "lib/features/learning/mth1w_split_draft_unit_screen.dart",
    "lib/features/practice/mth1w_practice_screen.dart",
)

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_accessible_export import verify_package  # noqa: E402
from tools.mth1w_review_evidence import canonical_digest  # noqa: E402


class AccessibilityReviewError(RuntimeError):
    """Raised when accessibility review evidence is stale, incomplete, or unsafe."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AccessibilityReviewError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise AccessibilityReviewError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise AccessibilityReviewError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def sha256_file(path: Path) -> str:
    try:
        return hashlib.sha256(path.read_bytes()).hexdigest()
    except OSError as error:
        raise AccessibilityReviewError(f"cannot read accessibility surface: {path}") from error


def _application_review_requirements(platform: str) -> list[str]:
    base = [
        "keyboard or equivalent non-touch navigation",
        "screen-reader navigation and labels",
        "text scaling and reflow",
        "contrast and non-colour cues",
        "motion independence/reduced-motion safety",
        "focus order and control labels",
        "cognitive usability across primary learner routes",
    ]
    platform_hint = {
        "android": "Android assistive-technology behaviour, including TalkBack or a documented equivalent",
        "windows": "Windows assistive-technology behaviour, including Narrator or a documented equivalent",
        "macos": "macOS assistive-technology behaviour, including VoiceOver or a documented equivalent",
        "ios": "iOS assistive-technology behaviour, including VoiceOver or a documented equivalent",
    }[platform]
    return [platform_hint, *base]


def build_plan() -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="axiom-accessibility-review-") as tmp:
        manifest = verify_package(Path(tmp))

    records = manifest.get("records")
    require(isinstance(records, list), "accessible export records missing")
    require(
        len(records) == EXPECTED_LESSON_TARGETS,
        f"expected {EXPECTED_LESSON_TARGETS} lesson export targets, found {len(records)}",
    )

    lesson_targets: list[dict[str, Any]] = []
    for record in records:
        require(isinstance(record, dict), "accessible export record must be an object")
        lesson_id = record.get("lesson_id")
        unit_id = record.get("unit_id")
        require(isinstance(lesson_id, str) and lesson_id, "accessible export lesson_id missing")
        require(isinstance(unit_id, str) and unit_id, f"{lesson_id}: unit_id missing")
        binding = {
            "lesson_id": lesson_id,
            "unit_id": unit_id,
            "source_lesson_sha256": record.get("source_lesson_sha256"),
            "student_sha256": record.get("student_sha256"),
            "answer_key_sha256": record.get("answer_key_sha256"),
            "format": record.get("format"),
        }
        for key in ("source_lesson_sha256", "student_sha256", "answer_key_sha256"):
            value = binding[key]
            require(
                isinstance(value, str) and SHA256_RE.fullmatch(value) is not None,
                f"{lesson_id}: invalid {key}",
            )
        require(
            binding["format"] == "text/markdown; charset=utf-8",
            f"{lesson_id}: unexpected accessibility export format",
        )
        lesson_targets.append(
            {
                "target_id": f"{lesson_id}-accessibility-alternative",
                "review_scope": "lesson-alternative",
                "lesson_id": lesson_id,
                "unit_id": unit_id,
                "platform": None,
                "target_sha256": canonical_digest(binding),
                "binding": binding,
                "review_requirements": [
                    "assistive-document compatibility",
                    "printable/offline usability",
                    "nonvisual equivalence",
                    "alternate response routes",
                    "cognitive usability and comprehension",
                ],
            }
        )
    lesson_targets.sort(key=lambda target: str(target["lesson_id"]))

    app_files: list[dict[str, str]] = []
    for relative in APPLICATION_SURFACE_FILES:
        path = ROOT / relative
        require(path.is_file(), f"learner application accessibility surface missing: {relative}")
        app_files.append({"path": relative, "sha256": sha256_file(path)})

    application_targets: list[dict[str, Any]] = []
    for platform in APPLICATION_PLATFORMS:
        app_binding = {
            "surface": "learner-application",
            "platform": platform,
            "files": app_files,
        }
        application_targets.append(
            {
                "target_id": f"mth1w-learner-application-accessibility-{platform}",
                "review_scope": "learner-application-surface",
                "lesson_id": None,
                "unit_id": None,
                "platform": platform,
                "target_sha256": canonical_digest(app_binding),
                "binding": app_binding,
                "review_requirements": _application_review_requirements(platform),
            }
        )

    targets = lesson_targets + application_targets
    require(len(targets) == EXPECTED_TARGETS, "accessibility review target count mismatch")
    return {
        "schema": "axiom-education-mth1w-accessibility-review-plan.v1",
        "course_code": "MTH1W",
        "status": "machine-generated-review-targets-no-human-approval",
        "target_count": len(targets),
        "lesson_alternative_targets": len(lesson_targets),
        "application_surface_targets": len(application_targets),
        "application_platforms": list(APPLICATION_PLATFORMS),
        "claim_boundary": (
            "Targets bind future human accessibility/usability review to exact current lesson alternatives and to separate Android, Windows, macOS, and iOS learner-app surfaces. "
            "Generating this plan, deterministic exports, green platform CI, or a debug/no-codesign build creates no WCAG, AODA, assistive-technology, usability, production-support, course-completion, or Ministry approval."
        ),
        "targets": targets,
    }


def target_index(plan: dict[str, Any] | None = None) -> dict[str, dict[str, Any]]:
    plan = plan or build_plan()
    targets = plan.get("targets")
    require(isinstance(targets, list), "accessibility review targets missing")
    index: dict[str, dict[str, Any]] = {}
    for target in targets:
        require(isinstance(target, dict), "accessibility review target must be an object")
        target_id = target.get("target_id")
        require(isinstance(target_id, str) and target_id, "accessibility target_id missing")
        require(target_id not in index, f"duplicate accessibility target_id: {target_id}")
        index[target_id] = target
    return index


def parse_timestamp(value: object) -> datetime:
    require(isinstance(value, str) and value, "reviewed_at must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise AccessibilityReviewError("reviewed_at must be an ISO-8601 timestamp") from error
    require(parsed.tzinfo is not None, "reviewed_at must include a timezone")
    return parsed


def required_confirmation_keys(scope: str) -> set[str]:
    if scope == "lesson-alternative":
        return LESSON_CONFIRMATION_KEYS
    if scope == "learner-application-surface":
        return APPLICATION_CONFIRMATION_KEYS
    raise AccessibilityReviewError(f"unsupported accessibility review scope: {scope}")


def verify_review(path: Path, plan: dict[str, Any] | None = None) -> dict[str, Any]:
    review = load_json(path)
    index = target_index(plan)
    require(
        review.get("schema") == "axiom-education-accessibility-review-evidence.v1",
        "unsupported accessibility review schema",
    )
    require(review.get("course_code") == "MTH1W", "accessibility review course mismatch")
    review_id = review.get("review_id")
    require(isinstance(review_id, str) and review_id, "accessibility review_id is required")
    scope = review.get("review_scope")
    require(
        scope in {"lesson-alternative", "learner-application-surface"},
        "invalid accessibility review scope",
    )

    target = review.get("target")
    require(isinstance(target, dict), "accessibility review target is required")
    require(
        set(target) == {"target_id", "lesson_id", "unit_id", "platform", "target_sha256"},
        "accessibility review target fields are invalid",
    )
    target_id = target.get("target_id")
    require(isinstance(target_id, str) and target_id in index, "accessibility review target is not current")
    current = index[target_id]
    require(scope == current["review_scope"], "accessibility review scope does not match target")
    require(target.get("lesson_id") == current["lesson_id"], "accessibility lesson binding mismatch")
    require(target.get("unit_id") == current["unit_id"], "accessibility unit binding mismatch")
    require(target.get("platform") == current["platform"], "accessibility platform binding mismatch")
    if scope == "lesson-alternative":
        require(target.get("platform") is None, "lesson accessibility review cannot claim an application platform")
    else:
        require(target.get("platform") in APPLICATION_PLATFORMS, "application accessibility platform is invalid")
    digest = target.get("target_sha256")
    require(
        isinstance(digest, str) and SHA256_RE.fullmatch(digest) is not None,
        "accessibility target digest is invalid",
    )
    require(digest == current["target_sha256"], "accessibility review is stale: target content changed")

    reviewer = review.get("reviewer")
    require(isinstance(reviewer, dict), "accessibility reviewer metadata is required")
    require(isinstance(reviewer.get("name"), str) and reviewer["name"].strip(), "accessibility reviewer name is required")
    require(
        isinstance(reviewer.get("qualification"), str) and reviewer["qualification"].strip(),
        "accessibility reviewer qualification is required",
    )
    parse_timestamp(review.get("reviewed_at"))

    environments = review.get("tested_environments")
    require(
        isinstance(environments, list)
        and environments
        and all(isinstance(item, str) and item.strip() for item in environments),
        "tested_environments must contain at least one human-tested environment",
    )

    decision = review.get("decision")
    require(decision in DECISIONS, "invalid accessibility review decision")
    confirmations = review.get("confirmations")
    require(isinstance(confirmations, dict), "accessibility review confirmations are required")
    expected_keys = required_confirmation_keys(str(scope))
    require(set(confirmations) == expected_keys, "accessibility review confirmations are incomplete or out of scope")
    require(
        all(isinstance(value, bool) for value in confirmations.values()),
        "accessibility review confirmations must be boolean",
    )

    findings = review.get("findings")
    require(isinstance(findings, list), "accessibility review findings must be an array")
    seen: set[str] = set()
    open_findings = False
    unresolved_major = False
    for finding in findings:
        require(isinstance(finding, dict), "accessibility finding must be an object")
        finding_id = finding.get("id")
        require(isinstance(finding_id, str) and finding_id, "accessibility finding id is required")
        require(finding_id not in seen, f"duplicate accessibility finding id: {finding_id}")
        seen.add(finding_id)
        severity = finding.get("severity")
        require(severity in {"note", "minor", "major", "critical"}, "invalid accessibility finding severity")
        require(
            isinstance(finding.get("description"), str) and finding["description"],
            "accessibility finding description is required",
        )
        disposition = finding.get("disposition")
        require(disposition in FINDING_DISPOSITIONS, "invalid accessibility finding disposition")
        open_findings = open_findings or disposition == "open"
        unresolved_major = unresolved_major or (
            severity in {"major", "critical"}
            and disposition not in {"resolved", "not-applicable"}
        )

    limitations = review.get("scope_limitations")
    require(
        isinstance(limitations, list) and all(isinstance(item, str) for item in limitations),
        "accessibility scope_limitations must be strings",
    )
    require(
        review.get("attestation_type") == "human-accessibility-usability-review",
        "accessibility review must be a human attestation",
    )

    if decision == "approved":
        require(all(confirmations.values()), "approved accessibility review requires every in-scope confirmation")
        require(not open_findings, "approved accessibility review cannot contain open findings")
        require(
            not unresolved_major,
            "approved accessibility review cannot contain unresolved major/critical findings",
        )
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
        require(review_id not in seen_review_ids, f"duplicate accessibility review_id: {review_id}")
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

    lesson_ids = {
        target_id
        for target_id, target in targets.items()
        if target["review_scope"] == "lesson-alternative"
    }
    application_ids = set(targets) - lesson_ids
    approved_application_platforms = sorted(
        str(targets[target_id]["platform"])
        for target_id in approved_targets
        if target_id in application_ids
    )
    return {
        "targets": len(targets),
        "lesson_alternative_targets": len(lesson_ids),
        "application_surface_targets": len(application_ids),
        "application_platforms": list(APPLICATION_PLATFORMS),
        "reviews": len(paths),
        "targets_with_any_review": sum(1 for value in latest.values() if value is not None),
        "latest_approved_targets": len(approved_targets),
        "latest_approved_lesson_alternatives": len(set(approved_targets) & lesson_ids),
        "latest_approved_application_surfaces": len(set(approved_targets) & application_ids),
        "latest_approved_application_platforms": approved_application_platforms,
        "all_current_targets_approved": len(approved_targets) == len(targets),
        "unreviewed_target_ids": sorted(target_id for target_id, value in latest.items() if value is None),
        "latest_nonapproved_target_ids": sorted(
            target_id
            for target_id, value in latest.items()
            if value is not None and value["decision"] != "approved"
        ),
    }


def verify_readiness_boundary(readiness_path: Path = READINESS_PATH) -> dict[str, Any]:
    readiness = load_json(readiness_path)
    summary = verify_directory()
    evidence = readiness.get("accessible_offline_delivery")
    require(isinstance(evidence, dict), "accessible_offline_delivery evidence is required")
    human = evidence.get("human_review_evidence")
    require(isinstance(human, dict), "accessibility human_review_evidence is required")
    require(
        human.get("schema_path") == "schemas/accessibility-review-evidence.v1.schema.json",
        "accessibility review schema path mismatch",
    )
    require(
        human.get("verification_tool") == "tools/mth1w_accessibility_review_evidence.py",
        "accessibility review verification tool mismatch",
    )
    require(human.get("content_addressed_targets") == summary["targets"], "accessibility target count claim mismatch")
    require(
        human.get("lesson_alternative_targets") == summary["lesson_alternative_targets"],
        "accessibility lesson target claim mismatch",
    )
    require(
        human.get("application_surface_targets") == summary["application_surface_targets"],
        "accessibility application target claim mismatch",
    )
    require(
        human.get("application_platforms") == summary["application_platforms"],
        "accessibility application platform claim mismatch",
    )
    require(human.get("submitted_review_records") == summary["reviews"], "accessibility review count claim mismatch")
    require(
        human.get("approved_current_targets") == summary["latest_approved_targets"],
        "accessibility approval count claim mismatch",
    )
    require(
        human.get("all_current_targets_approved") is summary["all_current_targets_approved"],
        "accessibility approval state claim mismatch",
    )

    gates = readiness.get("required_gates")
    require(isinstance(gates, list), "curriculum readiness gates missing")
    gate_status = {
        item.get("id"): item.get("status")
        for item in gates
        if isinstance(item, dict)
    }
    current = gate_status.get("accessible-alternatives")
    if summary["all_current_targets_approved"]:
        require(current in {"blocked", "verified"}, "accessibility readiness gate has an invalid state")
    else:
        require(
            current == "blocked",
            "accessibility gate cannot open before every current lesson and platform-specific application target is human-approved",
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
                print(f"MTH1W accessibility review plan written: {payload['target_count']} targets -> {args.output}")
            else:
                print(rendered, end="")
        elif args.command == "verify-review":
            review = verify_review(args.review)
            platform = review["target"].get("platform")
            suffix = f" platform={platform}" if platform else ""
            print(f"MTH1W accessibility review verified: {review['review_id']} decision={review['decision']}{suffix}")
        elif args.command == "verify-directory":
            print(json.dumps(verify_directory(), indent=2, sort_keys=True))
        else:
            print(json.dumps(verify_readiness_boundary(), indent=2, sort_keys=True))
    except (OSError, KeyError, AccessibilityReviewError, ValueError) as error:
        print(f"MTH1W accessibility review verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
