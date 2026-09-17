# JSON Lines reader

Version `0.1.0`; public prefix `u:jsonl_`; capabilities `core.include.v1` and
`fs.read-bounded.v1` (`file_size`, three-argument `read_bytes`,
`decode_bytes`, `tokenize_bytes`).

```mlpl
include "lib/jsonl/jsonl.mlpl";

problems = u:jsonl_read("data/problems.jsonl", {max_bytes: 4194304})?;
index = 0;
while lt(index, u:jsonl_count(problems)) {
  record = u:jsonl_get(problems, index)?;
  print(record.problem);
  index = index + 1
}
```

`parse_json` rejects a JSON array of objects by design, so a dataset is one
JSON object per line. This library reads that shape under explicit budgets
and reports every failure with its one-based line number.

## Record sets

MLPL has string lists and numeric arrays but no list of records, so the
reader returns a record set rather than a list. A record set is
`{count, line_numbers, lines, budgets, path}`: `count` validated records,
the one-based source line of each record in `line_numbers`, the raw lines,
and the budgets used. Records are parsed on demand:

- `u:jsonl_count(records)`: number of validated records.
- `u:jsonl_get(records, index)`: `ok(record)` for a zero-based index, or an
  `err` of kind `jsonl-index`. The line was validated during the read, so
  the parse cannot fail under the same budgets.
- `u:jsonl_line_number(records, index)`: `ok(line)` for diagnostics.

## Readers

- `u:jsonl_parse(text, opts)`: validate every line of `text`.
- `u:jsonl_read(path, opts)`: check `file_size` against `max_bytes`, read
  the file with bounded `read_bytes`, reject invalid UTF-8 exactly, then
  validate every line.
- `u:jsonl_take_first(path, n, opts)`: same read, but validation stops
  after `n` records; later lines are never parsed, so a malformed tail does
  not block a preview.

Every reader returns `ok(record set)` or `err({kind, line, cause, path})`
with `line` set to `0` for file-level failures:

| `kind` | Meaning |
|---|---|
| `jsonl-read` | the host refused the path (missing, unreadable, or outside the sandbox) |
| `jsonl-budget` | the file exceeds `max_bytes`; nothing was read |
| `jsonl-encoding` | the bytes are not valid UTF-8 |
| `jsonl-parse` | `parse_json` rejected the line, or it is not a JSON object |
| `jsonl-blank` | a blank line under the `error` policy |
| `jsonl-index` | a record index outside `0..count` |

## Options

All fields of `opts` are optional; pass `{}` for the defaults.

| Field | Default | Effect |
|---|---|---|
| `max_bytes` | 16777216 | file size limit checked before reading |
| `max_line_bytes` | 65536 | `parse_json` `max_bytes` per line |
| `max_depth` | 32 | `parse_json` nesting limit per line |
| `max_elements` | 4096 | `parse_json` collection limit per line |
| `blank_lines` | `"skip"` | `"skip"` ignores empty or whitespace-only lines; `"error"` rejects them |

Lines end with LF or CRLF; one final terminator is dropped; empty input is a
record set with `count` zero.

## Limitations

- Files are read whole after the size check, so `max_bytes` also bounds
  memory. There is no streaming reader.
- With blank lines present, `line_numbers` grows by array concatenation,
  which is quadratic in the interpreter (about a quarter second for
  twenty thousand records). Files without blank lines take a linear path.
- Records are re-parsed on every `u:jsonl_get`; cache the result in the
  caller when a record is used repeatedly.
- Invalid UTF-8 is rejected rather than replaced, because `decode_bytes`
  substitutes U+FFFD silently.
