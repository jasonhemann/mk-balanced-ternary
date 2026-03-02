# Divo Constructive Audit

This note is explanatory (not normative). Normative requirements remain in
`docs/SPEC.md`.

## Executive summary

- `divo` is implemented as a constructive long-division relation over balanced
  ternary integers, with a nonnegative natural core and a signed translation
  shell.
- The natural core is the recurrence `n = d + 3*n'`, with local correction from
  `t = d + 3*r'` to `(q, r)`.
- Euclidean remainder policy is enforced as `0 <= r < |m|`.
- The public surface is fixed arity: `(divo n m q r)`. Bound handling is
  internal.
- Unbounded shared-variable alias classes are intentionally classified as
  expected divergence; bounded/ground obligations are tested as required-finite.

## Constructive equation story

### 1) Public relation shape

`divo n m q r`:

1. derives an internal structural bound from `n` and `m`,
2. runs bounded signed Euclidean division,
3. constrains quotient length under that same bound.

This keeps the public API 4-ary while retaining internal operational control.

### 2) Natural core (nonnegative, positive divisor)

`divo-nat-boundedo n m q r bound` describes:

- base A (`n < m`): `q = 0`, `r = n`
- base B (`m = 1`): `q = n`, `r = 0`
- step (`n >= m`): write `n = d + 3*n'`, recurse on `n'`, then correct with
  `div-correcto` using `t = d + 3*r'`

with postconditions:

- `q >= 0`
- `r >= 0`
- `r < m`

### 3) Local correction

`div-correcto t m qrest q r bound` chooses one local quotient update:

- `k = -1`: `q = 3*qrest - 1`, `r = t + m` when `t < 0`
- `k = 0`: `q = 3*qrest`, `r = t` when `0 <= t < m`
- `k = 1`: `q = 3*qrest + 1`, `r = t - m` when `m <= t < 2m`
- `k = 2`: `q = 3*qrest + 2`, `r = t - 2m` when `2m <= t < 3m`

### 4) Signed lifting

`divo-boundedo` is a translation shell:

- divide by `m > 0` directly for `n >= 0`
- for `n < 0`, divide `|n|` then convert exact/inexact cases to Euclidean form
- for `m < 0`, divide by `|m|` and flip quotient sign accordingly

This separates sign handling from the natural long-division recurrence.

## Productivity / termination contract

Required to close:

- ground deterministic cases (`gggg`)
- bounded finite-domain inverse/mode-matrix checks in fast and assurance suites

Expected divergence:

- open shared-variable alias classes (for example `(*o q q q)` and selected open
  `divo` alias forms), unless explicitly bounded

This matches the repo policy: per-relation finite obligations under bounded or
grounded scenarios, not unbounded closure for all shared-variable conjunctions.

## Why this is less compact than binary naturals

Compared with the classic binary-naturals arithmetic:

- balanced ternary has 3 digits (`T/0/1`) and larger local branch tables,
- integers require sign translation around the natural core,
- Euclidean remainder policy across signs adds exact/inexact adjustment branches,
- bounded operational controls are explicit for required finite-mode behavior.

So the code is larger, but it is buying integer semantics plus tested bounded
productivity obligations.

## Abstraction policy (current phase)

- Keep `divo` control flow first-order and explicit while productivity tuning is
  active.
- Do not use higher-order relation patterns (relation arguments/returns,
  specialization flags).
- Extract helpers only for truly identical duplicated conjunctions when branch
  order and pruning behavior are preserved.

## Recent cleanup in this pass

- Removed dead helper relation `mqo-boundo` from `src/bt_rel.rkt`.
- Removed unused `factor1o` relation from `src/bt_rel.rkt`.
- Simplified one signed branch by removing a redundant `r` alias variable.
- Reordered one top-level `divo-boundedo` conjunct (`nonzeroo m`) before
  canonical/bounded checks to prune the `m = 0` branch earlier.

## Quick audit checklist for future edits

1. Every `divo` clause maps to one equation-level case.
2. Cheap pruning constraints stay before expensive recursive/disjunctive work.
3. No disequality in arithmetic or abstract-interpretation cores.
4. Fast suite remains green (`raco test test`).
5. Division assurance classification remains accurate (finite vs divergence).
