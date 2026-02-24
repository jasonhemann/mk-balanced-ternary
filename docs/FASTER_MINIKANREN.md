# faster-miniKanren Backend Notes

Normative arithmetic semantics and acceptance requirements live in `docs/SPEC.md`.
This file describes backend-specific syntax and coding discipline only.

This project assumes `faster-minikanren` is installed and uses:
- `(require minikanren)` in relation and test modules.

## Why
- Keep arithmetic relations fully relational and pure.
- Avoid relying on `numbers.scm` relational arithmetic wrappers.
- Make syntax/operational constraints explicit and consistent.

## Coding Rules for Relations
- Define relations with `defrel`.
- Use only relational constructs inside goals: `fresh`, `conde`, `==`, `=/=`, and relation calls.
- Keep host arithmetic out of relations.
- Put host arithmetic only in oracle/test code.

## Naming Conventions
- Canonical relation names end with `o`.
- Shared arithmetic names across modules should match where semantics match:
  - `add3o` for one-digit full-adder relations.
  - `add-carryo` for ripple-carry helpers.
  - `pluso`, `minuso`, `*o` for core arithmetic.
- Keep compatibility aliases only when needed (`full-addero`, `addero`, `gen-addero`, `>1o`, `odd-*o`, `bound-*o` in `binary-numbers.rkt`).

## Practical Effect
- Relations remain portable to hosted/faster-style miniKanren backends.
- Backend selection follows the installed `minikanren` collection.
