#!/usr/bin/env python3
"""Probe whether an allowlisted curriculum source returns stable exact bytes.

This is observation tooling, not a promotion mechanism. It performs repeated captures of
one already-allowlisted source and emits metadata only. A byte-unstable result does not
mean the curriculum changed; it means the selected transport surface is unsuitable for
naive exact-byte drift monitoring until a stable authoritative asset or a separately
reviewed canonicalization rule is resolved.
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
    """Raised when stability probing cannot produce bounded observations."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SourceStabilityError(message)


def classify_observations(source_id: str, observations: list[dict[str, Any]]) -> dict[str, Any]:
    require(len(observations) >= 2, "at least two observations are required")
    for item in observations:
        require(item.get("source_id") == source_id, "observation source_id mismatch")
        require(isinstance(item.get("sha256"), str), "observation sha256 missing")
        require(isinstance(item.get("byte_length"), int), "observation byte_length missing")
        require(isinstance(item.get("media_type"), str), "observation media_type missing")
        require(isinstance(item.get("resolved_locator"), str), "observation resolved_locator missing")
        require(isinstance(item.get("source_entry_sha256"), str), "observation source binding missing")

    signatures = {
        (
            item["sha256"],
            item["byte_length"],
            item["media_type"],
            item["resolved_locator"],
            item["source_entry_sha256"],
        )
        for item in observations
    }
    stable = len(signatures) == 1
    return {
        "schema": "axiom-curriculum-source-stability-observation.v1",
        "source_id": source_id,
        "attempt_count": len(observations),
        "exact_bytes_stable_across_attempts": stable,
        "distinct_exact_byte_signatures": len(signatures),
        "observations": [
            {
                "sha256": item["sha256"],
                "byte_length": item["byte_length"],
                "media_type": item["media_type"],
                "resolved_locator": item["resolved_locator"],
                "source_entry_sha256": item["source_entry_sha256"],
            }
            for item in observations
        ],
        "claim_boundary": (
            "This report observes repeatability of exact response bytes only. Stable bytes do not prove "
            "curriculum correctness or completeness. Unstable bytes do not prove curriculum content changed; "
            "they require a more stable authoritative source surface or separately reviewed canonicalization "
            "before exact-byte drift can be interpreted semantically."
        ),
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
            observations.append(capture(source_id, candidate))

    report = classify_observations(source_id, observations)
    report["capture_target_sha256"] = canonical_json_digest(target)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
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
            f"stable={report['exact_bytes_stable_across_attempts']} "
            f"signatures={report['distinct_exact_byte_signatures']}"
        )
    except (OSError, KeyError, RemoteCaptureError, SourceStabilityError, ValueError) as error:
        print(f"curriculum source stability probe failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
