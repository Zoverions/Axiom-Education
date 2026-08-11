#!/usr/bin/env python3
"""Derive Ontario Elementary readiness from immutable discovery and later evidence.

The C0 discovery ledger remains a historical/source-discovery artifact. Later C1 locks and
C2 records are separate evidence layers. This tool composes those layers without rewriting
older provenance or overstating whole-jurisdiction readiness.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DISCOVERY_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-discovery.v0.json"
LOCK_DIR = ROOT / "curriculum" / "ontario-elementary" / "source-locks"
RECORD_DIR = ROOT / "curriculum" / "ontario-elementary" / "records-v2"
CAPTURE_TARGETS_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-capture-targets.v1.json"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_lock import load_discovery, verify_lock  # noqa: E402
from tools.curriculum_standard_record import verify_record  # noqa: E402
from tools.remote_curriculum_source_capture import validate_target_registry  # noqa: E402


class ElementaryReadinessError(RuntimeError):
    """Raised when evidence layers conflict or a readiness claim would be unsafe."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ElementaryReadinessError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ElementaryReadinessError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise ElementaryReadinessError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def source_index(discovery: dict[str, Any]) -> dict[str, dict[str, Any]]:
    sources = discovery.get("confirmed_curriculum_sources")
    require(isinstance(sources, list) and sources, "confirmed curriculum sources are missing")
    index: dict[str, dict[str, Any]] = {}
    for source in sources:
        require(isinstance(source, dict), "confirmed curriculum source must be an object")
        source_id = source.get("source_id")
        require(isinstance(source_id, str) and source_id, "confirmed source_id is required")
        require(source_id not in index, f"duplicate confirmed source_id: {source_id}")
        index[source_id] = source
    return index


def load_locks(discovery_sources: dict[str, dict[str, Any]]) -> dict[str, dict[str, Any]]:
    locks: dict[str, dict[str, Any]] = {}
    if not LOCK_DIR.exists():
        return locks
    for path in sorted(LOCK_DIR.glob("*.json")):
        lock = verify_lock(path, DISCOVERY_PATH)
        source_id = lock.get("source_id")
        require(isinstance(source_id, str) and source_id, f"{path}: source_id missing")
        require(source_id in discovery_sources, f"C1 lock has no C0 discovery source: {source_id}")
        require(source_id not in locks, f"duplicate C1 lock for source: {source_id}")
        require(lock.get("claim_state") == "C1-bytes-captured-digested", f"unexpected lock stage for {source_id}")
        locks[source_id] = lock
    return locks


def load_canonical_records(
    discovery_sources: dict[str, dict[str, Any]],
) -> dict[str, list[dict[str, Any]]]:
    by_source: dict[str, list[dict[str, Any]]] = {}
    if not RECORD_DIR.exists():
        return by_source
    for path in sorted(RECORD_DIR.glob("*.json")):
        record = verify_record(path, LOCK_DIR)
        source = record.get("source")
        require(isinstance(source, dict), f"{path}: source binding missing")
        source_id = source.get("source_id")
        require(isinstance(source_id, str) and source_id in discovery_sources, f"{path}: unknown source_id")
        by_source.setdefault(source_id, []).append(record)
    return by_source


