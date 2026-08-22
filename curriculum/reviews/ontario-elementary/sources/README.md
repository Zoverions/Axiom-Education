# Ontario Elementary source reviews

This directory is reserved for **human source identity and scope review evidence**.

The deterministic review plan is generated from the current composed Ontario Elementary discovery view and all committed C1 source locks:

```bash
python tools/ontario_elementary_source_review.py plan
```

There are currently 16 review targets. Each target is content-addressed over the exact composed source metadata and C1 lock. A later source-route, version, scope, authority, or lock change therefore makes an earlier review stale instead of silently carrying approval forward.

A source review may confirm only:

- the named source is an official Ontario curriculum source for the represented program;
- the authority identity is correct;
- the policy/version identity is correct;
- the represented grade scope is correct;
- the official source locator is appropriate for the reviewed source identity.

A source review **does not** approve:

- redistribution or licensing;
- verbatim curriculum text;
- normalized C2 records;
- expectation completeness or correctness;
- competency crosswalks;
- pedagogy or assessment validity;
- accessibility completion;
- deterministic packs;
- staging or activation;
- Ministry endorsement.

Submitted review evidence must use schema marker `axiom-education-ontario-elementary-source-review.v1`, identify a qualified human reviewer, bind the current `target_sha256`, record an explicit decision, and preserve findings and scope limitations. The verifier rejects machine attestations and refuses an `approved` decision if any required confirmation is false or any finding remains open.

No source reviews are checked in merely to satisfy the gate. Until qualified human attestations exist, `human_source_review_complete` remains false.
