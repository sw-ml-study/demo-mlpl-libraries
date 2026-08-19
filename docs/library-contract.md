# MLPL library and provenance contract

Status: version 1, frozen for the vendored-source MVP.

## Module contract

A library is one public entry `.mlpl` file plus its transitively included source
files. Every source file is beneath `lib/`, starts with a module-purpose comment,
and gives every `def u:*` a first-expression docstring. The entry may include
private implementation files but consumers include only the declared entry.

Because current `include` performs source splicing into one global `u:`
namespace, each library exclusively owns a public prefix of the form `u:<name>_`.
All public functions and any included helpers use that prefix until upstream
ships isolated namespaces. A catalog may not assign the same name or prefix
twice. Prefix ownership is an API compatibility boundary.

## Catalog version 1

The root `schema_version = 1` is followed by zero or more `[[libraries]]`
tables. Every table has:

| Field | Contract |
|---|---|
| `name` | lowercase ASCII identifier `[a-z][a-z0-9-]*` |
| `version` | three-part SemVer, with optional prerelease/build suffix |
| `entry` | safe relative `lib/.../*.mlpl` path |
| `prefix` | exclusive `u:<identifier>_` prefix |
| `documentation` | safe relative `docs/.../*.md` path |
| `license` | SPDX expression identifier; initially `MIT` |
| `source_files` | non-empty array including `entry`, in install order |
| `capabilities` | sorted public host capability identifiers |
| `dependencies` | sorted `name@version-requirement` strings |

Paths must use `/`, contain no empty, `.` or `..` components, and must not be
absolute. Step 004 additionally checks canonical filesystem containment during
installation. Catalog arrays are literal strings in version 1; inline tables
and implicit dependency resolution are intentionally excluded.

Versions describe the MLPL-facing API: incompatible prefix/signature/value or
error changes increment major; compatible additions increment minor; internal
fixes increment patch. `0.y.z` may evolve faster but still requires explicit
consumer upgrades. Dependencies use an exact version or one leading constraint
operator (`=`, `^`, or `~`); the installer will reject rather than guess when it
cannot satisfy the declared set.

Capabilities are stable public host features, not executable probes embedded in
the manifest. Examples include `core.include.v1`, `fs.read-bounded.v1`,
`extension.port.v1`, `accelerator.mlx.v1`, and `accelerator.cuda.v1`. Tests own
the corresponding probes. An empty list means pure core language behavior.

## Consumer lock version 1

`swml.lock.toml` is generated, committed consumer state. It contains
`schema_version = 1`, producer `repository`, immutable 40-hex git `revision`,
and one `[[libraries]]` table per installed library with exact `name`, `version`,
`entry`, and `manifest_sha256`. Nested `[[libraries.files]]` tables record every
installed relative path and lowercase SHA-256 digest.

The lock is evidence, not authority: installation verifies the selected catalog,
revision, ordered file set, path containment, and hashes. Consumers never edit
hashes to make a check pass. Upgrades regenerate the complete library record and
are reviewed like source changes.

## Revision-pinned installation

`scripts/install-library --install --library NAME --dest CONSUMER --revision
COMMIT` resolves `COMMIT` to a full Git object ID, reads both the catalog and
declared source blobs with `git show`, and writes them beneath
`CONSUMER/vendor/swml/`. It therefore does not package uncommitted producer
files. The generated `CONSUMER/swml.lock.toml` records the repository, resolved
revision, catalog-entry hash, and installed file hashes.

`--check` hashes only the consumer's vendored files and requires no producer
source access. An existing lock makes installation fail closed; `--upgrade` is
required to replace it and repairs/relocks every declared file. The current MVP
rejects a dependency it cannot find with the exact dependency in its diagnostic,
and rejects even catalog-present dependencies until transactional transitive
installation is implemented. It never silently installs a partial graph.

## Known limitations

- Version 1 defines deterministic vendoring, not a network registry or solver.
- Prefix conventions reduce collisions but do not provide privacy.
- A git revision identifies source but says nothing about trust; signed releases
  and registry policy remain future distribution work.
- Interpreter/compiler parity is limited to upstream's current `include`
  contract. REPL/browser surfaces without a source provider cannot consume these
  modules directly.
