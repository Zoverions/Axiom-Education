#!/usr/bin/env python3
"""Probe whether an allowlisted curriculum source is repeatably recapturable.

This is observation tooling, not a promotion mechanism. It performs repeated captures of
one already-allowlisted source and emits metadata only. Changed bytes or failed requests
do not mean the curriculum changed. They mean the selected transport surface cannot be
treated as an immutable document for naive exact-byte drift monitoring until a stable
authoritative asset or separately reviewed canonicalization rule is resolved.
"""

from __future__ import annotations

import argparse
import json
import sys
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_lock import canonical_json_digest  # noqa: E402
from tools.remote_curriculum_source_capture import (  # noqa: E402
    RemoteCaptureError,
    capture,
    validate_target_registry,
)


class SourceStabilityError(RuntimeError):
    """Raised when stability probing violates the bounded observation contract."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SourceStabilityError(message)


def classify_observations(
    source_id: str, observations: list[dict[str, Any]]
) -> dict[str, Any]:
    require(len(observations) >= 2, "at least two observations are required")

    successful: list[dict[str, Any]] = []
    failed: list[dict[str, Any]] = []
    for item in observations:
        require(item.get("source_id") == source_id, "observation source_id mismatch")
        status = item.get("status")
        require(status in {"success", "error"}, "observation status is invalid")
        if status == "success":
            for field, expected in (
                ("sha256", str),
                ("byte_length", int),
                ("media_type", str),
                ("resolved_locator", str),
                ("source_entry_sha256", str),
            ):
                require(
                    isinstance(item.get(field), expected),
                    f"successful observation {field} missing",
                )
            successful.append(item)
        else:
            require(
                isinstance(item.get("error_type"), str) and item.get("error_type"),
                "failed observation error_type missing",
            )
            require(
                isinstance(item.get("error_message"), str)
                and item.get("error_message"),
                "failed observation error_message missing",
            )
            failed.append(item)

    signatures = {
        (
            item["sha256"],
            item["byte_length"],
            item["media_type"],
            item["resolved_locator"],
            item["source_entry_sha256"],
        )
        for item in successful
    }
    exact_bytes_stable = len(successful) >= 2 and len(signatures) == 1
    all_attempts_succeeded = len(failed) == 0
    recapturable_surface_stable = all_attempts_succeeded and exact_bytes_stable

    normalized: list[dict[str, Any]] = []
    for item in observations:
        if item["status"] == "success":
            normalized.append(
                {
                    "status": "success",
                    "sha256": item["sha256"],
                    "byte_length": item["byte_length"],
                    "media_type": item["media_type"],
                    "resolved_locator": item["resolved_locator"],
                    "source_entry_sha256": item["source_entry_sha256"],
                }
            )
        else:
            normalized.append(
                {
                    "status": "error",
                    "error_type": item["error_type"],
                    "error_message": item["error_message"],
                }
            )

    return {
        "schema": "axiom-curriculum-source-stability-observation.v1",
        "source_id": source_id,
        "attempt_count": len(observations),
        "successful_attempt_count": len(successful),
        "failed_attempt_count": len(failed),
        "all_attempts_succeeded": all_attempts_succeeded,
        "exact_bytes_stable_across_successful_attempts": exact_bytes_stable,
        "distinct_exact_byte_signatures": len(signatures),
        "recapturable_surface_stable": recapturable_surface_stable,
        "observations": normalized,
        "claim_boundary": (
            "This report observes repeatability and availability of the selected response surface only. "
            "Stable responses do not prove curriculum correctness or completeness. Changed bytes, HTTP "
            "errors, or other failed requests do not prove curriculum content changed; they require a more "
            "stable authoritative source surface or separately reviewed canonicalization before exact-byte "
            "drift can be interpreted semantically."
        ),
    }


def _success_observation(lock: dict[str, Any]) -> dict[str, Any]:
    return {
        "status": "success",
        "source_id": lock["source_id"],
        "sha256": lock["sha256"],
        "byte_length": lock["byte_length"],
        "media_type": lock["media_type"],
        "resolved_locator": lock["resolved_locator"],
        "source_entry_sha256": lock["source_entry_sha256"],
    }


def _error_observation(source_id: str, error: Exception) -> dict[str, Any]:
    return {
        "status": "error",
        "source_id": source_id,
        "error_type": type(error).__name__,
        "error_message": str(error),
    }


def probe(source_id: str, attempts: int, output: Path) -> dict[str, Any]:
    require(2 <= attempts <= 5, "attempts must be between 2 and 5")
    targets = validate_target_registry()
    target = targets.get(source_id)
    require(target is not None, f"source_id is not allowlisted: {source_id}")

    observations: list[dict[str, Any]] = []
    with tempfile.TemporaryDirectory(prefix="axiom-curriculum-stability-") as directory:
        root = Path(directory)
        for index in range(attempts):
            candidate = root / f"candidate-{index + 1}.json"
            try:
                observations.append(_success_observation(capture(source_id, candidate)))
            except (OSError, KeyError, RemoteCaptureError, ValueError) as error:
                observations.append(_error_observation(source_id, error))

    report = classify_observations(source_id, observations)
    report["capture_target_sha256"] = canonical_json_digest(target)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-id", required=True)
    parser.add_argument("--attempts", type=int, default=2)
    parser.add_argument("--output", required=True, type=Path)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        report = probe(args.source_id, args.attempts, args.output)
        print(
            f"source stability observed: {report['source_id']} "
            f"recapturable_surface_stable={report['recapturable_surface_stable']} "
            f"success={report['successful_attempt_count']}/{report['attempt_count']} "
            f"signatures={report['distinct_exact_byte_signatures']}"
        )
    except (OSError, KeyError, SourceStabilityError, ValueError) as error:
        print(f"curriculum source stability probe failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
