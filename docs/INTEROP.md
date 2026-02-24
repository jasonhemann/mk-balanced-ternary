# Representation Interop Strategy

This document addresses the question:
should this project include canonical translations and mixed-representation
comparisons for partially instantiated numbers?

Normative semantics and current acceptance gates live in `docs/SPEC.md`.
Interop work described here is future-facing and out of current acceptance scope unless explicitly adopted as a new phase.

## Recommendation
Yes, but as a later phase. Keep balanced ternary as the primary core first.

Reason:
- Core arithmetic must be stable before adding bridge complexity.
- Translation relations for partially instantiated terms require careful bounded search design.

## Interop Levels

### Level 0 (current)
- Single representation: balanced ternary only.
- Oracle conversions are host-only and test-only.

### Level 1 (later)
- Add relational translation between representations with explicit bounds.
- Example targets: binary LSD-first naturals + sign layer, or signed-digit binary.

### Level 2 (later)
- Add generic equality/comparison and arithmetic across representations.
- Prefer reducing through a canonical pivot representation.

## Proposed Interface Shape
For a representation `R`:
- `digitR-o d`
- `canonR-o n`
- `plusR-o x y z`
- `mulR-o x y z`
- `to-btR-o r bt max-r max-bt` (bounded bridge to balanced ternary)

For mixed representation operations:
- `same-value-o repA a repB b bounds`
- `compare-value-o repA a repB b rel bounds`
- `plus-mixed-o repA a repB b repOut out bounds`

All mixed relations should carry explicit bounds in their API.

## Canonical Translation Guidance
- Canonicalization should be explicit at boundaries, not forced deep in arithmetic recurrences.
- Translation must preserve denotation, not syntax.
- For partially instantiated terms, translation should be relational and bounded, not host-evaluated.

## Verification Plan for Interop
1. Roundtrip stability within bounds.
2. Denotation agreement against oracle on finite sampled domains.
3. Cross-representation equality symmetry.
4. Cross-representation arithmetic consistency.

## Non-goal
Unbounded, fully fair, fully terminating mixed-representation search in arbitrary conjunctions.
