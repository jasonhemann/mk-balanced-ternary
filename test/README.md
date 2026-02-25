# Test Suites

This directory is the fast regression suite.

Run with:
- `raco test test`

Composition:
- Primary balanced-ternary tests:
  - `bt_rel_test.rkt`
  - `bt_harness_primitive_test.rkt`
  - `bt_harness_ops_test.rkt`
  - `bt_mode_bounds_test.rkt` (bounded mode/groundedness matrix through `*o`)
  - `bt_div_mode_matrix_test.rkt` (bounded Euclidean division mode matrix across grounding patterns)
  - `bt_signed_valence_test.rkt` (explicit negative/positive crossing cases for `pluso`, `minuso`, `*o`, `divo`)
  - `bt_finite_failure_test.rkt` (bounded finite-failure matrix for `pluso`, `minuso`, `*o`, `divo`)
  - `bt_totality_test.rkt` (bounded completeness/totality checks, including all factor pairs for 12)
  - `bt_order_div_test.rkt` (bounded ordering + Euclidean `divo` semantics)
  - `support/bt_harness.rkt` (test-only BT harness utilities)
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
- Keep the default loop warning-light; slower completeness/divergence checks are in `assurance/`.
- BT harness checks that compare `bt_rel` with `bt_oracle` using the same classification model as BN.
- Bounded BT mode-matrix checks ensure finite all-groundedness variants through multiplication under explicit digit-length bounds.
- The heaviest open-mode totality check (`*o` vvv) is intentionally in `assurance/`.

Binary harness defaults:
- Prefix limits: `k=5`, `k2=10`.
- Timeout budget per query: `120ms`.
- Deterministic exhaustive ranges: naturals in `0..31`.
- Randomized sweeps: naturals in `0..300`.
- Fast-suite call sites may override defaults (for example `k=1`, `k2=1`, `timeout=1000ms`) to keep runtime predictable.

Binary harness classification policy:
- Spurious observed answers fail immediately.
- Missing expected answers by `k2` emit warnings.
- Timeouts on bounded finite checks emit warnings.
- Warnings are printed per-case to keep regressions informative without failing on incompleteness.

Bounded-query policy:
- Any query shape with potentially infinite solutions must be explicitly bounded in regression tests.
- Divergence assertions and timeout behavior belong in `assurance/`.
- Randomized `/o` coverage belongs in `assurance/` to avoid non-deterministic timeout warnings in the fast suite.
- As BT harness coverage expands, move warning-prone or high-latency cases to `assurance/` after measurement.

Partial-term policy:
- Harness coverage includes whole-number vars and bounded tail vars (for example, `(1 . x)` shapes).
- Internal-hole forms are deferred until needed.

Normative semantics and mode expectations are defined in `docs/SPEC.md`.
