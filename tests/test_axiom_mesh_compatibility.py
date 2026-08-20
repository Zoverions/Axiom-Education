from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.check_axiom_mesh_compatibility import (
    MeshCompatibilityError,
    PROFILE_PATH,
    verify,
)


class AxiomMeshCompatibilityTests(unittest.TestCase):
    def mutation(self, mutate) -> Path:
        payload = json.loads(PROFILE_PATH.read_text(encoding="utf-8"))
        mutate(payload)
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "profile.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        return path

    def test_canonical_profile_verifies(self) -> None:
        profile = verify()
        self.assertEqual(
            profile["mesh_baseline"]["authority_path"],
            ["Gateway", "Hypervisor", "Sandbox", "Grid"],
        )
        self.assertEqual(
            profile["mesh_baseline"]["head_role"],
            "observed-provenance-not-runtime-binding",
        )

    def test_provenance_checkpoint_drift_is_rejected_in_profile_evidence(self) -> None:
        path = self.mutation(
            lambda value: value["mesh_baseline"].update({"head_sha": "0" * 40})
        )
        with self.assertRaisesRegex(MeshCompatibilityError, "provenance checkpoint"):
            verify(path)

    def test_current_gateway_observation_drift_is_rejected(self) -> None:
        path = self.mutation(
            lambda value: value["mesh_baseline"].update(
                {"gateway_contract_canonical_sha256": "0" * 64}
            )
        )
        with self.assertRaisesRegex(MeshCompatibilityError, "Gateway canonical"):
            verify(path)

    def test_gateway_intent_seam_content_drift_is_rejected(self) -> None:
        path = self.mutation(
            lambda value: value["gateway_intents_submit_seam"]["route"].update(
                {"path": "/v1/unreviewed"}
            )
        )
        with self.assertRaises(MeshCompatibilityError):
            verify(path)

    def test_gateway_intent_seam_digest_drift_is_rejected(self) -> None:
        path = self.mutation(
            lambda value: value["gateway_intents_submit_seam"].update(
                {"sha256": "0" * 64}
            )
        )
        with self.assertRaises(MeshCompatibilityError):
            verify(path)

    def test_pinned_runtime_source_does_not_follow_unrelated_mesh_head(self) -> None:
        path = self.mutation(
            lambda value: value["required_runtime_contracts"][0].update(
                {"source_sha": value["mesh_baseline"]["head_sha"]}
            )
        )
        with self.assertRaisesRegex(MeshCompatibilityError, "source SHA drifted"):
            verify(path)

    def test_observed_feature_cannot_self_promote(self) -> None:
        path = self.mutation(
            lambda value: value["observed_upcoming_drafts"][0].update(
                {"runtime_adoption_allowed": True}
            )
        )
        with self.assertRaises(MeshCompatibilityError):
            verify(path)

    def test_merged_readiness_feature_still_cannot_promote(self) -> None:
        path = self.mutation(
            lambda value: value["feature_flags"].update({"assurance_graph": True})
        )
        with self.assertRaises(MeshCompatibilityError):
            verify(path)

    def test_contract_path_drift_is_rejected(self) -> None:
        path = self.mutation(
            lambda value: value["required_runtime_contracts"][0].update(
                {"path": "mesh/unreviewed/education.json"}
            )
        )
        with self.assertRaisesRegex(MeshCompatibilityError, "contract path drifted"):
            verify(path)

    def test_observed_draft_digest_drift_is_rejected(self) -> None:
        path = self.mutation(
            lambda value: value["observed_upcoming_drafts"][0][
                "contract_sha256"
            ].update({"axiom-human-authority.v1": "0" * 64})
        )
        with self.assertRaisesRegex(MeshCompatibilityError, "contract digests drifted"):
            verify(path)

    def test_merged_observation_requires_exact_merge_sha(self) -> None:
        path = self.mutation(
            lambda value: value["observed_upcoming_drafts"][2].update(
                {"merged_sha": "0" * 40}
            )
        )
        with self.assertRaisesRegex(MeshCompatibilityError, "merged SHA drifted"):
            verify(path)

    def test_direct_internal_service_access_is_rejected(self) -> None:
        path = self.mutation(
            lambda value: value["invariants"].update(
                {"direct_internal_service_access_allowed": True}
            )
        )
        with self.assertRaises(MeshCompatibilityError):
            verify(path)

    def test_submodule_integration_mode_is_rejected(self) -> None:
        path = self.mutation(
            lambda value: value["mesh_baseline"].update(
                {"integration_mode": "git-submodule"}
            )
        )
        with self.assertRaises(MeshCompatibilityError):
            verify(path)


if __name__ == "__main__":
    unittest.main()
