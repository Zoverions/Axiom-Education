#!/usr/bin/env python3
"""Bind MTH1W accessibility readiness claims to deterministic alternate delivery evidence."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
READINESS_PATH = ROOT / "config" / "curriculum-readiness.json"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_accessible_export import EXPECTED_LESSONS, verify_determinism  # noqa: E402


class AccessibilityReadinessError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AccessibilityReadinessError(message)


def verify(path: Path = READINESS_PATH) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise AccessibilityReadinessError(f"cannot read curriculum readiness: {error}") from error
    require(isinstance(payload, dict), "curriculum readiness root must be an object")

    evidence = payload.get("accessible_offline_delivery")
    require(isinstance(evidence, dict), "accessible_offline_delivery evidence is required")
    require(
        evidence.get("verification_tool") == "tools/mth1w_accessible_export.py",
        "accessibility verification tool mismatch",
    )
    require(
        evidence.get("verification_status") == "machine-verified-draft-alternative",
        "accessible delivery evidence must remain draft",
    )
    require(evidence.get("lesson_exports") == EXPECTED_LESSONS, "accessibility lesson coverage claim mismatch")
    require(evidence.get("student_and_answer_key_separated") is True, "student/answer-key separation claim missing")
    require(evidence.get("format") == "text/markdown; charset=utf-8", "accessible export format mismatch")
    require(evidence.get("deterministic_build") is True, "accessible export must be deterministic")
    require(evidence.get("printable_equivalent_required") is True, "printable-equivalent requirement missing")
    require(evidence.get("nonvisual_route_required") is True, "nonvisual-route requirement missing")
    require(
        evidence.get("representation_text_alternatives_required") is True,
        "representation text-alternative requirement missing",
    )
    require(
        evidence.get("human_accessibility_review_status") == "required",
        "machine export must not claim human accessibility review",
    )
    require(evidence.get("accessibility_gate_satisfied") is False, "machine export cannot satisfy accessibility gate")

    manifest = verify_determinism()
    require(manifest.get("lesson_count") == EXPECTED_LESSONS, "deterministic export coverage does not match readiness")
    require(manifest.get("human_accessibility_review_status") == "required", "export manifest must preserve human review requirement")

    gates = payload.get("required_gates")
    require(isinstance(gates, list), "required_gates must be an array")
    gate_status = {
        item.get("id"): item.get("status")
        for item in gates
        if isinstance(item, dict)
    }
    require(
        gate_status.get("accessible-alternatives") == "blocked",
        "machine-readable accessibility alternatives must not unlock human accessibility gate",
    )
    return payload


def main() -> int:
    try:
        payload = verify()
    except AccessibilityReadinessError as error:
        print(f"MTH1W accessibility readiness verification failed: {error}", file=sys.stderr)
        return 1
    evidence = payload["accessible_offline_delivery"]
    print(
        "MTH1W accessibility readiness verified: "
        f"{evidence['lesson_exports']} deterministic lesson alternatives; human review still required"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
