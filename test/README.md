# Test Suites

This directory is the fast regression suite.

Run with:
- `raco test test`

Composition:
- Primary balanced-ternary tests:
  - `bt_rel_test.rkt`
- Legacy baseline tests:
  - `binary_numbers_test.rkt`
  - `bn_harness_primitive_test.rkt`
  - `bn_harness_ops_test.rkt`
  - `support/bn_harness.rkt` (test-only harness utilities)

Purpose:
- Quick correctness checks for core behavior.
- Bounded inverse-mode checks for finite search in regression runs.
- Moderate randomized coverage for arithmetic properties.
- Binary harness checks that compare host naturals against miniKanren binary relations.

Binary harness defaults:
- Prefix limits: `k=5`, `k2=10`.
- Timeout budget per query: `120ms`.
- Deterministic exhaustive ranges: naturals in `0..31`.
- Randomized sweeps: naturals in `0..300`.

Binary harness classification policy:
- Spurious observed answers fail immediately.
- Missing expected answers by `k2` emit warnings.
- Timeouts on bounded finite checks emit warnings.
- Warnings are printed per-case to keep regressions informative without failing on incompleteness.

Bounded-query policy:
- Any query shape with potentially infinite solutions must be explicitly bounded in regression tests.
- Divergence assertions and timeout behavior belong in `assurance/`.

Partial-term policy:
- Harness coverage includes whole-number vars and bounded tail vars (for example, `(1 . x)` shapes).
- Internal-hole forms are deferred until needed.

Normative semantics and mode expectations are defined in `docs/SPEC.md`.
