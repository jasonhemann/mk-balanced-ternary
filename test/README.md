# Test Suites

This directory is the fast regression suite.

Run with:
- `raco test test`

Composition:
- Primary balanced-ternary tests:
  - `bt_rel_test.rkt`
    - includes canonical-surface regression checks for `pluso`/`minuso` zero-alias behavior
  - `bt_boundary_relations_test.rkt`
    - boundary/domain relation checks for `canco`, `canco-shapeo`, `digit-stepo`, and explicit trito-ablation demonstrations
  - `bt_symbolic_denotation_test.rkt`
    - bounded denotational checks that symbolic open-mode answers partition expected host sets (`pluso`/`minuso` identity surfaces and representative `*o` identity/zero surfaces)
  - `bt_bn_parity_test.rkt`
    - side-by-side parity checks for counterintuitive open-mode symbolic answers, confirming BT behavior matches the legacy binary suite
  - `bt_bn_prl_add_sub_parity_test.rkt`
    - side-by-side parity checks for arith.prl/paper add/sub showcase cases (including finite-failure vs integer-extension differences)
  - `bt_additive_laws_test.rkt`
    - commutativity/associativity/cancellation/inverse checks for additive relations (exhaustive bounded + randomized stress)
  - `bt_mul_laws_test.rkt`
    - commutativity/associativity/distributivity/identity checks for multiplication (exhaustive bounded + randomized stress)
  - `bt_mul_partial_modes_test.rkt`
    - bounded partial-tail mode checks for `*o` (single-tail, two-tail, inverse-tail, and finite-failure cases)
  - `bt_harness_primitive_test.rkt`
  - `bt_harness_ops_test.rkt`
  - `bt_mode_bounds_test.rkt` (bounded mode/groundedness matrix through `*o`)
  - `bt_signed_valence_test.rkt` (explicit negative/positive crossing cases for `pluso`, `minuso`, `*o`, and Euclidean `divo`)
  - `bt_finite_failure_test.rkt` (bounded finite-failure matrix for `pluso`, `minuso`, `*o`, and `divo`)
  - `bt_totality_test.rkt` (bounded completeness/totality checks, including all factor pairs for 12)
  - `bt_order_div_test.rkt` (bounded ordering checks + deterministic Euclidean `divo` checks)
  - `bt_div_mode_matrix_test.rkt` (bounded Euclidean `divo` representative mode matrix)
  - `bt_div_exhaustive_mode_test.rkt` (bounded Euclidean `divo` representative run* checks; full sweep is in assurance)
  - `bt_div_alias_mode_regression_test.rkt` (finite alias-mode guardrails for `divo`)
  - `support/bt_harness.rkt` (test-only BT harness utilities)
- Example regression tests:
  - `examples/bt_absint_rel_test.rkt`
    - validates the relational abstract-interpretation example modules in
      `examples/bt_absint_rel.rkt` and `examples/bt_absint_surface.rkt`,
      including surface-syntax parsing and big-step execution behavior
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
- Expected-divergence assertions are intentionally in `assurance/`, not fast regression.

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

BT harness note:
- Partially instantiated BT answers are expected in open modes.
- `check-bt-case` interprets symbolic answers denotationally over the bounded
  expected set (mK-style), instead of requiring concrete decode for every answer.
- Current symbolic denotation fallback is implemented for BT-integer tuple
  expectations and reified disequality constraints.

Bounded-query policy:
- Any query shape with potentially infinite solutions must be explicitly bounded in regression tests.
- Divergence assertions and timeout behavior belong in `assurance/`.
- Randomized `/o` coverage belongs in `assurance/` to avoid non-deterministic timeout warnings in the fast suite.
- As BT harness coverage expands, move warning-prone or high-latency cases to `assurance/` after measurement.
- BT `divo` coverage is active in fast regression; `divo` itself has no bound parameter, and representative run* checks still use explicit `bto-boundedo` domains in the test goals.

Fast-suite operational contract:
- Correctness checks: bounded semantic agreement with host arithmetic.
- Bounded termination checks: finite bounded queries must close within configured budgets.
- Non-overlap checks: bounded enumerations must have no duplicate raw or decoded answers.
- Expected-divergence checks are tracked separately in `assurance/`.

Partial-term policy:
- Harness coverage includes whole-number vars and bounded tail vars (for example, `(1 . x)` shapes).
- Internal-hole forms are deferred until needed.

Normative semantics and mode expectations are defined in `docs/SPEC.md`.
