# Safetensors header reader migration contract

Status: frozen extraction baseline, 2026-09-17; implemented by
`safetensors-header` 0.1.0 (step 004 added the optional `path` and
`budgets` fields and the caller-built record clause). Request L3 in
`../reasoning-from-scratch/docs/demo-mlpl-libraries-requests.md`.

## Evidence baseline

This inventory reads `../demo-ml-utils` at commit
`e6d285d1f9903468441feb006cc4c5ad622b9133` without modifying it. The proven
reader, its schema validation, the fixture generator, and the acceptance
scripts were:

| File | SHA-256 |
|---|---|
| `src/formats/safetensors_header.mlpl` | `885eb37b7848eec0342b8fcda2f8c9a6ca7b0e2d796f04b7d887f1e3315d7715` |
| `src/formats/safetensors_catalog.mlpl` | `1d2d9f2db4ee63aa99bc7a20265e478e4ca4ed77c2c0adb1dbc8782f8dc66774` |
| `scripts/generate-safetensors-fixtures` | `61c55e6ffd24156a7c7e9245b3ec97211da9ffcae6086a40eef40b3a8f272cb5` |
| `tests/safetensors-header-fixtures.mlpl` | `a0973b725201ad21c210107bdb60bd3aa68dfbe48c6aaa9f2f115909e04bba26` |
| `tests/safetensors-catalog.mlpl` | `65134a7efa974d41ac738d5fbe5e3723d6ed927283a9141f1fc92b66c7a02ea6` |

The archived `binary-format-foundations` saga there (steps
`003-safetensors-header-fixtures` and `004-bounded-io-reconciliation`) and
`probes/capabilities.mlpl` establish the host facts the reader relies on:
three-argument `read_bytes(path, offset, length)` clamps at end of file and
returns an empty array beyond it, `file_size` is a metadata read that never
loads the file, both reject sandbox traversal with `err`, and `parse_json`
rejects duplicate object keys and honors `max_depth`, `max_bytes`, and
`max_elements`.

The baseline is evidence, not a live synchronization mechanism. Later peer
changes require an explicit contract review rather than silently changing
this library.

## Migration map

| Source | Destination (`lib/safetensors-header/header.mlpl`) | Responsibility |
|---|---|---|
| `u:decode_safetensors_length_from`, `u:decode_safetensors_length` | `u:sth_decode_length(prefix, max_header_bytes)` | exact little-endian u64 decode that rejects before any inexact multiplication |
| `u:read_safetensors_header` | `u:sth_read_header(path, opts)` | `file_size`, eight-byte prefix read, budgeted length, truncation check, one bounded header read |
| `u:safetensors_dtype_bytes` | `u:sth_dtype_width(dtype)` | byte width of the byte-aligned dtype set |
| `u:safetensors_shape_product` | `u:sth_shape_product(shape, max_parameters)` | exact non-negative dimension product under a parameter budget |
| `u:safetensors_metadata_values` | `u:sth_validate_metadata(metadata)` | `__metadata__` must be a record of strings |
| `u:safetensors_tensor_row` | `u:sth_validate_tensor(name, entry, data_bytes, max_parameters)` | exactly `dtype`, `shape`, `data_offsets`; byte count agrees with the range |
| `u:safetensors_layout_rows` | `u:sth_check_layout(header)` | offset-sorted ranges cover the data buffer without overlap or holes |
| JSON decode and key walk inside `u:catalog_safetensors` | `u:sth_parse_header(raw, opts)` | budgeted `parse_json`, object root, sorted tensor-name discovery, per-tensor validation |
| none (new composition) | `u:sth_inspect(path, opts)` | `read_header`, then `parse_header`, then `check_layout` |
| none (new accessor) | `u:sth_tensor(header, name)` | validated record for one tensor name, or `sth-missing` |

`u:safetensors_header_length` and `u:safetensors_header_bytes` (whole-file
array variants) are not published: consumers read from a path, and the
array forms would invite loading tensor data into the interpreter.

