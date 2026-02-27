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

Open-mode queries may return symbolic answers with a constraint store:

```racket
(run 5 (q) (pluso '() q q))
;; => '(() (_.0 . _.1))
```

and with explicit reified disequalities:

```racket
(run 5 (q) (canco-shapeo q))
;; => '(() ((_.0) (=/= ((_.0 0)))) ...)
```

Those are valid relational answers. They denote sets of BT numerals.

## 4) Answer normalization in harness checks

Core ground arithmetic queries are deterministic. Open-mode queries may be symbolic.

The BT harness compares answers denotationally over bounded expected sets:

```racket
(check-bt-case
 "symbolic/pluso/id"
 #:expected-set (lambda () (for/list ([n (in-range -4 5)]) (list n)))
 #:run-observed (lambda (limit) (run limit (q) (pluso '() q q))))
```

So partial answers are treated as first-class semantics (mK style), not rejected just because they are non-ground.

## 5) Division status (active)

Euclidean division is active via bounded `divo`:

- relation shape: `(divo n m q r bound)`
- semantics: `n = m*q + r`, `m != 0`, `0 <= r < |m|`
- boundedness: all four numerals are constrained by `bound` through `bto-boundedo`

Division-focused coverage is active in:
- `/Users/jhemann/Code/mk-balanced-ternary/test/bt_order_div_test.rkt`
- `/Users/jhemann/Code/mk-balanced-ternary/test/bt_div_mode_matrix_test.rkt`
- `/Users/jhemann/Code/mk-balanced-ternary/test/bt_div_exhaustive_mode_test.rkt`
- `/Users/jhemann/Code/mk-balanced-ternary/test/bt_signed_valence_test.rkt`
- `/Users/jhemann/Code/mk-balanced-ternary/test/bt_finite_failure_test.rkt`

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
- `pluso`/`minuso` are canonical-domain surfaces: non-canonical numeral inputs are out of domain, and zero-alias outputs like `(0)` should not appear.
- Bounded runs are the intended mode for completeness/failure claims.
- Harness comparisons are denotational for both concrete and symbolic answers (within bounded expected sets).
