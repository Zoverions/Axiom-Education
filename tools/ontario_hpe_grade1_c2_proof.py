#!/usr/bin/env python3
"""Build and verify a C1-bound Ontario Elementary C2 construction fixture.

The generated records are reference-only build artifacts. They are not promoted into the
canonical reviewed-record directory until separate human source and licensing review exists.
The fixture binds to captured-source metadata but does not claim that its manually authored
reference structure was derived from source bytes that the repository does not retain.
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SLICE_PATH = ROOT / "curriculum" / "ontario-elementary" / "slices" / "hpe-grade1-c2-proof.v1.json"
LOCK_DIR = ROOT / "curriculum" / "ontario-elementary" / "source-locks"
EXPECTED_LOCK_DIGEST = "d5effa1a696250abe75704ce46c93cde37ab1d418b94920517084c0c0843adac"
EXPECTED_DOCUMENT_DIGEST = "37416922ca741b1fb32a0708442738ae8d964d974c3315d04cdcc8bd2e652622"
EXPECTED = {
    "A1": ("overall", None, "A", 94),
    "A1.1": ("specific", "A1", "A", 94),
    "B1": ("overall", None, "B", 97),
    "B1.1": ("specific", "B1", "B", 97),
    "C1": ("overall", None, "C", 101),
    "C1.1": ("specific", "C1", "C", 101),
    "D1": ("overall", None, "D", 104),
    "D1.1": ("specific", "D1", "D", 105),
}

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_lock import canonical_json_digest, verify_lock  # noqa: E402
from tools.curriculum_standard_record import (  # noqa: E402
    canonical_record_digest,
    verify_record,
)


class HpeC2ProofError(RuntimeError):
    """Raised when the narrow construction fixture drifts or overclaims."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise HpeC2ProofError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise HpeC2ProofError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise HpeC2ProofError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def validate_spec(path: Path = SLICE_PATH) -> tuple[dict[str, Any], dict[str, Any]]:
    spec = load_json(path)
    require(spec.get("schema") == "axiom-curriculum-reference-slice.v1", "unsupported reference slice schema")
    require(spec.get("slice_id") == "ontario-hpe-grade1-c2-proof", "slice id mismatch")
    require(spec.get("stage") == "C2-construction-fixture", "fixture stage mismatch")
    require(spec.get("jurisdiction_id") == "ca:on", "jurisdiction mismatch")
    require(spec.get("authority_id") == "gov:ontario:ministry-of-education", "authority mismatch")
    require(spec.get("language") == "en", "language mismatch")
    require(spec.get("program_family") == "english-language-schools", "program family mismatch")
    require(spec.get("level") == "elementary", "education level mismatch")
    require(spec.get("grade_or_level") == "1", "grade mismatch")
    require(spec.get("subject_id") == "health-and-physical-education", "subject mismatch")
    require(spec.get("complete_grade_claim_allowed") is False, "fixture cannot claim complete Grade 1 coverage")
    require(spec.get("complete_subject_claim_allowed") is False, "fixture cannot claim complete HPE coverage")
    require(spec.get("human_source_review_status") == "required", "human source review must remain required")
    require(spec.get("licensing_review_status") == "required", "licensing review must remain required")
    require(
        spec.get("reference_metadata_origin")
        == "manually-authored-not-derived-from-retained-source-bytes",
        "reference metadata origin must disclose manual authorship",
    )
    require(
        spec.get("source_bytes_retained_and_parsed") is False,
        "fixture cannot claim retained source bytes were parsed",
    )
    require(
        spec.get("c1_to_c2_derivation_proven") is False,
        "fixture cannot claim C1-to-C2 derivation proof",
    )

    lock_path = ROOT / str(spec.get("source_lock_path"))
    lock = verify_lock(lock_path)
    require(canonical_json_digest(lock) == EXPECTED_LOCK_DIGEST, "C1 source-lock digest mismatch")
    require(lock.get("sha256") == EXPECTED_DOCUMENT_DIGEST, "C1 source-document digest mismatch")
    require(lock.get("redistribution_status") == "review-required", "proof source must not preclaim redistribution permission")

    records = spec.get("records")
    require(isinstance(records, list) and len(records) == len(EXPECTED), "fixture must contain exactly 8 references")
    seen: set[str] = set()
    for item in records:
        require(isinstance(item, dict), "proof reference must be an object")
        official_id = item.get("official_id")
        require(official_id in EXPECTED, f"unexpected expectation id: {official_id}")
        require(official_id not in seen, f"duplicate expectation id: {official_id}")
        seen.add(str(official_id))
        kind, parent, strand, page = EXPECTED[str(official_id)]
        require(item.get("kind") == kind, f"{official_id}: kind mismatch")
        require(item.get("parent_official_id") == parent, f"{official_id}: parent mismatch")
        require(item.get("strand_id") == strand, f"{official_id}: strand mismatch")
        require(item.get("official_page") == page, f"{official_id}: official page mismatch")
        require(isinstance(item.get("strand_name"), str) and item["strand_name"], f"{official_id}: strand name missing")
    require(seen == set(EXPECTED), "proof expectation set is incomplete")
    return spec, lock


