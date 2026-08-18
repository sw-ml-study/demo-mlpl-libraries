# MLPL libraries demonstration plan

## Outcome

Prove that an MLPL application in a separate repository can consume a tested,
versioned, domain-neutral MLPL library without copying its implementation by
hand. `demo-extensions` is the first real consumer, but the conventions must
also fit argument parsing, structured error handling, filesystem helpers, data
preparation, and MLX/CUDA wrappers.

The deliverable is more than a collection of snippets: it is a reproducible
author-test-package-consume workflow, with compatibility metadata, executable
cross-repository evidence, and clear boundaries between ordinary MLPL modules,
native capabilities, and missing language/package functionality.

## Evidence and current constraints

- Upstream `sw-mlpl` documents `include "path.mlpl"` as top-level, static,
  source-order composition. Script and compiler paths expand includes beneath a
  sandboxed `--source-dir`; duplicate loads are ignored and cycles diagnosed.
- Included definitions currently share the global `u:` namespace. Prefixes such
  as `u:result_*`, `u:cli_*`, and `u:n3d_*` are therefore part of the public ABI,
  not cosmetic style.
- Native mlplunit provides `@test`, reflection, fixtures, and isolated script
  execution. Library behavior can be tested without inventing a shell-only
  harness.
- `demo-extensions/lib/native3d` already separates generic camera, geometry,
  and Port lifecycle helpers from cube, game, and Life semantics. It is the
  best initial extraction and external-consumer proof.
- MLX/CUDA modules must be MLPL facades over capability probes and generic
  upstream/native primitives. This repository must not duplicate backend
  kernels, own device memory unsafely, or encode application semantics.
- There is no demonstrated registry, dependency solver, version resolver,
  namespaced import, or remote fetch surface. The MVP must not imply otherwise.

## Design principles

1. One module has one responsibility and a documented prefix, inputs, outputs,
   effects, errors, and required host capabilities.
2. Pure MLPL is preferred. Effectful helpers wrap public sandboxed APIs; native
   helpers wrap versioned public extension/backend surfaces.
3. A module ships contract tests beside consumer integration tests. Examples
   are not substitutes for assertions.
4. Consumers choose dependencies explicitly. The first reproducible mechanism
   is a lock-described vendor/copy operation into the consumer source root;
   symlink-only success is not portable release evidence.
5. Compatibility is capability-based first and release-tag based second. A
   manifest records module version, exported prefixes, dependencies, and tested
   `sw-mlpl` revisions/capabilities.
6. General-purpose libraries contain no demo-specific policy. Applications own
   UI rules, scoring, dataset choice, model choice, and business semantics.

## Proposed layout

```text
lib/
  result/result.mlpl
  cli/args.mlpl
  fs/path.mlpl
  data/split.mlpl
  native3d/{camera,geometry,app}.mlpl
  accel/{capabilities,mlx,cuda}.mlpl
catalog/libraries.toml
tests/test_*.mlpl
examples/*.mlpl
integration/demo-extensions/
scripts/{check,check-mlpl-style,run-tests,install-library}
mlplunit.conf
justfile
```

Names are candidates, not promises. Each library is admitted only with a real
consumer need and a narrow contract. `result` and the native3d extraction give
one pure module and one capability-backed module before breadth is added.

## Consumer workflow to demonstrate

1. Select an immutable library revision (initially a git tag/commit).
2. Run a deterministic installer that copies declared source files and writes a
   lock record containing source revision and hashes beneath the application's
   source root, for example `vendor/swml/`.
3. Include the vendored entry module from application source. No absolute paths
   or implicit current-directory search are allowed.
4. Run the consumer's own mlplunit suite plus a provenance/hash check.
5. Upgrade explicitly, review source/API changes, regenerate the lock, and run
   both producer and consumer gates.

Development checkouts may optionally point at adjacent repositories for fast
iteration, but acceptance uses the copied artifact so CI and packaged source do
not depend on sibling directory layout.

