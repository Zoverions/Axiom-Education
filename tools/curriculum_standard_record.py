#!/usr/bin/env python3
"""Finalize and verify generic C2 curriculum standard records.

C2 records require a valid C1 source lock. They may normalize or reference source
content, but they are not human source-reviewed, pack-reproducible, signed, staged,
or active merely because this verifier accepts them.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LOCK_DIR = ROOT / "curriculum" / "ontario-elementary" / "source-locks"
DEFAULT_RECORD_DIR = ROOT / "curriculum" / "ontario-elementary" / "records-v2"
STANDARD_RECORD_SCHEMA = ROOT / "schemas" / "curriculum-standard-record.v2.schema.json"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ALLOWED_LEVELS = {
    "kindergarten",
    "elementary",
    "secondary",
    "postsecondary",
    "apprenticeship",
    "professional",
    "lifelong",
    "other",
}
ALLOWED_KINDS = {"overall", "specific", "expectation", "learning-area", "other"}
ALLOWED_MODES = {"verbatim", "paraphrase", "reference-only"}

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_lock import (  # noqa: E402
    canonical_json_digest,
    verify_lock,
)
from tools.json_schema_validation import (  # noqa: E402
    RepositoryJsonSchemaError,
    validate_json_schema,
)


class StandardRecordError(RuntimeError):
    """Raised when a C2 curriculum standard record is unsupported or unsafe."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise StandardRecordError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise StandardRecordError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise StandardRecordError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def canonical_record_digest(record: dict[str, Any]) -> str:
    payload = dict(record)
    payload.pop("content_digest", None)
    return canonical_json_digest(payload)


