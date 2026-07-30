from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FULL = ROOT / "assets" / "curriculum" / "ontario_curriculum_full.json"
SLICE = ROOT / "curriculum" / "slices" / "mth1w.v1.json"
LEDGER = ROOT / "curriculum" / "source-ledger.v1.json"
BUILDER = ROOT / "tools" / "curriculum_pack.py"

EXPECTED_IDS = [
    "MTH1W-A1",
    "MTH1W-A2",
    "MTH1W-A3",
    "MTH1W-B1",
    "MTH1W-B2",
    "MTH1W-B3",
    "MTH1W-B4",
    "MTH1W-C1",
    "MTH1W-C2",
    "MTH1W-D1",
    "MTH1W-D2",
]


class Mth1wSliceTests(unittest.TestCase):
    def test_slice_is_exact_projection_of_full_corpus(self) -> None:
        full = json.loads(FULL.read_text(encoding="utf-8"))
        subset = json.loads(SLICE.read_text(encoding="utf-8"))

        self.assertEqual(list(subset["courses"]), ["MTH1W"])
        self.assertEqual(subset["courses"]["MTH1W"], full["courses"]["MTH1W"])
        self.assertEqual(subset["version"], full["version"])
        self.assertEqual(subset["updated"], full["updated"])
        self.assertEqual(subset["legal_note"], full["legal_note"])

        identifiers = [
            expectation["id"]
            for strand in subset["courses"]["MTH1W"]["strands"].values()
            for expectation in strand
        ]
        self.assertEqual(identifiers, EXPECTED_IDS)

    def test_pack_build_is_byte_identical_and_contains_11_records(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            first = root / "first"
            second = root / "second"
            for output in (first, second):
                subprocess.run(
                    [
                        sys.executable,
                        str(BUILDER),
                        "build",
                        "--input",
                        str(SLICE),
                        "--ledger",
                        str(LEDGER),
                        "--output",
                        str(output),
                        "--pack-id",
                        "ontario-mth1w-phase-1",
                        "--pack-version",
                        "1.0.0",
                    ],
                    cwd=ROOT,
                    check=True,
                    capture_output=True,
                    text=True,
                )

            self.assertEqual(
                (first / "manifest.json").read_bytes(),
                (second / "manifest.json").read_bytes(),
            )
            self.assertEqual(
                (first / "records.jsonl").read_bytes(),
                (second / "records.jsonl").read_bytes(),
            )
            records = (first / "records.jsonl").read_text(encoding="utf-8").splitlines()
            self.assertEqual(len(records), 11)


if __name__ == "__main__":
    unittest.main()