Every published function starts with the `u:sth_` prefix; the entry is
`lib/safetensors-header/header.mlpl` with no other included file and no
dependencies. Changing a name, a field, an error kind, a budget default, or
the order of validation is an API change under `docs/library-contract.md`.

## Stable value contracts

`opts` is a record whose fields are all optional:

| Field | Default | Effect |
|---|---|---|
| `max_header_bytes` | 1048576 | budget for the declared header length; must be an exact integer from 2 through 2^53-1 |
| `max_depth` | 8 | `parse_json` nesting limit for the header |
| `max_elements` | 65536 | `parse_json` collection limit for the header |
| `max_parameters` | 9007199254740991 | exact budget for one tensor's element count and byte count |

`u:sth_read_header` returns `ok({file_size, header_length, header_bytes,
data_bytes, path})` where `data_bytes` is `file_size - 8 - header_length` and
`header_bytes` is the rank-1 byte array of the declared header. The file
is touched by `file_size` and exactly two budgeted reads (the eight-byte
prefix, then the declared header), so memory is O(`max_header_bytes`),
independent of tensor data.

`u:sth_parse_header` accepts any record with those fields, not only one
produced by `u:sth_read_header`; `path` is optional and defaults to `""`.
A consumer that fetched the prefix and header bytes another bounded way
(an HTTP range request, a test fixture built in memory) builds the record
itself and gets identical validation. The whole-file array slicers of the
proven reader are therefore unnecessary and are not published.

`u:sth_parse_header` and `u:sth_inspect` return
`ok({file_size, header_length, data_bytes, path, names, tensor_count,
parameter_count, tensor_bytes, metadata, metadata_present, table, entries,
budgets})`:

- `names`: the tensor names as a sorted string list, `__metadata__`
  excluded; discovery order comes from `record_keys` and is deterministic.
- `table`: a `[tensor_count, 4]` array of `start`, `end`, `parameters`,
  `width` rows in `names` order; `reshape([], [0, 4])` when empty.
- `metadata`: the `__metadata__` record, or `{}`; `metadata_present` is
  `1` or `0`.
- `entries`: the parsed JSON header record, so `u:sth_tensor(header, name)`
  can return `ok({name, dtype, shape, data_offsets, start, end, parameters,
  width})` without a second read.
- `budgets`: the resolved option record, so the accessor re-validates under
  the same `max_parameters`.

Validation order is fixed: host read errors, prefix length, header length
budget, truncation, short header read, JSON budgets and syntax, object
root, then keys in sorted order (metadata or tensor), then layout. The
first failure wins, so diagnostics are deterministic for a given file and
budget set.

Supported dtypes and widths: `F64`, `I64`, `U64` (8); `F32`, `I32`, `U32`
(4); `F16`, `BF16`, `I16`, `U16` (2); `I8`, `U8`, `BOOL` (1). Sub-byte and
unknown dtypes are `sth-tensor` errors; the library never interprets tensor
bytes.

### Error shape

Every function returns `err({kind, cause, path, name})`; `name` is `""`
unless the failure concerns one tensor.

| `kind` | Meaning |
|---|---|
| `sth-read` | the host refused `file_size` or `read_bytes` (missing, unreadable, or outside the sandbox) |
| `sth-prefix` | the file is shorter than the eight-byte prefix, or a prefix is not eight byte values |
| `sth-length` | a non-byte prefix value, a length over `max_header_bytes`, a length that would exceed 2^53-1, or an invalid budget |
| `sth-truncated` | the file ends inside the declared header, or the bounded read returned fewer bytes than declared |
| `sth-json` | `parse_json` rejected the header (syntax, duplicate key, or budget) or the root is not an object |
| `sth-metadata` | `__metadata__` is not a record of strings |
| `sth-tensor` | empty name, wrong field set, bad dtype, non-integer or negative dimension, parameter or byte budget, invalid or out-of-buffer offsets, or a size disagreement |
| `sth-layout` | ranges overlap, leave a hole, or do not cover the data buffer, or data exists with no tensors |
| `sth-missing` | `u:sth_tensor` was asked for a name that is not in `names` |

