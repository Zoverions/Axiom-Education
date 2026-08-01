#!/usr/bin/env python3
"""Build and verify a non-verbatim inventory of official MTH1W expectations."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INVENTORY_PATH = (
    ROOT / "curriculum" / "official" / "ontario-mth1w-2021.inventory.json"
)
SOURCE_SHA256 = "a153c03a809551770403376db606815ee10577c36c425533495ef1abb8da91aa"
SOURCE_URL = (
    "https://assets-us-01.kc-usercontent.com/fbd574c4-da36-0066-a0c5-"
    "849ffb2de96e/9f57c5ea-424b-42de-9152-68b4181655de/"
    "The%20Ontario%20Curriculum%20-%20Mathematics%20Grade%209%20"
    "De-streamed%20Course%202021_with%20Teacher%20Supports.pdf"
)
COPYRIGHT_URL = "https://www.ontario.ca/page/copyright-information"

STRANDS = {
    "AA": "Social-Emotional Learning Skills in Mathematics",
    "A": "Mathematical Thinking and Making Connections",
    "B": "Number",
    "C": "Algebra",
    "D": "Data",
    "E": "Geometry and Measurement",
    "F": "Financial Literacy",
}

EXPECTATION_PAGES = {
    "AA1": 62,
    "A1": 70,
    "A2": 74,
    "B1": 78,
    "B1.1": 78,
    "B1.2": 80,
    "B1.3": 82,
    "B2": 87,
    "B2.1": 87,
    "B2.2": 90,
    "B3": 92,
    "B3.1": 92,
    "B3.2": 94,
    "B3.3": 97,
    "B3.4": 99,
    "B3.5": 101,
    "C1": 105,
    "C1.1": 105,
    "C1.2": 107,
    "C1.3": 111,
    "C1.4": 116,
    "C1.5": 118,
    "C2": 121,
    "C2.1": 121,
    "C2.2": 124,
    "C2.3": 127,
    "C3": 131,
    "C3.1": 131,
    "C3.2": 136,
    "C3.3": 139,
    "C4": 141,
    "C4.1": 141,
    "C4.2": 143,
    "C4.3": 147,
    "C4.4": 151,
    "D1": 156,
    "D1.1": 156,
    "D1.2": 158,
    "D1.3": 162,
    "D2": 166,
    "D2.1": 166,
    "D2.2": 167,
    "D2.3": 170,
    "D2.4": 172,
    "D2.5": 174,
    "E1": 176,
    "E1.1": 176,
    "E1.2": 178,
    "E1.3": 185,
    "E1.4": 188,
    "E1.5": 191,
    "E1.6": 195,
    "F1": 199,
    "F1.1": 199,
    "F1.2": 201,
    "F1.3": 204,
    "F1.4": 206,
}

OVERALL_IDS = {
    "AA1",
    "A1",
    "A2",
    "B1",
    "B2",
    "B3",
    "C1",
    "C2",
    "C3",
    "C4",
    "D1",
    "D2",
    "E1",
    "F1",
}

EXPECTED_TITLES = {
    "AA1": "Social-Emotional Learning Skills",
    "A1": "Mathematical Processes",
    "A2": "Making Connections",
    "B1": "Development of Numbers and Number Sets",
    "B1.1": "Development and Use of Numbers",
    "B1.2": "Number Sets",
    "B1.3": "Number Sets",
    "B2": "Powers",
    "B2.1": "Powers",
    "B2.2": "Powers",
    "B3": "Number Sense and Operations",
    "B3.1": "Rational Numbers",
    "B3.2": "Rational Numbers",
    "B3.3": "Rational Numbers",
    "B3.4": "Applications",
    "B3.5": "Applications",
    "C1": "Algebraic Expressions and Equations",
    "C1.1": "Development and Use of Algebra",
    "C1.2": "Algebraic Expressions and Equations",
    "C1.3": "Algebraic Expressions and Equations",
    "C1.4": "Algebraic Expressions and Equations",
    "C1.5": "Algebraic Expressions and Equations",
    "C2": "Coding",
    "C2.1": "Coding",
    "C2.2": "Coding",
    "C2.3": "Coding",
    "C3": "Application of Relations",
    "C3.1": "Application of Linear and Non-Linear Relations",
    "C3.2": "Application of Linear and Non-Linear Relations",
    "C3.3": "Application of Linear and Non-Linear Relations",
    "C4": "Characteristics of Relations",
    "C4.1": "Characteristics of Linear and Non-Linear Relations",
    "C4.2": "Characteristics of Linear and Non-Linear Relations",
    "C4.3": "Characteristics of Linear and Non-Linear Relations",
    "C4.4": "Characteristics of Linear and Non-Linear Relations",
    "D1": "Collection, Representation, and Analysis of Data",
    "D1.1": "Application of Data",
    "D1.2": "Representation and Analysis of Data",
    "D1.3": "Representation and Analysis of Data",
    "D2": "Mathematical Modelling",
    "D2.1": "Application of Mathematical Modelling",
    "D2.2": "Process of Mathematical Modelling",
    "D2.3": "Process of Mathematical Modelling",
    "D2.4": "Process of Mathematical Modelling",
    "D2.5": "Process of Mathematical Modelling",
    "E1": "Geometric and Measurement Relationships",
    "E1.1": "Geometric and Measurement Relationships",
    "E1.2": "Geometric and Measurement Relationships",
    "E1.3": "Geometric and Measurement Relationships",
    "E1.4": "Geometric and Measurement Relationships",
    "E1.5": "Geometric and Measurement Relationships",
    "E1.6": "Geometric and Measurement Relationships",
    "F1": "Financial Decisions",
    "F1.1": "Financial Decisions",
    "F1.2": "Financial Decisions",
    "F1.3": "Financial Decisions",
    "F1.4": "Financial Decisions",
}

SHA256_RE = re.compile(r"^[0-9a-f]{64}$")


class InventoryError(RuntimeError):
    """Raised when source extraction or inventory verification fails."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise InventoryError(message)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_line(value: str) -> str:
    return " ".join(unicodedata.normalize("NFC", value).split())


