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
