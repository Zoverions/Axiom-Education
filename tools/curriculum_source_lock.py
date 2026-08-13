#!/usr/bin/env python3
"""Create and verify digest-bound curriculum source locks without storing source bytes.

C1 means exact bytes were captured and hashed. It does not mean the source is licensed
for redistribution, parsed correctly, human reviewed, signed, staged, or active.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_discovery import (  # noqa: E402
    SourceDiscoveryError,
    load_effective_discovery,
)
from tools.json_schema_validation import (  # noqa: E402
    RepositoryJsonSchemaError,
    validate_json_schema,
)

DEFAULT_DISCOVERY = ROOT / "curriculum" / "ontario-elementary" / "source-discovery.v0.json"
DEFAULT_LOCK_DIR = ROOT / "curriculum" / "ontario-elementary" / "source-locks"
SOURCE_LOCK_SCHEMA = ROOT / "schemas" / "curriculum-source-lock.v1.schema.json"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ALLOWED_REDISTRIBUTION = {
    "review-required",
    "external-only",
    "redistributable-reviewed",
}


class SourceLockError(RuntimeError):
    """Raised when source-lock evidence is incomplete or inconsistent."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SourceLockError(message)


def canonical_json_digest(value: Any) -> str:
    payload = json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def file_digest(path: Path) -> tuple[str, int]:
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            size += len(chunk)
            digest.update(chunk)
    require(size > 0, "captured source file must not be empty")
    return digest.hexdigest(), size


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise SourceLockError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise SourceLockError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def load_discovery(path: Path) -> dict[str, Any]:
    try:
        return load_effective_discovery(path)
    except SourceDiscoveryError as error:
        raise SourceLockError(str(error)) from error


def find_source(discovery: dict[str, Any], source_id: str) -> dict[str, Any]:
    sources = discovery.get("confirmed_curriculum_sources")
    require(isinstance(sources, list), "confirmed curriculum sources must be an array")
    matches = [
        item
        for item in sources
        if isinstance(item, dict) and item.get("source_id") == source_id
    ]
    require(len(matches) == 1, f"source_id must resolve exactly once: {source_id}")
    return matches[0]


def source_locators(source: dict[str, Any]) -> set[str]:
    locators: set[str] = set()
    for key, value in source.items():
        if (key == "url" or key.endswith("_url")) and isinstance(value, str):
            if value.startswith("https://"):
                locators.add(value)
    return locators


def validate_timestamp(value: object) -> None:
    require(isinstance(value, str), "captured_at must be an ISO-8601 timestamp")
    normalized = value.replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError as error:
        raise SourceLockError("captured_at must be an ISO-8601 timestamp") from error
    require(parsed.tzinfo is not None, "captured_at must include a timezone")


def verify_lock(
    lock_path: Path,
    discovery_path: Path = DEFAULT_DISCOVERY,
    *,
    verify_retained_bytes: bool = True,
) -> dict[str, Any]:
    lock = load_json(lock_path)
    try:
        validate_json_schema(lock, SOURCE_LOCK_SCHEMA, label=str(lock_path))
    except RepositoryJsonSchemaError as error:
        raise SourceLockError(str(error)) from error
    discovery = load_discovery(discovery_path)

    require(lock.get("schema") == "axiom-curriculum-source-lock.v1", "unsupported source-lock schema")
    source_id = lock.get("source_id")
    require(isinstance(source_id, str) and source_id, "source_id is required")
    source = find_source(discovery, source_id)

    require(lock.get("jurisdiction_id") == discovery.get("jurisdiction_id"), "jurisdiction_id mismatch")
    require(lock.get("authority_id") == discovery.get("authority_id"), "authority_id mismatch")

    expected_discovery_path = discovery_path.resolve().relative_to(ROOT.resolve()).as_posix()
    require(lock.get("discovery_path") == expected_discovery_path, "discovery_path mismatch")
    require(
        lock.get("source_entry_sha256") == canonical_json_digest(source),
        "source entry changed after capture; recapture or review the lock",
    )

    require(lock.get("capture_method") == "local-file-hash", "unsupported capture_method")
    validate_timestamp(lock.get("captured_at"))

    source_locator = lock.get("source_locator")
    require(
        isinstance(source_locator, str) and source_locator.startswith("https://"),
        "source_locator must use HTTPS",
    )
    require(
        source_locator in source_locators(source),
        "source_locator must be one of the official locators recorded in discovery",
    )
    resolved_locator = lock.get("resolved_locator")
    require(
        isinstance(resolved_locator, str) and resolved_locator.startswith("https://"),
        "resolved_locator must use HTTPS",
    )

    media_type = lock.get("media_type")
    require(isinstance(media_type, str) and media_type.strip(), "media_type is required")
    byte_length = lock.get("byte_length")
    require(isinstance(byte_length, int) and byte_length > 0, "byte_length must be positive")
    sha256 = lock.get("sha256")
    require(isinstance(sha256, str) and SHA256_RE.fullmatch(sha256) is not None, "invalid source SHA-256")

    require(isinstance(lock.get("bytes_retained"), bool), "bytes_retained must be boolean")
    retained_path = lock.get("retained_path")
    if lock["bytes_retained"]:
        require(isinstance(retained_path, str) and retained_path, "retained_path required when bytes are retained")
        retained = ROOT / retained_path
        require(retained.is_file(), f"retained source bytes missing: {retained_path}")
        if verify_retained_bytes:
            retained_digest, retained_size = file_digest(retained)
            require(retained_digest == sha256, "retained source digest mismatch")
            require(retained_size == byte_length, "retained source byte length mismatch")
    else:
        require(retained_path in (None, ""), "retained_path must be null when bytes are not retained")

    redistribution = lock.get("redistribution_status")
    require(redistribution in ALLOWED_REDISTRIBUTION, "invalid redistribution_status")
    require(
        redistribution != "redistributable-reviewed" or lock["bytes_retained"],
        "redistributable-reviewed evidence may not claim retained bytes are absent",
    )
    require(lock.get("claim_state") == "C1-bytes-captured-digested", "claim_state must remain C1")
    return lock


