# Balanced Ternary Arithmetic Specification (Normative)

## 1. Scope and authority

This file is the normative contract for balanced-ternary arithmetic in this repository.
If any other document conflicts with this file, this file wins.

Current required scope covers milestones M0 and M1 only.

## 2. Representation and canonical form

Balanced-ternary integers are represented as LSD-first lists of trits.

- Trit symbols: `'T`, `'0`, `'1`, where `'T` means -1.
- Zero is `'()`.
- Canonical non-zero form: the most-significant trit (last list element) is not `'0`.

## 3. Purity and layering

- Relation modules must not use host integer arithmetic in relation definitions.
  - Disallowed in relations: host `+`, `-`, `*`, `quotient`, `remainder`, and similar arithmetic evaluation.
- Host arithmetic is allowed only in oracle and test code.

Layer boundaries:
- `src/bt_rel.rkt`: pure relational semantics.
- `src/bt_oracle.rkt`: host arithmetic oracle for comparison in tests.

## 4. Required relations (M1)

The following relations are required:

- `trito t`
  - True iff `t` is one of `'T`, `'0`, `'1`.

- `add3o a b cin s cout`
  - Full-adder relation over trits.
  - Must satisfy: `a + b + cin = s + 3 * cout`.
  - All arguments are trits.

- `nego x y`
  - Digitwise negation relation.
  - Trit mapping: `'T <-> '1`, `'0 -> '0`.

- `pluso x y z`
  - Sum relation: `x + y = z`.
  - Implemented via ripple-carry over `add3o`.

- `minuso x y z`
  - Difference relation: `x - y = z`.
  - Preferred relational form: `pluso y z x` (no required intermediate negation goal).

- `mul1o x trit out`
  - Multiply balanced-ternary integer `x` by a trit in `{ 'T, '0, '1 }`.

- `*o x y z`
  - Product relation: `x * y = z`.
  - Uses recurrence `y = b0 + 3*y'` and combination:
    - partial `x*b0`
    - recursive `x*y'`
    - shift by one trit and add.

## 5. Operational and mode contract

Required successful modes for current acceptance:
- ground/ground correctness for `pluso` and `*o`.
- bounded inverse modes used by tests, for example:
  - ground `x,z` with variable `y` under explicit bound constraints.
  - explicit digit-length bounds are the default boundedness mechanism (for example, via `bto-boundedo` in `bt_rel.rkt`).
- open-mode answers may be partially instantiated symbolic terms; acceptance is
  by denotation under bounded domains, not by requiring every answer to be fully ground.
- raw answer stream ordering and symbolic partition shape are operationally
  significant but not semantically canonical; denotational set equality is the
  acceptance criterion for relational-law checks.

Not required in current acceptance:
- unbounded var/var termination.
- global completeness for arbitrary conjunction orderings.
- unbounded ordering relations.

## 6. Boundary canonicalization policy

Canonical form should be enforced at explicit boundaries, not deeply or implicitly in recursive arithmetic branches.

- Public arithmetic surfaces should expose canonical-domain behavior (canonical numerals in/out, non-canonical numerals out of domain).
- Do not force global canonicalization deep inside recursive branches of `pluso` or `*o` in ways that add avoidable branching.
- Local, non-branching canonical normalization steps are acceptable.
- Tests may apply bounded canonical predicates to constrain search spaces.

## 7. Milestones and definition of done

### M0 (Oracle)
- Implement `bt->int` and `int->bt` in `src/bt_oracle.rkt`.
- `int->bt` must produce canonical balanced-ternary output.

### M1 (Core relations)
- Implement `trito`, `add3o`, `nego`, `pluso`, `minuso`, `mul1o`, `*o` in `src/bt_rel.rkt`.

### Definition of done (current phase)
`raco test test/bt_rel_test.rkt` passes with:
- unit tests for `add3o`, `pluso`, `*o` edge cases,
- randomized property checks against oracle over bounded integer ranges,
- bounded inverse-mode tests that verify returned answers are correct.

Repository-level regression checks also include:
- `raco test test`
- `raco test assurance`

## 8. Acceptance test contract

Fast suite (`test/`) is the default regression gate:
- finite bounded queries,
- medium randomized coverage,
- correctness-first checks.

Slow assurance suite (`assurance/`) is the deeper confidence gate:
- larger randomized workloads,
- engine-based timeout assertions for known divergent query shapes.

Any test that can produce infinitely many satisfying answers must include explicit finite bounds when used as a regression check.

For bounded law checks (commutativity/associativity/cancellation/inverse),
equivalence is measured on decoded normalized bounded sets, not literal stream
order or exact symbolic answer partitioning.
