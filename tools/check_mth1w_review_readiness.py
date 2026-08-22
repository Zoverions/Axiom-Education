#!/usr/bin/env python3
"""Bind MTH1W readiness review claims to current content targets and review records."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
READINESS_PATH = ROOT / "config" / "curriculum-readiness.json"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_review_evidence import build_plan, verify_directory  # noqa: E402


class ReviewReadinessError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReviewReadinessError(message)


def verify(path: Path = READINESS_PATH) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReviewReadinessError(f"cannot read curriculum readiness: {error}") from error
    require(isinstance(payload, dict), "curriculum readiness root must be an object")

    evidence = payload.get("human_review_evidence")
    require(isinstance(evidence, dict), "human_review_evidence section is required")
    require(
        evidence.get("schema_path") == "schemas/content-review-evidence.v1.schema.json",
        "human review schema path mismatch",
    )
    require(
        evidence.get("verification_tool") == "tools/mth1w_review_evidence.py",
        "human review verification tool mismatch",
    )
    require(
        evidence.get("verification_status") == "machine-verified-review-contract",
        "review contract must remain machine-verified only",
    )

    plan = build_plan()
    summary = verify_directory()
    require(
        evidence.get("content_addressed_lesson_targets") == plan.get("target_count"),
        "readiness lesson review target count does not match current content",
    )
    require(
        evidence.get("submitted_review_records") == summary["reviews"],
        "readiness submitted review count does not match evidence directory",
    )

    approved_educator = 0
    review_dir = ROOT / "curriculum" / "reviews" / "mth1w"
    if review_dir.exists():
        from tools.mth1w_review_evidence import verify_review

        for review_path in sorted(review_dir.glob("*.json")):
            review = verify_review(review_path, plan)
            if (
                review.get("review_type") == "educator-instructional"
                and review.get("decision") == "approved"
            ):
                approved_educator += 1
    require(
        evidence.get("approved_educator_instructional_reviews") == approved_educator,
        "readiness educator approval count does not match review evidence",
    )

    gate_satisfied = approved_educator == plan["target_count"] and plan["target_count"] == 43
    require(
        evidence.get("educator_review_gate_satisfied") is gate_satisfied,
        "readiness educator review gate state does not match evidence",
    )

    gates = payload.get("required_gates")
    require(isinstance(gates, list), "required_gates must be an array")
    gate_status = {
        item.get("id"): item.get("status")
        for item in gates
        if isinstance(item, dict)
    }
    if gate_satisfied:
        require(
            gate_status.get("educator-source-review") != "verified",
            "lesson approvals alone cannot promote the broader educator-source-review gate",
        )
    else:
        require(
            gate_status.get("educator-source-review") == "blocked",
            "educator-source-review must remain blocked without complete lesson approvals",
        )
    return payload


def main() -> int:
    try:
        payload = verify()
    except ReviewReadinessError as error:
        print(f"MTH1W review readiness verification failed: {error}", file=sys.stderr)
        return 1
    evidence = payload["human_review_evidence"]
    print(
        "MTH1W review readiness verified: "
        f"{evidence['approved_educator_instructional_reviews']}/"
        f"{evidence['content_addressed_lesson_targets']} educator lesson approvals; "
        f"gate_satisfied={evidence['educator_review_gate_satisfied']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
