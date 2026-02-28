# mk-balanced-ternary

Balanced-ternary integer arithmetic relations for miniKanren, with bounded mode
testing and assurance suites. The active track is pure relational arithmetic
over integers (`'T '0 '1`, LSD-first), plus example programs that use it.

## Status

Implemented and test-backed:
- Core BT arithmetic: `trito`, `add3o`, `nego`, `pluso`, `minuso`, `mul1o`, `*o`.
- Euclidean division surface: `divo n m q r`.
- Oracle conversions for tests: `bt->int`, `int->bt`.
- Example relational abstract interpreter over interval states.

## Quickstart

Prerequisites:
- Racket
- `faster-minikanren` package installed for `#lang racket` + `minikanren`

Run fast regression tests:

```sh
raco test test
```

Run slower assurance tests:

```sh
raco test assurance
```

Try the playground in DrRacket / REPL:

```racket
(require (file "examples/bt_playground.rkt"))
```

## Project map

- `src/` - core relation implementation and host oracle modules.
- `test/` - fast regression suites (BT arithmetic + example tests).
- `assurance/` - slower exhaustive/randomized/operational checks.
- `examples/` - runnable usage examples (playground + abstract interpreter).
- `docs/` - specification, directives, planning docs, and related-work links.

Directory-level ownership docs:
- `src/README.md`
- `test/README.md`
- `assurance/README.md`
- `examples/README.md`
- `docs/README.md`

## Normative vs explanatory docs

SPOT policy:
- Entry and navigation: this `README.md`.
- Normative semantics and acceptance contract: `docs/SPEC.md`.
- Planning and strategy docs may summarize behavior, but `docs/SPEC.md` wins on conflicts.

## Public release prep

If you are preparing to publish this repository, use:
- `docs/PUBLIC_RELEASE_CHECKLIST.md`
