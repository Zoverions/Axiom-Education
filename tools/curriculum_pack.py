#!/usr/bin/env python3
"""Build, sign, and verify deterministic OntarioEdAI curriculum packs.

The pack content is deterministic and contains no build timestamp. Signing uses
an externally supplied Ed25519 key through OpenSSL; private keys are never
copied into the pack or repository.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable

BUILDER_VERSION = "1.0.0"
CANONICALIZATION = "utf8-nfc-json-sort-keys-compact-newline-v1"
PACK_SCHEMA = "ontarioedai-curriculum-pack.v1"
RECORD_SCHEMA = "ontarioedai-curriculum-record.v1"
LEDGER_SCHEMA = "ontarioedai-curriculum-source-ledger.v1"
SIGNATURE_SCHEMA = "ontarioedai-curriculum-pack-signature.v1"
MAX_INPUT_BYTES = 128 * 1024 * 1024
MAX_RECORD_LINE_BYTES = 256 * 1024
MAX_RECORDS = 250_000
COURSE_CODE_RE = re.compile(r"^[0-9A-Z]{2,16}$")
SEMVER_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$")
SHA256_RE = re.compile(r"^[a-f0-9]{64}$")
DATE_RE = re.compile(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$")


class PackError(RuntimeError):
    """Raised when pack input, output, or verification fails closed."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise PackError(message)


def nfc(value: str, field: str, *, minimum: int = 1, maximum: int = 20_000) -> str:
    require(isinstance(value, str), f"{field} must be a string")
    normalized = unicodedata.normalize("NFC", value).strip()
    require(minimum <= len(normalized) <= maximum, f"{field} length is invalid")
    require("\x00" not in normalized, f"{field} contains a NUL byte")
    return normalized


def canonicalize(value: Any) -> Any:
    if value is None or isinstance(value, (bool, int)):
        return value
    if isinstance(value, float):
        require(math.isfinite(value), "canonical JSON rejects non-finite numbers")
        return 0.0 if value == 0 else value
    if isinstance(value, str):
        return unicodedata.normalize("NFC", value)
    if isinstance(value, list):
        return [canonicalize(item) for item in value]
    if isinstance(value, dict):
        normalized: dict[str, Any] = {}
        for key, item in value.items():
            require(isinstance(key, str), "canonical JSON object keys must be strings")
            normalized_key = unicodedata.normalize("NFC", key)
            require(normalized_key not in normalized, "canonical key normalization collision")
            normalized[normalized_key] = canonicalize(item)
        return normalized
    raise PackError(f"unsupported canonical JSON type: {type(value).__name__}")


def canonical_bytes(value: Any) -> bytes:
    rendered = json.dumps(
        canonicalize(value),
        ensure_ascii=False,
        allow_nan=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return rendered.encode("utf-8") + b"\n"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path, *, maximum: int = MAX_INPUT_BYTES) -> str:
    require(path.is_file() and not path.is_symlink(), f"unsafe or missing file: {path}")
    require(path.stat().st_size <= maximum, f"file exceeds size limit: {path}")
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def read_json(path: Path, *, maximum: int = MAX_INPUT_BYTES) -> tuple[Any, bytes]:
    require(path.is_file() and not path.is_symlink(), f"unsafe or missing JSON file: {path}")
    require(path.stat().st_size <= maximum, f"JSON file exceeds size limit: {path}")
    raw = path.read_bytes()
    try:
        decoded = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise PackError(f"invalid UTF-8 JSON in {path}: {error}") from error
    return decoded, raw


def write_atomic(path: Path, data: bytes, *, mode: int = 0o644) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    require(not path.parent.is_symlink(), f"output parent must not be a symlink: {path.parent}")
    with tempfile.NamedTemporaryFile(
        mode="wb",
        dir=path.parent,
        prefix=f".{path.name}.",
        delete=False,
    ) as handle:
        temporary = Path(handle.name)
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())
    os.chmod(temporary, mode)
    temporary.replace(path)