### The exactness argument

The eight-byte prefix is decoded least-significant byte first with the
running total `total + byte * multiplier`. Before each multiplication the
decoder checks `byte <= floor((max_header_bytes - total) / multiplier)`, so
no product can exceed the budget and every intermediate value stays an
exact integer below 2^53. A prefix encoding the u64 maximum, or any value
above the budget, is rejected before the arithmetic that would lose
precision. The same guard style applies to shape products and byte counts
under `max_parameters`.

## Fixture provenance

Step 004 copies these twenty files byte-for-byte from
`../demo-ml-utils/fixtures/safetensors/` at the baseline revision into
`tests/fixtures/safetensors/`, and a shell gate verifies the table below.
The files are produced by `scripts/generate-safetensors-fixtures` there;
step 004 may port that generator, but the hashes are the authority.

| Fixture | SHA-256 | Exercises |
|---|---|---|
| `valid-small.safetensors` | `e98776e444aeb7927b5636c9751cc41c3362c0d4ebe6a760b9f8a9caae7d0c70` | one four-byte `U8` tensor |
| `valid-empty.safetensors` | `411a485216e432ece6b9af94fa32154cf79a2a56d4f81266baa50063f45092bd` | `{}` header, no data |
| `valid-catalog.safetensors` | `274e45d97259c464fb4db4b87f4f81742112898378d64ae17a783f9ea456a1c6` | three tensors written out of order, metadata, mixed dtypes, one empty tensor |
| `valid-decode.safetensors` | `92b280700a2be00bb042b8a64374c128a897a9f30c3c53b5fada5d0b3c96126b` | `U8`, `I8`, `U16`, `I16` payloads |
| `boundary-header.safetensors` | `95ea57f4376eb9bbfa666a42818c403a0bb57cf12468515305b0edea664b1380` | exactly 4096 header bytes with space padding |
| `empty.safetensors` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | no prefix (`sth-prefix`) |
| `truncated-prefix.safetensors` | `097328e8c957de2428283954f6a1ee8ff7ad7def12e100a600178407f5decf24` | four prefix bytes (`sth-prefix`) |
| `truncated-header.safetensors` | `5ea1f76a38c0a344d7bc284a69e78b087260ebb4896c674d14d37b992cdc7fc4` | declares 16 header bytes, supplies two (`sth-truncated`) |
| `malformed-json.safetensors` | `11f80f245e576543b9df05c9bb080d912c19e37922762478c9f8822f155016af` | complete header with invalid JSON (`sth-json`) |
| `oversized-header.safetensors` | `4d68c1fe398b934ca2d101e777cadb0aa85b163139968983ffd01656b7082b05` | declares 4097 bytes against a 4096 budget (`sth-length`) |
| `overflow-length.safetensors` | `12a3ae445661ce5dee78d0650d33362dec29c4f82af05e7e57fb595bbbacf0ca` | u64 maximum prefix (`sth-length`) |
| `duplicate-name.safetensors` | `bcc038e7440ff402212c5045f8d48cf77bf3798e692118ec86c016a74b710037` | repeated tensor key (`sth-json`) |
| `unsupported-dtype.safetensors` | `352c0225e68abe07bbc1d0646a002bf5fbf0f16ee781c39dc56222ceabba945a` | `Q4` dtype (`sth-tensor`) |
| `invalid-shape.safetensors` | `30054bb1118fc54c0dc3a6609b5fb097f50d23645f346dc398bcf7ac67ed1b4e` | negative dimension (`sth-tensor`) |
| `overlapping-offsets.safetensors` | `38d4a19bb47771948251561bd667aef5ce4527750092c57ab1ea9b96f55990d1` | overlapping ranges (`sth-layout`) |
| `hole-offsets.safetensors` | `b7eb60634ee295593ae1fc7387c4c7fc4014beae881b34ac9d8a07d53c9f0f00` | unindexed hole (`sth-layout`) |
| `out-of-bounds.safetensors` | `7951687570d52d9b4895e08eb4a4a6553171d43dc21f196e01685e8db2348548` | range past the data buffer (`sth-tensor`) |
| `size-mismatch.safetensors` | `f449f1adc47468fe64029452052428fea3a2abcb6466baac49923010d5584e5e` | shape and dtype disagree with the range (`sth-tensor`) |
| `invalid-metadata.safetensors` | `0117b7cce624f380cfc5ab8c0ca2ca21bbcf8311e6644eca4d267ba17276c9a5` | non-string metadata value (`sth-metadata`) |
| `missing-shape.safetensors` | `b39f233e948807c9520a6b03c55059e016b0b809a7c44f5dbfbe981c23dc0723` | tensor entry without `shape` (`sth-tensor`) |

