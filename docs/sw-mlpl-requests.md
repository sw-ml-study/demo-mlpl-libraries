# Requests to `../sw-mlpl` (core language and builtins)

This repository never edits `../sw-mlpl`. Gaps found while publishing
libraries are recorded here with the workaround in use, so upstream can
decide whether and when to ship them. Each entry names the library that hit
the gap and the test that would notice a change.

Status as of 2026-09-17: nothing blocks a published library. S4 is a
crash that libraries must guard against; the rest are conveniences or
retirement triggers.

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

## S4. Interpreter panic when broadcasting a scalar over an empty array

- Found by: `jsonl` 0.1.0 (`range(0) + 1` for an empty record set).
- Gap: `range(0) + 1` aborts the process with a Rust panic (`index out of
  bounds: the len is 0 but the index is 0` in
  `mlpl-array-ops-element/src/broadcast.rs`) instead of returning an empty
  array or an `err`. A panic cannot be caught by `try`, so a library
  cannot make the host total on its own.
- Workaround: `u:jsonl_numbers_upto` returns `[]` for a zero count before
  any arithmetic. Every library in this repository must guard empty arrays
  before element-wise operations until this is fixed.
- Priority: high. It is a crash reachable from valid data (an empty file).

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

## Not requested

- `chars(s)`: `str_split(s, "")` already yields the character list.