def validate_ledger(ledger: Any) -> tuple[dict[str, dict[str, Any]], list[tuple[re.Pattern[str], str]]]:
    require(isinstance(ledger, dict), "source ledger root must be an object")
    require(ledger.get("schema") == LEDGER_SCHEMA, "unsupported source ledger schema")
    require(isinstance(ledger.get("ledger_version"), str), "ledger_version is required")
    require(ledger.get("jurisdiction") == "CA-ON", "source ledger jurisdiction must be CA-ON")
    effective_date = ledger.get("effective_date")
    require(isinstance(effective_date, str) and DATE_RE.fullmatch(effective_date), "invalid ledger effective_date")

    sources_value = ledger.get("sources")
    require(isinstance(sources_value, list) and sources_value, "source ledger must contain sources")
    sources: dict[str, dict[str, Any]] = {}
    for source in sources_value:
        require(isinstance(source, dict), "source entry must be an object")
        source_id = nfc(source.get("source_id"), "source_id", maximum=128)
        require(source_id not in sources, f"duplicate source_id: {source_id}")
        classification = source.get("classification")
        require(
            classification in {"official-derived", "ontarioedai-extension", "third-party-oer"},
            f"invalid source classification: {source_id}",
        )
        require(isinstance(source.get("official_recognition"), bool), f"official_recognition missing: {source_id}")
        require(isinstance(source.get("licence"), dict), f"licence missing: {source_id}")
        for field in ("namespace", "authority", "upstream_digest_status", "review_status"):
            nfc(source.get(field), f"{source_id}.{field}", maximum=500)
        licence = source["licence"]
        for field in ("rights_holder", "usage_basis", "redistribution_status", "notice"):
            nfc(licence.get(field), f"{source_id}.licence.{field}", maximum=2_000)
        upstream_digest = source.get("upstream_document_sha256")
        require(
            upstream_digest is None or (isinstance(upstream_digest, str) and SHA256_RE.fullmatch(upstream_digest)),
            f"invalid upstream digest: {source_id}",
        )
        default_url = source.get("default_url")
        require(default_url is None or isinstance(default_url, str), f"invalid default_url: {source_id}")
        sources[source_id] = source

    routes_value = ledger.get("routing")
    require(isinstance(routes_value, list) and routes_value, "source ledger must contain routing rules")
    routes: list[tuple[re.Pattern[str], str]] = []
    for route in routes_value:
        require(isinstance(route, dict), "routing entry must be an object")
        pattern_text = nfc(route.get("course_code_pattern"), "course_code_pattern", maximum=256)
        source_id = nfc(route.get("source_id"), "routing.source_id", maximum=128)
        require(source_id in sources, f"routing references unknown source: {source_id}")
        try:
            pattern = re.compile(pattern_text)
        except re.error as error:
            raise PackError(f"invalid routing pattern {pattern_text}: {error}") from error
        routes.append((pattern, source_id))
    return sources, routes


def route_source(course_code: str, sources: dict[str, dict[str, Any]], routes: list[tuple[re.Pattern[str], str]]) -> dict[str, Any]:
    for pattern, source_id in routes:
        if pattern.fullmatch(course_code):
            return sources[source_id]
    raise PackError(f"no source routing rule matches course {course_code}")


def safe_number(value: Any, field: str) -> float | None:
    if value is None:
        return None
    require(isinstance(value, (int, float)) and not isinstance(value, bool), f"{field} must be numeric or null")
    converted = float(value)
    require(math.isfinite(converted), f"{field} must be finite")
    require(-1000.0 <= converted <= 1000.0, f"{field} is outside the allowed range")
    return converted


