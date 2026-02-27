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

Current focus:
- Keep hardening symbolic-denotational harness behavior and boundary/domain contracts while Euclidean `divo` remains active under explicit bounds.

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
- Implemented: bounded ordering/absolute kernel (`lto-boundedo`, `abso-boundedo`) and the initial Euclidean division kernel (`divo`).
- Implemented: bounded finite-failure matrix (`test/bt_finite_failure_test.rkt`) that enumerates grounding modes with unsatisfiable instances and asserts finite failure.
- Implemented: bounded totality/completeness checks for multiplication (`test/bt_totality_test.rkt`), including exhaustive factorization of 12 and mode-matrix coverage.
- Implemented: assurance-level fully open-mode totality check for bounded `*o` (`assurance/bt_totality_assurance_test.rkt`).
- Implemented: bounded Euclidean `divo` mode matrix and exhaustive bounded `run*` checks (`test/bt_div_mode_matrix_test.rkt`, `test/bt_div_exhaustive_mode_test.rkt`).
- Implemented: division portions of signed valence and finite-failure matrices.
- Implemented: tightened carry-construction pruning in `pluso` (`sum-trim0o`) to remove duplicate proof paths that propagated into division answers.
- Implemented: explicit deterministic-ground regression checks for Euclidean division.
- Implemented: symbolic denotational harness handling for partially instantiated answers (mK-style) and explicit boundary ablation tests.
- Implemented: symbolic-answer partition/non-overlap checks for key open modes (`pluso`, `minuso`, `*o`) in both fast and assurance suites.

Immediate worklist (API-shape and relationality cleanup):
- Extend symbolic-answer partition checks (exact denotation + non-overlap) to
  representative open `divo` modes under bounded domains.
- Keep boundary domain guards explicit and test-backed (via ablation checks)
  while arithmetic surfaces stay as implicit-domain as possible.
- Remove exposed bound parameter from the public Euclidean division surface (target public arity: `divo n m q r`).
- Move required bound/canonical constraints inside the arithmetic relation implementation path, so callers are not forced to add extra conjunctions for core arithmetic behavior.
- Keep deterministic ground canonical behavior while documenting partial-term behavior explicitly (ground uniqueness vs. open-term denotation).
- After the above refactor, re-run and tighten mode/termination matrices against the public arities.

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

### Representation contingency matrix (if BT stalls)
Current default path:
- Balanced ternary (`'T/'0/'1`, base `+3`).

Candidate comparison under current project constraints:
- Balanced ternary
  - Pros: local digitwise negation (`T <-> 1`), compact base-3 length, direct fit for signed arithmetic goals.
  - Risks: 3-digit full-adder space and carry branching must be tightly controlled for mode performance.
- Negabinary (base `-2`, digits `0/1`)
  - Pros: small digit alphabet and compact carry table for addition.
  - Risks: longer terms (base-2), nonlocal sign/negation behavior can complicate division/ordering relations.
- Negaternary (base `-3`, digits `0/1/2`)
  - Pros: base-3 length like BT with unique finite integer encodings.
  - Risks: more complex carry cases than BT and nonlocal negation behavior.

Fallback order if current BT milestone goals are not met:
1. Negabinary (`-2`) as first fallback.
2. Negaternary (`-3`) as second fallback.

### M3 Interop (optional)
- Add bounded translation/comparison interfaces across representations.
- Start with bridge relations to balanced ternary as canonical pivot.
- Validate cross-representation behavior with bounded property tests.

## Planning rules for future phases

- Treat `docs/SPEC.md` as the single source of normative truth.
- Keep phase docs focused on sequencing, risk, and acceptance progression.
- Require explicit boundedness for any query shape with potentially infinite answer spaces.
