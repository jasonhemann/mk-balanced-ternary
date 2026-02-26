# Relational Directives

These directives capture recurring implementation rules for arithmetic relations.

1. Keep representation-domain checks at representation boundaries.
   - In this codebase, keep explicit `trito` checks in boundary relations such as
     `canco`, `len<=o`, and `digit-stepo`.
   - Rationale: dropping them causes undecodable/spurious bounded-mode answers.

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