The fixtures assume the 4096-byte teaching budget of `demo-ml-utils`, so
tests pass `{max_header_bytes: 4096}` where the budget matters and add
in-memory prefix cases (`u:sth_decode_length` with `[0,16,0,0,0,0,0,0]`,
`[1,16,0,0,0,0,0,0]`, and `[0,0,0,0,0,0,32,0]`) for the boundary, one over,
and 2^53 rejections.

## Capability

The catalog entry declares `core.include.v1` and `fs.read-bounded.v1`. The
second names `file_size`, three-argument `read_bytes`, and `decode_bytes`
with sandbox refusal as `err`. Tests own the probes: a missing path and a
`../` path must produce `sth-read`, never a hard error.

## Ownership boundary

This library owns reading and validating the header: the prefix, the
budgeted length, the bounded header bytes, JSON decoding under budgets,
sorted tensor discovery, dtype widths, shape products, offset checks, and
layout coverage.

`demo-ml-utils` remains the algorithmic owner of everything that touches
tensor bytes or aggregates over them: `safetensors_catalog.mlpl` totals and
`rows_by_name`, `safetensors_slice.mlpl` bounded tensor reads and
decoding, `safetensors_statistics.mlpl`, checkpoint conversion, and GGUF
conversion. Those modules are expected to call `u:sth_inspect` and
`u:sth_tensor` after adoption, which is requested in
`docs/demo-ml-utils-requests.md` and never performed from here.

`reasoning-from-scratch` consumes the library in its Saga 3 to locate
tensors before its own bounded reads; it does not need the catalog totals.

## Acceptance migration

Step 004 must port, as native mlplunit tests over the copied fixtures:

1. The header fixture suite: valid, empty, and boundary headers with their
   `file_size` and `header_length` values; rejection of empty, truncated
   prefix, truncated header, oversized, and overflow files; the three
   in-memory prefix decodes.
2. The catalog rejections: duplicate name, unsupported dtype, invalid
   shape, overlapping, hole, out-of-bounds, size mismatch, invalid
   metadata, and missing shape, each asserting the error `kind` above.
3. `valid-catalog` discovery: `names` equal to `["tensor_a", "tensor_b",
   "tensor_c"]`, `metadata_present` 1, `tensor_count` 3,
   `parameter_count` 4, `tensor_bytes` 6, `data_bytes` 6, and the table
   rows `[0,2,2,1]`, `[2,6,2,2]`, `[6,6,0,4]`.
4. Host refusals: missing path and sandbox traversal as `sth-read`.
5. Budget behavior: `max_header_bytes` 4096 rejects `oversized-header`
   and accepts `boundary-header`; a `max_parameters` of 3 rejects
   `valid-small`; `max_elements` 1 rejects `valid-catalog` as `sth-json`.

Blocker: none. Every input is a committed fixture and every host call is a
documented bounded read.
