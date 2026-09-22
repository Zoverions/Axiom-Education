"""Tests for the MTH1W promotion gate ledger/config machinery (lab-grade)."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.mth1w_promotion_gate import (
    PromotionGateError,
    append_decision,
    build_decision,
    config_digest,
    current_content_digests,
    gate_plan,
    init_ledger,
    load_config,
    verify_config,
    verify_ledger,
)


class PromotionGateConfigTest(unittest.TestCase):
    def test_verify_config_passes(self) -> None:
        summary = verify_config()
        self.assertEqual(summary["gate_id"], "mth1w-promotion-gate")
        self.assertEqual(summary["claim"], "config-verified-not-production")
        # Reviewer appointments are parked: every required slot ships unassigned.
        self.assertEqual(len(summary["unassigned_slots"]), 5)

    def test_config_digest_is_stable(self) -> None:
        config = load_config()
        self.assertEqual(config_digest(config), config_digest(config))

    def test_config_is_lab_grade_only(self) -> None:
        config = load_config()
        self.assertEqual(config["verification"]["verification_status"], "lab-grade-not-production")

    def test_promotion_ledger_is_outside_review_evidence_directory(self) -> None:
        config = load_config()
        review_dir = Path(config["verification"]["review_evidence_dir"])
        ledger_path = Path(config["ledger"]["ledger_path"])
        self.assertNotEqual(ledger_path.parent, review_dir)
        self.assertNotIn(review_dir, ledger_path.parents)


class PromotionGateDecisionTest(unittest.TestCase):
    def setUp(self) -> None:
        self.config = load_config()

    def test_build_hold_decision_is_schema_valid(self) -> None:
        record = build_decision(
            self.config,
            decision="hold",
            decided_by="gate-operator",
            rationale="reviewer appointments pending; holding by default",
        )
        self.assertEqual(record["decision"], "hold")
        self.assertEqual(record["content"], current_content_digests(self.config))

    def test_promote_fails_closed_while_slots_unassigned(self) -> None:
        with self.assertRaises(PromotionGateError) as raised:
            build_decision(
                self.config,
                decision="promote",
                decided_by="gate-operator",
                rationale="attempting promote without appointed reviewers",
            )
        self.assertIn("unassigned", str(raised.exception))

    def test_decision_rejects_bad_evidence_digest(self) -> None:
        with self.assertRaises(PromotionGateError):
            build_decision(
                self.config,
                decision="hold",
                decided_by="gate-operator",
                rationale="bad digest",
                evidence_digests=["not-a-digest"],
            )

    def test_decision_requires_rationale(self) -> None:
        with self.assertRaises(PromotionGateError):
            build_decision(
                self.config,
                decision="reject",
                decided_by="gate-operator",
                rationale="   ",
            )


class PromotionGateLedgerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.config = load_config()
        self.tmp = Path(tempfile.mkdtemp(prefix="mth1w-promotion-ledger-test-"))
        self.ledger_path = self.tmp / "promotion-ledger.json"
        init_ledger(self.config, self.ledger_path)

    def test_genesis_ledger_verifies(self) -> None:
        summary = verify_ledger(self.config, self.ledger_path)
        self.assertEqual(summary["entries"], 0)
        self.assertIsNone(summary["head"])

    def test_append_and_verify_chain(self) -> None:
        first = append_decision(
            self.config,
            build_decision(
                self.config, decision="hold", decided_by="gate-operator", rationale="r1"
            ),
            self.ledger_path,
        )
        second = append_decision(
            self.config,
            build_decision(
                self.config, decision="reject", decided_by="gate-operator", rationale="r2"
            ),
            self.ledger_path,
        )
        self.assertNotEqual(first["entry_digest"], second["entry_digest"])
        summary = verify_ledger(self.config, self.ledger_path)
        self.assertEqual(summary["entries"], 2)
        self.assertEqual(summary["head"], second["entry_digest"])
        payload = json.loads(self.ledger_path.read_text(encoding="utf-8"))
        self.assertEqual(
            payload["entries"][1]["previous_entry_digest"], first["entry_digest"]
        )

    def test_tampered_entry_rejected(self) -> None:
        append_decision(
            self.config,
            build_decision(
                self.config, decision="hold", decided_by="gate-operator", rationale="r1"
            ),
            self.ledger_path,
        )
        payload = json.loads(self.ledger_path.read_text(encoding="utf-8"))
        payload["entries"][0]["decided_by"] = "intruder"
        self.ledger_path.write_text(json.dumps(payload), encoding="utf-8")
        with self.assertRaises(PromotionGateError):
            verify_ledger(self.config, self.ledger_path)

    def test_config_drift_rejected(self) -> None:
        payload = json.loads(self.ledger_path.read_text(encoding="utf-8"))
        payload["gate_config_digest"] = "0" * 64
        self.ledger_path.write_text(json.dumps(payload), encoding="utf-8")
        with self.assertRaises(PromotionGateError):
            verify_ledger(self.config, self.ledger_path)

    def test_stale_config_digest_on_decision_rejected(self) -> None:
        record = build_decision(
            self.config, decision="hold", decided_by="gate-operator", rationale="r1"
        )
        record["gate_config_digest"] = "0" * 64
        with self.assertRaises(PromotionGateError):
            append_decision(self.config, record, self.ledger_path)

    def test_double_init_rejected(self) -> None:
        with self.assertRaises(PromotionGateError):
            init_ledger(self.config, self.ledger_path)


class PromotionGatePlanTest(unittest.TestCase):
    def test_plan_is_read_only(self) -> None:
        config = load_config()
        plan = gate_plan(config)
        self.assertEqual(plan["claim"], "plan-only-no-promotion-performed")
        self.assertEqual(plan["content"], current_content_digests(config))


if __name__ == "__main__":
    unittest.main()
