# Ontario Elementary source locks

This directory stores **metadata locks**, not Ontario curriculum documents.

A source lock is C1 evidence produced after exact upstream bytes are obtained from an official locator and hashed with the bounded source-capture tooling. The committed lock records what was captured; it does not preserve the source document unless redistribution review separately permits that.

## Why source bytes are not checked in by default

Public availability does not automatically establish redistribution permission. Until source-by-source licensing review is complete, the default is:

- capture the exact official bytes through a declared official source target;
- record the source locator and any resolved locator;
- record SHA-256, byte length, media type, capture time, and the exact discovery entry revision;
- do **not** commit the captured source bytes;
- keep `redistribution_status` at `review-required` or `external-only`.

The current committed locks follow that boundary, including Kindergarten 2026. HTML response surfaces may be valid historical C1 snapshots while remaining observational rather than strict exact-byte drift sources; monitoring policy is kept separately in `../source-monitoring.v1.json`.

## Capture

Example for an operator who has already downloaded the official source to `/tmp/ontario-math.pdf`:

```bash
python tools/curriculum_source_lock.py capture \
  --source-id ontario-mathematics-grades-1-8-2020 \
  --input /tmp/ontario-math.pdf \
  --source-locator https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-mathematics \
  --resolved-locator https://www.dcp.edu.gov.on.ca/en/curriculum/elementary-mathematics \
  --media-type application/pdf \
  --output curriculum/ontario-elementary/source-locks/ontario-mathematics-grades-1-8-2020.v1.json
```

For hosted capture, `tools/remote_curriculum_source_capture.py` accepts only predeclared source IDs from the bounded target registry. `tools/attempt_pending_curriculum_capture.py` can preserve either a verified candidate or a truthful capture-unavailable result without turning source unavailability into fake success.

If the portal redirects to a distinct official download URL, preserve the discovery locator as `source_locator` and record the final official download URL as `resolved_locator`.

## Verify

```bash
python tools/curriculum_source_lock.py verify-directory \
  --directory curriculum/ontario-elementary/source-locks
```

A committed lock may be described as C1 **only for exact-byte capture and digest evidence**. Recapture stability is a separate monitoring property; a later differing HTML response does not erase a historical C1 capture and does not by itself establish curriculum change.

## C1 is not C2-C8

A valid source lock does not prove:

- the official document was interpreted correctly;
- expectation extraction or normalization is complete;
- the source can legally be redistributed;
- a crosswalk is correct;
- the pack is deterministic;
- a signer or reviewer approved it;
- the pack is staged or active;
- Ministry approval or endorsement.

Those claims require their own later evidence gates.
