# Source Modules

This directory contains relation implementations and oracle code.

Primary balanced-ternary modules:
- `bt_rel.rkt`
  - Core balanced-ternary relations (`trito`, `add3o`, `nego`/`negateo`, `pluso`, `minuso`, `mul1o`, `*o`, and helpers).
  - Includes pure length-bound helpers for finite-mode testing (`len<=o`, `bto-boundedo`) and bounded ordering helpers (`lto-boundedo`, `abso-boundedo`).
  - Includes bounded Euclidean division (`divo n m q r bound`) with remainder policy `0 <= r < |m|`.
  - Main implementation target for current milestones.
- `bt_oracle.rkt`
  - Host-level conversion oracle (`bt->int`, `int->bt`) used by tests.
  - Not part of relational arithmetic semantics.

Legacy baseline module:
- `binary-numbers.rkt`
  - Binary arithmetic relations maintained as regression and comparison baseline.

Boundary rules:
- Relational arithmetic semantics are defined by `docs/SPEC.md`.
- Host arithmetic belongs in oracle/test code, not in relation bodies.
