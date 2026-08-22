from __future__ import annotations

import json
import shutil
from pathlib import Path

import pytest

from tools.vendored_sqlite import (
    HOOK_BLOCK,
    PROVENANCE_RELATIVE_PATH,
    README_RELATIVE_PATH,
    SOURCE_RELATIVE_PATH,
    VendoredSqliteError,
    expected_provenance,
    expected_readme,
    verify,
)

ROOT = Path(__file__).resolve().parents[1]


def make_fixture(tmp_path: Path) -> Path:
    source = tmp_path / SOURCE_RELATIVE_PATH
    source.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ROOT / SOURCE_RELATIVE_PATH, source)
    (tmp_path / PROVENANCE_RELATIVE_PATH).write_text(
        json.dumps(expected_provenance(), indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    (tmp_path / README_RELATIVE_PATH).write_text(expected_readme(), encoding="utf-8")
    (tmp_path / "pubspec.yaml").write_text(
        f"name: vendored_sqlite_fixture\n{HOOK_BLOCK}\nflutter:\n  uses-material-design: true\n",
        encoding="utf-8",
    )
    return tmp_path


def test_current_vendored_sqlite_is_exactly_verified() -> None:
    verify(ROOT)


def test_rejects_vendored_source_byte_drift(tmp_path: Path) -> None:
    root = make_fixture(tmp_path)
    path = root / SOURCE_RELATIVE_PATH
    data = bytearray(path.read_bytes())
    data[len(data) // 2] ^= 0x01
    path.write_bytes(data)
    with pytest.raises(VendoredSqliteError, match="vendored sqlite3.c SHA3-256 mismatch"):
        verify(root)


def test_rejects_provenance_drift(tmp_path: Path) -> None:
    root = make_fixture(tmp_path)
    path = root / PROVENANCE_RELATIVE_PATH
    provenance = json.loads(path.read_text(encoding="utf-8"))
    provenance["sqlite_version"] = "0.0.0"
    path.write_text(json.dumps(provenance, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    with pytest.raises(VendoredSqliteError, match="provenance drift"):
        verify(root)


def test_rejects_missing_source_hook(tmp_path: Path) -> None:
    root = make_fixture(tmp_path)
    (root / "pubspec.yaml").write_text(
        "name: vendored_sqlite_fixture\nflutter:\n  uses-material-design: true\n",
        encoding="utf-8",
    )
    with pytest.raises(VendoredSqliteError, match="not pinned to vendored SQLite source"):
        verify(root)


def test_rejects_readme_drift(tmp_path: Path) -> None:
    root = make_fixture(tmp_path)
    (root / README_RELATIVE_PATH).write_text("stale provenance documentation\n", encoding="utf-8")
    with pytest.raises(VendoredSqliteError, match="README drift"):
        verify(root)
