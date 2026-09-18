# Safetensors header reader

Version `0.1.0`; public prefix `u:sth_`; capabilities `core.include.v1` and
`fs.read-bounded.v1` (`file_size`, three-argument `read_bytes`,
`decode_bytes`). The frozen API, error kinds, and provenance are in
[the migration contract](safetensors-header-migration.md); this page is the
consumer view.

```mlpl
include "lib/safetensors-header/header.mlpl";

header = u:sth_inspect("models/tiny.safetensors", {max_header_bytes: 1048576})?;
index = 0;
while lt(index, header.tensor_count) {
  tensor = u:sth_tensor(header, unwrap(list_get(header.names, index)))?;
  print(tensor.name, tensor.dtype, tensor.shape, tensor.start, tensor.end);
  index = index + 1
}
```

A safetensors file is an eight-byte little-endian length, that many bytes
of JSON, then tensor data. The reader touches the file with `file_size` and
exactly two bounded reads, so memory is proportional to `max_header_bytes`
and never to the tensors. It validates the header completely and tells a
consumer where every tensor lives; it never decodes tensor bytes.

## Functions

- `u:sth_inspect(path, opts)`: read, parse, and layout-check in one call.
  Returns `ok(header)` or `err({kind, cause, path, name})`.
- `u:sth_read_header(path, opts)`: the bounded read only, returning
  `ok({file_size, header_length, header_bytes, data_bytes, path})`.
- `u:sth_parse_header(raw, opts)`: validate a raw record from
  `read_header` or one built by the caller from bytes obtained another
  bounded way (`path` optional).
- `u:sth_check_layout(header)`: offset-sorted ranges must cover the data
  buffer exactly, without overlap or holes.
- `u:sth_tensor(header, name)`: `ok({name, dtype, shape, data_offsets,
  start, end, parameters, width})` or `sth-missing`.
- `u:sth_decode_length(prefix, max_header_bytes)`,
  `u:sth_dtype_width(dtype)`, `u:sth_shape_product(shape, max_parameters)`,
  `u:sth_validate_metadata(metadata)`, and
  `u:sth_validate_tensor(name, entry, data_bytes, max_parameters)`: the
  building blocks, public so consumers can validate pieces in memory.

The header record carries `names` (sorted, `__metadata__` excluded),
`tensor_count`, `parameter_count`, `tensor_bytes`, `data_bytes`,
`metadata`, `metadata_present`, a `[tensor_count, 4]` `table` of
`start, end, parameters, width` rows in `names` order, the parsed
`entries`, and the resolved `budgets`.

## Options and errors

| Field | Default |
|---|---|
| `max_header_bytes` | 1048576 |
| `max_depth` | 8 |
| `max_elements` | 65536 |
| `max_parameters` | 9007199254740991 |

Error kinds are `sth-read`, `sth-prefix`, `sth-length`, `sth-truncated`,
`sth-json`, `sth-metadata`, `sth-tensor`, `sth-layout`, and `sth-missing`;
the contract defines each. Tensor errors carry the tensor `name`.

## Fixtures

`tests/fixtures/safetensors/` holds twenty files copied byte-for-byte from
`../demo-ml-utils` at commit `e6d285d1`; `tests/test-safetensors-contract`
verifies their SHA-256 digests against the contract table. They assume a
4096-byte header budget, so tests pass `{max_header_bytes: 4096}` where the
budget matters.

## Limitations

- Supported dtypes are the byte-aligned set; sub-byte dtypes are rejected.
- The header is decoded whole, so `max_header_bytes` bounds both the read
  and the JSON parse. Real model headers are usually well under 1 MiB.
- Name discovery builds a JSON array text by string concatenation, which
  is quadratic in total name length; that is bounded by the header budget.
- Tensor bytes, catalog aggregates, slicing, statistics, and GGUF
  conversion remain in `../demo-ml-utils`.
