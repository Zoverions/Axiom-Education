#!/usr/bin/env python3
"""Prepare and verify the vendored SQLite amalgamation used by native builds."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

SQLITE_VERSION = "3.53.4"
SQLITE_VERSION_NUMBER = "3530400"
SQLITE_RELEASE_DATE = "2026-07-24"
SQLITE_ARCHIVE_URL = (
    "https://www.sqlite.org/2026/"
    f"sqlite-amalgamation-{SQLITE_VERSION_NUMBER}.zip"
)
SQLITE_ARCHIVE_SHA3_256 = (
    "628a44cfe82c66aed1ccbbe85a562d2e33ebe64b3288981ed76285612227934e"
)
SQLITE_C_SHA3_256 = (
    "67f423e9ebbbdc473cbc4772c872ee6b89f31fde4ed0279a5c25d5f65c043a16"
)
SQLITE_SOURCE_ID = (
    "2026-07-24 19:02:57 "
    "bf7c7f30031888f4e796e429ab3978879485813aaca6f641c7b33e4e09459bcc"
)
SOURCE_RELATIVE_PATH = Path("third_party/sqlite/sqlite3.c")
PROVENANCE_RELATIVE_PATH = Path("third_party/sqlite/PROVENANCE.json")
README_RELATIVE_PATH = Path("third_party/sqlite/README.md")
ARCHIVE_MEMBER = f"sqlite-amalgamation-{SQLITE_VERSION_NUMBER}/sqlite3.c"

HOOK_BLOCK = """hooks:
  user_defines:
    sqlite3:
      source: source
      path: third_party/sqlite/sqlite3.c
"""


class VendoredSqliteError(RuntimeError):
    """Raised when vendored SQLite evidence or configuration is invalid."""


def sha3_256(data: bytes) -> str:
    return hashlib.sha3_256(data).hexdigest()


def expected_provenance() -> dict[str, object]:
    return {
        "schema": "axiom-education-vendored-sqlite.v1",
        "authority": "SQLite.org",
        "sqlite_version": SQLITE_VERSION,
        "sqlite_version_number": SQLITE_VERSION_NUMBER,
        "release_date": SQLITE_RELEASE_DATE,
        "source_id": SQLITE_SOURCE_ID,
        "archive_url": SQLITE_ARCHIVE_URL,
        "archive_sha3_256": SQLITE_ARCHIVE_SHA3_256,
        "archive_member": ARCHIVE_MEMBER,
        "source_path": SOURCE_RELATIVE_PATH.as_posix(),
        "source_sha3_256": SQLITE_C_SHA3_256,
        "license": "public-domain",
        "package_hook_mode": "source",
        "default_sqlite3_package_compile_options": True,
        "archive_retained": False,
    }


def expected_readme() -> str:
    return f"""# Vendored SQLite source

Axiom Education compiles SQLite from the official SQLite.org amalgamation instead of
fetching precompiled `package:sqlite3` release assets during native builds.

Pinned upstream release: **SQLite {SQLITE_VERSION} ({SQLITE_RELEASE_DATE})**

- authority: SQLite.org
- archive: `{SQLITE_ARCHIVE_URL}`
- archive SHA3-256: `{SQLITE_ARCHIVE_SHA3_256}`
- `sqlite3.c` SHA3-256: `{SQLITE_C_SHA3_256}`
- SQLite source ID: `{SQLITE_SOURCE_ID}`
- license: public domain

`pubspec.yaml` selects `package:sqlite3` build-hook `source: source` and points at
`third_party/sqlite/sqlite3.c`. The package's default SQLite compile-time options
remain enabled. The downloaded archive is not retained.