## Saga 1: foundation and executable contract

1. Add the root `justfile`, tool selectors, `mlplunit.conf`, narrow `.gitignore`,
   canonical formatter/docstring gate, catalog schema, and repository checks.
2. Specify module manifests, prefix ownership, semantic versioning, dependency
   declarations, capability requirements, and lock/provenance format.
3. Build a minimal pure `result`/error-pipeline library test-first, with examples
   proving composition and stable failure values.
4. Build the deterministic vendor installer and a fixture consumer located
   outside the producer source tree; prove clean install, tamper detection,
   missing dependency diagnostics, and upgrade behavior.

Exit: `just check` passes from a clean checkout and a fixture app consumes a
pinned module copy without reading the producer tree at runtime.

## Saga 2: demo-extensions integration

1. Inventory `demo-extensions/lib/native3d` APIs, tests, upstream/native
   requirements, and application-specific coupling. Freeze a migration map.
2. Move or reimplement the generic camera, geometry, and app-lifecycle modules
   here under the `u:n3d_*` public prefix, preserving test coverage.
3. Install the library into an integration fixture matching the real
   `demo-extensions` layout and run its native mlplunit contracts without a
   window or GPU.
4. In a separately authorized consumer change, replace duplicated library files
   in `demo-extensions` with the pinned install workflow and run its full gate.

Exit: a committed consumer lock identifies the library revision; camera,
geometry, and lifecycle behavior is owned here; application semantics remain in
`demo-extensions`; producer and consumer gates pass.

## Saga 3: representative general-purpose libraries

Add only modules justified by executable applications, in this order:

- CLI argument normalization and validation over public `args()` behavior.
- Structured result/error combinators with context and recovery pipelines.
- Sandboxed filesystem/path helpers with explicit roots and bounded reads.
- Data split/normalization helpers useful to ML demos.
- MLX/CUDA capability selection and ergonomic facades, with deterministic CPU
  fallback tests where meaningful and explicit skip/unsupported results where
  not.

Each addition requires API docs, unit tests, at least one external-style fixture
consumer, catalog metadata, and negative capability/error tests. Native/GPU
integration tests are a separate gate from portable tests.

## Saga 4: distribution and upstream decision

Measure the vendored MVP against real consumers, then write
`docs/upstream-contract.md` for only the gaps that cannot be solved safely
downstream. Candidate upstream work includes namespaced imports, ordered search
paths, package manifests, and compiler/interpreter/REPL parity. Do not request a
registry until two or more consumers demonstrate the versioning and dependency
semantics it must preserve.

Evaluate distribution options—git subdirectory install, release archive with
checksums, or eventual registry—against offline reproducibility, sandboxing,
transitive dependency conflicts, supply-chain integrity, and compiled parity.

Exit: evidence supports either a stable vendoring workflow or a minimal,
testable upstream proposal; limitations are stated rather than hidden by local
checkout assumptions.

## Cross-cutting acceptance gates

- Canonical formatting for every tracked `.mlpl` file.
- Module-purpose comment and first-expression docstring for every user function.
- Native mlplunit tests for MLPL behavior; focused Rust tests for any installer
  or extension code; `just check` as the pre-commit umbrella.
- Tests for prefix collisions, include cycles/escapes, missing capabilities,
  malformed manifests, tampered sources, and deterministic diagnostics.
- Explicit file staging, tracked Agentrail state, narrow ignore rules, and
  documentation updated in the same step as behavior.
- No edits to sibling repositories unless a step and the user explicitly
  authorize that repository as a mutation target.
- Every step runs its focused checks and `just check`, commits with the checks
  and compatibility/limitation details in the message, pushes successfully,
  completes its Agentrail record, and reports status, next step, and blockers.

## Non-goals

- Building a network package registry in the first iteration.
- Treating source splicing as namespace isolation.
- Moving Rust crates or native kernels into this repository.
- Hiding host limitations behind shell environment tricks or absolute paths.
- Generalizing an API before a second credible consumer exists.