def program_family_rows(
    discovery: dict[str, Any],
    locks: dict[str, dict[str, Any]],
    canonical_records: dict[str, list[dict[str, Any]]],
) -> dict[str, list[dict[str, Any]]]:
    required = discovery.get("required_program_families")
    accounting = discovery.get("coverage_accounting")
    require(isinstance(required, dict), "required_program_families missing")
    require(isinstance(accounting, dict), "coverage_accounting missing")

    output: dict[str, list[dict[str, Any]]] = {}
    for stream_key in ("english_language_schools", "french_language_schools"):
        families = required.get(stream_key)
        stream_accounting = accounting.get(stream_key)
        require(isinstance(families, list) and families, f"{stream_key}: required family list missing")
        require(isinstance(stream_accounting, dict), f"{stream_key}: coverage accounting missing")
        require(set(stream_accounting) == set(families), f"{stream_key}: coverage accounting does not match required families")

        rows: list[dict[str, Any]] = []
        for family in families:
            require(isinstance(family, str) and family, f"{stream_key}: invalid program family")
            entry = stream_accounting[family]
            require(isinstance(entry, dict), f"{stream_key}/{family}: accounting entry must be an object")
            source_id = entry.get("source_id")
            if source_id is None:
                rows.append(
                    {
                        "program_family": family,
                        "source_id": None,
                        "highest_evidenced_stage": "unresolved",
                        "discovery_status": entry.get("status"),
                        "c1_locked": False,
                        "canonical_c2_records": 0,
                    }
                )
                continue

            require(isinstance(source_id, str) and source_id, f"{stream_key}/{family}: invalid source_id")
            c1 = source_id in locks
            c2_count = len(canonical_records.get(source_id, []))
            require(c2_count == 0 or c1, f"{stream_key}/{family}: C2 records exist without C1 source evidence")
            highest = "C2-canonical-records" if c2_count else ("C1-bytes-captured-digested" if c1 else "C0-discovered")
            rows.append(
                {
                    "program_family": family,
                    "source_id": source_id,
                    "highest_evidenced_stage": highest,
                    "discovery_status": entry.get("status"),
                    "c1_locked": c1,
                    "canonical_c2_records": c2_count,
                }
            )
        output[stream_key] = rows
    return output


def build_readiness() -> dict[str, Any]:
    discovery = load_discovery(DISCOVERY_PATH)
    require(discovery.get("state") == "C0-discovered", "discovery ledger must remain C0 and immutable in meaning")
    sources = source_index(discovery)
    locks = load_locks(sources)
    canonical_records = load_canonical_records(sources)
    capture_targets = validate_target_registry(CAPTURE_TARGETS_PATH)

    source_rows: list[dict[str, Any]] = []
    for source_id in sorted(sources):
        source = sources[source_id]
        lock = locks.get(source_id)
        records = canonical_records.get(source_id, [])
        stage = "C2-canonical-records" if records else ("C1-bytes-captured-digested" if lock else "C0-discovered")
        source_rows.append(
            {
                "source_id": source_id,
                "subject_family": source.get("subject_family"),
                "policy_version": source.get("policy_version"),
                "highest_evidenced_stage": stage,
                "c0_discovery_review_status": source.get("review_status"),
                "capture_target_registered": source_id in capture_targets,
                "c1": None
                if lock is None
                else {
                    "sha256": lock["sha256"],
                    "byte_length": lock["byte_length"],
                    "media_type": lock["media_type"],
                    "captured_at": lock["captured_at"],
                    "redistribution_status": lock["redistribution_status"],
                    "bytes_retained": lock["bytes_retained"],
                },
                "canonical_c2_record_count": len(records),
            }
        )

    programs = program_family_rows(discovery, locks, canonical_records)
    english = programs["english_language_schools"]
    french = programs["french_language_schools"]
    kindergarten_source = sources.get("ontario-kindergarten-2026")
    require(isinstance(kindergarten_source, dict), "Kindergarten 2026 source discovery is required")
    kindergarten_locked = "ontario-kindergarten-2026" in locks

    english_c1 = sum(1 for row in english if row["c1_locked"])
    french_c1 = sum(1 for row in french if row["c1_locked"])
    unresolved_french = [row["program_family"] for row in french if row["highest_evidenced_stage"] == "unresolved"]
    uncaptured_discovered = [row["source_id"] for row in source_rows if row["highest_evidenced_stage"] == "C0-discovered"]

    source_capture_complete = len(locks) == len(sources)
    english_base_capture_complete = english_c1 == len(english)
    french_base_capture_complete = french_c1 == len(french)
    overall_base_source_capture_complete = (
        source_capture_complete
        and english_base_capture_complete
        and french_base_capture_complete
        and kindergarten_locked
    )

    return {
        "schema": "axiom-education-ontario-elementary-readiness.v1",
        "jurisdiction_id": discovery["jurisdiction_id"],
        "scope": discovery["scope"],
        "derived_from": {
            "discovery_path": DISCOVERY_PATH.relative_to(ROOT).as_posix(),
            "source_lock_directory": LOCK_DIR.relative_to(ROOT).as_posix(),
            "canonical_c2_record_directory": RECORD_DIR.relative_to(ROOT).as_posix(),
            "capture_target_registry": CAPTURE_TARGETS_PATH.relative_to(ROOT).as_posix(),
        },
        "claim_boundary": (
            "This is a derived readiness view over immutable C0 discovery and later evidence. "
            "A source at C1 proves exact-byte capture/digest only. Canonical C2 records do not by themselves prove human source review, licensing, complete program coverage, pack verification, staging, activation, or Ministry endorsement."
        ),
        "summary": {
            "confirmed_discovery_sources": len(sources),
            "registered_capture_targets": len(capture_targets),
            "c1_locked_sources": len(locks),
            "canonical_c2_records": sum(len(records) for records in canonical_records.values()),
            "kindergarten_c1_locked": kindergarten_locked,
            "english_required_program_families": len(english),
            "english_program_families_with_c1_source": english_c1,
            "french_required_program_families": len(french),
            "french_program_families_with_c1_source": french_c1,
            "unresolved_french_program_families": unresolved_french,
            "uncaptured_discovered_source_ids": uncaptured_discovered,
            "all_discovered_sources_c1_locked": source_capture_complete,
            "english_base_source_capture_complete": english_base_capture_complete,
            "french_base_source_capture_complete": french_base_capture_complete,
            "overall_base_source_capture_complete": overall_base_source_capture_complete,
            "human_source_review_complete": False,
            "licensing_review_complete": False,
            "deterministic_full_pack_verified": False,
            "governed_activation_available": False,
        },
        "sources": source_rows,
        "program_families": programs,
    }


