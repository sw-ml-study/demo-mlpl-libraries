# Library catalog

`libraries.toml` is the machine-readable index of released entry modules. Its
normative contract is [documented here](../docs/library-contract.md) and checked
by `scripts/validate-catalog`.

Each `[[libraries]]` entry declares `name`, SemVer `version`, `.mlpl` `entry`,
owned `u:` `prefix`, `documentation`, SPDX `license`, `source_files`,
`capabilities`, and `dependencies`. The catalog describes producer intent; a
consumer lock records an exact revision and content hashes.

## Cataloged libraries

| Name | Version | Prefix | Capabilities | Documentation |
|---|---|---|---|---|
| `result` | 0.1.0 | `u:result_` | `core.include.v1` | [docs/result.md](../docs/result.md) |
| `native3d` | 0.1.0 | `u:n3d_` | `core.include.v1`, `extension.port.v1` | [docs/native3d.md](../docs/native3d.md) |
| `text` | 0.1.0 | `u:text_` | `core.include.v1` | [docs/text.md](../docs/text.md) |
| `jsonl` | 0.1.0 | `u:jsonl_` | `core.include.v1`, `fs.read-bounded.v1` | [docs/jsonl.md](../docs/jsonl.md) |
| `safetensors-header` | 0.1.0 | `u:sth_` | `core.include.v1`, `fs.read-bounded.v1` | [docs/safetensors-header.md](../docs/safetensors-header.md) |
| `checkpoint` | 0.1.0 | `u:ckpt_` | `core.include.v1`, `fs.read-bounded.v1`, `fs.write-atomic.v1` | [docs/checkpoint.md](../docs/checkpoint.md) |

Every library declares `dependencies = []`: the installer does not yet
perform transitive installation, so each library carries its own private
helpers under its prefix. Consumer evidence for each library lives under
`integration/<name>-consumer/` with a committed `swml.lock.toml`.
