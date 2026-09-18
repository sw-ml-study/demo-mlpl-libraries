# Requests to `../sw-mlpl` (core language and builtins)

This repository never edits `../sw-mlpl`. Gaps found while publishing
libraries are recorded here with the workaround in use, so upstream can
decide whether and when to ship them. Each entry names the library that hit
the gap and the test that would notice a change.

Status as of 2026-09-18, re-probed against the rebuilt interpreter at
`../sw-mlpl` commit `a5026255`: S4 is **resolved upstream**. Nothing blocks
a published library. S6 records a home decision (extension, not core); the
rest are conveniences or retirement triggers, and every builtin they name
is still absent, so each workaround in this file is still the one in use.

### Upstream identifier mapping

Upstream tracks its own findings as `RS<n>` in
`../sw-mlpl/docs/sw-mlpl-findings.md`. Only one overlaps this file:

| Upstream | Here | State |
|---|---|---|
| RS9 (no `str_replace`/`trim`/`starts_with`) | S1 | delivered as the `text` 0.1.0 library; core still ships none of the four |
| (unnumbered, our report) | S4 | fixed upstream in commit `1ce43dc2` |

Upstream routes RS7 (gradient clipping) and RS8 (weight decay) to this
repository as library work. Neither is a request to us yet:
`../reasoning-from-scratch/docs/demo-mlpl-libraries-requests.md` does not
list them, and that repository's `feature-homes.md` keeps both in its own
Saga 5 until unrelated consumers exist. They are recorded here so the
routing disagreement is visible, not acted on. If that repository asks for
either, it becomes a normal library request.

## S1. Native string helpers (`str_replace`, `str_trim`, `str_starts_with`, `str_contains`)

- Found by: `text` 0.1.0.
- Workaround: `u:text_replace_all`, `u:text_trim`, `u:text_starts_with`,
  `u:text_contains` over `str_find`, `str_slice`, and `str_len`.
- Retirement trigger: the `retirement probe` test in `tests/test_text.mlpl`
  fails as soon as any of the four names becomes a builtin, mirroring
  `../reasoning-from-scratch/probes/str-helpers.mlpl`.
- Priority: low. The library form is a few lines each and character exact.

## S2. Code-point access for a character

- Found by: `text` 0.1.0 character classes.
- Gap: no builtin returns the Unicode scalar value of a character (a
  `char_code`/`code_point` form). `tokenize_bytes` yields UTF-8 bytes, which
  is exact but forces a hand-written decoder for anything beyond ASCII.
- Workaround: `u:text_is_digit`, `u:text_is_letter`, and
  `u:text_is_whitespace` are documented as ASCII classes; non-ASCII input
  returns `0` rather than erring.
- Priority: low until a consumer needs Unicode letter classes.

## S3. Incremental string-list construction (`list_append`, `list_concat`)

- Found by: `text` 0.1.0 (`u:text_split_lines`), and expected by the JSONL
  reader and checkpoint index code in later steps.
- Gap: `concat` rejects string lists and no `list_append`/`list_concat`
  builtin exists (`docs/future-sagas-queue.md` upstream already lists it).
  A library can return only string lists that `str_split` produces, or must
  encode intermediate results as joined strings with a sentinel separator.
- Workaround: `u:text_split_lines` normalizes CRLF to LF and strips one
  trailing terminator before a single `str_split`.
- Priority: medium. This is the first gap likely to shape a library API
  (record-of-results instead of list-of-records) rather than merely its
  implementation.

## S4. Interpreter panic when broadcasting a scalar over an empty array (RESOLVED)

- Found by: `jsonl` 0.1.0 (`range(0) + 1` for an empty record set).
- Was: `range(0) + 1` aborted the process with a Rust panic (`index out of
  bounds: the len is 0 but the index is 0` in
  `mlpl-array-ops-element/src/broadcast.rs:98`) instead of returning an
  empty array. A panic cannot be caught by `try`, so no library could make
  the host total on its own.
- Fixed upstream in commit `1ce43dc2`. Re-probed here on 2026-09-18 against
  the rebuilt interpreter: `range(0) + 1` returns an empty array with
  `tally` zero, and the rank-2 form `reshape([], [0, 3]) + 1` is also
  total. Upstream reported the original write-up was sufficient to
  reproduce and root-cause it.
- The guard stays. `u:jsonl_numbers_upto` still returns `[]` for a zero
  count before any arithmetic, because a vendored library runs on whatever
  interpreter its consumer has, including builds older than this fix. The
  guard is three lines, costs nothing, and is the only thing that made the
  empty-file path safe on every build. New libraries need not add such
  guards for this operation.
- Priority: none. Closed.

## S5. A general list type, or records with computed keys

- Found by: `jsonl` 0.1.0. The requested `ok(list of records)` cannot be
  expressed: values are arrays, strings, string lists, records, and
  Results, and `parse_json` rejects arrays of objects by design.
- Workaround: readers return a record set (`{count, line_numbers, lines,
  budgets}`) and parse each record on demand through `u:jsonl_get`. The
  same shape will serve the safetensors header and checkpoint libraries.
- Priority: medium. A `list_map`/`list_of_records` form, or a builtin that
  builds a record from a key list and a value list, would let a library
  return fully parsed collections.

## S6. SHA-256: home decided, nothing requested from core

- Found by: `checkpoint` 0.1.0. The plan asked for a SHA-256 manifest;
  `sha256` appears in upstream docs but is not a builtin in the
  interpreter selected here (`unknown function: sha256`), and there are
  no bit operations to implement it in MLPL at usable speed.
- Decision (2026-09-18): the digest is a pure function over bytes with no
  autograd or device role, so under the feature-homes rule it is a Rust
  extension. The work order is `docs/demo-extensions-requests.md` E1
  (`digest:sha256`, `digest:sha256_text`, `digest:sha256_file`,
  `digest:sha256_verify`). Core is asked for nothing; if upstream ever
  ships a `sha256` builtin, the extension facade can alias it.
- Workaround until E1 ships: the manifest records a standard Adler-32
  computed exactly with vectorized `mod` and `reduce(:add, ...)` (about
  0.2 s per 10 MB), under a field named `adler32` so a `sha256` field can
  be added without breaking consumers. Adler-32 detects corruption but not
  tampering.
- Priority: none here; tracked as E1.

## S7. Directory listing and file removal (`list_dir`, `remove_file`)

- Found by: `checkpoint` 0.1.0.
- Gap: without `list_dir`, a member file that is present but unlisted
  cannot be reported, and without `remove_file` a re-save with fewer
  members cannot clean up stale files or a failed save cannot roll back.
- Workaround: the index is authoritative and stale files are documented as
  ignored; the index is written last so an interrupted save is detectable.
- Priority: low until a consumer needs garbage collection of checkpoints.

## Not requested

- `chars(s)`: `str_split(s, "")` already yields the character list.
