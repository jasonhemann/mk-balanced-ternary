# Slow Assurance Suite

This directory contains deeper confidence checks that are slower than the default regression suite.

Run with:
- `raco test assurance/slow_assurance_test.rkt`
- `raco test assurance/bn_harness_divergence_test.rkt`
- `raco test assurance/bt_harness_assurance_test.rkt`
- `raco test assurance/bt_totality_assurance_test.rkt`
- `raco test assurance/bt_finite_failure_exhaustive_assurance_test.rkt`
- `raco test assurance/bt_primitives_finite_failure_assurance_test.rkt`
- `raco test assurance/bt_additive_flow_exhaustive_assurance_test.rkt`
- `raco test assurance/bt_mul_flow_exhaustive_assurance_test.rkt`
- `raco test assurance/bt_mul_mode_profile_assurance_test.rkt`
- `raco test assurance/bt_symbolic_denotation_assurance_test.rkt`

Purpose:
- Heavy randomized property checks over wider ranges.
- Engine-based timeout assertions for known divergent query shapes.
- Sanity checks that finite queries still return within bounded time.
- Dedicated binary-harness assurance checks:
  - slower multi-answer and randomized `/o` checks,
  - explicit run* completion case (`/o` on `199/85`),
  - divergence timeout checks.
- The randomized `/o` sweep is seeded and range-limited to keep runtime stable while still exercising inverse division behavior.
- Dedicated BT-harness assurance checks:
  - seeded heavier randomized `pluso` and `*o` checks against `bt_oracle`.
- Dedicated BT totality assurance checks:
  - fully open `*o` vvv bounded-completeness check over len<=3.
- Dedicated BT finite-failure assurance checks:
  - exhaustive unsatisfiable mode instances for `pluso`/`minuso`/`*o` over len<=2,
  - multiple conjunction flow orderings per case,
  - each case must terminate and return empty.
- Dedicated BT primitive finite-failure checks:
  - exhaustive unsatisfiable mode instances for `add3o`, `mul1o`, and `nego`,
  - multiple conjunction flow orderings per case,
  - each case must terminate and return empty.
- Dedicated BT additive flow-completeness checks:
  - exhaustive satisfiable mode instances for `pluso` and `minuso` over len<=2,
  - multiple conjunction flow orderings per case,
  - each case must terminate and return the exact expected bounded set.
- Dedicated BT multiplicative flow-completeness checks:
  - exhaustive satisfiable mode instances for `*o` over len<=2,
  - representative satisfiable mode instances for `*o` over len<=3,
  - full flow-order coverage at len<=2; representative flow-order coverage at len<=3,
  - each case must terminate and return the exact expected bounded set.
  - representative finite-failure mode instances for `*o` over len<=3.
  - focused `bounds-rel-bind` smoke checks at len<=3.
- Dedicated BT multiplicative mode-profile checks:
  - per-query completion budgets for representative `*o` modes (`ggv`, `vgg`, `gvg`, `vvg`) at len<=3,
  - exact bounded answer-set comparison against host arithmetic,
  - designed to catch operational regressions early without involving `/o`.
- Dedicated BT symbolic denotation assurance checks:
  - open-mode symbolic partition checks for `pluso`, `minuso`, and `*o`,
  - exact coverage + non-overlap over host domains at len<=4,
  - explicit per-case engine timeout budgets.

Policy:
- Engine usage is intentional for divergence testing.
- Tests here are for assurance and operational risk detection, not fast edit-loop feedback.

Normative semantics and acceptance framing are defined in `docs/SPEC.md`.
