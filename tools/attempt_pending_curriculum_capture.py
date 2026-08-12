#!/usr/bin/env python3
"""Attempt a pending curriculum C1 capture without turning source unavailability into fake success.

Configuration/registry failures remain fatal. Once a target has passed validation, bounded
HTTP/content failures are recorded as metadata-only evidence and return a successful tool
exit so CI can represent `capture-unavailable` as a truthful source state rather than a
code failure. A produced C1 candidate is still only a candidate and is never committed or
promoted automatically.
"""

from __future__ import annotations

import argparse
import json
import sys
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


class PendingCaptureError(RuntimeError):
    """Raised for invalid pending-capture configuration, not source availability."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise PendingCaptureError(message)


def build_report(
    *,
    source_id: str,
    target: dict[str, Any],
    attempts: int,
    errors: list[Exception],
    candidate_produced: bool,
) -> dict[str, Any]:
    require(1 <= attempts <= 5, "attempts must be between 1 and 5")
    require(len(errors) <= attempts, "error count cannot exceed attempt count")
    require(
        candidate_produced or len(errors) == attempts,
        "unavailable result must account for every failed attempt",
    )
    return {
        "schema": "axiom-curriculum-pending-capture-attempt.v1",
        "source_id": source_id,
        "capture_target_sha256": canonical_json_digest(target),
        "attempt_count": attempts,
        "failed_attempt_count": len(errors),
        "candidate_produced": candidate_produced,
        "status": "candidate-produced" if candidate_produced else "capture-unavailable",
        "failures": [
            {
                "error_type": type(error).__name__,
                "error_message": str(error),
            }
            for error in errors
        ],
        "claim_boundary": (
            "This is bounded capture-attempt evidence only. `candidate-produced` does not promote C1 until the candidate is reviewed and deliberately committed. `capture-unavailable` does not prove the official source is invalid or the curriculum changed; it records that this runner could not obtain capturable bytes under the declared target policy."
        ),
    }


def attempt_capture(
    *,
    source_id: str,
    attempts: int,
    candidate_output: Path,
    status_output: Path,
) -> dict[str, Any]:
    require(1 <= attempts <= 5, "attempts must be between 1 and 5")
    targets = validate_target_registry()
    target = targets.get(source_id)
    require(target is not None, f"source_id is not a bounded capture target: {source_id}")

    errors: list[Exception] = []
    candidate_produced = False
    candidate_output.parent.mkdir(parents=True, exist_ok=True)
    for _ in range(attempts):
        candidate_output.unlink(missing_ok=True)
        try:
            capture(source_id, candidate_output)
            candidate_produced = True
            break
        except (OSError, KeyError, RemoteCaptureError, ValueError) as error:
            errors.append(error)

    report = build_report(
        source_id=source_id,
        target=target,
        attempts=attempts,
        errors=errors,
        candidate_produced=candidate_produced,
    )
    status_output.parent.mkdir(parents=True, exist_ok=True)
    status_output.write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-id", required=True)
    parser.add_argument("--attempts", type=int, default=3)
    parser.add_argument("--candidate-output", required=True, type=Path)
    parser.add_argument("--status-output", required=True, type=Path)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        report = attempt_capture(
            source_id=args.source_id,
            attempts=args.attempts,
            candidate_output=args.candidate_output,
            status_output=args.status_output,
        )
        print(
            f"pending curriculum capture observed: {report['source_id']} "
            f"status={report['status']} failed={report['failed_attempt_count']}/{report['attempt_count']}"
        )
    except (OSError, KeyError, PendingCaptureError, ValueError) as error:
        print(f"pending curriculum capture failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
