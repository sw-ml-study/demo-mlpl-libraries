# Requests to `../demo-extensions` (native extensions)

This repository never edits `../demo-extensions`. Native needs discovered
while publishing libraries are recorded here so that repository can decide
whether to build them; each entry names the library that hit the gap and
the MLPL fallback in use.

Status as of 2026-09-17: nothing blocks a published library.

## E1. A SHA-256 digest extension (fallback for core request S6)

- Found by: `checkpoint` 0.1.0 (see `docs/sw-mlpl-requests.md` S6).
- What: `sha256(bytes) -> hex string` over a rank-1 byte array, and
  ideally `sha256_file(path, offset, length)` so a multi-gigabyte member
  can be digested without loading it into an interpreter array.
- Why an extension: hashing is a pure function with no autograd or device
  role, so under the feature-homes rule it is core only if upstream wants
  it in the builtin set; otherwise it is an extension.
- Fallback in use: exact Adler-32 in MLPL, recorded under a separate
  manifest field so a `sha256` field can be added compatibly.
- Priority: medium, and only if `../sw-mlpl` declines S6.

## Not requested

- Anything for the `text`, `jsonl`, or `safetensors-header` libraries:
  they are complete over core builtins and bounded file reads.
