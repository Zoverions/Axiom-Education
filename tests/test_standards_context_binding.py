import hashlib
import json
from pathlib import Path
import unittest

from tools.jurisdiction_context import resolve_jurisdiction_context
from tools.standards_context_binding import (
    StandardsContextBindingError,
    bind_projection_to_event_payload,
    build_event_standards_projection,
    validate_event_standards_projection,
    validate_jurisdiction_resolution,
)


D1 = "a" * 64
D2 = "b" * 64
D3 = "c" * 64
D4 = "d" * 64
D5 = "e" * 64
D6 = "f" * 64
PINNED_EDUCATION_V1 = "a20e191a05308ef85bdc1cc74bfa0d54b98a176818f8030a172b4c3709a28fa2"


def claim(*, claim_id, authority_id, jurisdiction_id, authority_level):
    return {
        "claim_id": claim_id,
        "subject_id": "learner-1",
        "claim_type": "institution-enrollment" if authority_level == "institution" else "residency",
        "authority_id": authority_id,
        "jurisdiction_id": jurisdiction_id,
        "authority_level": authority_level,
        "assurance": "A2",
        "evidence_digest": D1 if authority_level == "region" else D2,
        "standards_role": "mandatory",
        "effective_from": "2026-01-01T00:00:00Z",
        "effective_until": None,
        "parent_replacement_delegated": False,
    }


def pack(*, pack_id, authority_id, jurisdiction_id, manifest):
    return {
        "pack_id": pack_id,
        "authority_id": authority_id,
        "jurisdiction_id": jurisdiction_id,
        "grade_bands": ["elementary-3"],
        "manifest_sha256": manifest,
        "signer_key_id": f"key:{authority_id}",
        "effective_from": "2026-01-01T00:00:00Z",
        "effective_until": None,
        "replaces_parent_minimums": False,
    }


def resolution():
    return resolve_jurisdiction_context(
        subject_id="learner-1",
        grade_band="elementary-3",
        claims=[
            claim(
                claim_id="claim-school-2",
                authority_id="school:oak",
                jurisdiction_id="ca:on:hamilton:oak",
                authority_level="institution",
            ),
            claim(
                claim_id="claim-region-1",
                authority_id="gov:on",
                jurisdiction_id="ca:on",
                authority_level="region",
            ),
        ],
        packs=[
            pack(
                pack_id="pack-school-2",
                authority_id="school:oak",
                jurisdiction_id="ca:on:hamilton:oak",
                manifest=D4,
            ),
            pack(
                pack_id="pack-region-1",
                authority_id="gov:on",
                jurisdiction_id="ca:on",
                manifest=D3,
            ),
        ],
        as_of="2026-08-11T12:00:00Z",
    )


def projection(context=None):
    return build_event_standards_projection(
        resolution=context or resolution(),
        selected_pack_manifest_sha256=D4,
        course_code="MAT3",
        expectation_ids=["B1.2", "B1.1"],
        crosswalk_manifest_sha256=D5,
        crosswalk_verification_digest=D6,
    )