def expectation_parts(course_code: str, strand_id: str, value: Any) -> tuple[str, str, list[str], dict[str, float | None]]:
    if isinstance(value, str):
        raw = nfc(value, "expectation text")
        match = re.match(r"^([A-Z][0-9]+(?:\.[0-9]+)+)\s+(.*)$", raw)
        expectation_id = match.group(1) if match else f"AUTO-{sha256_bytes(raw.encode('utf-8'))[:16].upper()}"
        text = nfc(match.group(2) if match else raw, "expectation text")
        tags: list[str] = []
        heuristics = {"difficulty": None, "discrimination": None, "guessing_assumption": None}
        return expectation_id, text, tags, heuristics

    require(isinstance(value, dict), f"expectation in {course_code}/{strand_id} must be an object or string")
    text_value = value.get("expectation", value.get("text"))
    text = nfc(text_value, "expectation text")
    raw_id = value.get("id")
    expectation_id = (
        nfc(raw_id, "expectation id", maximum=256)
        if raw_id is not None
        else f"AUTO-{sha256_bytes(text.encode('utf-8'))[:16].upper()}"
    )
    tags_value = value.get("tags", [])
    require(isinstance(tags_value, list) and len(tags_value) <= 64, "expectation tags must be a bounded array")
    tags = sorted({nfc(tag, "expectation tag", maximum=128) for tag in tags_value})
    heuristics = {
        "difficulty": safe_number(value.get("irt_b"), "irt_b"),
        "discrimination": safe_number(value.get("irt_a"), "irt_a"),
        "guessing_assumption": safe_number(value.get("irt_c"), "irt_c"),
    }
    return expectation_id, text, tags, heuristics


def record_without_digest(
    *,
    course_code: str,
    course_name: str,
    strand_id: str,
    strand_name: str,
    expectation_id: str,
    text: str,
    tags: list[str],
    heuristics: dict[str, float | None],
    source: dict[str, Any],
    course_url: str | None,
    input_name: str,
    input_digest: str,
) -> dict[str, Any]:
    namespace = nfc(source["namespace"], "source namespace", maximum=256)
    record_id = f"{namespace}:{course_code}:{expectation_id}"
    licence = source["licence"]
    return {
        "schema": RECORD_SCHEMA,
        "record_id": record_id,
        "jurisdiction": "CA-ON",
        "course": {"code": course_code, "name": course_name},
        "strand": {"id": strand_id, "name": strand_name},
        "expectation": {"id": expectation_id, "text": text, "tags": tags},
        "source": {
            "source_id": source["source_id"],
            "namespace": namespace,
            "classification": source["classification"],
            "authority": source["authority"],
            "official_recognition": source["official_recognition"],
            "upstream_url": course_url or source.get("default_url"),
            "upstream_document_sha256": source.get("upstream_document_sha256"),
            "upstream_digest_status": source["upstream_digest_status"],
            "ingestion_artifact": input_name,
            "ingestion_artifact_sha256": input_digest,
            "review_status": source["review_status"],
            "licence": {
                "rights_holder": licence["rights_holder"],
                "usage_basis": licence["usage_basis"],
                "redistribution_status": licence["redistribution_status"],
                "notice": licence["notice"],
            },
        },
        "adaptation_heuristics": {"status": "uncalibrated", **heuristics},
    }


def extract_records(input_data: Any, input_path: Path, input_digest: str, ledger: dict[str, Any]) -> list[dict[str, Any]]:
    require(isinstance(input_data, dict), "curriculum input root must be an object")
    courses = input_data.get("courses")
    require(isinstance(courses, dict) and courses, "curriculum input must contain courses")
    sources, routes = validate_ledger(ledger)
    records: list[dict[str, Any]] = []
    record_ids: set[str] = set()

    for raw_course_code in sorted(courses):
        course_code = nfc(raw_course_code, "course code", maximum=16).upper()
        require(COURSE_CODE_RE.fullmatch(course_code) is not None, f"invalid course code: {course_code}")
        course = courses[raw_course_code]
        require(isinstance(course, dict), f"course {course_code} must be an object")
        course_name = nfc(course.get("name"), f"{course_code}.name", maximum=500)
        course_url_value = course.get("official_url")
        require(course_url_value is None or isinstance(course_url_value, str), f"invalid official_url for {course_code}")
        course_url = unicodedata.normalize("NFC", course_url_value).strip() if course_url_value else None
        source = route_source(course_code, sources, routes)
        strands = course.get("strands")
        require(isinstance(strands, dict) and strands, f"course {course_code} must contain strands")

        for raw_strand_id in sorted(strands):
            strand_id = nfc(raw_strand_id, f"{course_code}.strand id", maximum=256)
            strand_name = strand_id.replace("_", " ").strip()
            expectations = strands[raw_strand_id]
            require(isinstance(expectations, list), f"strand {course_code}/{strand_id} must be an array")
            for expectation in expectations:
                expectation_id, text, tags, heuristics = expectation_parts(course_code, strand_id, expectation)
                core = record_without_digest(
                    course_code=course_code,
                    course_name=course_name,
                    strand_id=strand_id,
                    strand_name=strand_name,
                    expectation_id=expectation_id,
                    text=text,
                    tags=tags,
                    heuristics=heuristics,
                    source=source,
                    course_url=course_url,
                    input_name=input_path.name,
                    input_digest=input_digest,
                )
                record_id = core["record_id"]
                require(record_id not in record_ids, f"duplicate curriculum record id: {record_id}")
                record_ids.add(record_id)
                record = {**core, "content_digest": sha256_bytes(canonical_bytes(core))}
                records.append(record)
                require(len(records) <= MAX_RECORDS, "curriculum record count exceeds limit")

    records.sort(key=lambda item: item["record_id"])
    require(records, "curriculum pack contains no records")
    return records


