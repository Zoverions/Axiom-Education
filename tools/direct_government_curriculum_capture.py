#!/usr/bin/env python3
"""Capture exact Ontario-government curriculum routes already admitted by C0 discovery.

This path is narrower than the publication-CDN capture mechanism: every target must use
the exact HTTPS source locator already present in discovery, on an Ontario government
host, with no redirect to a different host. Downloaded bytes are temporary and discarded
after a metadata-only C1 lock candidate is emitted.
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
TARGETS_PATH = (
    ROOT
    / "curriculum"
    / "ontario-elementary"
    / "direct-government-capture-targets.v1.json"
)
DISCOVERY_PATH = (
    ROOT / "curriculum" / "ontario-elementary" / "source-discovery.v0.json"
)

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


class DirectGovernmentCaptureError(RuntimeError):
    """Raised when a direct-government target violates the bounded capture policy."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise DirectGovernmentCaptureError(message)


def load_targets(path: Path = TARGETS_PATH) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise DirectGovernmentCaptureError(
            f"missing direct-government target registry: {path}"
        ) from error
    except json.JSONDecodeError as error:
        raise DirectGovernmentCaptureError(
            f"invalid direct-government target JSON: {error}"
        ) from error
    require(isinstance(payload, dict), "direct target registry root must be an object")
    require(
        payload.get("schema")
        == "axiom-curriculum-direct-government-capture-targets.v1",
        "unsupported direct-government target schema",
    )
    targets = payload.get("targets")
    require(isinstance(targets, list), "direct-government targets must be an array")
    return payload


def validate_https_government_url(url: object, expected_host: str, field: str) -> str:
    require(isinstance(url, str) and url, f"{field} is required")
    parsed = urllib.parse.urlparse(url)
    require(parsed.scheme == "https", f"{field} must use HTTPS")
    require(parsed.hostname == expected_host, f"{field} must remain on {expected_host}")
    require(
        expected_host.endswith(".gov.on.ca") or expected_host == "gov.on.ca",
        f"{field} host is not an Ontario government host",
    )
    require(parsed.username is None and parsed.password is None, f"{field} cannot contain credentials")
    require(parsed.fragment == "", f"{field} cannot contain a fragment")
    return url


def validate_target_registry(path: Path = TARGETS_PATH) -> dict[str, dict[str, Any]]:
    payload = load_targets(path)
    discovery = load_discovery(DISCOVERY_PATH)
    require(
        payload.get("jurisdiction_id") == discovery.get("jurisdiction_id"),
        "direct target registry jurisdiction mismatch",
    )
    discovery_sources = {
        item.get("source_id"): item
        for item in discovery.get("confirmed_curriculum_sources", [])
        if isinstance(item, dict) and isinstance(item.get("source_id"), str)
    }

    index: dict[str, dict[str, Any]] = {}
    for target in payload["targets"]:
        require(isinstance(target, dict), "direct-government target must be an object")
        source_id = target.get("source_id")
        require(isinstance(source_id, str) and source_id, "direct target source_id is required")
        require(source_id not in index, f"duplicate direct target source_id: {source_id}")
        source = discovery_sources.get(source_id)
        require(
            isinstance(source, dict),
            f"direct target references unknown discovery source: {source_id}",
        )
        host = target.get("allowed_host")
        require(isinstance(host, str) and host, f"{source_id}: allowed_host is required")
        locator = validate_https_government_url(
            target.get("source_locator"), host, f"{source_id}: source_locator"
        )
        download = validate_https_government_url(
            target.get("download_url"), host, f"{source_id}: download_url"
        )
        require(
            download == locator,
            f"{source_id}: direct-government download_url must equal source_locator exactly",
        )
        require(
            locator in source_locators(source),
            f"{source_id}: direct source locator is not present in C0 discovery",
        )
        expected_media = target.get("expected_media_type")
        require(
            expected_media in {"text/html", "application/pdf"},
            f"{source_id}: unsupported expected_media_type",
        )
        maximum_bytes = target.get("maximum_bytes")
        require(
            isinstance(maximum_bytes, int)
            and 1024 <= maximum_bytes <= 250 * 1024 * 1024,
            f"{source_id}: maximum_bytes is outside the safe range",
        )
        require(
            target.get("redistribution_status") in {"review-required", "external-only"},
            f"{source_id}: direct capture cannot pre-approve redistribution",
        )
        index[source_id] = target
    return index


