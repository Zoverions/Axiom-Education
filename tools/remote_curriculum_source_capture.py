#!/usr/bin/env python3
"""Capture predeclared official curriculum bytes and emit metadata-only C1 lock candidates.

Remote capture is deliberately allowlisted. The caller supplies a source_id, never an
arbitrary URL. Downloaded bytes are held only in a temporary file and deleted after the
lock candidate is written.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
TARGETS_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-capture-targets.v1.json"
DISCOVERY_PATH = ROOT / "curriculum" / "ontario-elementary" / "source-discovery.v0.json"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.curriculum_source_lock import (  # noqa: E402
    SourceLockError,
    canonical_json_digest,
    create_lock,
    load_discovery,
    source_locators,
    verify_lock,
)


class RemoteCaptureError(RuntimeError):
    """Raised when a remote capture target or download violates the bounded policy."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RemoteCaptureError(message)


def load_targets(path: Path = TARGETS_PATH) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise RemoteCaptureError(f"missing capture target registry: {path}") from error
    except json.JSONDecodeError as error:
        raise RemoteCaptureError(f"invalid capture target JSON: {error}") from error
    require(isinstance(payload, dict), "capture target registry root must be an object")
    require(
        payload.get("schema") == "axiom-curriculum-remote-capture-targets.v1",
        "unsupported capture target schema",
    )
    targets = payload.get("targets")
    require(isinstance(targets, list), "capture targets must be an array")
    return payload


def validate_url(url: object, allowed_hosts: set[str], field: str) -> str:
    require(isinstance(url, str) and url, f"{field} is required")
    parsed = urllib.parse.urlparse(url)
    require(parsed.scheme == "https", f"{field} must use HTTPS")
    require(parsed.hostname in allowed_hosts, f"{field} host is not allowlisted: {parsed.hostname}")
    require(parsed.username is None and parsed.password is None, f"{field} must not contain credentials")
    require(parsed.fragment == "", f"{field} must not contain a fragment")
    return url


def validate_target_registry(path: Path = TARGETS_PATH) -> dict[str, dict[str, Any]]:
    payload = load_targets(path)
    discovery = load_discovery(DISCOVERY_PATH)
    require(payload.get("jurisdiction_id") == discovery.get("jurisdiction_id"), "target registry jurisdiction mismatch")
    discovery_sources = {
        item.get("source_id"): item
        for item in discovery.get("confirmed_curriculum_sources", [])
        if isinstance(item, dict) and isinstance(item.get("source_id"), str)
    }

    index: dict[str, dict[str, Any]] = {}
    for target in payload["targets"]:
        require(isinstance(target, dict), "capture target must be an object")
        source_id = target.get("source_id")
        require(isinstance(source_id, str) and source_id, "capture target source_id is required")
        require(source_id not in index, f"duplicate capture target source_id: {source_id}")
        source = discovery_sources.get(source_id)
        require(isinstance(source, dict), f"capture target references unknown discovery source: {source_id}")

        allowed_raw = target.get("allowed_hosts")
        require(
            isinstance(allowed_raw, list)
            and allowed_raw
            and all(isinstance(host, str) and host for host in allowed_raw),
            f"{source_id}: allowed_hosts must be a non-empty string array",
        )
        allowed_hosts = set(allowed_raw)
        require(len(allowed_hosts) == len(allowed_raw), f"{source_id}: allowed_hosts contains duplicates")
        for host in allowed_hosts:
            require(host.endswith(".gov.on.ca") or host == "gov.on.ca", f"{source_id}: non-Ontario-government host is forbidden: {host}")

        source_locator = target.get("source_locator")
        require(
            source_locator in source_locators(source),
            f"{source_id}: source_locator must already be recorded in C0 discovery",
        )
        download_url = validate_url(target.get("download_url"), allowed_hosts, f"{source_id}: download_url")
        require(
            urllib.parse.urlparse(download_url).hostname in allowed_hosts,
            f"{source_id}: download host is not allowlisted",
        )
        expected_media = target.get("expected_media_type")
        require(isinstance(expected_media, str) and expected_media, f"{source_id}: expected_media_type is required")
        maximum_bytes = target.get("maximum_bytes")
        require(
            isinstance(maximum_bytes, int) and 1024 <= maximum_bytes <= 250 * 1024 * 1024,
            f"{source_id}: maximum_bytes is outside the safe range",
        )
        require(
            target.get("redistribution_status") in {"review-required", "external-only"},
            f"{source_id}: remote capture cannot pre-approve redistribution",
        )
        publication_url = target.get("publication_catalog_url")
        if publication_url is not None:
            parsed = urllib.parse.urlparse(str(publication_url))
            require(parsed.scheme == "https" and parsed.hostname == "www.publications.gov.on.ca", f"{source_id}: publication catalog must be Publications Ontario")
        index[source_id] = target
    return index


