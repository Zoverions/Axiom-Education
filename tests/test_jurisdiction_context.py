import unittest

from tools.jurisdiction_context import JurisdictionResolutionError, resolve_jurisdiction_context


D1 = "a" * 64
D2 = "b" * 64
D3 = "c" * 64
D4 = "d" * 64


def claim(
    *,
    claim_id: str,
    authority_id: str,
    jurisdiction_id: str,
    authority_level: str,
    assurance: str = "A2",
    standards_role: str = "mandatory",
    effective_from: str = "2026-01-01T00:00:00Z",
    effective_until=None,
    parent_replacement_delegated: bool = False,
):
    return {
        "claim_id": claim_id,
        "subject_id": "learner-1",
        "claim_type": "institution-enrollment" if authority_level == "institution" else "residency",
        "authority_id": authority_id,
        "jurisdiction_id": jurisdiction_id,
        "authority_level": authority_level,
        "assurance": assurance,
        "evidence_digest": D1 if claim_id.endswith("1") else D2,
        "standards_role": standards_role,
        "effective_from": effective_from,
        "effective_until": effective_until,
        "parent_replacement_delegated": parent_replacement_delegated,
    }


def pack(
    *,
    pack_id: str,
    authority_id: str,
    jurisdiction_id: str,
    effective_from: str = "2026-01-01T00:00:00Z",
    effective_until=None,
    replaces_parent_minimums: bool = False,
):
    return {
        "pack_id": pack_id,
        "authority_id": authority_id,
        "jurisdiction_id": jurisdiction_id,
        "grade_bands": ["elementary-3"],
        "manifest_sha256": D3 if pack_id.endswith("1") else D4,
        "signer_key_id": f"key:{authority_id}",
        "effective_from": effective_from,
        "effective_until": effective_until,
        "replaces_parent_minimums": replaces_parent_minimums,
    }