def create_lock(
    *,
    source_id: str,
    input_path: Path,
    source_locator: str,
    resolved_locator: str,
    media_type: str,
    discovery_path: Path,
    redistribution_status: str,
    retained_path: str | None,
    notes: str | None,
) -> dict[str, Any]:
    discovery = load_discovery(discovery_path)
    source = find_source(discovery, source_id)
    require(source_locator in source_locators(source), "source_locator is not recorded in discovery")
    require(resolved_locator.startswith("https://"), "resolved_locator must use HTTPS")
    require(redistribution_status in ALLOWED_REDISTRIBUTION, "invalid redistribution_status")
    digest, size = file_digest(input_path)

    if retained_path is not None:
        retained = (ROOT / retained_path).resolve()
        require(retained.is_file(), "retained_path must already exist inside the repository")
        require(ROOT.resolve() in retained.parents, "retained_path must stay inside the repository")
        retained_digest, retained_size = file_digest(retained)
        require(retained_digest == digest and retained_size == size, "retained bytes differ from captured input")

    relative_discovery = discovery_path.resolve().relative_to(ROOT.resolve()).as_posix()
    return {
        "schema": "axiom-curriculum-source-lock.v1",
        "source_id": source_id,
        "jurisdiction_id": discovery["jurisdiction_id"],
        "authority_id": discovery["authority_id"],
        "discovery_path": relative_discovery,
        "source_entry_sha256": canonical_json_digest(source),
        "capture_method": "local-file-hash",
        "captured_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "source_locator": source_locator,
        "resolved_locator": resolved_locator,
        "media_type": media_type,
        "byte_length": size,
        "sha256": digest,
        "bytes_retained": retained_path is not None,
        "retained_path": retained_path,
        "redistribution_status": redistribution_status,
        "claim_state": "C1-bytes-captured-digested",
        **({"notes": notes} if notes else {}),
    }


def verify_directory(directory: Path, discovery_path: Path, allow_empty: bool) -> int:
    locks = sorted(directory.glob("*.json")) if directory.exists() else []
    require(allow_empty or locks, f"no source locks found in {directory}")
    source_ids: set[str] = set()
    for lock_path in locks:
        lock = verify_lock(lock_path, discovery_path)
        source_id = str(lock["source_id"])
        require(source_id not in source_ids, f"duplicate source lock for {source_id}")
        source_ids.add(source_id)
    return len(locks)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    capture = subparsers.add_parser("capture", help="hash a locally captured official source")
    capture.add_argument("--source-id", required=True)
    capture.add_argument("--input", required=True, type=Path)
    capture.add_argument("--source-locator", required=True)
    capture.add_argument("--resolved-locator", required=True)
    capture.add_argument("--media-type", required=True)
    capture.add_argument("--output", required=True, type=Path)
    capture.add_argument("--discovery", type=Path, default=DEFAULT_DISCOVERY)
    capture.add_argument(
        "--redistribution-status",
        choices=sorted(ALLOWED_REDISTRIBUTION),
        default="review-required",
    )
    capture.add_argument("--retained-path")
    capture.add_argument("--notes")

    verify = subparsers.add_parser("verify", help="verify one source lock")
    verify.add_argument("lock", type=Path)
    verify.add_argument("--discovery", type=Path, default=DEFAULT_DISCOVERY)

    verify_dir = subparsers.add_parser("verify-directory", help="verify every source lock")
    verify_dir.add_argument("--directory", type=Path, default=DEFAULT_LOCK_DIR)
    verify_dir.add_argument("--discovery", type=Path, default=DEFAULT_DISCOVERY)
    verify_dir.add_argument("--allow-empty", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "capture":
            lock = create_lock(
                source_id=args.source_id,
                input_path=args.input,
                source_locator=args.source_locator,
                resolved_locator=args.resolved_locator,
                media_type=args.media_type,
                discovery_path=args.discovery,
                redistribution_status=args.redistribution_status,
                retained_path=args.retained_path,
                notes=args.notes,
            )
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(lock, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            verify_lock(args.output, args.discovery)
            print(f"source lock created: {args.output} ({lock['byte_length']} bytes, {lock['sha256']})")
        elif args.command == "verify":
            lock = verify_lock(args.lock, args.discovery)
            print(f"source lock verified: {lock['source_id']} {lock['sha256']}")
        else:
            count = verify_directory(args.directory, args.discovery, args.allow_empty)
            print(f"source lock directory verified: {count} C1 lock(s)")
    except (OSError, SourceLockError, ValueError) as error:
        print(f"curriculum source lock failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
