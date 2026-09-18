# Checkpoint directories

Version `0.1.0`; public prefix `u:ckpt_`; capabilities `core.include.v1`,
`fs.read-bounded.v1`, and `fs.write-atomic.v1` (`make_dir` and
`write_atomic` with sandbox refusal as `err`).

```mlpl
include "lib/checkpoint/checkpoint.mlpl";

params = {w1: randn(1, [64, 32]), b1: zeros([32])};
u:ckpt_save("runs/step-100", params, {})?;
restored = u:ckpt_load("runs/step-100", {})?;
```

A checkpoint is a directory. Each array field of the saved record becomes
one `<name>.mlpb` file written by `to_native` and `write_atomic`, then
`manifest.json` records every member's byte size and Adler-32 checksum, and
`index.json` is written last with the format tag, version, count, and the
sorted member list. Every write is atomic, and the index is the last file
to land, so a crash mid-save leaves either the previous complete
checkpoint or a directory without a valid index, never a torn one.

## Functions

- `u:ckpt_save(dir, record, opts)`: validate names and values, create
  `dir`, write members, manifest, then index. Returns
  `ok({dir, count, members, bytes})`.
- `u:ckpt_verify(dir, opts)`: cross-check index against manifest, then
  check every member's size and checksum without decoding.
- `u:ckpt_load(dir, opts)`: verify and decode every member and return
  `ok(record)` of arrays keyed by member name, exactly equal to what was
  saved, including shape and rank-0 values.
- `u:ckpt_open(dir, opts)` and `u:ckpt_get(checkpoint, name)`: read the
  control files once, then verify and decode one member at a time, so a
  large checkpoint never needs more than one tensor in memory.
- `u:ckpt_adler32(bytes)` and `u:ckpt_valid_name(name)`: public building
  blocks; the checksum matches the standard Adler-32 (`"abc"` is
  `024d0127`), so external tools can verify a manifest.

Member names are 1 to 128 characters of ASCII letters, digits, `_`, `-`,
and `.`, not starting with `.`. Values must be arrays; strings, records,
and Results are rejected before anything is written. Members are written
and listed in sorted name order.

## Options and errors

| Field | Default | Effect |
|---|---|---|
| `max_members` | 4096 | record fields on save, listed members on open |
| `max_index_bytes` | 65536 | size limit for `index.json` and `manifest.json` |
| `max_member_bytes` | 134217728 | limit for one member's encoded bytes |
| `max_total_bytes` | 1073741824 | limit for the sum of member bytes |

Errors are `err({kind, cause, path, member})`:

| `kind` | Meaning |
|---|---|
| `ckpt-input` | not a record, a non-array member, or an unsafe name |
| `ckpt-budget` | a member, index, or total budget was exceeded |
| `ckpt-encode` | `to_native` refused a value |
| `ckpt-write` | the host refused `make_dir` or `write_atomic` |
| `ckpt-read` | the host refused a read (missing directory, sandbox) |
| `ckpt-index` | `index.json` is malformed, foreign, or disagrees with the manifest |
| `ckpt-manifest` | `manifest.json` is malformed or an entry lacks `bytes`/`adler32` |
| `ckpt-missing` | a listed member has no file |
| `ckpt-size` | a member file's size differs from the manifest |
| `ckpt-checksum` | a member's bytes do not match the manifest checksum |
| `ckpt-decode` | `parse_native` failed or the member is not an array |

## Limitations

- The checksum is Adler-32, not SHA-256, because this interpreter build has
  no hashing builtin and no bit operations. Adler-32 detects corruption and
  truncation reliably but is not tamper-resistant. SHA-256 is requested as
  a Rust extension in `docs/demo-extensions-requests.md` E1; when it
  ships, `checkpoint` 0.2.0 will write a `sha256` field beside `adler32`
  and verify whichever fields a manifest carries.
- Files present in the directory but absent from the index are ignored,
  and a re-save with fewer members leaves the stale files in place, since
  there is no directory listing or file removal builtin (S7).
- `u:ckpt_load` assembles the result through a tagged JSON round trip,
  because records cannot be built with computed keys (S5). It is exact,
  costs about 0.2 s per million elements, and holds roughly three copies
  of the data transiently. Use `u:ckpt_open` and `u:ckpt_get` for
  checkpoints that would not fit that way.
