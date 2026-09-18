# Requests to `../demo-extensions` (Rust extensions)

Work orders for capabilities that need native code or throughput the
interpreter cannot reach. Each is consumed by MLPL libraries and
applications through `load_extension`, with every value crossing the
boundary as arrays, records, strings, packed bytes, or opaque handles.
Nothing here authorizes a change from this repository; the extension agent
revalidates each order before its own saga begins, and this repository
never edits `../demo-extensions`.

Status as of 2026-09-18: E1 is requested and unblocked. Nothing blocks a
published library; the `checkpoint` library ships with an MLPL Adler-32
fallback until E1 exists.

## E1. SHA-256 digest extension (`digest`)

Requested by: `checkpoint` 0.1.0, whose manifest is specified as a size
and hash manifest but currently records Adler-32, because the interpreter
selected here has no `sha256` builtin and no bit operations, so SHA-256
cannot be written in MLPL at usable speed. Every future verifier in this
family (downloaded weights and datasets, vendored library files, exported
reports) needs the same primitive.

Home: a Rust extension. Under the feature-homes rule a digest is a pure
function over bytes with no autograd or device role, and a mainstream ML
stack ships hashing as a separate package, so it belongs in
`../demo-extensions`, not in `../sw-mlpl` core. `docs/sw-mlpl-requests.md`
S6 records the decision and asks core for nothing.

Requested public surface (private namespace `_digest`, public facade
`digest`):

- `digest:sha256(bytes) -> ok(hex) | err`: SHA-256 of a rank-1 array whose
  cells are integers `0..=255`, returned as 64 lowercase hexadecimal
  characters. A rank other than 1, a non-integer cell, or a value outside
  the byte range is an `err` naming the offending index, never a panic.
  An empty array yields the digest of no bytes
  (`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`).
- `digest:sha256_text(text) -> ok(hex)`: SHA-256 of the UTF-8 encoding of
  a string, identical to `digest:sha256(tokenize_bytes(text))`.
- `digest:sha256_file(path, offset, length) -> ok(record) | err`: stream
  the byte range `[offset, offset + length)` of a file beneath the granted
  sandbox root in bounded chunks and return `{hex, bytes}` where `bytes` is
  the number of bytes actually digested (clamped at end of file, as the
  three-argument `read_bytes` clamps). The file never enters an
  interpreter array, so a multi-gigabyte member costs O(chunk) memory.
  Negative or non-integer `offset` or `length`, a missing file, and a path
  outside the sandbox are `err` results with the same wording the core
  `read_bytes` uses (`outside the sandbox`, `No such file or directory`).
- `digest:sha256_verify(path, expected_hex) -> ok(1) | ok(0) | err`:
  convenience over `sha256_file` for the whole file, comparing
  case-insensitively, so a consumer can check a manifest entry in one
  call.
- `digest:info() -> record`: `{algorithms: ["sha256"], chunk_bytes,
  version}` so a library can probe the surface before declaring a
  capability.

Budgets and behavior:

- `sha256_file` must honor an optional fourth argument `opts` with
  `max_bytes` (default: no limit beyond the sandbox) and refuse before
  reading when `length` exceeds it, so callers can bound wall-clock time
  the same way the MLPL libraries bound memory.
- Throughput target: at least 200 MB/s on the reference machine for
  `sha256_file`, and `sha256` over a 10 MB array in under 250 ms including
  the array-to-bytes conversion, so a checkpoint manifest costs less than
  the `to_native` encode it protects.
- Deterministic, allocation-bounded, and thread-free: no background work,
  no handles to free.

Capability identifier: once shipped, this repository adds
`extension.digest.v1` to the accepted table in `docs/library-contract.md`,
and `checkpoint` 0.2.0 declares it, writing a `sha256` field beside the
existing `adler32` field in `manifest.json` and verifying whichever fields
are present. Consumers on 0.1.0 manifests keep working.

Acceptance:

1. The FIPS 180-4 test vectors: the empty message, `"abc"`
   (`ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`),
   the 448-bit and 896-bit messages, and the one-million-`a` message,
   through `sha256`, `sha256_text`, and `sha256_file` on fixture files.
2. `sha256_file` on every fixture under
   `../demo-mlpl-libraries/tests/fixtures/safetensors/` matches the
   SHA-256 table in
   `../demo-mlpl-libraries/docs/safetensors-header-migration.md`, and a
   ranged call over a fixture equals `sha256(read_bytes(path, offset,
   length))` for offsets at 0, inside, at, and past the end of the file.
3. Malformed arrays, bad ranges, missing files, and sandbox escapes are
   `err` results with stable messages, never panics; a fuzz pass over
   random byte arrays agrees with the `sha2` crate.
4. A native mlplunit test in `demo-extensions` loads the extension and
   runs the vectors, and the `demo-mlpl-libraries` consumer test for
   `checkpoint` 0.2.0 verifies a manifest with both fields.

Blocker: none. The `sha2` crate is the reference implementation; no new
boundary type is needed.

## Not requested

- Anything for the `text`, `jsonl`, or `safetensors-header` libraries:
  they are complete over core builtins and bounded file reads.
- Weaker or faster checksums (CRC32, xxHash): Adler-32 in MLPL already
  covers corruption detection; only a cryptographic digest is missing.
