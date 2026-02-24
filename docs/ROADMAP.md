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
- Slow assurance suite (`raco test assurance/slow_assurance_test.rkt`) passes.
- Any current gaps are tracked as explicit follow-up tasks.

## Planned follow-on phases

### M1.25 Binary harness hardening (immediate pre-BT step)
- Build a binary-only validation harness between host Racket naturals and miniKanren backward binary relations.
- Include deterministic bounded checks, randomized checks, partial-term bounded cases, and explicit divergence classification.
- Treat harness behavior as a confidence gate before adding balanced-ternary comparison layers.

### M1.5 Operational profile hardening
- Expand mode behavior notes per relation.
- Ensure bounded inverse-mode expectations are explicit in tests.
- Add targeted regression cases for known divergence shapes.

### M2 Ordering (optional)
- Add bounded ordering relations (for example, `<o`, `<=o`) with explicit max-digit bound parameters.
- Keep unbounded var/var ordering out of scope unless a separate strategy is approved.

### M3 Interop (optional)
- Add bounded translation/comparison interfaces across representations.
- Start with bridge relations to balanced ternary as canonical pivot.
- Validate cross-representation behavior with bounded property tests.

## Planning rules for future phases

- Treat `docs/SPEC.md` as the single source of normative truth.
- Keep phase docs focused on sequencing, risk, and acceptance progression.
- Require explicit boundedness for any query shape with potentially infinite answer spaces.
