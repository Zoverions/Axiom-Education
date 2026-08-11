#!/usr/bin/env python3
"""Inventory every declared MTH1W external source use and verify human licence reviews.

Machine inventory does not decide copyright or licence permission. A human review record
must bind to the exact current source-use digest, so content/source-use changes make prior
licensing decisions stale rather than silently carrying them forward.
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
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
REVIEW_DIR = ROOT / "curriculum" / "licensing" / "mth1w" / "reviews"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ALLOWED_DECISIONS = {
    "permitted-as-used",
    "permission-required",
    "replace-source",
    "restricted",
    "unresolved",
}
ALLOWED_FINDING_DISPOSITIONS = {
    "open",
    "resolved",
    "accepted-with-rationale",
    "not-applicable",
}

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.mth1w_review_evidence import canonical_digest, load_authored_units  # noqa: E402


class SourceUseError(RuntimeError):
    """Raised when source-use provenance or licence-review evidence is unsafe."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SourceUseError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise SourceUseError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise SourceUseError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def validate_https(url: object, message: str) -> str:
    require(isinstance(url, str) and url.startswith("https://"), message)
    parsed = urlparse(url)
    require(parsed.hostname is not None, message)
    require(parsed.username is None and parsed.password is None, "source URL must not embed credentials")
    return url


def collect_https_strings(value: Any) -> set[str]:
    found: set[str] = set()
    if isinstance(value, dict):
        for child in value.values():
            found.update(collect_https_strings(child))
    elif isinstance(value, list):
        for child in value:
            found.update(collect_https_strings(child))
    elif isinstance(value, str) and value.startswith("https://"):
        found.add(value)
    return found


def build_inventory() -> dict[str, Any]:
    aggregates: dict[str, dict[str, Any]] = {}
    unit_bindings: list[dict[str, Any]] = []

    for _source_path, unit in load_authored_units():
        unit_id = unit.get("unit_id")
        require(isinstance(unit_id, str) and unit_id, "unit_id missing")
        unit_digest = canonical_digest(unit)
        notes = unit.get("source_notes")
        require(isinstance(notes, list) and notes, f"{unit_id}: source_notes must be non-empty")

        declared_urls: set[str] = set()
        for index, note in enumerate(notes):
            require(isinstance(note, dict), f"{unit_id}: source note {index} must be an object")
            title = note.get("title")
            publisher = note.get("publisher")
            use = note.get("use")
            require(isinstance(title, str) and title.strip(), f"{unit_id}: source title missing")
            require(isinstance(publisher, str) and publisher.strip(), f"{unit_id}: source publisher missing")
            require(isinstance(use, str) and use.strip(), f"{unit_id}: source use description missing")
            url = validate_https(note.get("url"), f"{unit_id}: source URL must use HTTPS")
            require(url not in declared_urls, f"{unit_id}: duplicate source note URL: {url}")
            declared_urls.add(url)

            aggregate = aggregates.setdefault(
                url,
                {
                    "url": url,
                    "title": title.strip(),
                    "publisher": publisher.strip(),
                    "uses": [],
                },
            )
            require(aggregate["title"] == title.strip(), f"source title conflicts across units: {url}")
            require(aggregate["publisher"] == publisher.strip(), f"source publisher conflicts across units: {url}")
            aggregate["uses"].append(
                {
                    "unit_id": unit_id,
                    "unit_content_sha256": unit_digest,
                    "declared_use": use.strip(),
                }
            )

        observed_urls = collect_https_strings(unit)
        unmanaged = observed_urls - declared_urls
        require(
            not unmanaged,
            f"{unit_id}: HTTPS locator(s) occur outside source_notes: {sorted(unmanaged)}",
        )
        unit_bindings.append(
            {
                "unit_id": unit_id,
                "unit_content_sha256": unit_digest,
                "declared_source_count": len(declared_urls),
            }
        )

    records: list[dict[str, Any]] = []
    for url in sorted(aggregates):
        record = aggregates[url]
        record["uses"] = sorted(
            record["uses"],
            key=lambda use: (use["unit_id"], use["declared_use"]),
        )
        use_payload = {
            "url": record["url"],
            "title": record["title"],
            "publisher": record["publisher"],
            "uses": record["uses"],
        }
        record["source_use_sha256"] = canonical_digest(use_payload)
        record["human_licensing_review_status"] = "required"
        records.append(record)

    require(records, "MTH1W source-use inventory must not be empty")
    return {
        "schema": "axiom-education-source-use-inventory.v1",
        "course_code": "MTH1W",
        "status": "machine-verified-use-inventory",
        "claim_boundary": (
            "This inventory proves which external sources the authored MTH1W units declare and binds each use to exact unit content. "
            "It does not decide copyright, licence, permission, or redistribution rights."
        ),
        "unit_count": len(unit_bindings),
        "source_count": len(records),
        "unit_bindings": sorted(unit_bindings, key=lambda item: item["unit_id"]),
        "sources": records,
    }


def source_index(inventory: dict[str, Any]) -> dict[str, dict[str, Any]]:
    sources = inventory.get("sources")
    require(isinstance(sources, list), "inventory sources missing")
    index: dict[str, dict[str, Any]] = {}
    for source in sources:
        require(isinstance(source, dict), "inventory source must be an object")
        url = source.get("url")
        require(isinstance(url, str), "inventory source URL missing")
        require(url not in index, f"duplicate inventory source URL: {url}")
        index[url] = source
    return index