class JurisdictionContextTest(unittest.TestCase):
    def test_resolves_broad_to_specific_and_is_deterministic(self):
        claims = [
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
        ]
        packs = [
            pack(
                pack_id="pack-school-2",
                authority_id="school:oak",
                jurisdiction_id="ca:on:hamilton:oak",
            ),
            pack(
                pack_id="pack-region-1",
                authority_id="gov:on",
                jurisdiction_id="ca:on",
            ),
        ]

        first = resolve_jurisdiction_context(
            subject_id="learner-1",
            grade_band="elementary-3",
            claims=claims,
            packs=packs,
            as_of="2026-08-10T12:00:00Z",
        )
        second = resolve_jurisdiction_context(
            subject_id="learner-1",
            grade_band="elementary-3",
            claims=list(reversed(claims)),
            packs=list(reversed(packs)),
            as_of="2026-08-10T12:00:00Z",
        )

        self.assertEqual([layer["authority_level"] for layer in first["layers"]], ["region", "institution"])
        self.assertEqual(first["resolution_digest"], second["resolution_digest"])

    def test_rejects_claim_below_a2(self):
        with self.assertRaises(JurisdictionResolutionError) as caught:
            resolve_jurisdiction_context(
                subject_id="learner-1",
                grade_band="elementary-3",
                claims=[
                    claim(
                        claim_id="claim-region-1",
                        authority_id="gov:on",
                        jurisdiction_id="ca:on",
                        authority_level="region",
                        assurance="A1",
                    )
                ],
                packs=[
                    pack(
                        pack_id="pack-region-1",
                        authority_id="gov:on",
                        jurisdiction_id="ca:on",
                    )
                ],
                as_of="2026-08-10T12:00:00Z",
            )
        self.assertEqual(caught.exception.code, "insufficient_claim_assurance")

    def test_missing_mandatory_pack_fails_closed(self):
        with self.assertRaises(JurisdictionResolutionError) as caught:
            resolve_jurisdiction_context(
                subject_id="learner-1",
                grade_band="elementary-3",
                claims=[
                    claim(
                        claim_id="claim-region-1",
                        authority_id="gov:on",
                        jurisdiction_id="ca:on",
                        authority_level="region",
                    )
                ],
                packs=[],
                as_of="2026-08-10T12:00:00Z",
            )
        self.assertEqual(caught.exception.code, "required_pack_missing")

    def test_ambiguous_same_authority_pack_fails_closed(self):
        claims = [
            claim(
                claim_id="claim-region-1",
                authority_id="gov:on",
                jurisdiction_id="ca:on",
                authority_level="region",
            )
        ]
        packs = [
            pack(
                pack_id="pack-region-1",
                authority_id="gov:on",
                jurisdiction_id="ca:on",
                effective_from="2026-06-01T00:00:00Z",
            ),
            pack(
                pack_id="pack-region-2",
                authority_id="gov:on",
                jurisdiction_id="ca:on",
                effective_from="2026-06-01T00:00:00Z",
            ),
        ]
        with self.assertRaises(JurisdictionResolutionError) as caught:
            resolve_jurisdiction_context(
                subject_id="learner-1",
                grade_band="elementary-3",
                claims=claims,
                packs=packs,
                as_of="2026-08-10T12:00:00Z",
            )
        self.assertEqual(caught.exception.code, "ambiguous_pack")

    def test_parent_minimum_replacement_requires_delegation(self):
        claims = [
            claim(
                claim_id="claim-region-1",
                authority_id="gov:on",
                jurisdiction_id="ca:on",
                authority_level="region",
            ),
            claim(
                claim_id="claim-school-2",
                authority_id="school:oak",
                jurisdiction_id="ca:on:hamilton:oak",
                authority_level="institution",
            ),
        ]
        packs = [
            pack(
                pack_id="pack-region-1",
                authority_id="gov:on",
                jurisdiction_id="ca:on",
            ),
            pack(
                pack_id="pack-school-2",
                authority_id="school:oak",
                jurisdiction_id="ca:on:hamilton:oak",
                replaces_parent_minimums=True,
            ),
        ]
        with self.assertRaises(JurisdictionResolutionError) as caught:
            resolve_jurisdiction_context(
                subject_id="learner-1",
                grade_band="elementary-3",
                claims=claims,
                packs=packs,
                as_of="2026-08-10T12:00:00Z",
            )
        self.assertEqual(caught.exception.code, "parent_replacement_not_delegated")

    def test_jurisdiction_change_is_effective_dated_without_rewriting_history(self):
        claims = [
            claim(
                claim_id="claim-region-1",
                authority_id="gov:on",
                jurisdiction_id="ca:on",
                authority_level="region",
                effective_from="2026-01-01T00:00:00Z",
                effective_until="2026-09-01T00:00:00Z",
            ),
            claim(
                claim_id="claim-region-2",
                authority_id="gov:ab",
                jurisdiction_id="ca:ab",
                authority_level="region",
                effective_from="2026-09-01T00:00:00Z",
            ),
        ]
        packs = [
            pack(
                pack_id="pack-region-1",
                authority_id="gov:on",
                jurisdiction_id="ca:on",
            ),
            pack(
                pack_id="pack-region-2",
                authority_id="gov:ab",
                jurisdiction_id="ca:ab",
            ),
        ]

        before = resolve_jurisdiction_context(
            subject_id="learner-1",
            grade_band="elementary-3",
            claims=claims,
            packs=packs,
            as_of="2026-08-10T12:00:00Z",
        )
        after = resolve_jurisdiction_context(
            subject_id="learner-1",
            grade_band="elementary-3",
            claims=claims,
            packs=packs,
            as_of="2026-09-10T12:00:00Z",
        )

        self.assertEqual(before["layers"][0]["jurisdiction_id"], "ca:on")
        self.assertEqual(after["layers"][0]["jurisdiction_id"], "ca:ab")
        self.assertNotEqual(before["resolution_digest"], after["resolution_digest"])


if __name__ == "__main__":
    unittest.main()
