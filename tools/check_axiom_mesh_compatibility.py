#!/usr/bin/env python3
"""Fail closed on drift in the pinned Axiom Education to AXIOM-MESH seam."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
PROFILE_PATH = ROOT / "config" / "axiom-mesh-compatibility.v1.json"
SCHEMA_PATH = ROOT / "schemas" / "axiom-mesh-compatibility.v1.schema.json"

if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.json_schema_validation import (  # noqa: E402
    RepositoryJsonSchemaError,
    validate_json_schema,
)


class MeshCompatibilityError(RuntimeError):
    """Raised when a compatibility pin or authority boundary drifts."""


EXPECTED_PROFILE_ID = "axiom-education.mesh-0.12.0-dev.3-provider-v1"
EXPECTED_PROFILE_VERSION = "1.1.0"
EXPECTED_BASELINE_HEAD = "eb3614b3f8ccdd6c7f6367ceaaec5cc43c306534"
PINNED_BASE_ARTIFACT_SOURCE = "4d3ddbbe1b9baded8d57d8115a11dee3a1d8e26c"
EXPECTED_PROVIDER_HEAD = "2365bf5ed19e0da81288551b2bb4135a7094d02b"
EXPECTED_GATEWAY_CANONICAL_DIGEST = (
    "77d57f3f031ef0c8f777b0c77a4560fe3b9bacf8c14935ffc7a917b677544ddd"
)
EXPECTED_GATEWAY_COMPATIBILITY_MODE = (
    "pinned-v1-intents-submit-seam-with-additive-read-route-tolerance"
)
EXPECTED_REQUIRED_DIGESTS = {
    "axiom.education.v1": "a20e191a05308ef85bdc1cc74bfa0d54b98a176818f8030a172b4c3709a28fa2",
    "axiom-gateway-client-contract.v1": "1d639b06adcf046ff19dab096a9b92134cbaaba8367c2331c10bc37a3c826949",
    "axiom-gateway-client-contract.schema.v1": "bae7fad4b6e6cc5e0181ebb799f13fac3b797dcfd6f9c00c4f3b23339a5413b2",
    "axiom.agent-runtime-adapter.v1": "4954c3d1a49ea57fb0bf5a7eea29140b852e8b5fa2bb11634665f004aca2c19c",
    "axiom.education.learner-memory.v1": "3763a28919d36721467160ef772e30da1d5a536a8733fd88b65f2c60c9107d78",
}
EXPECTED_REQUIRED_PATHS = {
    "axiom.education.v1": "mesh/config/domain-contracts/education.v1.json",
    "axiom-gateway-client-contract.v1": "mesh/config/gateway-client-contract.json",
    "axiom-gateway-client-contract.schema.v1": "mesh/config/gateway-client-contract.schema.json",
    "axiom.agent-runtime-adapter.v1": "docs/architecture/contracts/agent-runtime-adapter.v1.schema.json",
    "axiom.education.learner-memory.v1": "mesh/config/domain-contracts/education-learner-memory.v1.json",
}
EXPECTED_REQUIRED_SOURCES = {
    "axiom.education.v1": PINNED_BASE_ARTIFACT_SOURCE,
    "axiom-gateway-client-contract.v1": PINNED_BASE_ARTIFACT_SOURCE,
    "axiom-gateway-client-contract.schema.v1": PINNED_BASE_ARTIFACT_SOURCE,
    "axiom.agent-runtime-adapter.v1": PINNED_BASE_ARTIFACT_SOURCE,
    "axiom.education.learner-memory.v1": EXPECTED_PROVIDER_HEAD,
}
EXPECTED_READINESS_CONTRACTS = {
    "axiom.runtime-capsule.v1": (
        "docs/architecture/contracts/agent-runtime-capsule.v1.schema.json",
        "f86e3c0febbb8c6a7e0ef5e87aedcdcce72e4a6c8c5fa2c432622306bb85eaa5",
    ),
    "axiom.personal-agent-pack.v1": (
        "docs/architecture/contracts/personal-agent-pack.v1.schema.json",
        "d9a41a752980bbc67e8de88ba1f9b603dd4d0f344c3831950d1109c1d0a5972d",
    ),
    "axiom.compute-node-profile.v1": (
        "docs/architecture/contracts/compute-node-profile.v1.schema.json",
        "a033dca8d5f560e3677a25c5738d47c890355677d3e02972708f95f5147b5417",
    ),
    "axiom.local-trust-envelope.v1": (
        "docs/architecture/contracts/local-trust-envelope.v1.schema.json",
        "5dafb467111c743c5f90e2a02e7b888dc7456e75460e667b4ceff58177bc2089",
    ),
}
EXPECTED_OBSERVED_FEATURES = {
    "delegated-human-authority": {
        "head_sha": "f3bfab6c524d61b101018fa5c7c4fa965984e2c7",
        "status": "draft-not-production",
        "merged_sha": None,
        "contract_sha256": {
            "axiom-human-authority.v1": "bb70bc73cfc8ed7a041e71074a80565764a5f6796138113674d12642c8c15d9c",
            "axiom-delegated-consent.v1": "d4e0cefb487a52096a757c759c748ff5975e20da59e8ef72252bb8881dc147d1",
        },
    },
    "axiom-host-profile": {
        "head_sha": "5f8defd99618690d1eeaeb6b082e7fda7c899f67",
        "status": "draft-not-production",
        "merged_sha": None,
        "contract_sha256": {
            "axiom-host-profile.v1": "30e01862577f1ed12486406fdf3b2cd17f4e0c76aeb8adc7ea930566c4e1cf53",
        },
    },
    "assurance-graph-a0": {
        "head_sha": "ba67408f9e7495a8f23cf070105efcf619cd86d9",
        "status": "merged-readiness-only-not-adopted",
        "merged_sha": "488073e4f04d8a3ec54d4ba7cd4567063a93305f",
        "contract_sha256": {},
    },
    "provider-observation": {
        "head_sha": "893968f1607e277a18271102d95b178d2dce7fd1",
        "status": "merged-readiness-only-not-adopted",
        "merged_sha": "0e3427e6197acf79104b1e30eaf8b01488055df8",
        "contract_sha256": {},
    },
    "checkout-source-freshness": {
        "head_sha": "7300e38d20ebcbb0963090e5a8a491eda5de6e45",
        "status": "merged-readiness-only-not-adopted",
        "merged_sha": "0b41429bb1bbb716089874b70cc57a5bb68ea527",
        "contract_sha256": {},
    },
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise MeshCompatibilityError(message)


def load_profile(path: Path = PROFILE_PATH) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise MeshCompatibilityError(f"missing compatibility profile: {path}") from error
    except json.JSONDecodeError as error:
        raise MeshCompatibilityError(f"invalid compatibility JSON: {error}") from error
    require(isinstance(payload, dict), "compatibility profile root must be an object")
    return payload


def verify(path: Path = PROFILE_PATH) -> dict[str, Any]:
    profile = load_profile(path)
    try:
        validate_json_schema(profile, SCHEMA_PATH, label=str(path))
    except RepositoryJsonSchemaError as error:
        raise MeshCompatibilityError(str(error)) from error

    require(profile["profile_id"] == EXPECTED_PROFILE_ID, "compatibility profile id drifted")
    require(profile["profile_version"] == EXPECTED_PROFILE_VERSION, "compatibility profile version drifted")

    baseline = profile["mesh_baseline"]
    require(baseline["head_sha"] == EXPECTED_BASELINE_HEAD, "Mesh baseline head drifted")
    require(baseline["kernel_version"] == "0.12.0-dev.3", "Mesh kernel version drifted")
    require(
        baseline["authority_path"] == ["Gateway", "Hypervisor", "Sandbox", "Grid"],
        "Mesh authority path drifted",
    )
    require(
        baseline["integration_mode"] == "released-artifact-pins-no-submodule",
        "Axiom Education must consume pinned artifacts without a Mesh submodule",
    )
    require(
        baseline["gateway_contract_source_sha"] == EXPECTED_BASELINE_HEAD,
        "current Gateway observation source drifted",
    )
    require(
        baseline["gateway_contract_canonical_sha256"] == EXPECTED_GATEWAY_CANONICAL_DIGEST,
        "current Gateway canonical contract digest drifted",
    )
    require(
        baseline["gateway_compatibility_mode"] == EXPECTED_GATEWAY_COMPATIBILITY_MODE,
        "Gateway compatibility mode drifted",
    )

    required = {item["id"]: item for item in profile["required_runtime_contracts"]}
    require(set(required) == set(EXPECTED_REQUIRED_DIGESTS), "required runtime contract set drifted")
    for contract_id, digest in EXPECTED_REQUIRED_DIGESTS.items():
        item = required[contract_id]
        require(item["sha256"] == digest, f"{contract_id}: contract digest drifted")
        require(item["path"] == EXPECTED_REQUIRED_PATHS[contract_id], f"{contract_id}: contract path drifted")
        require(item["source_sha"] == EXPECTED_REQUIRED_SOURCES[contract_id], f"{contract_id}: source SHA drifted")
        require(item["status"] == "required-runtime-pin", f"{contract_id}: runtime status drifted")

    readiness = {item["id"]: item for item in profile["readiness_only_contracts"]}
    require(set(readiness) == set(EXPECTED_READINESS_CONTRACTS), "readiness-only contract set drifted")
    for contract_id, (path_value, digest) in EXPECTED_READINESS_CONTRACTS.items():
        item = readiness[contract_id]
        require(item["path"] == path_value, f"{contract_id}: readiness path drifted")
        require(item["sha256"] == digest, f"{contract_id}: readiness digest drifted")
        require(item["source_sha"] == PINNED_BASE_ARTIFACT_SOURCE, f"{contract_id}: readiness source drifted")
        require(
            item["status"] == "documentation-readiness-only-no-runtime-authority",
            f"{contract_id}: readiness contract cannot become runtime authority",
        )

    observed = {item["feature_id"]: item for item in profile["observed_upcoming_drafts"]}
    require(set(observed) == set(EXPECTED_OBSERVED_FEATURES), "observed Mesh feature set drifted")
    for feature_id, expected in EXPECTED_OBSERVED_FEATURES.items():
        item = observed[feature_id]
        require(item["head_sha"] == expected["head_sha"], f"{feature_id}: observed head drifted")
        require(item["status"] == expected["status"], f"{feature_id}: observed status drifted")
        require(item["runtime_adoption_allowed"] is False, f"{feature_id}: observed feature cannot self-promote")
        require(item.get("contract_sha256", {}) == expected["contract_sha256"], f"{feature_id}: observed contract digests drifted")
        merged_sha = expected["merged_sha"]
        if merged_sha is None:
            require("merged_sha" not in item, f"{feature_id}: draft must not claim a merge SHA")
        else:
            require(item.get("merged_sha") == merged_sha, f"{feature_id}: merged SHA drifted")

    flags = profile["feature_flags"]
    require(flags["native_learner_self_write"] is True, "native learner self-write must be present")
    require(flags["native_learner_self_read"] is True, "native learner self-read must be present")
    for feature in (
        "delegated_human_authority",
        "axiom_host_profile",
        "assurance_graph",
        "provider_observation",
        "checkout_freshness",
        "local_trust_activation",
    ):
        require(flags[feature] is False, f"{feature}: readiness or draft feature cannot be enabled")

    invariants = profile["invariants"]
    require(invariants["gateway_is_only_network_authority_entry"] is True, "Gateway authority entry drifted")
    for forbidden in (
        "direct_internal_service_access_allowed",
        "contract_presence_grants_authority",
        "installation_grants_learner_data_access",
        "drafts_may_promote_themselves",
        "application_owns_kernel_authority",
    ):
        require(invariants[forbidden] is False, f"forbidden authority claim enabled: {forbidden}")
    return profile


def main() -> int:
    try:
        profile = verify()
    except (OSError, MeshCompatibilityError) as error:
        print(f"AXIOM-MESH compatibility verification failed: {error}", file=sys.stderr)
        return 1
    print(
        "AXIOM-MESH compatibility verified: "
        f"{profile['profile_id']} at checkpoint {profile['mesh_baseline']['head_sha']}; "
        "pinned runtime artifacts remain explicit and readiness features remain non-authoritative"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
