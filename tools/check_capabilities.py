#!/usr/bin/env python3
"""Fail-closed verification for OntarioEdAI's public capability registry."""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY_PATH = ROOT / "config" / "capabilities.json"
PUBSPEC_PATH = ROOT / "pubspec.yaml"
README_PATH = ROOT / "README.md"
PRODUCT_DEFINITION_PATH = ROOT / "docs" / "rebuild" / "PRODUCT-DEFINITION.md"

ALLOWED_STATUSES = {
    "implemented",
    "experimental",
    "adapter_required",
    "specified",
    "disabled",
}

REQUIRED_CAPABILITIES = {
    "app.curriculum-browser",
    "curriculum.ontario-data",
    "curriculum.signed-packs",
    "education.axiom-bridge",
    "tutor.local-inference",
    "tools.deterministic-math",
    "canvas.watcher",
    "classroom.legacy-lan-mesh",
    "classroom.axiom-causal-sync",
    "learner.local-records",
    "learner.axiom-records",
    "assessment.calibrated-irt",
    "portfolio.selective-export",
    "identity.education-credentials",
    "accessibility.learner-interface",
}

VERSION_RE = re.compile(r"^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$")


class RegistryError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RegistryError(message)


def load_registry() -> dict[str, object]:
    try:
        raw = REGISTRY_PATH.read_text(encoding="utf-8")
        decoded = json.loads(raw)
    except FileNotFoundError as error:
        raise RegistryError(f"missing registry: {REGISTRY_PATH}") from error
    except json.JSONDecodeError as error:
        raise RegistryError(f"invalid registry JSON: {error}") from error

    require(isinstance(decoded, dict), "registry root must be an object")
    return decoded


def pubspec_version() -> str:
    content = PUBSPEC_PATH.read_text(encoding="utf-8")
    match = re.search(r"(?m)^version:\s*([^\s]+)\s*$", content)
    require(match is not None, "pubspec.yaml must contain one version field")
    return match.group(1)


def verify() -> Counter[str]:
    registry = load_registry()
    require(
        registry.get("schema") == "ontarioedai-capabilities.v1",
        "unsupported capability registry schema",
    )

    version = registry.get("application_version")
    require(isinstance(version, str), "application_version must be a string")
    require(bool(VERSION_RE.fullmatch(version)), "invalid application_version")
    require(version == pubspec_version(), "registry and pubspec versions differ")

    integration_target = registry.get("integration_target")
    require(isinstance(integration_target, dict), "integration_target must be an object")
    require(integration_target.get("platform") == "AXIOM-MESH", "AXIOM target missing")
    require(
        integration_target.get("mode") == "governed-domain-capability-pack",
        "unsupported AXIOM integration mode",
    )

    definitions = registry.get("status_definitions")
    require(isinstance(definitions, dict), "status_definitions must be an object")
    require(set(definitions) == ALLOWED_STATUSES, "status definitions are incomplete")

    capabilities = registry.get("capabilities")
    require(isinstance(capabilities, list), "capabilities must be an array")
    require(capabilities, "capabilities must not be empty")

    ids: list[str] = []
    counts: Counter[str] = Counter()
    for index, capability in enumerate(capabilities):
        require(isinstance(capability, dict), f"capability {index} must be an object")
        capability_id = capability.get("id")
        family = capability.get("family")
        status = capability.get("status")
        summary = capability.get("summary")

        require(
            isinstance(capability_id, str) and re.fullmatch(r"[a-z0-9.-]+", capability_id),
            f"capability {index} has an invalid id",
        )
        require(isinstance(family, str) and family, f"{capability_id}: family missing")
        require(status in ALLOWED_STATUSES, f"{capability_id}: invalid status")
        require(
            isinstance(summary, str) and len(summary.strip()) >= 20,
            f"{capability_id}: summary is too short",
        )

        ids.append(capability_id)
        counts[status] += 1

        evidence = capability.get("evidence")
        if status == "implemented":
            require(
                isinstance(evidence, list) and evidence,
                f"{capability_id}: implemented capability requires evidence",
            )

        if evidence is not None:
            require(isinstance(evidence, list), f"{capability_id}: evidence must be an array")
            for path_text in evidence:
                require(isinstance(path_text, str) and path_text, f"{capability_id}: invalid evidence path")
                path = ROOT / path_text
                require(path.exists(), f"{capability_id}: missing evidence path {path_text}")

    require(len(ids) == len(set(ids)), "capability ids must be unique")
    require(REQUIRED_CAPABILITIES.issubset(ids), "required capability families are missing")

    non_claims = registry.get("non_claims")
    require(isinstance(non_claims, list) and len(non_claims) >= 5, "non_claims are incomplete")
    require(all(isinstance(item, str) and item.strip() for item in non_claims), "invalid non_claim")

    for document_path in (README_PATH, PRODUCT_DEFINITION_PATH):
        content = document_path.read_text(encoding="utf-8")
        require(version in content, f"{document_path.relative_to(ROOT)} does not name {version}")

    readme = README_PATH.read_text(encoding="utf-8")
    require("config/capabilities.json" in readme, "README does not link the registry")
    require("not production-ready" in readme, "README production boundary is missing")

    return counts


def main() -> int:
    try:
        counts = verify()
    except (OSError, RegistryError) as error:
        print(f"capability registry verification failed: {error}", file=sys.stderr)
        return 1

    rendered = ", ".join(f"{key}={counts[key]}" for key in sorted(counts))
    print(f"capability registry verified: {rendered}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
