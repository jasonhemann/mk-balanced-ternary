# mk-balanced-ternary

This project builds pure miniKanren arithmetic for balanced-ternary integers in LSD-first form, with executable relation definitions, an oracle for test comparison, and test suites that enforce both semantic correctness and bounded operational behavior.

## Current phase and primary deliverables

Current delivery target is balanced-ternary M0 and M1:
- M0 oracle in host code: `bt->int`, `int->bt` for tests.
- M1 core relations in miniKanren: `trito`, `add3o`, `nego`, `pluso`, `minuso`, `mul1o`, `*o`.
- Verification focus: ground/ground and bounded inverse modes exercised by tests.

## Quickstart

Run fast regression tests:

```sh
raco test test
```

Run slow assurance tests:

```sh
raco test assurance
```

## Repository map

Core balanced-ternary track:
- `src/bt_rel.rkt` - primary relation implementation target.
- `src/bt_oracle.rkt` - host oracle conversions used by tests.
- `test/bt_rel_test.rkt` - primary balanced-ternary regression tests.
- `test/bt_harness_primitive_test.rkt` and `test/bt_harness_ops_test.rkt` - BT harness parity checks against the oracle.
- `test/bt_mode_bounds_test.rkt` - bounded mode/groundedness matrix checks through `*o`.
- `test/bt_order_div_test.rkt` - bounded ordering and Euclidean division semantics checks.
- `test/bt_div_exhaustive_mode_test.rkt` - exhaustive bounded `run*` mode checks for Euclidean `divo` against host denotations.
- `test/bt_div_mode_matrix_test.rkt`, `test/bt_finite_failure_test.rkt`, `test/bt_signed_valence_test.rkt` - Euclidean `divo` mode, failure, and signed-case coverage.

Legacy baseline track:
- `src/binary-numbers.rkt` - binary miniKanren arithmetic baseline.
- `test/binary_numbers_test.rkt` - binary baseline regression tests.

Reference artifacts:
- `artifacts/arith.prl` - copied Prolog reference implementation.
- `artifacts/Pure_Declarative_and_Constructive_Arithmetic_Relat.pdf` - source paper referenced during design.

Assurance:
- `assurance/slow_assurance_test.rkt` - heavy randomized checks and bounded timeout assertions.
- `assurance/bn_harness_divergence_test.rkt` - binary harness divergence and slower `/o` assurance checks.
- `assurance/bt_harness_assurance_test.rkt` - heavier seeded BT harness checks.

Documentation:
- `docs/SPEC.md` - normative arithmetic and operational contract.
- `docs/BALANCED_TERNARY_101.md` - practical guide for reading/writing raw BT terms.
- `docs/ROADMAP.md` - phase sequencing and planning.
- `docs/FASTER_MINIKANREN.md` - backend syntax and discipline notes.
- `docs/INTEROP.md` - future interop strategy.

## Normative vs explanatory docs

Documentation SPOT policy:
- Entry point: this `README.md`.
- Normative source of truth: `docs/SPEC.md`.
- Planning and future strategy docs may summarize or sequence work, but if any wording differs, `docs/SPEC.md` is authoritative.