def build_pack(args: argparse.Namespace) -> dict[str, Any]:
    input_path = args.input.resolve()
    ledger_path = args.ledger.resolve()
    output_dir = args.output.resolve()
    require(SEMVER_RE.fullmatch(args.pack_version) is not None, "pack_version must be semantic versioning")
    require(re.fullmatch(r"[a-z0-9.-]{3,128}", args.pack_id) is not None, "invalid pack_id")
    require(not output_dir.is_symlink(), "output directory must not be a symlink")
    output_dir.mkdir(parents=True, exist_ok=True)
    require(not any(output_dir.iterdir()), "output directory must be empty")

    input_data, input_raw = read_json(input_path)
    ledger, ledger_raw = read_json(ledger_path)
    input_digest = sha256_bytes(input_raw)
    ledger_digest = sha256_bytes(ledger_raw)
    validate_ledger(ledger)
    records = extract_records(input_data, input_path, input_digest, ledger)

    record_lines = [canonical_bytes(record) for record in records]
    records_bytes = b"".join(record_lines)
    records_digest = sha256_bytes(records_bytes)
    write_atomic(output_dir / "records.jsonl", records_bytes)

    course_records: dict[str, list[bytes]] = defaultdict(list)
    course_sources: dict[str, tuple[str, bool]] = {}
    classification_counts: Counter[str] = Counter()
    for record, line in zip(records, record_lines, strict=True):
        code = record["course"]["code"]
        course_records[code].append(line)
        course_sources[code] = (
            record["source"]["source_id"],
            record["source"]["official_recognition"],
        )
        classification_counts[record["source"]["classification"]] += 1

    course_index = []
    for code in sorted(course_records):
        source_id, official_recognition = course_sources[code]
        course_index.append(
            {
                "course_code": code,
                "record_count": len(course_records[code]),
                "source_id": source_id,
                "official_recognition": official_recognition,
                "records_sha256": sha256_bytes(b"".join(course_records[code])),
            }
        )

    content_version = str(input_data.get("version", "unversioned"))
    effective_date = input_data.get("updated", ledger["effective_date"])
    require(isinstance(effective_date, str) and DATE_RE.fullmatch(effective_date), "invalid curriculum effective date")
    manifest = {
        "schema": PACK_SCHEMA,
        "pack_id": args.pack_id,
        "pack_version": args.pack_version,
        "jurisdiction": "CA-ON",
        "content_version": content_version,
        "effective_date": effective_date,
        "record_schema": RECORD_SCHEMA,
        "builder": {
            "name": "tools/curriculum_pack.py",
            "version": BUILDER_VERSION,
            "canonicalization": CANONICALIZATION,
        },
        "input": {"file": input_path.name, "sha256": input_digest},
        "source_ledger": {
            "file": ledger_path.name,
            "schema": ledger["schema"],
            "ledger_version": ledger["ledger_version"],
            "sha256": ledger_digest,
        },
        "records": {
            "file": "records.jsonl",
            "sha256": records_digest,
            "count": len(records),
            "course_count": len(course_index),
        },
        "course_index": course_index,
        "classification_counts": dict(sorted(classification_counts.items())),
    }
    write_atomic(output_dir / "manifest.json", canonical_bytes(manifest))
    verify_pack_directory(output_dir, public_key=None, require_signature=False)
    return manifest


