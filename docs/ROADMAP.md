# Roadmap

This document is planning-only.
Normative semantics and acceptance requirements are defined in `docs/SPEC.md`.

## Objective

Sequence work from a stable balanced-ternary arithmetic core toward optional ordering and interop features, while preserving explicit operational bounds in tests and APIs where needed.

## Current phase (M0 + M1)

Focus:
- Oracle conversions for test comparison.
- Core balanced-ternary relations.
- Test-backed behavior in required modes from `docs/SPEC.md`.

Exit criteria:
- Fast suite (`raco test test`) passes.
- Slow assurance suite (`raco test assurance`) passes.
- Any current gaps are tracked as explicit follow-up tasks.

## Planned follow-on phases

### M1.25 Binary harness hardening (immediate pre-BT step)
- Build a binary-only validation harness between host Racket naturals and miniKanren backward binary relations.
- Include deterministic bounded checks, randomized checks, partial-term bounded cases, and explicit divergence classification.
- Treat harness behavior as a confidence gate before adding balanced-ternary comparison layers.

Current status:
- Implemented: `test/support/bn_harness.rkt` with deterministic and randomized checks, classification, and warning logging.
- Implemented: fast/slow split for harness tests (`test/` vs `assurance/`), including seeded slow `/o` assurance and divergence checks.
- Completed: removed harness-only self-check fixtures from regression/assurance suites.

### M1.5 Operational profile hardening
- Expand mode behavior notes per relation.
- Ensure bounded inverse-mode expectations are explicit in tests.
- Add targeted regression cases for known divergence shapes.

Suggested immediate next step:
- Start balanced-ternary harness parity:
  - add BT-side deterministic/randomized ground checks against `bt_oracle.rkt`,
  - add bounded inverse-mode checks mirroring the binary harness structure,
  - split BT fast vs assurance checks from the start to avoid rework.

Progress:
- Started: BT harness skeleton added with fast (`test/bt_harness_*.rkt`) and assurance (`assurance/bt_harness_assurance_test.rkt`) tracks.
- Implemented: bounded BT mode-matrix tests through `*o` (`test/bt_mode_bounds_test.rkt`) covering all grounding patterns under explicit digit-length bounds.
- Implemented: bounded ordering/absolute/division kernel (`lto-boundedo`, `abso-boundedo`, `divo`) with Euclidean remainder tests in `test/bt_order_div_test.rkt`.
- Implemented: bounded finite-failure matrix (`test/bt_finite_failure_test.rkt`) that enumerates grounding modes with unsatisfiable instances and asserts finite failure.
- Implemented: bounded totality/completeness checks for multiplication (`test/bt_totality_test.rkt`), including exhaustive factorization of 12 and mode-matrix coverage.
- Implemented: assurance-level fully open-mode totality check for bounded `*o` (`assurance/bt_totality_assurance_test.rkt`).
- Implemented: bounded Euclidean `divo` mode matrix for representative sign cases (`test/bt_div_mode_matrix_test.rkt`).
- Implemented: exhaustive bounded `run*` mode checks for `divo` with denotational set equality against host semantics (`test/bt_div_exhaustive_mode_test.rkt`).
- Implemented: explicit cross-sign valence regression checks (`test/bt_signed_valence_test.rkt`) for add/subtract/multiply/divide, including subtract-negatives and mixed-sign inverse modes.
- Implemented: tightened carry-construction pruning in `pluso` (`sum-trim0o`) to remove duplicate proof paths that propagated into division answers.
- Implemented: explicit deterministic-ground regression checks for Euclidean division (`test/bt_order_div_test.rkt`).
- Implemented: promoted Euclidean `divo` as the primary division relation surface (with `divo-boundedo` compatibility alias).
- Next: add assurance-level larger-bound `divo` completeness/termination checks mirroring the new exhaustive fast-suite structure.

### M2 Ordering (optional)
- Add bounded ordering relations (for example, `<o`, `<=o`) with explicit max-digit bound parameters.
- Keep unbounded var/var ordering out of scope unless a separate strategy is approved.

### M2.5 Alternate division semantics (deferred)
Current active track:
- Keep Euclidean-style division as the primary `divo` target (`n = m*q + r`, `m =/= 0`, `0 <= r < |m|`).
- Preserve the current goal of deterministic ground behavior (single `(q, r)` for fixed `n, m`) and bounded all-mode operational checks.

Planned alternate track (after current track is stable):
- Add a separate division relation with symmetric remainder semantics (`|r| < |m|`) so signed remainder answers can be explored relationally.
- Do not merge this with the Euclidean relation; keep it as an explicit second relation with its own tests and mode expectations.

Why this is a separate relation:
- The two semantics have different answer multiplicity for ground inputs (Euclidean: unique; symmetric remainder: typically two).
- That multiplicity changes search branching and termination behavior, so each version needs distinct operational design and test budgets.

Similarity and difference summary:
- Same arithmetic equation: `n = m*q + r`, same non-zero divisor requirement.
- Different canonical remainder policy, answer-set size, and expected operational profile.

Return-to work item:
- Once Euclidean `divo` behavior and tests are fully stable, define the second relation contract and add a dedicated fast/assurance mode matrix for it.

### M3 Interop (optional)
- Add bounded translation/comparison interfaces across representations.
- Start with bridge relations to balanced ternary as canonical pivot.
- Validate cross-representation behavior with bounded property tests.

## Planning rules for future phases

- Treat `docs/SPEC.md` as the single source of normative truth.
- Keep phase docs focused on sequencing, risk, and acceptance progression.
- Require explicit boundedness for any query shape with potentially infinite answer spaces.