`python tools/vendored_sqlite.py verify` fails closed if the source, provenance, or
hook configuration drifts.
"""


def download_archive(*, attempts: int = 4, timeout_seconds: int = 60) -> bytes:
    request = urllib.request.Request(
        SQLITE_ARCHIVE_URL,
        headers={"User-Agent": "Axiom-Education-SQLite-Provenance/1"},
    )
    last_error: Exception | None = None
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
                data = response.read()
            actual = sha3_256(data)
            if actual != SQLITE_ARCHIVE_SHA3_256:
                raise VendoredSqliteError(
                    "SQLite amalgamation archive SHA3-256 mismatch: "
                    f"expected {SQLITE_ARCHIVE_SHA3_256}, got {actual}"
                )
            return data
        except (OSError, urllib.error.URLError, VendoredSqliteError) as error:
            last_error = error
            if attempt < attempts:
                time.sleep(min(2 ** (attempt - 1), 8))
    raise VendoredSqliteError(
        f"unable to fetch verified SQLite amalgamation after {attempts} attempts: "
        f"{last_error}"
    )


def extract_sqlite_c(archive: bytes) -> bytes:
    try:
        with zipfile.ZipFile(io.BytesIO(archive)) as bundle:
            source = bundle.read(ARCHIVE_MEMBER)
    except (KeyError, zipfile.BadZipFile) as error:
        raise VendoredSqliteError(
            f"SQLite amalgamation does not contain {ARCHIVE_MEMBER}"
        ) from error
    actual = sha3_256(source)
    if actual != SQLITE_C_SHA3_256:
        raise VendoredSqliteError(
            "sqlite3.c SHA3-256 mismatch: "
            f"expected {SQLITE_C_SHA3_256}, got {actual}"
        )
    return source


def configure_pubspec(root: Path) -> None:
    path = root / "pubspec.yaml"
    text = path.read_text(encoding="utf-8")
    if HOOK_BLOCK in text:
        return
    if "\nhooks:\n" in text or text.startswith("hooks:\n"):
        raise VendoredSqliteError(
            "pubspec.yaml already contains a different hooks configuration"
        )
    marker = "\nflutter:\n"
    if marker not in text:
        raise VendoredSqliteError("pubspec.yaml has no top-level flutter section")
    updated = text.replace(marker, f"\n{HOOK_BLOCK}{marker}", 1)
    path.write_text(updated, encoding="utf-8")


def prepare(root: Path) -> None:
    archive = download_archive()
    source = extract_sqlite_c(archive)
    source_path = root / SOURCE_RELATIVE_PATH
    source_path.parent.mkdir(parents=True, exist_ok=True)
    source_path.write_bytes(source)
    (root / PROVENANCE_RELATIVE_PATH).write_text(
        json.dumps(expected_provenance(), indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    (root / README_RELATIVE_PATH).write_text(expected_readme(), encoding="utf-8")
    configure_pubspec(root)
    verify(root)


def verify(root: Path) -> None:
    source_path = root / SOURCE_RELATIVE_PATH
    if not source_path.is_file():
        raise VendoredSqliteError(f"missing vendored SQLite source: {source_path}")
    actual_source = sha3_256(source_path.read_bytes())
    if actual_source != SQLITE_C_SHA3_256:
        raise VendoredSqliteError(
            "vendored sqlite3.c SHA3-256 mismatch: "
            f"expected {SQLITE_C_SHA3_256}, got {actual_source}"
        )

    provenance_path = root / PROVENANCE_RELATIVE_PATH
    try:
        provenance = json.loads(provenance_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise VendoredSqliteError("invalid vendored SQLite provenance") from error
    if provenance != expected_provenance():
        raise VendoredSqliteError("vendored SQLite provenance drift")

    readme_path = root / README_RELATIVE_PATH
    try:
        readme = readme_path.read_text(encoding="utf-8")
    except OSError as error:
        raise VendoredSqliteError("missing vendored SQLite README") from error
    if readme != expected_readme():
        raise VendoredSqliteError("vendored SQLite README drift")

    pubspec = (root / "pubspec.yaml").read_text(encoding="utf-8")
    if HOOK_BLOCK not in pubspec:
        raise VendoredSqliteError("pubspec.yaml is not pinned to vendored SQLite source")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("prepare", "verify"))
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    root = args.root.resolve()
    if args.command == "prepare":
        prepare(root)
    else:
        verify(root)
    print(
        json.dumps(
            {
                "valid": True,
                "sqlite_version": SQLITE_VERSION,
                "source_sha3_256": SQLITE_C_SHA3_256,
                "hook_mode": "source",
            },
            sort_keys=True,
            separators=(",", ":"),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
