#!/usr/bin/env python3
"""Verify fail-closed monitoring policy for committed Ontario Elementary C1 sources."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
POLICY_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-monitoring.v1.json"
TARGETS_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-capture-targets.v1.json"
LOCK_DIR = ROOT / "curriculum" / "ontario-elementary" / "source-locks"
ALLOWED_MODES = {"strict-exact-byte", "observational-response-surface"}


class SourceMonitoringError(RuntimeError):
    """Raised when source monitoring policy drifts from committed evidence."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SourceMonitoringError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise SourceMonitoringError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise SourceMonitoringError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(value, dict), f"JSON root must be object: {path}")
    return value


def verify_policy(
    path: Path = POLICY_PATH,
    targets_path: Path = TARGETS_PATH,
    lock_dir: Path = LOCK_DIR,
) -> dict[str, Any]:
    policy = load_json(path)
    require(
        policy.get("schema") == "axiom-curriculum-source-monitoring.v1",
        "unsupported source monitoring schema",
    )
    require(policy.get("jurisdiction_id") == "ca:on", "monitoring jurisdiction mismatch")
    require(
        isinstance(policy.get("claim_boundary"), str) and policy["claim_boundary"],
        "monitoring claim boundary is required",
    )

    targets = load_json(targets_path)
    target_index = {
        item["source_id"]: item
        for item in targets.get("targets", [])
        if isinstance(item, dict) and isinstance(item.get("source_id"), str)
    }
    require(target_index, "capture target registry must be non-empty")

    locks: dict[str, dict[str, Any]] = {}
    for lock_path in sorted(lock_dir.glob("*.json")):
        lock = load_json(lock_path)
        source_id = lock.get("source_id")
        require(isinstance(source_id, str) and source_id, f"lock missing source_id: {lock_path}")
        require(source_id not in locks, f"duplicate C1 lock source_id: {source_id}")
        locks[source_id] = lock

    require(
        set(locks).issubset(target_index),
        "every committed C1 source must retain a bounded capture target",
    )

    entries = policy.get("sources")
    require(isinstance(entries, list) and entries, "monitoring sources must be non-empty array")
    index: dict[str, dict[str, Any]] = {}
    for entry in entries:
        require(isinstance(entry, dict), "monitoring source entry must be object")
        source_id = entry.get("source_id")
        require(isinstance(source_id, str) and source_id, "monitoring source_id is required")
        require(source_id not in index, f"duplicate monitoring source_id: {source_id}")
        require(source_id in locks, f"monitoring source lacks committed C1 lock: {source_id}")
        require(source_id in target_index, f"monitoring source lacks capture target: {source_id}")
        mode = entry.get("monitoring_mode")
        require(mode in ALLOWED_MODES, f"invalid monitoring mode for {source_id}")
        require(entry.get("semantic_change_claimed") is False, f"monitoring cannot claim semantic change: {source_id}")
        require(isinstance(entry.get("reason"), str) and entry["reason"], f"monitoring reason required: {source_id}")

        target = target_index[source_id]
        lock = locks[source_id]
        require(
            target.get("expected_media_type") == lock.get("media_type"),
            f"target/lock media type mismatch: {source_id}",
        )
        if mode == "strict-exact-byte":
            require(
                target.get("expected_media_type") == "application/pdf",
                f"strict monitoring currently requires document-like PDF evidence: {source_id}",
            )
            require("observation" not in entry, f"strict source must not carry volatility observation: {source_id}")
        else:
            require(
                target.get("expected_media_type") == "text/html",
                f"observational response-surface mode currently requires HTML: {source_id}",
            )
            observation = entry.get("observation")
            require(isinstance(observation, dict), f"observation evidence required: {source_id}")
            require(
                isinstance(observation.get("attempt_count"), int)
                and observation["attempt_count"] >= 2,
                f"multi-attempt observation required: {source_id}",
            )
            require(
                isinstance(entry.get("promotion_blocker"), str) and entry["promotion_blocker"],
                f"observational source requires promotion blocker: {source_id}",
            )
        index[source_id] = entry

    require(
        set(index) == set(locks),
        "monitoring policy must account for every committed C1 source exactly",
    )

    pending_targets = sorted(set(target_index) - set(locks))
    strict = sorted(
        source_id
        for source_id, item in index.items()
        if item["monitoring_mode"] == "strict-exact-byte"
    )
    observational = sorted(
        source_id
        for source_id, item in index.items()
        if item["monitoring_mode"] == "observational-response-surface"
    )
    return {
        "sources": len(index),
        "capture_targets": len(target_index),
        "pending_capture_targets": pending_targets,
        "strict_exact_byte": strict,
        "observational_response_surface": observational,
    }


def main() -> int:
    try:
        result = verify_policy()
        print(
            "curriculum source monitoring verified: "
            f"monitored={result['sources']} targets={result['capture_targets']} "
            f"pending={len(result['pending_capture_targets'])} "
            f"strict={len(result['strict_exact_byte'])} "
            f"observational={len(result['observational_response_surface'])}"
        )
    except (OSError, KeyError, SourceMonitoringError, ValueError) as error:
        print(f"curriculum source monitoring verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
