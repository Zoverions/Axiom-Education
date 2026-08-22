# MTH1W source licensing reviews

This directory is reserved for human source/licensing review records that conform to `schemas/source-license-review.v1.schema.json` and remain bound to the current source-use inventory.

## Machine inventory first

```bash
python tools/mth1w_source_use_inventory.py inventory \
  --output /tmp/mth1w-source-use-inventory.json
```

The inventory derives every declared external source from the current nine authored units. It binds each source to:

- URL;
- title and publisher;
- every unit that declares the source;
- the exact current unit-content digest;
- the stated use in that unit;
- a deterministic `source_use_sha256`.

It also fails if an HTTPS locator appears anywhere in authored unit content without being registered in that unit's `source_notes`.

## Human review evidence

A review record must identify the current source URL and exact `source_use_sha256`, reviewer identity and qualification, review date, decision, evidence locators, findings, and scope limitations.

Allowed decisions are deliberately explicit:

- `permitted-as-used`;
- `permission-required`;
- `replace-source`;
- `restricted`;
- `unresolved`.

Only `permitted-as-used` may set `redistribution_allowed_as_used: true`, and it requires at least one evidence locator and no open finding. Other decisions must keep redistribution false.

If an authored unit or its declared source use changes, its content-addressed source-use digest changes and the earlier review becomes stale.

## Verify submitted reviews

```bash
python tools/mth1w_source_use_inventory.py verify
```

A public webpage, government source, museum page, scholarly article, or open educational resource is **not** automatically treated as redistributable merely because it can be accessed online.

At present this mechanism is a review framework, not completed licensing evidence. The MTH1W licensing/redistribution promotion gate remains blocked until the actual shipped uses are reviewed and resolved.
