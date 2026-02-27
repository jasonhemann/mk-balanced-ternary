# Examples

This directory contains non-core modules that demonstrate how to use the
balanced-ternary arithmetic relations in larger relational programs.

Current examples:
- `bt_playground.rkt`
  - DrRacket/REPL playground helpers and sample queries for `pluso`, `*o`,
    and `divo`.
- `bt_absint_rel.rkt`
  - Big-step relational abstract interpreter over interval states using BT
    arithmetic (`aevalo`, `execo`, interval operations, and state helpers).
  - Includes grammar comments and surface-language parser helpers
    (`surface->expr`, `surface->stmt`) to lower Racket-like syntax into the
    core relational AST.
  - Uses `minikanren/matche` for clearer branch structure in `aevalo`/`execo`.

Testing policy:
- Example behavior is regression-tested from `test/examples/` so examples stay
  executable and do not silently drift.
- Core arithmetic semantics remain specified in `docs/SPEC.md`.
