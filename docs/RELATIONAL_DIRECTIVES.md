# Relational Directives

These directives capture recurring implementation rules for arithmetic relations.

1. Keep representation-domain checks at representation boundaries.
   - In this codebase, keep explicit `trito` checks in boundary relations such as
     `canco`, `len<=o`, and `digit-stepo`.
   - Rationale: dropping them weakens the numeral domain (non-trit terms can be admitted).

2. Prefer equation-based structure checks over redundant destructuring.
   - Replacing `fresh` destructuring with helpers like `nonzeroo` is fine when the
     accepted term set is unchanged.
   - Examples that validated: `shift3o` and carry-propagation guards in `add-carryo`.

3. Use disequality only when the variable domain is already constrained.
   - Example: `(=/= d '0)` in `canco` is acceptable because `d` is constrained by `trito`.
   - Avoid using disequality as the only digit-domain mechanism.

4. Keep "shape-only" helpers separate from strict canonical predicates.
   - `canco-shapeo` may be lighter-weight for arithmetic surface checks.
   - `canco` remains the strict boundary predicate used for bounded-domain contracts.

5. Validate relation edits with both fast and assurance suites.
   - Fast suite catches regressions in core behavior/modes.
   - Assurance suite catches slow-mode and divergence-expectation regressions.

6. Keep an ablation test for critical boundary constraints.
   - The fast suite includes boundary ablations that intentionally remove
     `trito` checks from bounded predicates and assert non-trit terms are admitted.
   - This guards against accidentally weakening domain contracts in future edits.

7. Treat partially instantiated answers as first-class semantics.
   - BT harness checks should interpret symbolic answers denotationally against
     bounded expected sets (rather than requiring concrete decode only).
   - This matches the mK arithmetic style where generalized answers denote sets
     of valid numerals.

8. Preserve non-overlapping/well-formed clause structure at the bit/trit level.
   - Prefer clauses that enforce well-formed numerals by construction in core
     recurrences (mutatis mutandis from the binary suite).
   - Avoid adding branches whose only effect is overlapping aliases of the same
     denotation.

9. Keep finite-failure guarantees scoped like the binary reference.
   - Refutational completeness expectations are per relation invocation with
     non-shared variables (and explicit bounds where required), not arbitrary
     conjunctions with shared vars.

10. Keep operational bounds inside the arithmetic relation family.
   - Bound/ordering constraints should be relation-internal (or in designated
     boundary helpers), not externally bolted on at random call sites.

11. Compare relational laws by denotation, not raw stream shape.
   - For commutativity/associativity/cancellation checks, compare decoded
     normalized answer sets under explicit bounds.
   - Do not require identical answer ordering or identical symbolic partitioning.

12. Test both failure and success across conjunction flow orderings.
   - Finite-failure flow checks are necessary but not sufficient.
   - Add satisfiable flow-completeness checks to ensure each ordering returns
     the exact expected bounded set (not merely some prefix).

13. Document dispatch limits when negative information is unavailable.
   - Under pure-unification discipline, some unbounded shared-variable alias
     modes cannot be cleanly partitioned into disjoint operational cases.
   - Classify those modes explicitly as expected divergence (for example
     `(*o q q q)` after the first two answers), and keep bounded checks as the
     regression contract.
