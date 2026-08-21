#!/usr/bin/env python3
"""Install pinned dependencies and run the complete repository verification."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_FLUTTER = "3.41.1"
EXPECTED_DART_PREFIX = "3.11."
EXPECTED_PYTHON = (3, 12)
EXPECTED_OPENSSL_MAJOR = 3


class VerificationSetupError(RuntimeError):
    """Raised when the pinned verification toolchain is unavailable."""


def require_tool(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise VerificationSetupError(f"required command is unavailable: {name}")
    return path


def validate_flutter_payload(payload: dict[str, object]) -> None:
    framework = payload.get("frameworkVersion")
    dart = payload.get("dartSdkVersion")
    if framework != EXPECTED_FLUTTER:
        raise VerificationSetupError(
            f"Flutter {EXPECTED_FLUTTER} is required; found {framework!r}"
        )
    if not isinstance(dart, str) or not dart.startswith(EXPECTED_DART_PREFIX):
        raise VerificationSetupError(
            f"Dart {EXPECTED_DART_PREFIX}x is required; found {dart!r}"
        )


def parse_openssl_major(output: str) -> int:
    fields = output.strip().split()
    if len(fields) < 2 or fields[0] != "OpenSSL":
        raise VerificationSetupError(f"unexpected OpenSSL version output: {output!r}")
    try:
        return int(fields[1].split(".", 1)[0])
    except ValueError as error:
        raise VerificationSetupError(
            f"unexpected OpenSSL version output: {output!r}"
        ) from error


def verify_toolchain() -> tuple[str, str]:
    if sys.version_info[:2] != EXPECTED_PYTHON:
        found = ".".join(str(part) for part in sys.version_info[:3])
        raise VerificationSetupError(
            f"Python {EXPECTED_PYTHON[0]}.{EXPECTED_PYTHON[1]} is required; "
            f"found {found}"
        )

    flutter = require_tool("flutter")
    dart = require_tool("dart")
    openssl = require_tool("openssl")

    flutter_output = subprocess.run(
        [flutter, "--version", "--machine"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    try:
        flutter_payload = json.loads(flutter_output)
    except json.JSONDecodeError as error:
        raise VerificationSetupError("Flutter returned invalid version metadata") from error
    if not isinstance(flutter_payload, dict):
        raise VerificationSetupError("Flutter returned invalid version metadata")
    validate_flutter_payload(flutter_payload)

    openssl_output = subprocess.run(
        [openssl, "version"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    openssl_major = parse_openssl_major(openssl_output)
    if openssl_major != EXPECTED_OPENSSL_MAJOR:
        raise VerificationSetupError(
            f"OpenSSL {EXPECTED_OPENSSL_MAJOR}.x is required; "
            f"found major version {openssl_major}"
        )

    return flutter, dart


def verification_commands(flutter: str, dart: str) -> list[tuple[str, list[str]]]:
    python = sys.executable
    return [
        (
            "Install pinned Python dependencies",
            [python, "-m", "pip", "install", "--requirement", "requirements-dev.txt"],
        ),
        (
            "Verify vendored SQLite source and provenance",
            [python, "tools/vendored_sqlite.py", "verify"],
        ),
        (
            "Install locked Dart dependencies",
            [flutter, "pub", "get", "--enforce-lockfile"],
        ),
        ("Verify capability registry", [python, "tools/check_capabilities.py"]),
        (
            "Verify AXIOM-MESH compatibility profile",
            [python, "tools/check_axiom_mesh_compatibility.py"],
        ),
        (
            "Verify Ontario Elementary human source-review targets and submitted evidence",
            [python, "tools/ontario_elementary_source_review.py", "verify-directory"],
        ),
        (
            "Verify Ontario Elementary licensing-review targets and submitted evidence",
            [python, "tools/ontario_elementary_licensing_review.py", "verify-directory"],
        ),
        (
            "Verify Ontario Elementary readiness boundary",
            [python, "tools/ontario_elementary_readiness.py", "verify"],
        ),
        (
            "Verify deterministic Ontario Elementary reviewer dossier",
            [python, "tools/ontario_elementary_reviewer_dossier.py", "verify"],
        ),
        (
            "Verify fail-closed Ontario Elementary C2 intake gate",
            [python, "-m", "unittest", "tests.test_ontario_elementary_c2_intake", "-q"],
        ),
        (
            "Verify official MTH1W expectation inventory",
            [
                python,
                "tools/mth1w_official_inventory.py",
                "verify",
                "--inventory",
                "curriculum/official/ontario-mth1w-2021.inventory.json",
            ],
        ),
        (
            "Verify complete MTH1W course blueprint",
            [python, "tools/check_mth1w_course_blueprint.py"],
        ),
        (
            "Verify MTH1W cumulative assessment blueprint",
            [python, "tools/check_mth1w_cumulative_assessment.py"],
        ),
        (
            "Verify authored MTH1W unit content",
            [python, "tools/check_mth1w_unit_content.py"],
        ),
        (
            "Verify split MTH1W unit content",
            [python, "tools/check_mth1w_split_unit_content.py"],
        ),
        (
            "Verify effective MTH1W authored state",
            [python, "tools/check_mth1w_effective_authored_state.py"],
        ),
        (
            "Verify MTH1W human review targets and submitted evidence",
            [python, "tools/mth1w_review_evidence.py", "verify-directory"],
        ),
        (
            "Verify MTH1W review readiness claim parity",
            [python, "tools/check_mth1w_review_readiness.py"],
        ),
        (
            "Verify governed educator workflow contract",
            [python, "tools/check_educator_workflow_contract.py"],
        ),
        (
            "Verify native learner admission contract coherence",
            [python, "tools/check_native_learner_admission.py"],
        ),
        (
            "Verify MTH1W accessibility human-review targets and submitted evidence",
            [python, "tools/mth1w_accessibility_review_evidence.py", "verify-readiness"],
        ),
        (
            "Verify MTH1W accessible/offline delivery evidence",
            [python, "tools/check_mth1w_accessibility_readiness.py"],
        ),
        (
            "Verify MTH1W external source-use and licensing evidence",
            [python, "tools/mth1w_source_use_inventory.py", "verify"],
        ),
        (
            "Verify MTH1W licensing readiness claim parity",
            [python, "tools/check_mth1w_licensing_readiness.py"],
        ),
        (
            "Verify deterministic MTH1W reviewer dossier",
            [python, "tools/mth1w_reviewer_dossier.py", "verify"],
        ),
        (
            "Verify curriculum readiness boundary",
            [python, "tools/check_curriculum_readiness.py"],
        ),
        (
            "Verify amendments to append-only curriculum source additions",
            [python, "tools/curriculum_source_addition_amendments.py"],
        ),
        (
            "Verify atomic conditional curriculum family evidence",
            [python, "tools/check_conditional_curriculum_family_evidence.py"],
        ),
        ("Run complete Python test suite", [python, "-m", "pytest", "-q"]),
        (
            "Verify Dart formatting",
            [dart, "format", "--output=none", "--set-exit-if-changed", "lib", "test"],
        ),
        ("Analyze Dart and Flutter", [flutter, "analyze", "--no-fatal-infos"]),
        (
            "Run complete Flutter test suite",
            [flutter, "test", "--no-pub", "--reporter", "expanded"],
        ),
    ]


def main() -> int:
    try:
        flutter, dart = verify_toolchain()
        for label, command in verification_commands(flutter, dart):
            print(f"\n==> {label}", flush=True)
            subprocess.run(command, cwd=ROOT, check=True)
    except VerificationSetupError as error:
        print(f"verification setup failed: {error}", file=sys.stderr)
        return 2
    except subprocess.CalledProcessError as error:
        print(
            f"verification command failed with exit code {error.returncode}: "
            f"{' '.join(error.cmd)}",
            file=sys.stderr,
        )
        return error.returncode or 1

    print("\nAxiom Education verification passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
