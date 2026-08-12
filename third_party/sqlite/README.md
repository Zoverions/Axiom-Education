# Vendored SQLite source

Axiom Education compiles SQLite from the official SQLite.org amalgamation instead of
fetching precompiled `package:sqlite3` release assets during native builds.

Pinned upstream release: **SQLite 3.53.4 (2026-07-24)**

- authority: SQLite.org
- archive: `https://www.sqlite.org/2026/sqlite-amalgamation-3530400.zip`
- archive SHA3-256: `628a44cfe82c66aed1ccbbe85a562d2e33ebe64b3288981ed76285612227934e`
- `sqlite3.c` SHA3-256: `67f423e9ebbbdc473cbc4772c872ee6b89f31fde4ed0279a5c25d5f65c043a16`
- SQLite source ID: `2026-07-24 19:02:57 bf7c7f30031888f4e796e429ab3978879485813aaca6f641c7b33e4e09459bcc`
- license: public domain

`pubspec.yaml` selects `package:sqlite3` build-hook `source: source` and points at
`third_party/sqlite/sqlite3.c`. The package's default SQLite compile-time options
remain enabled. The downloaded archive is not retained.

`python tools/vendored_sqlite.py verify` fails closed if the source, provenance, or
hook configuration drifts.
