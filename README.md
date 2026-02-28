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

## Try it in DrRacket / REPL

Playground queries:

```racket
(require (file "examples/bt_playground.rkt"))
```

Abstract interpretation example (surface syntax + big-step relation):

```racket
(require minikanren
         (file "examples/bt_absint_rel.rkt")
         (file "examples/bt_absint_surface.rkt"))

(define vars '(i acc chk))
(define stmt
  (surface->stmt
   vars
   '(begin
      (set! acc 1)
      (while-negative? i
        (begin
          (set! acc (+ (* acc (- 0 i)) 0))
          (set! i (+ i 1))))
      (set! chk (+ (* acc 1) (+ i 0))))))

(define B4 (build-list 4 (lambda (_) 'k)))
(run* (q)
  (execo stmt
         (build-state (list (cons -4 -4) (cons 0 0) (cons 0 0)))
         q
         B4
         (build-fuel 8)
         (make-top-state 3 B4)))
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

## Known limitations

- Unbounded shared-variable alias goals (for example `(*o q q q)` beyond early answers) are expected to diverge under pure-unification search.
- Finite closure/completeness claims are made for bounded modes covered by `test/` and `assurance/`.
