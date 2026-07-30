from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from tools.curriculum_pack import (
    PackError,
    build_pack,
    sign_pack,
    verify_pack_directory,
)


SAMPLE_LEDGER = {
    "schema": "ontarioedai-curriculum-source-ledger.v1",
    "ledger_version": "1.0.0",
    "jurisdiction": "CA-ON",
    "effective_date": "2026-03-05",
    "sources": [
        {
            "source_id": "official",
            "namespace": "ca.on.education.secondary.derived",
            "classification": "official-derived",
            "authority": "Ontario Ministry of Education",
            "official_recognition": True,
            "default_url": "https://example.invalid/official",
            "upstream_document_sha256": None,
            "upstream_digest_status": "not-captured",
            "review_status": "test-review-required",
            "licence": {
                "rights_holder": "King's Printer for Ontario",
                "usage_basis": "test",
                "redistribution_status": "review-required",
                "notice": "Test fixture only.",
            },
        },
        {
            "source_id": "extension",
            "namespace": "org.ontarioedai.extension.ethics",
            "classification": "ontarioedai-extension",
            "authority": "OntarioEdAI",
            "official_recognition": False,
            "default_url": None,
            "upstream_document_sha256": None,
            "upstream_digest_status": "not-applicable",
            "review_status": "experimental",
            "licence": {
                "rights_holder": "OntarioEdAI contributors",
                "usage_basis": "test",
                "redistribution_status": "project-policy-required",
                "notice": "Not an Ontario Ministry-recognized course.",
            },
        },
    ],
    "routing": [
        {"course_code_pattern": "^EMF[0-9A-Z]*$", "source_id": "extension"},
        {"course_code_pattern": "^[0-9A-Z]+$", "source_id": "official"},
    ],
}

SAMPLE_CURRICULUM = {
    "version": "test-content-1",
    "updated": "2026-03-05",
    "courses": {
        "MTH1W": {
            "name": "Mathematics, Grade 9",
            "official_url": "https://example.invalid/mth1w",
            "strands": {
                "A_Number": [
                    {
                        "id": "MTH1W-A1",
                        "expectation": "Perform operations on integers.",
                        "irt_b": -0.8,
                        "irt_a": 1.1,
                        "irt_c": 0.2,
                        "tags": ["math", "eqao", "math"],
                    }
                ]
            },
        },
        "EMF1O": {
            "name": "Ethics and Moral Foundations Extension",
            "strands": {
                "A_Foundations": [
                    "A1.1 Compare ethical frameworks without presenting the extension as official curriculum."
                ]
            },
        },
    },
}


class CurriculumPackTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="ontarioedai-pack-test-")
        self.root = Path(self.temporary.name)
        self.input_path = self.root / "curriculum.json"
        self.ledger_path = self.root / "ledger.json"
        self.input_path.write_text(json.dumps(SAMPLE_CURRICULUM), encoding="utf-8")
        self.ledger_path.write_text(json.dumps(SAMPLE_LEDGER), encoding="utf-8")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def build(self, name: str) -> Path:
        output = self.root / name
        manifest = build_pack(
            argparse.Namespace(
                input=self.input_path,
                ledger=self.ledger_path,
                output=output,
                pack_id="ontario-secondary-test",
                pack_version="1.0.0",
            )
        )
        self.assertEqual(manifest["records"]["count"], 2)
        return output

    def test_build_is_byte_for_byte_deterministic(self) -> None:
        first = self.build("first")
        second = self.build("second")

        self.assertEqual(
            (first / "manifest.json").read_bytes(),
            (second / "manifest.json").read_bytes(),
        )
        self.assertEqual(
            (first / "records.jsonl").read_bytes(),
            (second / "records.jsonl").read_bytes(),
        )
        verify_pack_directory(first, public_key=None, require_signature=False)

    def test_extension_records_are_visibly_non_official(self) -> None:
        pack = self.build("pack")
        records = [
            json.loads(line)
            for line in (pack / "records.jsonl").read_text(encoding="utf-8").splitlines()
        ]
        extension = next(record for record in records if record["course"]["code"] == "EMF1O")
        official = next(record for record in records if record["course"]["code"] == "MTH1W")

        self.assertFalse(extension["source"]["official_recognition"])
        self.assertEqual(extension["source"]["classification"], "ontarioedai-extension")
        self.assertTrue(official["source"]["official_recognition"])
        self.assertEqual(official["source"]["classification"], "official-derived")
        self.assertEqual(official["adaptation_heuristics"]["status"], "uncalibrated")
        self.assertNotIn("irt_b", official)

    def test_tampered_records_are_rejected(self) -> None:
        pack = self.build("pack")
        records_path = pack / "records.jsonl"
        data = bytearray(records_path.read_bytes())
        data[-2] ^= 0x01
        records_path.write_bytes(data)

        with self.assertRaises(PackError):
            verify_pack_directory(pack, public_key=None, require_signature=False)

    @unittest.skipUnless(shutil.which("openssl"), "OpenSSL is required")
    def test_ed25519_signature_round_trip_and_wrong_key_rejection(self) -> None:
        pack = self.build("signed")
        private_key = self.root / "private.pem"
        public_key = self.root / "public.pem"
        wrong_private = self.root / "wrong-private.pem"
        wrong_public = self.root / "wrong-public.pem"

        subprocess.run(
            ["openssl", "genpkey", "-algorithm", "ED25519", "-out", private_key],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["openssl", "pkey", "-in", private_key, "-pubout", "-out", public_key],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["openssl", "genpkey", "-algorithm", "ED25519", "-out", wrong_private],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            ["openssl", "pkey", "-in", wrong_private, "-pubout", "-out", wrong_public],
            check=True,
            capture_output=True,
        )
        if os.name != "nt":
            private_key.chmod(0o600)
            wrong_private.chmod(0o600)

        envelope = sign_pack(
            argparse.Namespace(
                pack_dir=pack,
                private_key=private_key,
                public_key=public_key,
                force=False,
            )
        )
        self.assertEqual(envelope["algorithm"], "Ed25519")
        verify_pack_directory(pack, public_key=public_key, require_signature=True)

        with self.assertRaises(PackError):
            verify_pack_directory(pack, public_key=wrong_public, require_signature=True)


if __name__ == "__main__":
    unittest.main()