class SameHostRedirectHandler(urllib.request.HTTPRedirectHandler):
    def __init__(self, expected_host: str):
        super().__init__()
        self.expected_host = expected_host

    def redirect_request(self, req, fp, code, msg, headers, newurl):  # type: ignore[override]
        validate_https_government_url(newurl, self.expected_host, "redirect URL")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def download_target(target: dict[str, Any], destination: Path) -> tuple[str, str]:
    host = str(target["allowed_host"])
    url = validate_https_government_url(target["download_url"], host, "download_url")
    opener = urllib.request.build_opener(SameHostRedirectHandler(host))
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Axiom-Education-Direct-Curriculum-Capture/1.0 (+metadata-only)",
            "Accept": str(target["expected_media_type"]),
        },
        method="GET",
    )
    maximum_bytes = int(target["maximum_bytes"])
    try:
        with opener.open(request, timeout=45) as response, destination.open("wb") as output:
            final_url = response.geturl()
            validate_https_government_url(final_url, host, "resolved URL")
            media_type = response.headers.get_content_type()
            require(
                media_type == target["expected_media_type"],
                f"unexpected media type: expected {target['expected_media_type']}, got {media_type}",
            )
            declared = response.headers.get("Content-Length")
            if declared is not None:
                try:
                    declared_bytes = int(declared)
                except ValueError as error:
                    raise DirectGovernmentCaptureError(
                        "invalid Content-Length from official source"
                    ) from error
                require(
                    declared_bytes <= maximum_bytes,
                    "official source exceeds maximum_bytes",
                )

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
            require(total > 0, "official source returned zero bytes")
            if media_type == "application/pdf":
                require(prefix.startswith(b"%PDF-"), "PDF target lacks PDF file signature")
            return final_url, media_type
    except (urllib.error.URLError, TimeoutError) as error:
        raise DirectGovernmentCaptureError(
            f"direct official source download failed: {error}"
        ) from error


def capture(source_id: str, output: Path) -> dict[str, Any]:
    targets = validate_target_registry()
    target = targets.get(source_id)
    require(target is not None, f"source_id is not a direct-government capture target: {source_id}")
    target_digest = canonical_json_digest(target)
    run_id = os.environ.get("GITHUB_RUN_ID")
    run_attempt = os.environ.get("GITHUB_RUN_ATTEMPT")

    with tempfile.TemporaryDirectory(prefix="axiom-direct-curriculum-") as directory:
        source_path = Path(directory) / "source.bin"
        resolved_url, media_type = download_target(target, source_path)
        notes = (
            f"Exact direct-government capture target {target_digest}. "
            f"GitHub run {run_id or 'local'} attempt {run_attempt or 'local'}. "
            "Downloaded bytes were discarded after hashing. C1 capture does not resolve version-history, licensing, or review questions."
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
        output.write_text(
            json.dumps(lock, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        verify_lock(output, DISCOVERY_PATH)
        source_path.unlink(missing_ok=True)
        return lock


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("validate-targets")
    capture_parser = commands.add_parser("capture")
    capture_parser.add_argument("--source-id", required=True)
    capture_parser.add_argument("--output", required=True, type=Path)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "validate-targets":
            targets = validate_target_registry()
            print(f"direct-government capture targets verified: {len(targets)}")
        else:
            lock = capture(args.source_id, args.output)
            print(
                "direct-government C1 candidate captured: "
                f"{lock['source_id']} bytes={lock['byte_length']} sha256={lock['sha256']}"
            )
    except (
        OSError,
        KeyError,
        SourceLockError,
        DirectGovernmentCaptureError,
        ValueError,
    ) as error:
        print(f"direct government curriculum capture failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