def expectation_strand(expectation_id: str) -> str:
    return "AA" if expectation_id.startswith("AA") else expectation_id[0]


def expectation_parent(expectation_id: str) -> str | None:
    return expectation_id.split(".", 1)[0] if "." in expectation_id else None


def extract_record(page_text: str, expectation_id: str, official_page: int) -> dict[str, object]:
    lines = [normalize_line(line) for line in page_text.splitlines()]
    lines = [line for line in lines if line]
    title = EXPECTED_TITLES[expectation_id]
    separator = " " if "." in expectation_id else ". "
    header = f"{expectation_id}{separator}{title}"
    try:
        start = lines.index(header)
    except ValueError as error:
        raise InventoryError(
            f"official page {official_page} does not contain exact header {header!r}"
        ) from error

    stop_prefixes = (
        "Teacher supports",
        "Specific expectations",
        "This overall expectation",
    )
    description_lines: list[str] = []
    for line in lines[start + 1 :]:
        if line.startswith(stop_prefixes):
            break
        description_lines.append(line)

    description = normalize_line(" ".join(description_lines))
    require(
        len(description) >= 35,
        f"{expectation_id} extracted description is unexpectedly short",
    )
    require(
        len(description) <= 800,
        f"{expectation_id} extracted description crossed a section boundary",
    )
    description_sha256 = hashlib.sha256(description.encode("utf-8")).hexdigest()
    return {
        "id": expectation_id,
        "kind": "overall" if expectation_id in OVERALL_IDS else "specific",
        "strand_id": expectation_strand(expectation_id),
        "parent_id": expectation_parent(expectation_id),
        "title": title,
        "official_page": official_page,
        "pdf_page": official_page + 1,
        "description_length": len(description),
        "description_sha256": description_sha256,
    }