def validate_manifest(manifest: Any) -> None:
    require(isinstance(manifest, dict), "manifest root must be an object")
    require(manifest.get("schema") == PACK_SCHEMA, "unsupported pack schema")
    require(isinstance(manifest.get("pack_id"), str), "manifest pack_id missing")
    require(isinstance(manifest.get("pack_version"), str) and SEMVER_RE.fullmatch(manifest["pack_version"]), "invalid manifest pack_version")
    require(manifest.get("jurisdiction") == "CA-ON", "manifest jurisdiction must be CA-ON")
    require(manifest.get("record_schema") == RECORD_SCHEMA, "unsupported record schema")
    builder = manifest.get("builder")
    require(isinstance(builder, dict), "manifest builder missing")
    require(builder.get("canonicalization") == CANONICALIZATION, "unsupported canonicalization")
    records = manifest.get("records")
    require(isinstance(records, dict), "manifest records missing")
    require(records.get("file") == "records.jsonl", "records file must be records.jsonl")
    require(isinstance(records.get("count"), int) and records["count"] > 0, "invalid records count")
    require(isinstance(records.get("course_count"), int) and records["course_count"] > 0, "invalid course count")
    require(isinstance(records.get("sha256"), str) and SHA256_RE.fullmatch(records["sha256"]), "invalid records digest")


def verify_record(record: Any) -> None:
    require(isinstance(record, dict), "curriculum record must be an object")
    require(record.get("schema") == RECORD_SCHEMA, "unsupported curriculum record schema")
    digest = record.get("content_digest")
    require(isinstance(digest, str) and SHA256_RE.fullmatch(digest), "invalid record content digest")
    core = dict(record)
    del core["content_digest"]
    require(sha256_bytes(canonical_bytes(core)) == digest, f"record content digest mismatch: {record.get('record_id')}")
    require(record.get("jurisdiction") == "CA-ON", "record jurisdiction must be CA-ON")
    course = record.get("course")
    require(isinstance(course, dict) and COURSE_CODE_RE.fullmatch(str(course.get("code", ""))), "invalid record course")
    source = record.get("source")
    require(isinstance(source, dict), "record source missing")
    require(isinstance(source.get("official_recognition"), bool), "record official_recognition missing")
    require(isinstance(source.get("ingestion_artifact_sha256"), str) and SHA256_RE.fullmatch(source["ingestion_artifact_sha256"]), "invalid ingestion digest")
    heuristics = record.get("adaptation_heuristics")
    require(isinstance(heuristics, dict) and heuristics.get("status") == "uncalibrated", "record heuristics must be uncalibrated")


def safe_pack_file(pack_dir: Path, filename: str) -> Path:
    require(Path(filename).name == filename and filename not in {".", ".."}, "unsafe pack filename")
    path = pack_dir / filename
    require(path.is_file() and not path.is_symlink(), f"missing or unsafe pack file: {filename}")
    return path


