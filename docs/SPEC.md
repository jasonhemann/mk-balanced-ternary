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
- Domain assumption: arithmetic relations are specified over this BT numeral
  domain (and partially instantiated logical generalizations of it). Behavior
  on malformed concrete non-BT terms is out of scope.

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

- `divo n m q r` (active extension)
  - Euclidean division relation.
  - Must satisfy: `n = m*q + r`, `m =/= 0`, `0 <= r < |m|`.
  - Public surface is 4-ary (no explicit bound argument).
  - Any bound/ordering helper arguments remain internal to the implementation.
  - Constructive core (nonnegative division by positive divisor):
    - Decompose dividend as `n = d + 3*n'` (LSD-first).
    - Recurse on `n' = m*q' + r'`.
    - Form `t = d + 3*r'`, then choose correction digit `k in {-1,0,1,2}`:
      - `q = 3*q' + k`
      - `r = t - k*m`
      - with local branch conditions guaranteeing `0 <= r < m`.
  - Signed wrapper:
    - Translate to the nonnegative core with `|n|` and/or `|m|`,
      then map `(q,r)` back to Euclidean form for the original signs.
  - Structural-dispatch target (next acceptance gate):
    - branch selection should come from local structural constraints
      (split/length/decomposition relations), not a generic bounded comparator pass.
    - no synthetic bound-token helper should be required on the critical `divo`
      recursion path (for example `nmo-boundo`/`nm-tight-boundo`-style control envelopes).
    - internal ordering/bounds must still be relation-internal and constructive.

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

### 5.1 Mode classification by relation family

The current phase uses three operational classes:

- **Guaranteed finite**
  - ground arithmetic (`ggg`, `gggg`) for `pluso`, `minuso`, `*o`, `divo`.
  - bounded inverse templates used by tests (for example with explicit
    `bto-boundedo` domains).
  - bounded denotation checks where expected host sets are finite.
- **Expected possibly divergent**
  - unbounded shared-variable alias goals that require negative-information
    dispatch not available in pure unification.
  - canonical example: `(*o q q q)` beyond the first two answers.
  - analogous additive aliases such as `(pluso q q q)` and `(minuso q q q)`
    in unbounded open search.
  - open division alias classes such as `(divo q q q '())`,
    `(divo q q (build-num 1) q)`, and `(divo x x (build-num 1) x)`.
  - bounded finite-domain aliases like `(bto-boundedo x B), (divo x (build-num 2) '() x)`
    are tracked as finite success/failure, not expected divergence.
- **Out of scope**
  - claims of finite refutation for arbitrary conjunctions with shared variables.

### 5.2 Non-overlap requirement in bounded enumerations

For bounded exhaustive checks (fast or assurance), answer streams must satisfy:

- no duplicate raw answer terms, and
- no duplicate decoded host tuples.

This non-overlap requirement applies to acceptance tests, even when analogous
unbounded query shapes are classified as possibly divergent.

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

Division structural-dispatch acceptance (next gate):
- `divo` remains 4-ary at the public surface.
- `divo` control flow is driven by local structural dispatch (arithm.prl-style),
  not a synthetic internal bound-token envelope.
- fast and assurance `divo` matrices are re-baselined against that structural
  implementation and continue to pass.

Any test that can produce infinitely many satisfying answers must include explicit finite bounds when used as a regression check.

For bounded law checks (commutativity/associativity/cancellation/inverse),
equivalence is measured on decoded normalized bounded sets, not literal stream
order or exact symbolic answer partitioning.
