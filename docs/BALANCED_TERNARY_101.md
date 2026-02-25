# Balanced Ternary 101 (for relational programmers)

This note is for people who already know miniKanren-style relational programming and need to read/write balanced-ternary terms directly.

## 1) Representation at a glance

- Numerals are LSD-first lists.
- Digits are trits: `T`, `0`, `1` where `T` means `-1`.
- Zero is the empty list: `()`.
- Canonical form:
  - `()` is canonical zero.
  - non-zero numerals must not end with `0` (no trailing most-significant zero).

Examples:

- `1` -> `(1)`
- `2` -> `(T 1)` because `-1 + 3 = 2`
- `3` -> `(0 1)`
- `4` -> `(1 1)`
- `-1` -> `(T)`
- `-2` -> `(1 T)`
- `-3` -> `(0 T)`
- `-4` -> `(T T)`

## 2) Why bounds are list lengths (not host ints)

The core bounded predicate is `bto-boundedo` in `/Users/jhemann/Code/mk-balanced-ternary/src/bt_rel.rkt`.

- A bound is a ground list token, e.g. `(k k k)`.
- If bound length is `L`, then allowed values are exactly:
  - `|n| <= (3^L - 1) / 2`
- So:
  - `L=2` gives `[-4,4]`
  - `L=3` gives `[-13,13]`

This is the BT analogue of binary digit-length bounds.

## 3) Reading raw query output

A bounded domain query:

```racket
(run* (q) (bto-boundedo q '(k k)))
```

returns raw BT terms:

```racket
'(() (T) (1) (T T) (T 1) (0 T) (1 T) (0 1) (1 1))
```

To decode to integers in tests/harness:

```racket
(require (file "/Users/jhemann/Code/mk-balanced-ternary/test/support/bt_harness.rkt"))
(remove-duplicates (map decode-bt-tuple raw) equal?)
```

Decoded result (same query):

```racket
'((0) (-1) (1) (-4) (2) (-3) (-2) (3) (4))
```

## 4) Answer normalization in harness checks

Core ground arithmetic queries are expected to be deterministic. Example:

```racket
(run* (q)
  (fresh (qq rr)
    (divo '(1 1) '(0 1) qq rr '(k k k))
    (== q (list qq rr))))
;; => '(((1) (1)))
```

The harness still normalizes answers with `remove-duplicates` defensively for larger open-mode queries.

## 5) Euclidean division semantics

`divo n m q r bound` (in `/Users/jhemann/Code/mk-balanced-ternary/src/bt_rel.rkt`) uses:

- `m != 0`
- `n = m*q + r`
- `0 <= r < |m|`

This is the chosen division convention for BT work in this repo.

Current surface note:
- Primary relation name is `divo`.
- `divo-boundedo` is kept as a compatibility alias while older call sites are phased out.

Current fast-suite coverage for division:
- `test/bt_order_div_test.rkt`: denotational Euclidean checks and deterministic ground cases.
- `test/bt_div_mode_matrix_test.rkt`: bounded grounding-mode matrix.
- `test/bt_div_exhaustive_mode_test.rkt`: bounded exhaustive `run*` mode checks with host-denotation equality.
- `test/bt_finite_failure_test.rkt`: bounded finite-failure mode matrix.
- `test/bt_signed_valence_test.rkt`: cross-sign regression cases.

## 6) Practical query templates

Bounded solve for addends:

```racket
(run* (q)
  (fresh (x y)
    (bto-boundedo x '(k k))
    (bto-boundedo y '(k k))
    (pluso x y '(1))
    (== q (list x y))))
```

Bounded solve for factor pairs:

```racket
(run* (q)
  (fresh (x y)
    (bto-boundedo x '(k k k))
    (bto-boundedo y '(k k k))
    (*o x y '(0 1 1)) ; 12
    (== q (list x y))))
```

## 7) What to remember when inspecting outputs

- Lists are LSD-first.
- `T` is `-1`, not a type marker.
- Canonicality matters: terms ending in MS `0` are non-canonical unless `()`.
- Bounded runs are the intended mode for completeness/failure claims.
- Harness comparisons normalize answer sets before denotational checks.
