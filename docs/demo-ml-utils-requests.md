# Requests to `../demo-ml-utils`

This repository never edits `../demo-ml-utils`. Requests are recorded here
so that repository can act on them in its own sagas.

Status as of 2026-09-18: one request, now actionable. `safetensors-header`
0.1.0 is cataloged at revision
`f3244ac79b3b2cd4ed43657d450bdcba0905fc5b` with a committed consumer
fixture under `integration/safetensors-header-consumer/`.

## M1. Adopt the `safetensors-header` library by pinned revision

- What: vendor it with
  `scripts/install-library --install --library safetensors-header --dest
  ../demo-ml-utils --revision f3244ac79b3b2cd4ed43657d450bdcba0905fc5b`
  and replace the header-reading half of
  `src/formats/safetensors_header.mlpl` and the schema walk in
  `src/formats/safetensors_catalog.mlpl` with `u:sth_inspect` and
  `u:sth_tensor`.
- Why: `docs/safetensors-header-migration.md` freezes the API from your
  proven implementation at commit
  `e6d285d1f9903468441feb006cc4c5ad622b9133`. Keeping one copy of the
  exact-decode argument and the schema rules avoids drift between the
  teaching repository and its consumers.
- What stays with you: `catalog_safetensors` aggregates and
  `rows_by_name`, tensor slicing and decoding, statistics, checkpoint and
  GGUF conversion, and the 4096-byte teaching budget (pass
  `{max_header_bytes: 4096}` in `opts`).
- Fixtures: the twenty files under `fixtures/safetensors/` are copied here
  byte-for-byte and pinned by SHA-256. If your generator changes an
  existing fixture, please bump a note in its README so the contract can
  be reviewed; new fixtures need no coordination.
- Blocker for you: none until step 004 lands. Blocker for us: none.
