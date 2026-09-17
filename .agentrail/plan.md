# Requested MLPL libraries plan

## Outcome

Publish the domain-neutral MLPL libraries that
`../reasoning-from-scratch/docs/demo-mlpl-libraries-requests.md` (status
2026-09-16) lists as concrete promotion candidates, in the order that
document expects them to become real: text helpers (L1), a JSONL reader
(L2), a bounded safetensors header reader promoted from `../demo-ml-utils`
(L3), and per-tensor `MLPB` checkpoint helpers (L4). Each library lands
under the frozen version-1 contract in `docs/library-contract.md`: one entry
file beneath `lib/`, an exclusive `u:<name>_` prefix, module comments and
docstrings, native mlplunit tests, a catalog entry, documentation, and
revision-pinned, hash-locked installation proven from a consumer fixture.

The deliverable is a set of libraries a consumer can vendor today by pinned
revision, plus written answers to the requesting repository: exact names,
versions, prefixes, capabilities, and the revision to pin.

## Evidence and current constraints

- The request document says no request is formally triggered yet; the
  promotion bar is unrelated consumers. This saga builds the candidates
  ahead of that bar so the requesting repository can vendor instead of
  re-deriving, and records the consumer evidence it does have.
- `include` splices sources into one global `u:` namespace, so prefixes are
  ABI. Each new library owns one prefix and includes no other library.
- The installer rejects catalog-present dependencies until transactional
  transitive installation exists. Every library in this saga therefore
  declares `dependencies = []` and carries any tiny private helper it needs
  under its own prefix rather than including `result` or `text`.
- Host surface available today (from sibling probes, read-only): character
  indexed `str_len`, `str_slice`, `str_find`, `str_concat`, `str_split`,
  `str_join`, `chars`; `parse_json` with budgets that rejects arrays of
  objects by design; bounded `read_bytes(path, offset, length)`,
  `file_size`, `decode_bytes`, `tokenize_bytes`, `read_text`, `write_text`,
  `write_bytes`, `write_atomic`, `make_dir`, `sha256`, `to_native`,
  `parse_native`. `str_replace`, `str_trim`, `str_starts_with`, and
  `str_contains` do not exist as builtins (`str-helpers` probe fails).
- `../demo-ml-utils` already proved the safetensors header idiom: eight
  byte little-endian length prefix, header budget, `file_size` check, two
  budgeted reads, JSON validation, and ten tiny fixtures. It stays the
  algorithmic owner of tensor decoding and cataloging.
- Sibling repositories (`../sw-mlpl`, `../demo-extensions`,
  `../demo-ml-utils`, `../reasoning-from-scratch`) are read-only evidence.
  Needed changes there are documented, never applied.

## Steps

1. `text-library` (production): `lib/text/text.mlpl`, prefix `u:text_`,
   pure core. Test-first: `is_empty`, `trim`, `trim_left`, `trim_right`,
   `starts_with`, `ends_with`, `contains`, bounded `replace_all`,
   `pad_left`, `pad_right`, `split_lines`, and character-class tests
   `is_digit`, `is_letter`, `is_whitespace`. Character-indexed Unicode
   behavior, total on empty input, and a retirement probe test that pins
   the absence of native `str_replace`/`str_trim`/`str_starts_with`/
   `str_contains` so the library can retire when core ships them.
2. `jsonl-library` (production): `lib/jsonl/jsonl.mlpl`, prefix
   `u:jsonl_`, capability `fs.read-bounded.v1`. `u:jsonl_parse(text,
   opts)` splits LF and CRLF lines, skips blank lines by policy, parses
   each with `parse_json` under caller budgets, and returns
   `ok(list of records)` or a structured `err` naming the one-based line
   number; `u:jsonl_read(path, opts)` adds a byte budget and `file_size`
   check; `u:jsonl_take_first(path, n, opts)` stops after `n` records
   without parsing the rest. Records that are not JSON objects are
   diagnosed by line.
3. `safetensors-contract` (validation): inventory the proven reader in
   `../demo-ml-utils` read-only (its probes, archived saga steps, tests,
   and fixtures), freeze `docs/safetensors-header-migration.md` with the
   exact `u:sth_*` API, budgets, error shapes, fixture provenance, and the
   boundary that decoding and cataloging remain in `demo-ml-utils`. Record
   the publish request to `demo-ml-utils` in
   `docs/demo-ml-utils-requests.md`. Guard the contract with a shell test
   like `tests/test-native3d-contract`.
4. `safetensors-library` (production): `lib/safetensors-header/`, prefix
   `u:sth_`, capability `fs.read-bounded.v1`, implemented against the
   frozen contract with vendored or regenerated tiny fixtures whose
   provenance is documented. Tests cover truncation, header budget excess,
   `file_size` mismatch, u64 maximum, 2^53 precision hazard, malformed and
   non-object JSON, missing files, and sandbox traversal.
5. `checkpoint-library` (production): `lib/checkpoint/`, prefix
   `u:ckpt_`, capabilities `fs.read-bounded.v1` plus a write capability
   identifier the step defines and documents in the contract. Save a
   record of named arrays as one `to_native` file per tensor beneath a
   directory with a JSON index and a size and `sha256` manifest, written
   atomically; load verifies sizes and hashes under budgets before
   `parse_native`, and diagnoses missing, extra, or tampered members.
6. `consumer-evidence` (validation): vendor every new library into an
   `integration/` consumer fixture at a pinned revision with the existing
   installer, run the vendored consumers under the test gate, update the
   README and catalog documentation, and write
   `docs/requests-response.md` answering the requesting repository item by
   item with names, versions, prefixes, capabilities, and the revision to
   pin. Consolidate any remaining host gaps into the per-repository
   request files.

## Cross-cutting acceptance gates

- Canonical formatting for every tracked `.mlpl` file, module-purpose
  comments, and first-expression docstrings; `just check` before every
  commit and push.
- Native mlplunit tests for all MLPL behavior, including capability
  negative and budget-exceeded paths, and deterministic diagnostics.
- Catalog entries validated by `scripts/validate-catalog`; documentation in
  `docs/<library>.md` updated in the same step as behavior.
- Changes needed in sibling repositories are recorded, never applied:
  `docs/sw-mlpl-requests.md` for core language or builtin gaps,
  `docs/demo-extensions-requests.md` for native extension gaps, and
  `docs/demo-ml-utils-requests.md` for the safetensors publish request.
  These files replace `docs/upstream-contract.md` for those repositories.
- Explicit file staging, tracked Agentrail state committed with source, and
  the branch pushed before `agentrail complete`.

## Non-goals

- L5, the bounded arithmetic expression evaluator: the request document
  says it is math-verifier-specific and likely stays in
  `../reasoning-from-scratch` until a second numeric-equivalence consumer
  exists.
- A tokenizer or anything on the autograd tape (explicitly not requested).
- Transitive dependency installation, a registry, or namespace isolation.
- Vendoring `result` into the requesting repository: that is consumer-side
  work owned there.
- Deferred, not abandoned, from the archived `mlpl-library-consumption`
  saga: the `demo-extensions` adoption handoff and the distribution
  decision. They return as their own saga when authorized.
