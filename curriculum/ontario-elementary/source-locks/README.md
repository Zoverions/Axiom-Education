# Ontario Elementary source locks

This directory stores **metadata locks**, not Ontario curriculum documents.

A source lock is the C1 evidence record produced after an operator obtains exact upstream bytes from an official locator and hashes that local file with `tools/curriculum_source_lock.py`.

## Why source bytes are not checked in by default

Public availability does not automatically establish redistribution permission. Until source-by-source licensing review is complete, the default is:

- capture the exact official bytes locally;
- record the source locator and any resolved locator;
- record SHA-256, byte length, media type, capture time, and the exact discovery entry revision;
- do **not** commit the captured source bytes;
- keep `redistribution_status` at `review-required` or `external-only`.

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

If the portal redirects to a distinct official download URL, preserve the discovery locator in `--source-locator` and record the final official download URL in `--resolved-locator`.

## Verify

```bash
python tools/curriculum_source_lock.py verify-directory \
  --directory curriculum/ontario-elementary/source-locks
```

CI currently permits an empty source-lock directory because Ontario Elementary remains C0 overall. Once the first lock is deliberately promoted, that source may be described as C1 **only for exact-byte capture and digest evidence**.

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
