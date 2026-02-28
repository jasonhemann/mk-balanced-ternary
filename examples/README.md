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
  - Uses `minikanren/matche` for clearer branch structure in `aevalo`/`execo`.
- `bt_absint_surface.rkt`
  - Surface-language lowering helpers (`surface->expr`, `surface->stmt`) that
    parse Racket-like syntax into the abstract-interpreter core AST.
  - Surface statement forms use `if-negative?` / `while-negative?` to map
    directly to core `if-neg` / `while-neg`.
  - Repeats the core/surface grammar near the parser for local readability.
  - Includes a capstone test program (factorial-style countdown) in its
    `module+ test` block to exercise nested arithmetic and loops end-to-end.

Testing policy:
- Example behavior is regression-tested from `test/examples/` so examples stay
  executable and do not silently drift.
- Core arithmetic semantics remain specified in `docs/SPEC.md`.
