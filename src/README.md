# Source Modules

This directory contains relation implementations and oracle code.

Primary balanced-ternary modules:
- `bt_rel.rkt`
  - Core balanced-ternary relations (`trito`, `add3o`, `nego`/`negateo`, `pluso`, `minuso`, `mul1o`, `*o`, and helpers).
  - Includes pure length-bound helpers for finite-mode testing (`len<=o`, `bto-boundedo`) and bounded ordering helpers (`lto-boundedo`, `abso-boundedo`).
  - Includes Euclidean division surface (`divo n m q r`) with remainder policy `0 <= r < |m|`.
  - Division keeps bound handling internal via `divo-boundedo`; callers do not pass a bound parameter to `divo`.
  - Main implementation target for current milestones.
- `bt_oracle.rkt`
  - Host-level conversion oracle (`bt->int`, `int->bt`) used by tests.
  - Not part of relational arithmetic semantics.
- `bt_div_structural.rkt`
  - Alternative structural-dispatch Euclidean division prototype (`divo-structo`)
    and supporting local structural helpers.
  - Built for side-by-side comparison while migrating `divo` toward arithm.prl-style dispatch.

Boundary rules:
- Relational arithmetic semantics are defined by `docs/SPEC.md`.
- Host arithmetic belongs in oracle/test code, not in relation bodies.
