# Library catalog

`libraries.toml` is the machine-readable index of released entry modules. Each
entry must contain non-empty `name`, `version`, `entry`, `prefix`,
`documentation`, and `license` strings plus a `capabilities` array. Step 002
freezes the complete manifest and dependency contract before the first entry is
admitted.
