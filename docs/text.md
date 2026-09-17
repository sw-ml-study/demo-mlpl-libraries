# Text helpers

Version `0.1.0`; public prefix `u:text_`; pure MLPL with no native capability.

```mlpl
include "lib/text/text.mlpl";

label = u:text_trim("  answer: 42 \r\n");
lines = u:text_split_lines(read_text("problems.txt")?);
if u:text_starts_with(label, "answer:") { ok(label) } else { err("no answer") }
```

The library fills the gap between the character-indexed core builtins
(`str_len`, `str_slice`, `str_find`, `str_concat`, `str_split`, `str_join`,
`str_eq`) and the helpers most text scanners reinvent. Every function is
total on empty input and empty needles: it returns a value, never a hard
error. All indexing counts Unicode scalar values, exactly like the builtins,
so `u:text_trim("  héllo  ")` is `"héllo"` and padding counts characters.

## Predicates (return `1` or `0`)

- `u:text_is_empty(text)`: `1` when `text` has no characters.
- `u:text_starts_with(text, prefix)`, `u:text_ends_with(text, suffix)`: an
  empty affix always matches; an affix longer than `text` never does.
- `u:text_contains(text, needle)`: substring test; an empty needle matches.
- `u:text_is_digit(text)`, `u:text_is_letter(text)`,
  `u:text_is_whitespace(text)`: `1` when `text` is non-empty and every
  character is in the ASCII class. Digits are `0`-`9`, letters are `A`-`Z`
  and `a`-`z`, whitespace is tab, LF, vertical tab, form feed, CR, and
  space. Pass one character for a scanner test or a run to validate it.
  Non-ASCII digits and letters (`"٣"`, `"é"`) are `0`; the interpreter
  exposes no code-point access yet (see `docs/sw-mlpl-requests.md`).

## Transforms

- `u:text_trim(text)`, `u:text_trim_left(text)`, `u:text_trim_right(text)`:
  remove ASCII whitespace at the chosen edges only.
- `u:text_replace_all(text, needle, replacement, max_replacements)`: replace
  at most `max_replacements` non-overlapping occurrences, left to right,
  without rescanning replaced text (`"xx"` with `x` to `xx` gives `"xxxx"`).
  An empty needle or a cap of `0` returns `text` unchanged. Pass
  `str_len(text)` as the cap for every occurrence.
- `u:text_pad_left(text, width, pad)`, `u:text_pad_right(text, width, pad)`:
  add the first character of `pad` until `text` has at least `width`
  characters. Wider text is never truncated; an empty `pad` returns `text`.
- `u:text_split_lines(text)`: string list of lines split on LF or CRLF.
  Exactly one final terminator is dropped, interior blank lines are kept,
  and empty text yields an empty list, matching `read_stdin_lines`.

## Retirement

`tests/test_text.mlpl` carries a retirement probe that fails the moment the
interpreter defines `str_replace`, `str_trim`, `str_starts_with`, or
`str_contains`. When that happens, the matching helpers should become thin
aliases or be removed in the next minor version, and consumers re-vendor by
pinned revision. The probe mirrors
`../reasoning-from-scratch/probes/str-helpers.mlpl`.

## Limitations

- Character classes are ASCII only.
- `u:text_replace_all` and the trims are linear in the text for each
  occurrence, which is adequate for configuration and dataset lines but not
  for multi-megabyte documents.
- Building a string list incrementally is not possible in MLPL today, so the
  library returns only lists that `str_split` can produce.
