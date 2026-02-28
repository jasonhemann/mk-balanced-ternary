# Contributing

Thanks for contributing to this repository.

## Local workflow

Run tests before opening a PR:

- Fast regression:
  - `raco test test`
- Assurance suite:
  - `raco test assurance`
- Example-focused checks:
  - `raco test test/examples`

## PR discipline

- Prefer small, focused commits.
- Keep docs in sync with behavior changes.
- Preserve the documentation SPOT policy:
  - `README.md` is the index/onboarding surface.
  - `docs/SPEC.md` is the normative semantics contract.

## Documentation path policy

- Do not add machine-specific absolute paths (for example `/Users/...`) in
  public docs.
- Use repository-relative paths in examples and references.

## Relation purity policy

In relation modules (for example `src/bt_rel.rkt`):
- Use pure relational goals (`fresh`, `conde`, `==`, `=/=`, relation calls).
- Do not use host arithmetic operators inside relation bodies.

Host arithmetic belongs in:
- oracle modules (for example `src/bt_oracle.rkt`)
- test/support code
