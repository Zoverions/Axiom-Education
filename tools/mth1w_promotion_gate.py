#!/usr/bin/env python3
"""MTH1W promotion gate: config verification, decision recording, ledger audit.

The promotion gate records promotion decisions and the exact gate config each
decision was taken under. It is machinery, not authority:

- reviewer appointments are NOT made here (all required slots ship
  ``unassigned``; a ``promote`` decision fails closed until they are assigned);
- a ``promote`` decision additionally requires approved, content-bound review
  evidence for every required review type and the current on-disk content;
- ``hold`` / ``reject`` decisions are conservative and always recordable;
- every decision binds to the gate config digest and the exact content
  digests, so config drift or content edits invalidate promote eligibility;
- ledger entries are hash-chained (``previous_entry_digest`` -> ``entry_digest``).

A promotion decision is not pack readiness, signing, staging, activation,
curriculum completeness, learner mastery, or any grade/credit/licensing/
Ministry authority. Verification status: lab-grade, not production.

Open gaps (documented, not silently closed):
- approved-evidence binding currently indexes lesson review evidence in
  ``review_evidence_dir`` (content-review-evidence.v1). Accessibility and
  licensing evidence live in sibling directories with their own schemas;
  cross-directory approval aggregation is a documented future step.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "config" / "mth1w-promotion-gate.v1.json"
CONFIG_SCHEMA_PATH = ROOT / "schemas" / "mth1w-promotion-gate-config.v1.schema.json"
DECISION_SCHEMA_PATH = ROOT / "schemas" / "mth1w-promotion-decision.v1.schema.json"
LEDGER_SCHEMA_PATH = ROOT / "schemas" / "mth1w-promotion-ledger.v1.schema.json"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.json_schema_validation import (  # noqa: E402
    RepositoryJsonSchemaError,
    validate_json_schema,
)
from tools.mth1w_review_evidence import build_plan, verify_review  # noqa: E402


class PromotionGateError(RuntimeError):
    """Raised when gate config, decision, or ledger verification fails."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise PromotionGateError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise PromotionGateError(f"missing JSON file: {path}") from error
    except json.JSONDecodeError as error:
        raise PromotionGateError(f"invalid JSON in {path}: {error}") from error
    require(isinstance(payload, dict), f"JSON root must be an object: {path}")
    return payload


def canonical_digest(value: Any) -> str:
    encoded = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def config_digest(config: dict[str, Any]) -> str:
    """Digest of the exact gate config bytes on disk."""
    return file_sha256(CONFIG_PATH)


def load_config(path: Path = CONFIG_PATH) -> dict[str, Any]:
    config = load_json(path)
    try:
        validate_json_schema(config, CONFIG_SCHEMA_PATH, label="MTH1W promotion gate config")
    except RepositoryJsonSchemaError as error:
        raise PromotionGateError(str(error)) from error
    return config


def verify_config(path: Path = CONFIG_PATH) -> dict[str, Any]:
    """Verify the gate config: schema, file bindings, quorum shape, claim honesty."""
    config = load_config(path)
    require(config["gate_id"] == "mth1w-promotion-gate", "gate_id mismatch")
    course = config["course"]
    course_path = ROOT / course["course_payload_path"]
    assessment_path = ROOT / course["assessment_plan_path"]
    require(course_path.is_file(), f"course payload missing: {course_path}")
    require(assessment_path.is_file(), f"assessment plan missing: {assessment_path}")
    slots = config["reviewer_slots"]
    slot_ids = [slot["slot_id"] for slot in slots]
    require(len(set(slot_ids)) == len(slot_ids), "reviewer slot_ids must be unique")
    slot_types = {slot["review_type"] for slot in slots}
    required_types = set(config["required_review_types"])
    require(
        required_types <= slot_types,
        f"every required review type needs a slot; missing: {sorted(required_types - slot_types)}",
    )
    for slot in slots:
        if slot["appointment_status"] == "assigned":
            reviewer = slot.get("reviewer") or {}
            require(
                isinstance(reviewer.get("name"), str) and reviewer["name"].strip(),
                f"assigned slot {slot['slot_id']} must name a reviewer",
            )
        else:
            require(
                slot.get("reviewer") is None,
                f"unassigned slot {slot['slot_id']} must not name a reviewer",
            )
    verification = config["verification"]
    require(
        verification["verification_status"] == "lab-grade-not-production",
        "gate config must not claim production status",
    )
    require(
        (ROOT / verification["verification_tool"]).resolve() == Path(__file__).resolve(),
        "verification_tool must name this tool",
    )
    require(bool(config["claim_boundaries"]), "claim boundaries must be stated")
    ledger = config["ledger"]
    require(
        ledger["ledger_schema"] == "axiom-education-mth1w-promotion-ledger.v1",
        "ledger schema mismatch",
    )
    return {
        "gate_id": config["gate_id"],
        "gate_version": config["gate_version"],
        "config_digest": config_digest(config),
        "unassigned_slots": [slot["slot_id"] for slot in slots if slot["appointment_status"] != "assigned"],
        "claim": "config-verified-not-production",
    }


