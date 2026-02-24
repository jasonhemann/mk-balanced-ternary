# Test Suites

This directory is the fast regression suite.

Run with:
- `raco test test`

Composition:
- Primary balanced-ternary tests:
  - `bt_rel_test.rkt`
- Legacy baseline tests:
  - `binary_numbers_test.rkt`

Purpose:
- Quick correctness checks for core behavior.
- Bounded inverse-mode checks for finite search in regression runs.
- Moderate randomized coverage for arithmetic properties.

Bounded-query policy:
- Any query shape with potentially infinite solutions must be explicitly bounded in regression tests.
- Divergence assertions and timeout behavior belong in `assurance/`.

Normative semantics and mode expectations are defined in `docs/SPEC.md`.
