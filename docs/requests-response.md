# Response to `../reasoning-from-scratch/docs/demo-mlpl-libraries-requests.md`

Status: answered 2026-09-18 by saga `requested-libraries`. Every library
below is cataloged at revision
`f3244ac79b3b2cd4ed43657d450bdcba0905fc5b` of this repository, installable
with `scripts/install-library --install --library <name> --dest <consumer>
--revision f3244ac79b3b2cd4ed43657d450bdcba0905fc5b`, and proven by a
committed consumer fixture under `integration/<name>-consumer/` that the
pre-commit gate runs from its lock alone. Later revisions add nothing to
these libraries unless `catalog/libraries.toml` says so.

All four libraries declare `dependencies = []` and include no other
library, because the installer does not yet perform transitive
installation. Each carries the few private helpers it needs under its own
prefix. Vendoring `result` remains your decision and is unaffected.

## L1. Text helpers: published as `text` 0.1.0

| Field | Value |
|---|---|
| name | `text` |
| version | `0.1.0` |
| prefix | `u:text_` |
| entry | `lib/text/text.mlpl` |
| capabilities | `core.include.v1` |
| documentation | `docs/text.md` |

Provides `is_empty`, `trim`, `trim_left`, `trim_right`, `starts_with`,
`ends_with`, `contains`, bounded `replace_all`, `pad_left`, `pad_right`,
`split_lines` (LF and CRLF), and `is_digit`, `is_letter`, `is_whitespace`.

Against the acceptance you stated: behavior is character-indexed like the
builtins and verified on Unicode input; every function is total on empty
input and empty needles; the retirement probe test fails the moment core
ships `str_replace`, `str_trim`, `str_starts_with`, or `str_contains`,
mirroring your `probes/str-helpers.mlpl`. One deviation: the character
classes are ASCII only, because the interpreter exposes no code-point
access (our request S2 upstream). Your scanners over math text are ASCII
by construction, so this should not bind; say so if it does.

## L2. JSONL reader: published as `jsonl` 0.1.0

| Field | Value |
|---|---|
| name | `jsonl` |
| version | `0.1.0` |
| prefix | `u:jsonl_` |
| entry | `lib/jsonl/jsonl.mlpl` |
| capabilities | `core.include.v1`, `fs.read-bounded.v1` |
| documentation | `docs/jsonl.md` |

`u:jsonl_read(path, opts)` splits LF and CRLF lines, parses each with
`parse_json` under `max_line_bytes`, `max_depth`, and `max_elements`,
checks `file_size` against `max_bytes` before reading, rejects invalid
UTF-8 exactly, and reports failures as `err({kind, line, cause, path})`
with one-based line numbers. `u:jsonl_take_first(path, n, opts)` validates
only the first `n` records.

One shape difference from your request: the result is not a list of
records, because MLPL has no such value. It is a record set with
`u:jsonl_count` and `u:jsonl_get(records, index)`, which parses the
already-validated line on demand; `u:jsonl_line_number` gives the source
line for diagnostics. This is request S5 upstream. Your
`lib/eval/data.mlpl` loop becomes `while lt(i, u:jsonl_count(r)) { record
= u:jsonl_get(r, i)?; ... }`.

## L3. Bounded safetensors header reader: published as `safetensors-header` 0.1.0

| Field | Value |
|---|---|
| name | `safetensors-header` |
| version | `0.1.0` |
| prefix | `u:sth_` |
| entry | `lib/safetensors-header/header.mlpl` |
| capabilities | `core.include.v1`, `fs.read-bounded.v1` |
| documentation | `docs/safetensors-header.md`, contract `docs/safetensors-header-migration.md` |

Promoted from `../demo-ml-utils` at its commit `e6d285d1` under a frozen
migration contract, with that repository's twenty fixtures copied and
digest-pinned. `u:sth_inspect(path, opts)` does `file_size` plus exactly
two bounded reads, decodes the length exactly, validates the JSON under
budgets, discovers tensors in sorted order, validates every dtype, shape,
and offset pair, and checks that ranges cover the data buffer;
`u:sth_tensor(header, name)` returns `{start, end, parameters, width,
dtype, shape}` so your Saga 3 step 1 can issue its own bounded reads.
Memory is O(`max_header_bytes`), independent of model size. Decoding and
cataloging stay in `demo-ml-utils`, which is asked separately to adopt this
library (`docs/demo-ml-utils-requests.md`).

## L4. Per-tensor `MLPB` checkpoint helpers: published as `checkpoint` 0.1.0

| Field | Value |
|---|---|
| name | `checkpoint` |
| version | `0.1.0` |
| prefix | `u:ckpt_` |
| entry | `lib/checkpoint/checkpoint.mlpl` |
| capabilities | `core.include.v1`, `fs.read-bounded.v1`, `fs.write-atomic.v1` |
| documentation | `docs/checkpoint.md` |

`u:ckpt_save(dir, record, opts)` writes one `to_native` file per array
field with `write_atomic`, then `manifest.json` with byte sizes and
checksums, then `index.json` last; `u:ckpt_verify` checks sizes and
checksums without decoding; `u:ckpt_load` returns the exact record;
`u:ckpt_open` plus `u:ckpt_get` decode one member at a time. Your
`native-roundtrip-10mb` probe was the evidence for the primitive.

Two deviations to weigh for your Saga 5 step 2. The manifest checksum is a
standard Adler-32, not SHA-256, because this interpreter has no hashing
builtin and no bit operations; it detects corruption and truncation but
not tampering. A Rust `digest` extension is requested from
`../demo-extensions` (`docs/demo-extensions-requests.md` E1), after which
`checkpoint` 0.2.0 will add a `sha256` field beside `adler32` without
breaking 0.1.0 manifests. And there is no directory listing or file
removal builtin, so files present but unlisted are ignored and a re-save
with fewer members leaves stale files behind.

## L5. Bounded arithmetic expression evaluator: not published

Your document says it is math-verifier-specific until a second numeric
equivalence consumer exists, and we agree. No library is reserved for it;
if it is ever promoted, the prefix `u:expr_` is free.

## Not requested, and still not built

No tokenizer and nothing on the autograd tape.

## Host gaps found while building these

Recorded, never applied, in `docs/sw-mlpl-requests.md` (S1 native string
helpers, S2 code-point access, S3 string-list append, S4 an interpreter
panic on `range(0) + 1`, S5 a list-of-records type, S6 the SHA-256 home
decision, S7 directory listing and file removal) and
`docs/demo-extensions-requests.md` (E1 the SHA-256 digest extension). S4
is the one to know about: adding a scalar to an empty array aborts the
process, so guard empty arrays before element-wise arithmetic.