def validate_timestamp(value: object) -> None:
    require(isinstance(value, str), "normalized_at must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise StandardRecordError("normalized_at must be an ISO-8601 timestamp") from error
    require(parsed.tzinfo is not None, "normalized_at must include a timezone")


def load_source_lock(lock_dir: Path, source_id: str) -> tuple[Path, dict[str, Any]]:
    matches: list[tuple[Path, dict[str, Any]]] = []
    if lock_dir.exists():
        for path in sorted(lock_dir.glob("*.json")):
            try:
                lock = verify_lock(path)
            except Exception as error:  # convert source-lock failures to record failures
                raise StandardRecordError(f"invalid source lock {path}: {error}") from error
            if lock.get("source_id") == source_id:
                matches.append((path, lock))
    require(len(matches) == 1, f"C2 record requires exactly one valid C1 source lock for {source_id}")
    return matches[0]


def verify_record(record_path: Path, lock_dir: Path = DEFAULT_LOCK_DIR) -> dict[str, Any]:
    record = load_json(record_path)
    try:
        validate_json_schema(
            record,
            STANDARD_RECORD_SCHEMA,
            label=str(record_path),
        )
    except RepositoryJsonSchemaError as error:
        raise StandardRecordError(str(error)) from error
    require(record.get("schema") == "axiom-curriculum-standard-record.v2", "unsupported standard record schema")
    require(record.get("stage") == "C2-normalized", "standard record must remain C2-normalized")

    record_id = record.get("record_id")
    require(isinstance(record_id, str) and len(record_id) >= 8, "record_id is required")
    language = record.get("language")
    require(isinstance(language, str) and len(language) >= 2, "language is required")

    context = record.get("education_context")
    require(isinstance(context, dict), "education_context is required")
    require(context.get("level") in ALLOWED_LEVELS, "invalid education level")
    for key in ("program_family", "grade_or_level", "subject_id", "subject_name"):
        require(isinstance(context.get(key), str) and context[key].strip(), f"education_context.{key} is required")
    if context.get("level") in {"kindergarten", "elementary"}:
        require(context.get("course_code") in (None, ""), "kindergarten/elementary records must not invent a course code")

    standard = record.get("standard")
    require(isinstance(standard, dict), "standard is required")
    require(isinstance(standard.get("official_id"), str) and standard["official_id"], "official standard id is required")
    require(standard.get("kind") in ALLOWED_KINDS, "invalid standard kind")
    require(isinstance(standard.get("strand_id"), str) and standard["strand_id"], "strand_id is required")
    require(isinstance(standard.get("strand_name"), str) and standard["strand_name"], "strand_name is required")

    content = standard.get("content")
    require(isinstance(content, dict), "standard content is required")
    mode = content.get("mode")
    require(mode in ALLOWED_MODES, "invalid standard content mode")
    text = content.get("text")
    official_text_sha = content.get("official_text_sha256")
    if official_text_sha is not None:
        require(isinstance(official_text_sha, str) and SHA256_RE.fullmatch(official_text_sha) is not None, "invalid official text digest")
    if mode in {"verbatim", "paraphrase"}:
        require(isinstance(text, str) and text.strip(), f"{mode} content requires text")
    else:
        require(text is None, "reference-only content must not embed source text")

    source = record.get("source")
    require(isinstance(source, dict), "source binding is required")
    source_id = source.get("source_id")
    require(isinstance(source_id, str) and source_id, "source_id is required")
    _, lock = load_source_lock(lock_dir, source_id)

    require(record.get("jurisdiction_id") == lock.get("jurisdiction_id"), "jurisdiction does not match C1 source lock")
    require(record.get("authority_id") == lock.get("authority_id"), "authority does not match C1 source lock")
    require(source.get("source_lock_sha256") == canonical_json_digest(lock), "source lock digest mismatch")
    require(source.get("upstream_document_sha256") == lock.get("sha256"), "upstream document digest mismatch")
    require(
        source.get("official_locator") in {lock.get("source_locator"), lock.get("resolved_locator")},
        "official locator is not bound to the C1 source lock",
    )
    require(source.get("official_recognition") is True, "Ontario official-derived record must retain official recognition")

    if mode == "verbatim":
        require(
            lock.get("redistribution_status") == "redistributable-reviewed",
            "verbatim curriculum text requires reviewed redistribution permission",
        )

    provenance = record.get("provenance")
    require(isinstance(provenance, dict), "provenance is required")
    require(isinstance(provenance.get("normalization_method"), str) and provenance["normalization_method"], "normalization_method is required")
    validate_timestamp(provenance.get("normalized_at"))
    require(
        provenance.get("human_source_review_status") == "required",
        "C2 machine normalization cannot claim human source review without separate evidence",
    )

    metadata = record.get("axiom_metadata")
    require(isinstance(metadata, dict), "axiom_metadata is required")
    require(metadata.get("namespace") == "org.axiom.education", "Axiom-authored metadata must use its own namespace")
    tags = metadata.get("tags")
    require(isinstance(tags, list) and all(isinstance(tag, str) and tag for tag in tags), "axiom tags must be strings")
    require(len(tags) == len(set(tags)), "axiom tags must be unique")

    digest = record.get("content_digest")
    require(isinstance(digest, str) and SHA256_RE.fullmatch(digest) is not None, "content_digest is invalid")
    require(digest == canonical_record_digest(record), "content_digest mismatch")
    return record


def finalize_record(input_path: Path, output_path: Path) -> dict[str, Any]:
    record = load_json(input_path)
    record["content_digest"] = canonical_record_digest(record)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(record, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return record


def verify_directory(directory: Path, lock_dir: Path, allow_empty: bool) -> int:
    paths = sorted(directory.glob("*.json")) if directory.exists() else []
    require(allow_empty or paths, f"no C2 standard records found in {directory}")
    seen_ids: set[str] = set()
    for path in paths:
        record = verify_record(path, lock_dir)
        record_id = str(record["record_id"])
        require(record_id not in seen_ids, f"duplicate C2 record_id: {record_id}")
        seen_ids.add(record_id)
    return len(paths)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    finalize = commands.add_parser("finalize", help="compute the canonical content digest")
    finalize.add_argument("input", type=Path)
    finalize.add_argument("output", type=Path)

    verify = commands.add_parser("verify", help="verify one C2 standard record")
    verify.add_argument("record", type=Path)
    verify.add_argument("--lock-dir", type=Path, default=DEFAULT_LOCK_DIR)

    verify_dir = commands.add_parser("verify-directory", help="verify every C2 standard record")
    verify_dir.add_argument("--directory", type=Path, default=DEFAULT_RECORD_DIR)
    verify_dir.add_argument("--lock-dir", type=Path, default=DEFAULT_LOCK_DIR)
    verify_dir.add_argument("--allow-empty", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "finalize":
            record = finalize_record(args.input, args.output)
            print(f"C2 record finalized: {args.output} {record['content_digest']}")
        elif args.command == "verify":
            record = verify_record(args.record, args.lock_dir)
            print(f"C2 record verified: {record['record_id']}")
        else:
            count = verify_directory(args.directory, args.lock_dir, args.allow_empty)
            print(f"C2 record directory verified: {count} record(s)")
    except (OSError, KeyError, StandardRecordError, ValueError) as error:
        print(f"curriculum standard record verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
