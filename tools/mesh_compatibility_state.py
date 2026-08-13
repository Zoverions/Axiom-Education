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

from tools.json_schema_validation import RepositoryJsonSchemaError, validate_json_schema  # noqa: E402


class MeshCompatibilityError(RuntimeError):
    pass


BASELINE_HEAD = "0b41429bb1bbb716089874b70cc57a5bb68ea527"
LEARNER_MEMORY_HEAD = "2365bf5ed19e0da81288551b2bb4135a7094d02b"
PROFILE_ID = "axiom-education.mesh-0.12.0-dev.3-provider-v1"
PROFILE_VERSION = "1.1.0"

REQUIRED = {
    "axiom.education.v1": (
        "mesh/config/domain-contracts/education.v1.json",
        "a20e191a05308ef85bdc1cc74bfa0d54b98a176818f8030a172b4c3709a28fa2",
        BASELINE_HEAD,
    ),
    "axiom-gateway-client-contract.v1": (
        "mesh/config/gateway-client-contract.json",
        "1d639b06adcf046ff19dab096a9b92134cbaaba8367c2331c10bc37a3c826949",
        BASELINE_HEAD,
    ),
    "axiom-gateway-client-contract.schema.v1": (
        "mesh/config/gateway-client-contract.schema.json",
        "bae7fad4b6e6cc5e0181ebb799f13fac3b797dcfd6f9c00c4f3b23339a5413b2",
        BASELINE_HEAD,
    ),
    "axiom.agent-runtime-adapter.v1": (
        "docs/architecture/contracts/agent-runtime-adapter.v1.schema.json",
        "4954c3d1a49ea57fb0bf5a7eea29140b852e8b5fa2bb11634665f004aca2c19c",
        BASELINE_HEAD,
    ),
    "axiom.education.learner-memory.v1": (
        "mesh/config/domain-contracts/education-learner-memory.v1.json",
        "3763a28919d36721467160ef772e30da1d5a536a8733fd88b65f2c60c9107d78",
        LEARNER_MEMORY_HEAD,
    ),
}

READINESS = {
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

OBSERVED = {
    "delegated-human-authority": (
        "f3bfab6c524d61b101018fa5c7c4fa965984e2c7",
        "draft-not-production",
        None,
    ),
    "axiom-host-profile": (
        "5f8defd99618690d1eeaeb6b082e7fda7c899f67",
        "draft-not-production",
        None,
    ),
    "assurance-graph-a0": (
        "ba67408f9e7495a8f23cf070105efcf619cd86d9",
        "merged-readiness-only-not-adopted",
        "488073e4f04d8a3ec54d4ba7cd4567063a93305f",
    ),
    "provider-observation": (
        "893968f1607e277a18271102d95b178d2dce7fd1",
        "merged-readiness-only-not-adopted",
        "0e3427e6197acf79104b1e30eaf8b01488055df8",
    ),
    "checkout-source-freshness": (
        "7300e38d20ebcbb0963090e5a8a491eda5de6e45",
        "merged-readiness-only-not-adopted",
        BASELINE_HEAD,
    ),
}


def require(value: bool, message: str) -> None:
    if not value:
        raise MeshCompatibilityError(message)


def load_profile(path: Path = PROFILE_PATH) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise MeshCompatibilityError(str(error)) from error
    require(isinstance(value, dict), "compatibility profile root must be an object")
    return value


def verify(path: Path = PROFILE_PATH) -> dict[str, Any]:
    profile = load_profile(path)
    try:
        validate_json_schema(profile, SCHEMA_PATH, label=str(path))
    except RepositoryJsonSchemaError as error:
        raise MeshCompatibilityError(str(error)) from error

    require(profile["profile_id"] == PROFILE_ID, "compatibility profile id drifted")
    require(profile["profile_version"] == PROFILE_VERSION, "compatibility profile version drifted")
    baseline = profile["mesh_baseline"]
    require(baseline["head_sha"] == BASELINE_HEAD, "Mesh baseline head drifted")
    require(baseline["kernel_version"] == "0.12.0-dev.3", "Mesh kernel version drifted")
    require(baseline["authority_path"] == ["Gateway", "Hypervisor", "Sandbox", "Grid"], "Mesh authority path drifted")
    require(baseline["integration_mode"] == "released-artifact-pins-no-submodule", "integration_mode drifted")

    required = {item["id"]: item for item in profile["required_runtime_contracts"]}
    require(set(required) == set(REQUIRED), "required runtime contract set drifted")
    for contract_id, (expected_path, digest, source_sha) in REQUIRED.items():
        item = required[contract_id]
        require(item["path"] == expected_path, f"{contract_id}: contract path drifted")
        require(item["sha256"] == digest, f"{contract_id}: contract digest drifted")
        require(item["source_sha"] == source_sha, f"{contract_id}: source SHA drifted")
        require(item["status"] == "required-runtime-pin", f"{contract_id}: runtime status drifted")

    readiness = {item["id"]: item for item in profile["readiness_only_contracts"]}
    require(set(readiness) == set(READINESS), "readiness-only contract set drifted")
    for contract_id, (expected_path, digest) in READINESS.items():
        item = readiness[contract_id]
        require(item["path"] == expected_path, f"{contract_id}: readiness path drifted")
        require(item["sha256"] == digest, f"{contract_id}: readiness digest drifted")
        require(item["source_sha"] == BASELINE_HEAD, f"{contract_id}: readiness source drifted")
        require(item["status"] == "documentation-readiness-only-no-runtime-authority", f"{contract_id}: readiness status drifted")

    observed = {item["feature_id"]: item for item in profile["observed_upcoming_drafts"]}
    require(set(observed) == set(OBSERVED), "observed Mesh feature set drifted")
    for feature_id, (head_sha, status, merged_sha) in OBSERVED.items():
        item = observed[feature_id]
        require(item["head_sha"] == head_sha, f"{feature_id}: observed head drifted")
        require(item["status"] == status, f"{feature_id}: observed status drifted")
        require(item.get("merged_sha") == merged_sha, f"{feature_id}: merge provenance drifted")
        require(item["runtime_adoption_allowed"] is False, f"{feature_id}: runtime_adoption_allowed drifted")

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
        require(flags[feature] is False, f"{feature}: unadopted feature cannot be enabled")

    invariants = profile["invariants"]
    require(invariants["gateway_is_only_network_authority_entry"] is True, "Gateway authority entry drifted")
    for key in (
        "direct_internal_service_access_allowed",
        "contract_presence_grants_authority",
        "installation_grants_learner_data_access",
        "drafts_may_promote_themselves",
        "application_owns_kernel_authority",
    ):
        require(invariants[key] is False, f"forbidden authority claim enabled: {key}")
    return profile