def verify_pack_directory(pack_dir: Path, *, public_key: Path | None, require_signature: bool) -> dict[str, Any]:
    pack_dir = pack_dir.resolve()
    require(pack_dir.is_dir() and not pack_dir.is_symlink(), "pack directory is missing or unsafe")
    allowed = {"manifest.json", "records.jsonl", "signature.json", "manifest.sig"}
    entries = {entry.name for entry in pack_dir.iterdir()}
    require(entries.issubset(allowed), f"unexpected pack files: {sorted(entries - allowed)}")

    manifest_path = safe_pack_file(pack_dir, "manifest.json")
    manifest, manifest_raw = read_json(manifest_path, maximum=16 * 1024 * 1024)
    validate_manifest(manifest)
    require(manifest_raw == canonical_bytes(manifest), "manifest is not canonical JSON")

    records_path = safe_pack_file(pack_dir, manifest["records"]["file"])
    require(sha256_file(records_path) == manifest["records"]["sha256"], "records digest mismatch")
    records_raw = records_path.read_bytes()
    require(len(records_raw) <= MAX_INPUT_BYTES, "records file exceeds size limit")
    lines = records_raw.splitlines(keepends=True)
    require(len(lines) == manifest["records"]["count"], "records count mismatch")
    require(len(lines) <= MAX_RECORDS, "records count exceeds limit")

    record_ids: list[str] = []
    course_lines: dict[str, list[bytes]] = defaultdict(list)
    course_sources: dict[str, tuple[str, bool]] = {}
    classifications: Counter[str] = Counter()
    for line in lines:
        require(line.endswith(b"\n") and len(line) <= MAX_RECORD_LINE_BYTES, "invalid JSONL record framing")
        try:
            record = json.loads(line.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise PackError(f"invalid record JSON: {error}") from error
        require(line == canonical_bytes(record), "record is not canonical JSON")
        verify_record(record)
        record_id = record["record_id"]
        require(isinstance(record_id, str), "record_id missing")
        record_ids.append(record_id)
        code = record["course"]["code"]
        course_lines[code].append(line)
        course_sources[code] = (record["source"]["source_id"], record["source"]["official_recognition"])
        classifications[record["source"]["classification"]] += 1
    require(record_ids == sorted(record_ids) and len(record_ids) == len(set(record_ids)), "records must be uniquely sorted")

    rebuilt_index = []
    for code in sorted(course_lines):
        source_id, official_recognition = course_sources[code]
        rebuilt_index.append(
            {
                "course_code": code,
                "record_count": len(course_lines[code]),
                "source_id": source_id,
                "official_recognition": official_recognition,
                "records_sha256": sha256_bytes(b"".join(course_lines[code])),
            }
        )
    require(rebuilt_index == manifest["course_index"], "course index mismatch")
    require(len(rebuilt_index) == manifest["records"]["course_count"], "course count mismatch")
    require(dict(sorted(classifications.items())) == manifest["classification_counts"], "classification counts mismatch")

    signature_path = pack_dir / "signature.json"
    if signature_path.exists():
        require(public_key is not None, "public key is required to verify a signed pack")
        verify_signature(pack_dir, manifest_raw, public_key)
    elif require_signature:
        raise PackError("curriculum pack signature is required")
    return manifest


def openssl_path() -> str:
    executable = shutil.which("openssl")
    require(executable is not None, "OpenSSL is required for Ed25519 signing and verification")
    return executable


def run_openssl(arguments: Iterable[str]) -> None:
    completed = subprocess.run(
        [openssl_path(), *arguments],
        check=False,
        capture_output=True,
        timeout=30,
    )
    if completed.returncode != 0:
        stderr = completed.stderr.decode("utf-8", errors="replace")[:2_000]
        raise PackError(f"OpenSSL command failed: {stderr.strip()}")


def key_id(public_key: Path) -> str:
    return f"sha256:{sha256_file(public_key, maximum=1024 * 1024)}"


def ensure_external_key(path: Path, pack_dir: Path, *, private: bool) -> Path:
    resolved = path.resolve()
    require(resolved.is_file() and not resolved.is_symlink(), f"missing or unsafe key: {path}")
    require(pack_dir not in resolved.parents, "signing keys must not be stored inside the pack")
    if private and os.name != "nt":
        require((resolved.stat().st_mode & 0o077) == 0, "private key permissions must not grant group or other access")
    return resolved


def sign_pack(args: argparse.Namespace) -> dict[str, Any]:
    pack_dir = args.pack_dir.resolve()
    verify_pack_directory(pack_dir, public_key=None, require_signature=False)
    private_key = ensure_external_key(args.private_key, pack_dir, private=True)
    public_key = ensure_external_key(args.public_key, pack_dir, private=False)
    signature_path = pack_dir / "manifest.sig"
    envelope_path = pack_dir / "signature.json"
    if not args.force:
        require(not signature_path.exists() and not envelope_path.exists(), "pack is already signed")

    with tempfile.NamedTemporaryFile(dir=pack_dir, prefix=".manifest.sig.", delete=False) as handle:
        temporary_signature = Path(handle.name)
    try:
        run_openssl(
            [
                "pkeyutl",
                "-sign",
                "-rawin",
                "-inkey",
                str(private_key),
                "-in",
                str(pack_dir / "manifest.json"),
                "-out",
                str(temporary_signature),
            ]
        )
        signature_bytes = temporary_signature.read_bytes()
        require(32 <= len(signature_bytes) <= 256, "unexpected Ed25519 signature length")
        write_atomic(signature_path, signature_bytes)
    finally:
        temporary_signature.unlink(missing_ok=True)

    manifest_raw = (pack_dir / "manifest.json").read_bytes()
    envelope = {
        "schema": SIGNATURE_SCHEMA,
        "algorithm": "Ed25519",
        "key_id": key_id(public_key),
        "manifest_sha256": sha256_bytes(manifest_raw),
        "signature_file": "manifest.sig",
        "signature_sha256": sha256_bytes(signature_path.read_bytes()),
    }
    write_atomic(envelope_path, canonical_bytes(envelope))
    verify_pack_directory(pack_dir, public_key=public_key, require_signature=True)
    return envelope


def verify_signature(pack_dir: Path, manifest_raw: bytes, public_key: Path) -> None:
    public_key = ensure_external_key(public_key, pack_dir, private=False)
    envelope_path = safe_pack_file(pack_dir, "signature.json")
    signature_path = safe_pack_file(pack_dir, "manifest.sig")
    envelope, envelope_raw = read_json(envelope_path, maximum=64 * 1024)
    require(envelope_raw == canonical_bytes(envelope), "signature envelope is not canonical JSON")
    require(isinstance(envelope, dict) and envelope.get("schema") == SIGNATURE_SCHEMA, "unsupported signature schema")
    require(envelope.get("algorithm") == "Ed25519", "unsupported signature algorithm")
    require(envelope.get("key_id") == key_id(public_key), "signature key id mismatch")
    require(envelope.get("manifest_sha256") == sha256_bytes(manifest_raw), "signed manifest digest mismatch")
    require(envelope.get("signature_file") == "manifest.sig", "unexpected signature filename")
    require(envelope.get("signature_sha256") == sha256_file(signature_path, maximum=1024), "signature digest mismatch")
    run_openssl(
        [
            "pkeyutl",
            "-verify",
            "-rawin",
            "-pubin",
            "-inkey",
            str(public_key),
            "-in",
            str(pack_dir / "manifest.json"),
            "-sigfile",
            str(signature_path),
        ]
    )


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description=__doc__)
    subcommands = root.add_subparsers(dest="command", required=True)

    build = subcommands.add_parser("build", help="build a deterministic curriculum pack")
    build.add_argument("--input", type=Path, required=True)
    build.add_argument("--ledger", type=Path, required=True)
    build.add_argument("--output", type=Path, required=True)
    build.add_argument("--pack-id", default="ontario-secondary")
    build.add_argument("--pack-version", default="1.0.0")

    verify = subcommands.add_parser("verify", help="verify pack digests and optional signature")
    verify.add_argument("--pack-dir", type=Path, required=True)
    verify.add_argument("--public-key", type=Path)
    verify.add_argument("--require-signature", action="store_true")

    sign = subcommands.add_parser("sign", help="sign an existing pack with an external Ed25519 key")
    sign.add_argument("--pack-dir", type=Path, required=True)
    sign.add_argument("--private-key", type=Path, required=True)
    sign.add_argument("--public-key", type=Path, required=True)
    sign.add_argument("--force", action="store_true")
    return root


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "build":
            manifest = build_pack(args)
            print(json.dumps({"pack_id": manifest["pack_id"], "records": manifest["records"]}, sort_keys=True))
        elif args.command == "verify":
            manifest = verify_pack_directory(
                args.pack_dir,
                public_key=args.public_key.resolve() if args.public_key else None,
                require_signature=args.require_signature,
            )
            print(json.dumps({"verified": True, "pack_id": manifest["pack_id"], "records": manifest["records"]["count"]}, sort_keys=True))
        elif args.command == "sign":
            envelope = sign_pack(args)
            print(json.dumps({"signed": True, "key_id": envelope["key_id"]}, sort_keys=True))
        else:  # pragma: no cover
            raise PackError(f"unsupported command: {args.command}")
    except (OSError, PackError, subprocess.TimeoutExpired) as error:
        print(f"curriculum pack operation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