class StandardsContextBindingTest(unittest.TestCase):
    def test_pinned_axiom_education_v1_contract_is_byte_unchanged(self):
        contract = Path("contracts/axiom-education.v1.json").read_bytes()
        self.assertEqual(hashlib.sha256(contract).hexdigest(), PINNED_EDUCATION_V1)

    def test_projection_preserves_full_ordered_context_while_selecting_one_event_pack(self):
        context = validate_jurisdiction_resolution(resolution())
        result = projection(context)

        self.assertEqual(
            result["context_pack_manifest_sha256s"],
            [D3, D4],
        )
        self.assertEqual(result["selected_pack_manifest_sha256"], D4)
        self.assertEqual(result["resolution_digest"], context["resolution_digest"])
        self.assertEqual(result["expectation_ids"], ["B1.1", "B1.2"])
        self.assertRegex(result["projection_digest"], r"^[a-f0-9]{64}$")
        self.assertNotEqual(
            result["context_pack_manifest_sha256s"],
            [result["selected_pack_manifest_sha256"]],
        )

    def test_event_v1_selected_pack_course_and_expectations_must_match_projection(self):
        context = resolution()
        result = projection(context)
        event = {
            "subject_id": "learner-1",
            "active_pack_manifest_sha256": D4,
            "course_code": "MAT3",
            "expectation_ids": ["B1.1", "B1.2"],
        }
        self.assertEqual(
            validate_event_standards_projection(
                resolution=context,
                projection=result,
                event_input=event,
            ),
            result,
        )

        for field, value, code in [
            ("subject_id", "learner-2", "event_subject_mismatch"),
            ("active_pack_manifest_sha256", D3, "event_pack_mismatch"),
            ("course_code", "SCI3", "event_course_mismatch"),
            ("expectation_ids", ["B1.1"], "event_expectations_mismatch"),
        ]:
            changed = dict(event)
            changed[field] = value
            with self.assertRaises(StandardsContextBindingError) as caught:
                validate_event_standards_projection(
                    resolution=context,
                    projection=result,
                    event_input=changed,
                )
            self.assertEqual(caught.exception.code, code)

    def test_selected_event_pack_must_exist_in_full_context(self):
        with self.assertRaises(StandardsContextBindingError) as caught:
            build_event_standards_projection(
                resolution=resolution(),
                selected_pack_manifest_sha256="0" * 64,
                course_code="MAT3",
                expectation_ids=["B1.1"],
                crosswalk_manifest_sha256=D5,
                crosswalk_verification_digest=D6,
            )
        self.assertEqual(caught.exception.code, "selected_pack_outside_context")

    def test_resolution_digest_and_broad_to_specific_order_are_fail_closed(self):
        changed_digest = dict(resolution())
        changed_digest["resolution_digest"] = "0" * 64
        with self.assertRaises(StandardsContextBindingError) as caught:
            validate_jurisdiction_resolution(changed_digest)
        self.assertEqual(caught.exception.code, "resolution_digest_mismatch")

        reordered = resolution()
        reordered["layers"] = list(reversed(reordered["layers"]))
        unsigned = dict(reordered)
        unsigned.pop("resolution_digest")
        reordered["resolution_digest"] = hashlib.sha256(
            json.dumps(
                unsigned,
                sort_keys=True,
                separators=(",", ":"),
                ensure_ascii=False,
            ).encode("utf-8")
        ).hexdigest()
        with self.assertRaises(StandardsContextBindingError) as caught:
            validate_jurisdiction_resolution(reordered)
        self.assertEqual(caught.exception.code, "resolution_order_mismatch")

    def test_projection_cannot_be_reused_after_full_context_changes(self):
        first = resolution()
        bound = projection(first)

        second = resolution()
        second["layers"][0]["claim_evidence_digest"] = "9" * 64
        unsigned = dict(second)
        unsigned.pop("resolution_digest")
        second["resolution_digest"] = hashlib.sha256(
            json.dumps(
                unsigned,
                sort_keys=True,
                separators=(",", ":"),
                ensure_ascii=False,
            ).encode("utf-8")
        ).hexdigest()

        with self.assertRaises(StandardsContextBindingError) as caught:
            validate_event_standards_projection(
                resolution=second,
                projection=bound,
            )
        self.assertEqual(caught.exception.code, "projection_context_mismatch")

    def test_projection_digest_rejects_substitution(self):
        result = projection()
        changed = dict(result)
        changed["selected_pack_manifest_sha256"] = D3
        with self.assertRaises(StandardsContextBindingError) as caught:
            validate_event_standards_projection(
                resolution=resolution(),
                projection=changed,
            )
        self.assertEqual(caught.exception.code, "projection_digest_mismatch")

    def test_payload_digest_can_bind_projection_without_expanding_v1_event_contract(self):
        result = projection()
        bound = bind_projection_to_event_payload(
            event_payload={
                "activity_id": "claw.the-one-bridge.v1",
                "activity_content_digest": "1" * 64,
                "learner_evidence_digest": "2" * 64,
            },
            projection=result,
        )
        self.assertEqual(bound["payload"]["standards_projection"], result)
        self.assertEqual(bound["standards_projection_digest"], result["projection_digest"])
        self.assertRegex(bound["payload_digest"], r"^[a-f0-9]{64}$")

        changed = dict(bound["payload"])
        changed["learner_evidence_digest"] = "3" * 64
        changed_digest = hashlib.sha256(
            json.dumps(
                changed,
                sort_keys=True,
                separators=(",", ":"),
                ensure_ascii=False,
            ).encode("utf-8")
        ).hexdigest()
        self.assertNotEqual(changed_digest, bound["payload_digest"])

    def test_expectations_are_canonical_and_duplicates_fail_closed(self):
        result = projection()
        self.assertEqual(result["expectation_ids"], ["B1.1", "B1.2"])
        with self.assertRaises(StandardsContextBindingError) as caught:
            build_event_standards_projection(
                resolution=resolution(),
                selected_pack_manifest_sha256=D4,
                course_code="MAT3",
                expectation_ids=["B1.1", "B1.1"],
                crosswalk_manifest_sha256=D5,
                crosswalk_verification_digest=D6,
            )
        self.assertEqual(caught.exception.code, "duplicate_expectation")


if __name__ == "__main__":
    unittest.main()