class AllowlistedRedirectHandler(urllib.request.HTTPRedirectHandler):
    def __init__(self, allowed_hosts: set[str]):
        super().__init__()
        self.allowed_hosts = allowed_hosts

    def redirect_request(self, req, fp, code, msg, headers, newurl):  # type: ignore[override]
        validate_url(newurl, self.allowed_hosts, "redirect URL")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def download_target(target: dict[str, Any], destination: Path) -> tuple[str, str]:
    allowed_hosts = set(target["allowed_hosts"])
    download_url = validate_url(target["download_url"], allowed_hosts, "download_url")
    opener = urllib.request.build_opener(AllowlistedRedirectHandler(allowed_hosts))
    request = urllib.request.Request(
        download_url,
        headers={
            "User-Agent": "Axiom-Education-Curriculum-Capture/1.0 (+metadata-only)",
            "Accept": target["expected_media_type"],
        },
        method="GET",
    )
    maximum_bytes = int(target["maximum_bytes"])
    try:
        with opener.open(request, timeout=45) as response, destination.open("wb") as output:
            final_url = response.geturl()
            validate_url(final_url, allowed_hosts, "resolved URL")
            media_type = response.headers.get_content_type()
            require(
                media_type == target["expected_media_type"],
                f"unexpected media type: expected {target['expected_media_type']}, got {media_type}",
            )
            content_length = response.headers.get("Content-Length")
            if content_length is not None:
                try:
                    declared = int(content_length)
                except ValueError as error:
                    raise RemoteCaptureError("invalid Content-Length from upstream") from error
                require(declared <= maximum_bytes, "upstream content exceeds maximum_bytes")

            total = 0
            prefix = b""
            while True:
                chunk = response.read(min(1024 * 1024, maximum_bytes - total + 1))
                if not chunk:
                    break
                total += len(chunk)
                require(total <= maximum_bytes, "download exceeded maximum_bytes")
                if len(prefix) < 8:
                    prefix += chunk[: 8 - len(prefix)]
                output.write(chunk)
            require(total > 0, "upstream source returned zero bytes")
            if media_type == "application/pdf":
                require(prefix.startswith(b"%PDF-"), "PDF target does not contain a PDF file signature")
            return final_url, media_type
    except (urllib.error.URLError, TimeoutError) as error:
        raise RemoteCaptureError(f"official source download failed: {error}") from error


def capture(source_id: str, output: Path) -> dict[str, Any]:
    targets = validate_target_registry()
    target = targets.get(source_id)
    require(target is not None, f"source_id is not an allowlisted capture target: {source_id}")
    run_id = os.environ.get("GITHUB_RUN_ID")
    run_attempt = os.environ.get("GITHUB_RUN_ATTEMPT")
    target_digest = canonical_json_digest(target)

    with tempfile.TemporaryDirectory(prefix="axiom-curriculum-capture-") as directory:
        source_path = Path(directory) / "source.bin"
        resolved_url, media_type = download_target(target, source_path)
        notes = (
            f"Allowlisted remote capture target {target_digest}. "
            f"GitHub run {run_id or 'local'} attempt {run_attempt or 'local'}. "
            "Downloaded source bytes were discarded after hashing; this lock candidate does not approve redistribution."
        )
        lock = create_lock(
            source_id=source_id,
            input_path=source_path,
            source_locator=target["source_locator"],
            resolved_locator=resolved_url,
            media_type=media_type,
            discovery_path=DISCOVERY_PATH,
            redistribution_status=target["redistribution_status"],
            retained_path=None,
            notes=notes,
        )
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(lock, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        verify_lock(output, DISCOVERY_PATH)
        source_path.unlink(missing_ok=True)
        return lock


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("validate-targets", help="validate the allowlisted capture target registry without network access")
    capture_parser = commands.add_parser("capture", help="capture one predeclared official source and emit a lock candidate")
    capture_parser.add_argument("--source-id", required=True)
    capture_parser.add_argument("--output", required=True, type=Path)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "validate-targets":
            targets = validate_target_registry()
            print(f"remote capture targets verified: {len(targets)} allowlisted target(s)")
        else:
            lock = capture(args.source_id, args.output)
            print(
                "C1 source-lock candidate captured: "
                f"{lock['source_id']} bytes={lock['byte_length']} sha256={lock['sha256']}"
            )
    except (OSError, KeyError, RemoteCaptureError, SourceLockError, ValueError) as error:
        print(f"remote curriculum source capture failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
