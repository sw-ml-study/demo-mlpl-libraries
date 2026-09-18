# demo-mlpl-libraries

A demonstration and proving ground for reusable libraries written in MLPL and
consumed by MLPL applications in other repositories. The first integration
target is `../demo-extensions`, whose camera, geometry, and application helpers
already show why domain-neutral MLPL modules should be shareable rather than
copied. The same structure should support familiar general-purpose library
roles: argument parsing, result/error pipelines, filesystem helpers, data
transforms, and MLX/CUDA adapter facades.

Today the supported mechanism is static source composition:

```mlpl
include "vendor/swml/result.mlpl"
```

`include` is sandboxed beneath the application's `--source-dir`, is expanded in
source order, ignores duplicate loads, and rejects cycles. Consequently the
initial demo uses explicit vendoring or a reproducible checkout/copy step; it
does not claim that MLPL already has a package registry, dependency solver, or
isolated module namespaces. Those gaps and the criteria for requesting minimal
upstream work are covered in [the implementation plan](docs/plan.md).
The versioned producer manifest, prefix, dependency, capability, and consumer
provenance rules are defined in the [library contract](docs/library-contract.md).

## Intended repository shape

- `lib/`: documented, domain-neutral `.mlpl` library modules.
- `tests/`: native mlplunit contract and behavior tests.
- `examples/`: small local consumers.
- `integration/`: fixtures/scripts proving consumption from another repo.
- `catalog/`: machine-readable module, compatibility, and ownership metadata.
- `docs/`: architecture, consumer guidance, evidence, and upstream contracts.

## Development process

Work is divided into durable Agentrail saga steps. In each fresh session run
`agentrail next`, then `agentrail begin`; implement only that step; run focused
tests and the pre-commit gate; commit code and `.agentrail/` metadata; and only
then run `agentrail complete`. `AGENTS.md` contains the full protocol and
`CLAUDE.md` links to it so agents share one instruction source.

Every tracked `.mlpl` file must begin with a module-purpose comment, every
user-defined function must have a first-expression docstring, and canonical
formatting is mandatory. Before every commit and push, run:

```sh
scripts/check-mlpl-style
just check
```

These commands will be introduced by the foundation saga before executable
library code lands.

## Available libraries

- [`result` 0.1.0](docs/result.md): small pure helpers for validation,
  contextual errors, error-payload mapping, and deterministic pairing.
- [`native3d` 0.1.0](docs/native3d.md): orbit camera, picking, validated bulk
  lines/grids, headless transitions, and optional Port-backed lifecycle.
- [`text` 0.1.0](docs/text.md): total, character-indexed trim, affix and
  substring tests, bounded replace, padding, line splitting, and ASCII
  character classes over the core string builtins.
- [`jsonl` 0.1.0](docs/jsonl.md): budgeted JSON Lines reader with one-based
  line diagnostics, a bounded preview, and on-demand record access.
- [`safetensors-header` 0.1.0](docs/safetensors-header.md): exact header
  length decode, two bounded reads, budgeted JSON validation, sorted tensor
  discovery, and validated dtype, shape, and offset records.
- [`checkpoint` 0.1.0](docs/checkpoint.md): per-tensor MLPB checkpoint
  directories with atomic writes, a JSON index, and a size and Adler-32
  manifest verified before decoding.

The Native3D extraction is governed by the frozen
[Native3D migration contract](docs/native3d-migration.md), and the
safetensors header reader by the frozen
[safetensors header migration contract](docs/safetensors-header-migration.md),
which keeps tensor decoding and cataloging in `../demo-ml-utils`. The libraries
requested by `../reasoning-from-scratch` are being published in the
`requested-libraries` saga; changes this work needs in sibling repositories
are recorded in `docs/<repo>-requests.md` files rather than applied there.

Each library has a committed consumer fixture under `integration/`: the
vendored sources, the generated `swml.lock.toml` pinned to a full revision,
and a small application that runs only against `vendor/swml/`. The
pre-commit gate re-verifies every lock and runs every fixture, so the
repository proves consumption on each commit. The answers to the requesting
repository, with the exact revision to pin, are in
[docs/requests-response.md](docs/requests-response.md).

Install a library from an immutable commit into another MLPL repository, then
verify its committed lock and file hashes:

```sh
just install result /path/to/consumer COMMIT_SHA
just verify-install result /path/to/consumer
```

An existing lock is never replaced implicitly; pass `--upgrade` directly to
`scripts/install-library` after reviewing the selected revision.

## License

MIT. See [LICENSE](LICENSE) and [COPYRIGHT](COPYRIGHT).