def current_content_digests(config: dict[str, Any]) -> dict[str, str]:
    course = config["course"]
    return {
        "course_payload_digest": file_sha256(ROOT / course["course_payload_path"]),
        "assessment_plan_digest": file_sha256(ROOT / course["assessment_plan_path"]),
    }


def index_approved_evidence(config: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """Index approved lesson review evidence by file digest.

    Only files in the configured review evidence dir that pass
    ``verify_review`` with the config's required decision count as approvals.
    """
    review_dir = ROOT / config["verification"]["review_evidence_dir"]
    plan = build_plan()
    approved: dict[str, dict[str, Any]] = {}
    if not review_dir.is_dir():
        return approved
    for path in sorted(review_dir.rglob("*.json")):
        if path.name == "promotion-ledger.json":
            continue
        digest = file_sha256(path)
        try:
            review = verify_review(path, plan)
        except Exception:
            continue
        if review.get("decision") != config["required_decision"]:
            continue
        reviewer = review.get("reviewer") or {}
        approved[digest] = {
            "review_id": review.get("review_id"),
            "review_type": review.get("review_type"),
            "reviewer_name": str(reviewer.get("name", "")).strip(),
        }
    return approved


def ledger_path(config: dict[str, Any]) -> Path:
    return ROOT / config["ledger"]["ledger_path"]


def init_ledger(config: dict[str, Any], path: Path | None = None) -> dict[str, Any]:
    target = path or ledger_path(config)
    require(not target.exists(), f"ledger already exists: {target}")
    target.parent.mkdir(parents=True, exist_ok=True)
    ledger = {
        "schema": "axiom-education-mth1w-promotion-ledger.v1",
        "gate_id": config["gate_id"],
        "gate_version": config["gate_version"],
        "gate_config_digest": config_digest(config),
        "genesis_at": utc_now(),
        "entries": [],
    }
    write_ledger(ledger, target)
    return ledger


def write_ledger(ledger: dict[str, Any], path: Path) -> None:
    path.write_text(
        json.dumps(ledger, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def load_ledger(config: dict[str, Any], path: Path | None = None) -> dict[str, Any]:
    target = path or ledger_path(config)
    ledger = load_json(target)
    try:
        validate_json_schema(ledger, LEDGER_SCHEMA_PATH, label="MTH1W promotion ledger")
    except RepositoryJsonSchemaError as error:
        raise PromotionGateError(str(error)) from error
    return ledger


def verify_ledger(config: dict[str, Any], path: Path | None = None) -> dict[str, Any]:
    """Verify ledger header binding, schema, and entry hash chain."""
    ledger = load_ledger(config, path)
    current_digest = config_digest(config)
    require(
        ledger["gate_config_digest"] == current_digest,
        "ledger header binds a different gate config digest: config drifted; "
        "decisions under this ledger are no longer eligible",
    )
    previous: str | None = None
    for index, entry in enumerate(ledger["entries"]):
        require(
            entry["previous_entry_digest"] == previous,
            f"entry {index} breaks the hash chain",
        )
        recomputed = canonical_digest({k: v for k, v in entry.items() if k != "entry_digest"})
        require(
            entry["entry_digest"] == recomputed,
            f"entry {index} digest mismatch: ledger tampered",
        )
        previous = entry["entry_digest"]
    return {"entries": len(ledger["entries"]), "head": previous, "claim": "ledger-verified"}


def build_decision(
    config: dict[str, Any],
    *,
    decision: str,
    decided_by: str,
    rationale: str,
    evidence_digests: list[str] | None = None,
    decided_at: str | None = None,
) -> dict[str, Any]:
    require(decision in config["promotion_decisions"], f"unsupported decision: {decision}")
    require(isinstance(decided_by, str) and decided_by.strip(), "decided_by is required")
    require(isinstance(rationale, str) and rationale.strip(), "rationale is required")
    for digest in evidence_digests or []:
        require(
            isinstance(digest, str) and SHA256_RE.fullmatch(digest) is not None,
            f"invalid evidence digest: {digest}",
        )
    content = current_content_digests(config)
    slots = [
        {
            "slot_id": slot["slot_id"],
            "review_type": slot["review_type"],
            "appointment_status": slot["appointment_status"],
            "reviewer_name": (slot.get("reviewer") or {}).get("name"),
        }
        for slot in config["reviewer_slots"]
    ]
    if decision == "promote":
        unassigned = [slot["slot_id"] for slot in config["reviewer_slots"] if slot["appointment_status"] != "assigned"]
        require(not unassigned, f"promote blocked: reviewer slots unassigned: {unassigned}")
        required_types = set(config["required_review_types"])
        appointed_by_type: dict[str, set[str]] = {}
        for slot in config["reviewer_slots"]:
            if slot["review_type"] not in required_types:
                continue
            reviewer_name = str((slot.get("reviewer") or {}).get("name", "")).strip()
            require(
                reviewer_name,
                f"promote blocked: assigned slot {slot['slot_id']} has no reviewer name",
            )
            appointed_by_type.setdefault(slot["review_type"], set()).add(reviewer_name)

        approved = index_approved_evidence(config)
        supplied = evidence_digests or []
        require(supplied, "promote requires review evidence digests")
        for digest in supplied:
            require(digest in approved, f"evidence digest is not verified approved review evidence: {digest}")
            review_type = approved[digest]["review_type"]
            reviewer_name = approved[digest]["reviewer_name"]
            require(
                review_type in required_types,
                f"promote blocked: supplied evidence has non-required review type: {review_type}",
            )
            require(
                reviewer_name in appointed_by_type.get(review_type, set()),
                f"promote blocked: evidence reviewer {reviewer_name or '<missing>'} is not appointed for review type {review_type}",
            )
        covered = {approved[d]["review_type"] for d in supplied}
        missing = required_types - covered
        require(not missing, f"promote blocked: missing approved review types: {sorted(missing)}")
        reviewers = {approved[d]["reviewer_name"] for d in supplied if approved[d]["reviewer_name"]}
        require(
            len(reviewers) >= config["quorum"]["min_distinct_reviewers"],
            "promote blocked: reviewer quorum not met",
        )
    record: dict[str, Any] = {
        "schema": "axiom-education-mth1w-promotion-decision.v1",
        "decision_id": f"mth1w-promotion-{utc_now().replace(':', '').replace('-', '')}-{decision}",
        "gate_id": config["gate_id"],
        "gate_version": config["gate_version"],
        "gate_config_digest": config_digest(config),
        "decision": decision,
        "decided_at": decided_at or utc_now(),
        "decided_by": decided_by.strip(),
        "content": content,
        "review_evidence_digests": sorted(set(evidence_digests or [])),
        "reviewer_slots": slots,
        "rationale_digest": hashlib.sha256(rationale.encode("utf-8")).hexdigest(),
        "previous_entry_digest": None,
        "entry_digest": "",
    }
    # Provisional digest so the built record is schema-valid on its own; append_decision
    # re-chains it (previous_entry_digest + entry_digest) and re-validates.
    record["entry_digest"] = canonical_digest({k: v for k, v in record.items() if k != "entry_digest"})
    try:
        validate_json_schema(record, DECISION_SCHEMA_PATH, label="MTH1W promotion decision")
    except RepositoryJsonSchemaError as error:
        raise PromotionGateError(str(error)) from error
    return record


def append_decision(
    config: dict[str, Any],
    record: dict[str, Any],
    path: Path | None = None,
) -> dict[str, Any]:
    target = path or ledger_path(config)
    require(target.exists(), f"ledger missing; run init-ledger first: {target}")
    verify_ledger(config, target)
    ledger = load_ledger(config, target)
    head = ledger["entries"][-1]["entry_digest"] if ledger["entries"] else None
    require(
        record["gate_config_digest"] == config_digest(config),
        "decision was built against a different gate config; rebuild it",
    )
    require(
        record["content"] == current_content_digests(config),
        "content changed since the decision was built; rebuild it",
    )
    record["previous_entry_digest"] = head
    record["entry_digest"] = canonical_digest({k: v for k, v in record.items() if k != "entry_digest"})
    try:
        validate_json_schema(record, DECISION_SCHEMA_PATH, label="MTH1W promotion decision")
    except RepositoryJsonSchemaError as error:
        raise PromotionGateError(str(error)) from error
    ledger["entries"].append(record)
    write_ledger(ledger, target)
    verify_ledger(config, target)
    return {"decision_id": record["decision_id"], "entry_digest": record["entry_digest"]}


def gate_plan(config: dict[str, Any]) -> dict[str, Any]:
    content = current_content_digests(config)
    approved = index_approved_evidence(config)
    return {
        "gate_id": config["gate_id"],
        "gate_version": config["gate_version"],
        "config_digest": config_digest(config),
        "content": content,
        "reviewer_slots": [
            {"slot_id": s["slot_id"], "review_type": s["review_type"], "appointment_status": s["appointment_status"]}
            for s in config["reviewer_slots"]
        ],
        "approved_evidence_count": len(approved),
        "claim": "plan-only-no-promotion-performed",
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="MTH1W promotion gate machinery (lab-grade).")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("verify-config", help="Verify the gate config.")
    sub.add_parser("init-ledger", help="Create the genesis promotion ledger.")
    sub.add_parser("verify-ledger", help="Verify the ledger header binding and hash chain.")
    sub.add_parser("plan", help="Show current gate state without recording anything.")
    append = sub.add_parser("append", help="Record a promotion decision in the ledger.")
    append.add_argument("--decision", required=True, choices=["promote", "hold", "reject"])
    append.add_argument("--by", required=True, help="Who recorded the decision (role/name).")
    append.add_argument("--rationale", required=True, help="Decision rationale text (only its digest is recorded).")
    append.add_argument("--evidence", nargs="*", default=[], help="Review evidence digests.")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    config = load_config()
    if args.command == "verify-config":
        print(json.dumps(verify_config(), indent=2, ensure_ascii=False, sort_keys=True))
    elif args.command == "init-ledger":
        ledger = init_ledger(config)
        print(
            json.dumps(
                {"initialized": str(ledger_path(config)), "genesis_at": ledger["genesis_at"]},
                indent=2,
                ensure_ascii=False,
            )
        )
    elif args.command == "verify-ledger":
        print(json.dumps(verify_ledger(config), indent=2, ensure_ascii=False, sort_keys=True))
    elif args.command == "plan":
        print(json.dumps(gate_plan(config), indent=2, ensure_ascii=False, sort_keys=True))
    elif args.command == "append":
        record = build_decision(
            config,
            decision=args.decision,
            decided_by=args.by,
            rationale=args.rationale,
            evidence_digests=list(args.evidence),
        )
        print(json.dumps(append_decision(config, record), indent=2, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except PromotionGateError as error:
        print(f"promotion gate error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
