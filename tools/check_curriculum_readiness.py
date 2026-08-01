#!/usr/bin/env python3
"""Fail closed when curriculum readiness could be mistaken for course completion."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
READINESS_PATH = ROOT / "config" / "curriculum-readiness.json"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
EXPECTED_INVENTORY_RECORDS_SHA256 = (
    "d023c3ee1e441c13d0b8ca6bd9a87f9b6004766f92182303385511b517642766"
)
REQUIRED_GATES = {
    "official-expectation-inventory",
    "educator-source-review",
    "licensing-and-redistribution-review",
    "lesson-and-practice-coverage",
    "assessment-and-cumulative-review",
    "accessible-alternatives",
    "governed-progress-and-educator-workflow",
}
EXPECTED_GATE_STATUS = {
    "official-expectation-inventory": "verified",
    "educator-source-review": "blocked",
    "licensing-and-redistribution-review": "blocked",
    "lesson-and-practice-coverage": "blocked",
    "assessment-and-cumulative-review": "blocked",
    "accessible-alternatives": "blocked",
    "governed-progress-and-educator-workflow": "blocked",
}
REQUIRED_SEQUENCE = [
    "complete-and-verify-mth1w",
    "complete-remaining-grade-9-courses",
    "advance-through-later-grades-in-order",
]


class ReadinessError(RuntimeError):
    """Raised when the readiness declaration is incomplete or unsafe."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReadinessError(message)


def verify(path: Path = READINESS_PATH) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ReadinessError(f"missing curriculum readiness file: {path}") from error
    except json.JSONDecodeError as error:
        raise ReadinessError(f"invalid curriculum readiness JSON: {error}") from error

    require(isinstance(payload, dict), "readiness root must be an object")
    require(
        payload.get("schema") == "axiom-education-curriculum-readiness.v1",
        "unsupported curriculum readiness schema",
    )

    course = payload.get("course")
    require(isinstance(course, dict), "course readiness must be an object")
    require(course.get("code") == "MTH1W", "MTH1W must be the first course")
    require(
        course.get("student_label") == "Grade 9 Math Foundations Preview",
        "student label must disclose the foundations preview",
    )
    require(
        course.get("claim_status") == "blocked_pending_source_review",
        "course claim must remain blocked pending source review",
    )
    require(
        course.get("complete_course_claim_allowed") is False,
        "complete MTH1W claims must fail closed",
    )

    source = payload.get("official_source")
    require(isinstance(source, dict), "official source must be an object")
    require(
        source.get("authority") == "Ontario Ministry of Education",
        "official source authority mismatch",
    )
    source_url = source.get("url")
    require(
        isinstance(source_url, str) and source_url.startswith("https://"),
        "official source must use HTTPS",
    )
    source_sha = source.get("sha256")
    require(
        isinstance(source_sha, str) and SHA256_RE.fullmatch(source_sha) is not None,
        "official source SHA-256 is missing or invalid",
    )

    inventory = payload.get("official_inventory")
    require(isinstance(inventory, dict), "official inventory evidence must be an object")
    require(
        inventory.get("path")
        == "curriculum/official/ontario-mth1w-2021.inventory.json",
        "official inventory path mismatch",
    )
    require(
        inventory.get("verification_status")
        == "source-digest-and-layout-verified",
        "official inventory is not source verified",
    )
    require(
        inventory.get("counts")
        == {"overall": 14, "specific": 43, "total": 57},
        "official inventory counts are incorrect",
    )
    inventory_sha = inventory.get("records_sha256")
    require(
        isinstance(inventory_sha, str)
        and SHA256_RE.fullmatch(inventory_sha) is not None,
        "official inventory records digest is missing or invalid",
    )
    require(
        inventory_sha == EXPECTED_INVENTORY_RECORDS_SHA256,
        "official inventory records digest mismatch",
    )
    require(
        inventory.get("verbatim_expectation_text_included") is False,
        "readiness inventory must not claim verbatim text redistribution",
    )

    local_snapshot = payload.get("local_snapshot")
    require(isinstance(local_snapshot, dict), "local snapshot must be an object")
    require(local_snapshot.get("record_count") == 11, "local snapshot count changed")
    require(
        local_snapshot.get("allowed_use") == "foundations_preview_only",
        "local snapshot use must remain preview-only",
    )

    conflicts = payload.get("known_conflicts")
    require(isinstance(conflicts, list) and len(conflicts) >= 2, "known source conflicts missing")
    conflict_ids = {
        item.get("local_id") for item in conflicts if isinstance(item, dict)
    }
    require(
        {"MTH1W-B2", "MTH1W-B4"}.issubset(conflict_ids),
        "known MTH1W identifier conflicts are incomplete",
    )

    gates = payload.get("required_gates")
    require(isinstance(gates, list), "required gates must be an array")
    gate_status = {
        item.get("id"): item.get("status") for item in gates if isinstance(item, dict)
    }
    require(set(gate_status) == REQUIRED_GATES, "curriculum readiness gates are incomplete")
    require(
        gate_status == EXPECTED_GATE_STATUS,
        "a curriculum gate status does not match the available evidence",
    )
    require(
        payload.get("delivery_sequence") == REQUIRED_SEQUENCE,
        "course delivery sequence must finish MTH1W, then Grade 9, then later grades",
    )
    return payload


def main() -> int:
    try:
        payload = verify()
    except (OSError, ReadinessError) as error:
        print(f"curriculum readiness verification failed: {error}", file=sys.stderr)
        return 1

    print(
        "curriculum readiness verified: "
        f"{payload['course']['student_label']}; complete-course claim blocked"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