def canonical_records_digest(records: list[dict[str, object]]) -> str:
    payload = json.dumps(
        records,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def build_inventory(pdf_path: Path) -> dict[str, object]:
    require(pdf_path.is_file(), f"official source PDF is missing: {pdf_path}")
    actual_source_sha = sha256_file(pdf_path)
    require(
        actual_source_sha == SOURCE_SHA256,
        f"official source digest mismatch: {actual_source_sha}",
    )

    try:
        from pypdf import PdfReader
    except ImportError as error:
        raise InventoryError(
            "pypdf is required to extract the official inventory"
        ) from error

    reader = PdfReader(pdf_path)
    require(len(reader.pages) == 222, "official source must contain 222 PDF pages")
    records = []
    for expectation_id, official_page in EXPECTATION_PAGES.items():
        page_text = reader.pages[official_page].extract_text() or ""
        records.append(extract_record(page_text, expectation_id, official_page))

    return {
        "schema": "axiom-education-official-course-inventory.v1",
        "course": {
            "code": "MTH1W",
            "name": "Mathematics, Grade 9, De-streamed",
            "jurisdiction": "Ontario, Canada",
            "credit_value": 1.0,
            "prerequisite": None,
        },
        "source": {
            "authority": "Ontario Ministry of Education",
            "title": "The Ontario Curriculum, Grade 9: Mathematics, 2021",
            "url": SOURCE_URL,
            "sha256": SOURCE_SHA256,
            "pdf_page_count": 222,
            "copyright": "Crown copyright, King's Printer for Ontario",
            "copyright_url": COPYRIGHT_URL,
            "verbatim_expectation_text_included": False,
        },
        "review": {
            "extraction_status": "source-digest-and-layout-verified",
            "educator_review_status": "required",
            "commercial_reproduction_permission": "unconfirmed",
        },
        "strands": [
            {"id": strand_id, "title": title}
            for strand_id, title in STRANDS.items()
        ],
        "counts": {
            "strands": len(STRANDS),
            "overall_expectations": len(OVERALL_IDS),
            "specific_expectations": len(EXPECTATION_PAGES) - len(OVERALL_IDS),
            "expectations_total": len(EXPECTATION_PAGES),
        },
        "records_sha256": canonical_records_digest(records),
        "records": records,
    }


def load_inventory(path: Path) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise InventoryError(f"inventory is missing: {path}") from error
    except json.JSONDecodeError as error:
        raise InventoryError(f"invalid inventory JSON: {error}") from error
    require(isinstance(payload, dict), "inventory root must be an object")
    return payload


def verify_inventory(payload: dict[str, object]) -> None:
    require(
        payload.get("schema") == "axiom-education-official-course-inventory.v1",
        "unsupported official inventory schema",
    )
    course = payload.get("course")
    require(isinstance(course, dict), "course metadata must be an object")
    require(course.get("code") == "MTH1W", "official inventory course mismatch")

    source = payload.get("source")
    require(isinstance(source, dict), "source metadata must be an object")
    require(source.get("sha256") == SOURCE_SHA256, "source digest pin mismatch")
    require(source.get("url") == SOURCE_URL, "source URL pin mismatch")
    require(
        source.get("copyright_url") == COPYRIGHT_URL,
        "source copyright notice URL mismatch",
    )
    require(
        source.get("verbatim_expectation_text_included") is False,
        "inventory must not redistribute verbatim expectation descriptions",
    )

    counts = payload.get("counts")
    require(
        counts
        == {
            "strands": 7,
            "overall_expectations": 14,
            "specific_expectations": 43,
            "expectations_total": 57,
        },
        "official inventory counts are incorrect",
    )

    records = payload.get("records")
    require(isinstance(records, list), "inventory records must be an array")
    record_ids = [record.get("id") for record in records if isinstance(record, dict)]
    require(len(record_ids) == len(records), "every inventory record must be an object")
    require(record_ids == list(EXPECTATION_PAGES), "official expectation order or IDs changed")

    for record in records:
        expectation_id = record["id"]
        require(
            record.get("official_page") == EXPECTATION_PAGES[expectation_id],
            f"{expectation_id}: official page mismatch",
        )
        require(
            record.get("pdf_page") == EXPECTATION_PAGES[expectation_id] + 1,
            f"{expectation_id}: PDF page mismatch",
        )
        require(
            record.get("title") == EXPECTED_TITLES[expectation_id],
            f"{expectation_id}: title mismatch",
        )
        require(
            record.get("strand_id") == expectation_strand(expectation_id),
            f"{expectation_id}: strand mismatch",
        )
        require(
            record.get("parent_id") == expectation_parent(expectation_id),
            f"{expectation_id}: parent mismatch",
        )
        expected_kind = "overall" if expectation_id in OVERALL_IDS else "specific"
        require(record.get("kind") == expected_kind, f"{expectation_id}: kind mismatch")
        description_sha = record.get("description_sha256")
        require(
            isinstance(description_sha, str) and SHA256_RE.fullmatch(description_sha),
            f"{expectation_id}: description digest missing",
        )
        description_length = record.get("description_length")
        require(
            isinstance(description_length, int) and 35 <= description_length <= 800,
            f"{expectation_id}: description length invalid",
        )

    require(
        payload.get("records_sha256") == canonical_records_digest(records),
        "official inventory records digest mismatch",
    )


def write_inventory(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    build_parser = subparsers.add_parser("build", help="extract inventory from source PDF")
    build_parser.add_argument("--pdf", type=Path, required=True)
    build_parser.add_argument("--output", type=Path, default=DEFAULT_INVENTORY_PATH)

    verify_parser = subparsers.add_parser("verify", help="verify pinned inventory")
    verify_parser.add_argument("--inventory", type=Path, default=DEFAULT_INVENTORY_PATH)
    verify_parser.add_argument("--source-pdf", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if args.command == "build":
            payload = build_inventory(args.pdf)
            verify_inventory(payload)
            write_inventory(args.output, payload)
            print(
                f"wrote {len(payload['records'])} official expectation references "
                f"to {args.output}"
            )
            return 0

        payload = load_inventory(args.inventory)
        verify_inventory(payload)
        if args.source_pdf is not None:
            extracted = build_inventory(args.source_pdf)
            require(
                payload == extracted,
                "pinned inventory differs from the digest-verified official PDF",
            )
        print(
            "official MTH1W inventory verified: 14 overall, 43 specific, "
            "57 total expectations"
        )
        return 0
    except (InventoryError, OSError) as error:
        print(f"official MTH1W inventory verification failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
