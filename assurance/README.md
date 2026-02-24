# Slow Assurance Suite

This directory contains deeper confidence checks that are slower than the default regression suite.

Run with:
- `raco test assurance/slow_assurance_test.rkt`
- `raco test assurance/bn_harness_divergence_test.rkt`

Purpose:
- Heavy randomized property checks over wider ranges.
- Engine-based timeout assertions for known divergent query shapes.
- Sanity checks that finite queries still return within bounded time.
- Dedicated divergence checks for the binary harness classification path.

Policy:
- Engine usage is intentional for divergence testing.
- Tests here are for assurance and operational risk detection, not fast edit-loop feedback.

Normative semantics and acceptance framing are defined in `docs/SPEC.md`.
