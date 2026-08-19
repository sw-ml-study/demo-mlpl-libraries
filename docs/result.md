# Result helpers

Version `0.1.0`; public prefix `u:result_`; pure MLPL with no native capability.

```mlpl
include "lib/result/result.mlpl";

port = u:result_ensure(gt(config.port, 0), config.port, "port must be positive")?;
parsed = u:result_context("server configuration", ok(port))?;
```

The library complements rather than replaces the built-in `ok`, `err`, `?`,
`map_ok`, `and_then`, and `or_else` primitives:

- `u:result_ensure(condition, value, error_value)` converts a domain predicate
  to `Ok(value)` or `Err(error_value)`.
- `u:result_context(context, result)` preserves `Ok` and converts `Err(cause)`
  to `Err({kind: "context", context, cause})`.
- `u:result_map_error(transform, result)` maps only an error payload. The
  callable must accept one value and return the replacement payload.
- `u:result_zip(left, right)` returns `Ok({left, right})` when both succeed and
  otherwise returns the leftmost error, giving deterministic failure priority.

These helpers do not catch hard evaluator errors, mutate values, collect an
unbounded result sequence, or stringify arbitrary error payloads. In particular,
`result_context` and `result_map_error` require an actual Result and use
`err_message`; misuse remains a hard type/evaluation error, consistent with the
upstream Result builtins.