def verify_readiness(payload: dict[str, Any]) -> None:
    summary = payload.get("summary")
    require(isinstance(summary, dict), "readiness summary missing")
    require(summary.get("confirmed_discovery_sources") >= summary.get("c1_locked_sources", 0), "C1 count exceeds discovered sources")
    require(summary.get("registered_capture_targets") >= summary.get("c1_locked_sources", 0), "committed C1 source lacks a bounded capture target")
    require(summary.get("english_program_families_with_c1_source") <= summary.get("english_required_program_families", 0), "English C1 coverage exceeds required families")
    require(summary.get("french_program_families_with_c1_source") <= summary.get("french_required_program_families", 0), "French C1 coverage exceeds required families")
    require(summary.get("overall_base_source_capture_complete") is False, "Ontario Elementary must not claim complete base source capture while known gaps remain")
    require(summary.get("human_source_review_complete") is False, "machine readiness view cannot claim human source review")
    require(summary.get("licensing_review_complete") is False, "machine readiness view cannot claim licensing completion")
    require(summary.get("governed_activation_available") is False, "machine readiness view cannot enable governed activation")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    report = commands.add_parser("report", help="print or write the derived readiness view")
    report.add_argument("--output", type=Path)
    commands.add_parser("verify", help="derive and verify fail-closed readiness")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        payload = build_readiness()
        verify_readiness(payload)
        if args.command == "report":
            rendered = json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
            if args.output:
                args.output.parent.mkdir(parents=True, exist_ok=True)
                args.output.write_text(rendered, encoding="utf-8")
                print(f"Ontario Elementary readiness written: {args.output}")
            else:
                print(rendered, end="")
        else:
            summary = payload["summary"]
            print(
                "Ontario Elementary readiness verified: "
                f"C1 sources={summary['c1_locked_sources']}/{summary['confirmed_discovery_sources']}; "
                f"English families={summary['english_program_families_with_c1_source']}/{summary['english_required_program_families']}; "
                f"French families={summary['french_program_families_with_c1_source']}/{summary['french_required_program_families']}; "
                "overall source capture incomplete"
            )
    except (OSError, KeyError, ElementaryReadinessError, ValueError) as error:
        print(f"Ontario Elementary readiness verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
