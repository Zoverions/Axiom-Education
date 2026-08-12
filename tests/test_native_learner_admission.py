from __future__ import annotations

import copy
import hashlib

import pytest

from tools.check_native_learner_admission import (
    DOMAIN_PATH,
    WORKFLOW_PATH,
    NativeLearnerAdmissionError,
    load_json,
    verify_contracts,
    verify_native_learner_admission,
)
from tools.learner_memory_profile import load_profile


def current_inputs():
    domain, domain_raw = load_json(DOMAIN_PATH)
    workflow, _ = load_json(WORKFLOW_PATH)
    profile = load_profile()
    return domain, workflow, profile, hashlib.sha256(domain_raw).hexdigest()


def test_current_native_learner_admission_contracts_are_coherent() -> None:
    result = verify_native_learner_admission()
    assert result["valid"] is True
    assert result["append_action"] == "education.learner.event.append"
    assert result["provider_capability"] == "education.learner-record"
    assert result["consent_controller"] == "capsule:axiom.education"
    assert result["consent_purpose"] == "learning-progress-recording"
    assert result["consent_scope"] == "learning-progress:write"
    assert result["gateway_scope"] == "education:learner:write"
    assert result["memory_action"] == "memory.put"
    assert result["memory_event_types"] == sorted(
        load_profile()["event_type_to_memory_kind"]
    )


def test_rejects_parent_contract_digest_drift() -> None:
    domain, workflow, profile, domain_digest = current_inputs()
    changed = copy.deepcopy(workflow)
    changed["parent_contract"]["contract_sha256"] = "0" * 64
    with pytest.raises(NativeLearnerAdmissionError, match="parent contract digest"):
        verify_contracts(
            domain,
            changed,
            profile,
            domain_sha256=domain_digest,
        )


def test_rejects_consent_scope_drift() -> None:
    domain, workflow, profile, domain_digest = current_inputs()
    changed = copy.deepcopy(domain)
    changed["actions"]["education.learner.event.append"]["consent"][
        "data_scopes"
    ] = ["learning-progress:read"]
    with pytest.raises(NativeLearnerAdmissionError, match="consent scope drift"):
        verify_contracts(
            changed,
            workflow,
            profile,
            domain_sha256=domain_digest,
        )


def test_rejects_workflow_projection_field_drift() -> None:
    domain, workflow, profile, domain_digest = current_inputs()
    changed = copy.deepcopy(workflow)
    changed["projection"]["required_parent_input"].remove("memory_object_id")
    with pytest.raises(NativeLearnerAdmissionError, match="required projection"):
        verify_contracts(
            domain,
            changed,
            profile,
            domain_sha256=domain_digest,
        )


def test_rejects_unknown_profile_event() -> None:
    domain, workflow, profile, domain_digest = current_inputs()
    changed = copy.deepcopy(profile)
    changed["event_type_to_memory_kind"]["unknown.created"] = (
        "education.learner-submission"
    )
    changed["event_type_to_memory_owner"]["unknown.created"] = "subject"
    with pytest.raises(NativeLearnerAdmissionError, match="unknown workflow event"):
        verify_contracts(
            domain,
            workflow,
            changed,
            domain_sha256=domain_digest,
        )


def test_rejects_actor_owner_binding_on_non_educator_event() -> None:
    domain, workflow, profile, domain_digest = current_inputs()
    changed = copy.deepcopy(profile)
    changed["event_type_to_memory_owner"]["submission.created"] = "actor"
    with pytest.raises(NativeLearnerAdmissionError, match="educator-only"):
        verify_contracts(
            domain,
            workflow,
            changed,
            domain_sha256=domain_digest,
        )


def test_rejects_raw_content_or_automatic_tombstone_promotion() -> None:
    domain, workflow, profile, domain_digest = current_inputs()
    changed = copy.deepcopy(profile)
    changed["invariants"]["raw_content_in_learner_event"] = True
    with pytest.raises(NativeLearnerAdmissionError, match="raw content"):
        verify_contracts(
            domain,
            workflow,
            changed,
            domain_sha256=domain_digest,
        )

    changed = copy.deepcopy(profile)
    changed["invariants"]["automatic_tombstone_on_append_failure"] = True
    with pytest.raises(NativeLearnerAdmissionError, match="tombstones"):
        verify_contracts(
            domain,
            workflow,
            changed,
            domain_sha256=domain_digest,
        )