def validate_timestamp(value: object) -> None:
    require(isinstance(value, str), "reviewed_at must be an ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise SourceUseError("reviewed_at must be an ISO-8601 timestamp") from error
    require(parsed.tzinfo is not None, "reviewed_at must include a timezone")


def verify_review(path: Path, inventory: dict[str, Any] | None = None) -> dict[str, Any]:
    review = load_json(path)
    inventory = inventory or build_inventory()
    index = source_index(inventory)

    require(review.get("schema") == "axiom-education-source-licence-review.v1", "unsupported source licence review schema")
    require(review.get("course_code") == "MTH1W", "licence review course mismatch")
    review_id = review.get("review_id")
    require(isinstance(review_id, str) and review_id.strip(), "review_id is required")
    url = validate_https(review.get("source_url"), "review source_url must use HTTPS")
    current = index.get(url)
    require(current is not None, "licence review source is not in the current MTH1W source-use inventory")
    digest = review.get("source_use_sha256")
    require(isinstance(digest, str) and SHA256_RE.fullmatch(digest) is not None, "source_use_sha256 is invalid")
    require(digest == current.get("source_use_sha256"), "licence review is stale: source use changed")

    reviewer = review.get("reviewer")
    require(isinstance(reviewer, dict), "reviewer metadata is required")
    require(isinstance(reviewer.get("name"), str) and reviewer["name"].strip(), "reviewer name is required")
    require(isinstance(reviewer.get("qualification"), str) and reviewer["qualification"].strip(), "reviewer qualification is required")
    validate_timestamp(review.get("reviewed_at"))

    decision = review.get("decision")
    require(decision in ALLOWED_DECISIONS, "invalid licensing decision")
    allowed = review.get("redistribution_allowed_as_used")
    require(isinstance(allowed, bool), "redistribution_allowed_as_used must be boolean")
    evidence = review.get("evidence_locators")
    require(isinstance(evidence, list), "evidence_locators must be an array")
    for locator in evidence:
        validate_https(locator, "licensing evidence locator must use HTTPS")

    findings = review.get("findings")
    require(isinstance(findings, list), "findings must be an array")
    seen_findings: set[str] = set()
    has_open = False
    for finding in findings:
        require(isinstance(finding, dict), "licensing finding must be an object")
        finding_id = finding.get("id")
        require(isinstance(finding_id, str) and finding_id, "licensing finding id is required")
        require(finding_id not in seen_findings, f"duplicate licensing finding id: {finding_id}")
        seen_findings.add(finding_id)
        require(finding.get("severity") in {"note", "minor", "major", "critical"}, "invalid licensing finding severity")
        require(isinstance(finding.get("description"), str) and finding["description"], "licensing finding description required")
        disposition = finding.get("disposition")
        require(disposition in ALLOWED_FINDING_DISPOSITIONS, "invalid licensing finding disposition")
        has_open = has_open or disposition == "open"

    limitations = review.get("scope_limitations")
    require(isinstance(limitations, list) and all(isinstance(item, str) for item in limitations), "scope_limitations must be strings")
    require(review.get("attestation_type") == "human-licensing-review", "licensing evidence must be a human attestation")

    if decision == "permitted-as-used":
        require(allowed is True, "permitted-as-used review must explicitly allow redistribution as used")
        require(evidence, "permitted-as-used review requires evidence locators")
        require(not has_open, "permitted-as-used review cannot contain open findings")
    else:
        require(allowed is False, "non-permitted licensing decision cannot claim redistribution allowed")
    return review


def verify_reviews(directory: Path = REVIEW_DIR) -> dict[str, int]:
    inventory = build_inventory()
    paths = sorted(directory.glob("*.json")) if directory.exists() else []
    seen_ids: set[str] = set()
    reviewed_urls: set[str] = set()
    permitted = 0
    for path in paths:
        review = verify_review(path, inventory)
        review_id = str(review["review_id"])
        require(review_id not in seen_ids, f"duplicate licence review_id: {review_id}")
        seen_ids.add(review_id)
        url = str(review["source_url"])
        require(url not in reviewed_urls, f"multiple current licence reviews for one source use: {url}")
        reviewed_urls.add(url)
        if review["decision"] == "permitted-as-used":
            permitted += 1
    return {
        "sources": inventory["source_count"],
        "reviews": len(paths),
        "permitted_as_used": permitted,
        "unreviewed": inventory["source_count"] - len(reviewed_urls),
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    inventory = commands.add_parser("inventory")
    inventory.add_argument("--output", type=Path)
    review = commands.add_parser("verify-review")
    review.add_argument("review", type=Path)
    commands.add_parser("verify")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "inventory":
            inventory = build_inventory()
            rendered = json.dumps(inventory, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
            if args.output:
                args.output.parent.mkdir(parents=True, exist_ok=True)
                args.output.write_text(rendered, encoding="utf-8")
                print(f"MTH1W source-use inventory written: {inventory['source_count']} sources -> {args.output}")
            else:
                print(rendered, end="")
        elif args.command == "verify-review":
            review = verify_review(args.review)
            print(f"source licence review verified: {review['review_id']} decision={review['decision']}")
        else:
            summary = verify_reviews()
            print(json.dumps(summary, indent=2, sort_keys=True))
    except (OSError, KeyError, SourceUseError, ValueError) as error:
        print(f"MTH1W source-use/licensing verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