def record_id(official_id: str) -> str:
    return "ca:on:hpe:grade-1:" + official_id.lower().replace(".", "-")


def build_record(spec: dict[str, Any], lock: dict[str, Any], item: dict[str, Any]) -> dict[str, Any]:
    record: dict[str, Any] = {
        "schema": "axiom-curriculum-standard-record.v2",
        "stage": "C2-normalized",
        "record_id": record_id(str(item["official_id"])),
        "jurisdiction_id": spec["jurisdiction_id"],
        "authority_id": spec["authority_id"],
        "language": spec["language"],
        "education_context": {
            "program_family": spec["program_family"],
            "level": spec["level"],
            "grade_or_level": spec["grade_or_level"],
            "subject_id": spec["subject_id"],
            "subject_name": spec["subject_name"],
            "course_code": None,
            "course_name": None,
        },
        "standard": {
            "official_id": item["official_id"],
            "kind": item["kind"],
            "parent_official_id": item["parent_official_id"],
            "strand_id": item["strand_id"],
            "strand_name": item["strand_name"],
            "content": {
                "mode": "reference-only",
                "text": None,
                "official_text_sha256": None,
            },
        },
        "source": {
            "source_id": lock["source_id"],
            "source_lock_sha256": canonical_json_digest(lock),
            "upstream_document_sha256": lock["sha256"],
            "official_locator": lock["resolved_locator"],
            "official_recognition": True,
            "effective_from": spec["effective_from"],
            "effective_to": None,
        },
        "provenance": {
            "normalization_method": spec["normalization_method"],
            "normalized_at": spec["normalized_at"],
            "human_source_review_status": "required",
        },
        "axiom_metadata": {
            "namespace": "org.axiom.education",
            "tags": ["grade-1", "hpe", "construction-fixture", "reference-only"],
        },
        "content_digest": "",
    }
    record["content_digest"] = canonical_record_digest(record)
    return record


def build(output: Path, spec_path: Path = SLICE_PATH) -> dict[str, Any]:
    spec, lock = validate_spec(spec_path)
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    manifest_records: list[dict[str, Any]] = []
    for item in spec["records"]:
        record = build_record(spec, lock, item)
        filename = f"{record['record_id'].split(':')[-1]}.v2.json"
        path = output / filename
        path.write_text(json.dumps(record, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        verified = verify_record(path, LOCK_DIR)
        require(verified["standard"]["content"]["mode"] == "reference-only", "generated record embedded source text")
        manifest_records.append(
            {
                "path": filename,
                "official_id": item["official_id"],
                "official_page": item["official_page"],
                "content_digest": record["content_digest"],
            }
        )

    manifest = {
        "schema": "axiom-curriculum-c2-fixture-build.v1",
        "slice_id": spec["slice_id"],
        "stage": "C2-normalized-fixture-build",
        "source_lock_sha256": canonical_json_digest(lock),
        "upstream_document_sha256": lock["sha256"],
        "record_count": len(manifest_records),
        "content_mode": "reference-only",
        "human_source_review_status": "required",
        "licensing_review_status": "required",
        "reference_metadata_origin": spec["reference_metadata_origin"],
        "source_bytes_retained_and_parsed": False,
        "c1_to_c2_derivation_proven": False,
        "promoted_to_canonical_records": False,
        "records": manifest_records,
    }
    (output / "manifest.json").write_text(
        json.dumps(manifest, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    return manifest


def verify_determinism(spec_path: Path = SLICE_PATH) -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix="axiom-hpe-c2-a-") as a, tempfile.TemporaryDirectory(prefix="axiom-hpe-c2-b-") as b:
        first = Path(a)
        second = Path(b)
        first_manifest = build(first, spec_path)
        second_manifest = build(second, spec_path)
        require(first_manifest == second_manifest, "C2 proof manifests differ between builds")
        first_files = sorted(path.relative_to(first) for path in first.iterdir() if path.is_file())
        second_files = sorted(path.relative_to(second) for path in second.iterdir() if path.is_file())
        require(first_files == second_files, "C2 proof file sets differ between builds")
        for relative in first_files:
            require((first / relative).read_bytes() == (second / relative).read_bytes(), f"C2 proof bytes differ: {relative}")
        require(first_manifest["record_count"] == 8, "C2 proof record count drifted")
        return first_manifest


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    build_parser = commands.add_parser("build")
    build_parser.add_argument("--output", type=Path, required=True)
    commands.add_parser("verify")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "build":
            manifest = build(args.output)
            print(f"Ontario HPE Grade 1 C2 fixture built: {manifest['record_count']} records -> {args.output}")
        else:
            manifest = verify_determinism()
            print(
                "Ontario HPE Grade 1 C2 fixture verified: "
                f"{manifest['record_count']} deterministic reference-only records bound to C1 metadata; "
                "manual structure is not source-byte derivation proof and records are not promoted"
            )
    except (OSError, KeyError, HpeC2ProofError, ValueError) as error:
        print(f"Ontario HPE Grade 1 C2 fixture failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
