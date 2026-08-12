#!/usr/bin/env python3
"""Compare a freshly captured C1 candidate with any committed lock for that source.

Capture timestamps and run notes may change. Source bytes, byte length, media type,
source-entry binding, and resolved locator may not change silently once a source is locked.
A genuinely changed upstream source therefore becomes an explicit review event.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LOCK_DIR = ROOT / "curriculum" / "ontario-elementary" / "source-locks"
DEFAULT_DISCOVERY = ROOT / "curriculum" / "ontario-elementary" / "source-discovery.v0.json"
BOUND_FIELDS = (
    "source_id",
    "jurisdiction_id",
    "authority_id",
    "source_entry_sha256",
    "source_locator",
    "resolved_locator",
    "media_type",
    "byte_length",
    "sha256",
    "bytes_retained",
    "retained_path",
    "redistribution_status",
    "claim_state",
)

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_lock import SourceLockError, verify_lock  # noqa: E402


class SourceLockDriftError(RuntimeError):
    """Raised when a fresh source capture differs from committed C1 evidence."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SourceLockDriftError(message)


def load_committed(lock_dir: Path) -> dict[str, tuple[Path, dict[str, Any]]]:
    index: dict[str, tuple[Path, dict[str, Any]]] = {}
    if not lock_dir.exists():
        return index
    for path in sorted(lock_dir.glob("*.json")):
        lock = verify_lock(path, DEFAULT_DISCOVERY)
        source_id = lock.get("source_id")
        require(isinstance(source_id, str) and source_id, f"{path}: source_id missing")
        require(source_id not in index, f"duplicate committed source lock: {source_id}")
        index[source_id] = (path, lock)
    return index


def compare_candidate(
    candidate_path: Path,
    lock_dir: Path = DEFAULT_LOCK_DIR,
    *,
    allow_uncommitted: bool = False,
) -> dict[str, Any]:
    candidate = verify_lock(candidate_path, DEFAULT_DISCOVERY)
    source_id = candidate.get("source_id")
    require(isinstance(source_id, str) and source_id, "candidate source_id missing")
    committed_index = load_committed(lock_dir)
    committed_entry = committed_index.get(source_id)
    if committed_entry is None:
        require(
            allow_uncommitted,
            f"fresh capture has no committed C1 lock: {source_id}",
        )
        return {
            "source_id": source_id,
            "status": "new-uncommitted-candidate",
            "candidate_sha256": candidate["sha256"],
            "candidate_byte_length": candidate["byte_length"],
        }

    committed_path, committed = committed_entry
    drift: dict[str, dict[str, Any]] = {}
    for field in BOUND_FIELDS:
        if candidate.get(field) != committed.get(field):
            drift[field] = {
                "committed": committed.get(field),
                "candidate": candidate.get(field),
            }
    require(
        not drift,
        "upstream/source-binding drift detected for "
        f"{source_id}: {json.dumps(drift, sort_keys=True)}",
    )
    return {
        "source_id": source_id,
        "status": "matches-committed-lock",
        "committed_path": committed_path.relative_to(ROOT).as_posix(),
        "sha256": candidate["sha256"],
        "byte_length": candidate["byte_length"],
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--lock-dir", type=Path, default=DEFAULT_LOCK_DIR)
    parser.add_argument("--allow-uncommitted", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        result = compare_candidate(
            args.candidate,
            args.lock_dir,
            allow_uncommitted=args.allow_uncommitted,
        )
    except (OSError, SourceLockError, SourceLockDriftError, ValueError) as error:
        print(f"curriculum source-lock drift verification failed: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
