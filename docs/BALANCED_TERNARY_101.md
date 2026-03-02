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

The core bounded predicate is `bto-boundedo` in `src/bt_rel.rkt`.

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
(require (file "test/support/bt_harness.rkt"))
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

Euclidean division is active via `divo`:

- relation shape: `(divo n m q r)`
- semantics: `n = m*q + r`, `m != 0`, `0 <= r < |m|`
- bounds are internalized in the relation implementation (no public bound argument)

Division-focused coverage is active in:
- `test/bt_order_div_test.rkt`
- `test/bt_div_mode_matrix_test.rkt`
- `test/bt_div_exhaustive_mode_test.rkt`
- `test/bt_signed_valence_test.rkt`
- `test/bt_finite_failure_test.rkt`

## 6) How to audit `divo` constructively

Executive summary:
- The relation is long-division style over LSD-first BT numerals, not a host
  arithmetic wrapper.
- Every recursive step peels one dividend trit and commits one quotient trit.
- Bounds are shape relations over numeral length, not host integers.

Equation-level audit view:
1. Core decomposition:
   - `n = d + 3*n'`
   - recurse with `n' = m*q' + r'`
2. Correction stage:
   - `t = d + 3*r'`
   - choose `k in {-1,0,1,2}` such that:
     - `q = 3*q' + k`
     - `r = t - k*m`
     - `0 <= r < m` (nonnegative core)
3. Signed wrapper:
   - reduce to positive-divisor core through `|n|` and/or `|m|`,
   - map quotient sign and Euclidean remainder back to original signs.

Size/bound audit view:
- Internal shape bound is derived from divisor/dividend structure:
  - `len(bound) = 1 + len(n) + len(m)`
- Public `divo` keeps arity 4 and internalizes this bound.
- Quotient length is constrained internally by that bound relation.

Operational classification audit view:
- Ground deterministic queries must close (fast suite).
- Bounded finite-domain mode checks must close (fast + assurance).
- Shared-variable alias classes are tracked as expected divergence in assurance
  (and selected fast regression guardrails), not as finite-failure obligations.

## 7) Practical query templates

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

## 8) What to remember when inspecting outputs

- Lists are LSD-first.
- `T` is `-1`, not a type marker.
- Canonicality matters: terms ending in MS `0` are non-canonical unless `()`.
- `pluso`/`minuso` are canonical-domain surfaces: non-canonical numeral inputs are out of domain, and zero-alias outputs like `(0)` should not appear.
- Bounded runs are the intended mode for completeness/failure claims.
- Harness comparisons are denotational for both concrete and symbolic answers (within bounded expected sets).
