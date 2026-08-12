#!/usr/bin/env python3
"""Bind MTH1W licensing readiness claims to current source-use and review evidence."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
READINESS_PATH = ROOT / "config" / "curriculum-readiness.json"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_source_use_inventory import build_inventory, verify_reviews  # noqa: E402


class LicensingReadinessError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise LicensingReadinessError(message)


def verify(path: Path = READINESS_PATH) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise LicensingReadinessError(f"cannot read curriculum readiness: {error}") from error
    require(isinstance(payload, dict), "curriculum readiness root must be an object")

    evidence = payload.get("source_use_licensing")
    require(isinstance(evidence, dict), "source_use_licensing evidence is required")
    require(evidence.get("schema_path") == "schemas/source-license-review.v1.schema.json", "source licensing schema path mismatch")
    require(evidence.get("verification_tool") == "tools/mth1w_source_use_inventory.py", "source-use verification tool mismatch")
    require(evidence.get("verification_status") == "machine-verified-source-use-inventory", "source-use inventory status mismatch")
    require(evidence.get("human_licensing_review_status") == "required", "machine inventory must not claim human licensing review")

    inventory = build_inventory()
    summary = verify_reviews()
    require(inventory.get("unit_count") == 9, "source-use inventory must cover all nine authored units")
    require(summary["sources"] == inventory["source_count"], "source-use review source count mismatch")
    require(evidence.get("submitted_review_records") == summary["reviews"], "readiness licensing review count does not match evidence")
    require(evidence.get("permitted_as_used_reviews") == summary["permitted_as_used"], "readiness permitted-source count does not match evidence")

    external_complete = summary["sources"] > 0 and summary["unreviewed"] == 0 and summary["permitted_as_used"] == summary["sources"]
    require(evidence.get("external_source_use_reviews_complete") is external_complete, "external-source licensing completion state does not match evidence")

    # External source notes are only one licensing scope. This checker intentionally
    # cannot promote the full gate because shipped quotations/assets/exports and future
    # additions require their own reviewed evidence.
    require(evidence.get("licensing_gate_satisfied") is False, "external source-use reviews alone cannot satisfy the full licensing gate")

    gates = payload.get("required_gates")
    require(isinstance(gates, list), "required_gates must be an array")
    gate_status = {
        item.get("id"): item.get("status")
        for item in gates
        if isinstance(item, dict)
    }
    require(
        gate_status.get("licensing-and-redistribution-review") == "blocked",
        "licensing-and-redistribution-review must remain blocked without broader asset/export evidence",
    )
    return payload


def main() -> int:
    try:
        payload = verify()
    except LicensingReadinessError as error:
        print(f"MTH1W licensing readiness verification failed: {error}", file=sys.stderr)
        return 1
    evidence = payload["source_use_licensing"]
    print(
        "MTH1W licensing readiness verified: "
        f"reviews={evidence['submitted_review_records']}; "
        f"permitted_as_used={evidence['permitted_as_used_reviews']}; "
        "full licensing gate remains blocked"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
