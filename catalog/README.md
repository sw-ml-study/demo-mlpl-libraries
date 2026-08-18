# Library catalog

`libraries.toml` is the machine-readable index of released entry modules. Its
normative contract is [documented here](../docs/library-contract.md) and checked
by `scripts/validate-catalog`.

Each `[[libraries]]` entry declares `name`, SemVer `version`, `.mlpl` `entry`,
owned `u:` `prefix`, `documentation`, SPDX `license`, `source_files`,
`capabilities`, and `dependencies`. The catalog describes producer intent; a
consumer lock records an exact revision and content hashes.
