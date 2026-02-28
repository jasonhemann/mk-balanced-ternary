# Public Release Checklist

Use this checklist before making the repository public.

## Required

- Choose and add a license file (`LICENSE`).
- Verify top-level docs are accurate:
  - `README.md`
  - `docs/SPEC.md` (normative contract)
  - directory READMEs (`src/`, `test/`, `assurance/`, `examples/`, `docs/`)
  - `docs/RELATED_WORK.md` (external references)
- Run regression gates:
  - `raco test test`
  - `raco test assurance`
- Confirm no local-only paths or machine-specific assumptions in docs/tests.
- Confirm no accidental large binaries or secrets are tracked.

## Recommended

- Add CI to run at least `raco test test` on each push/PR.
- Add `CONTRIBUTING.md` with local workflow and test expectations.
- Add issue templates for bug reports and operational regressions.
- Add a short “known limitations” section (for example expected alias-mode divergence cases).
- Tag an initial release once tests and docs are green.

## Optional polish

- Add a small screenshot or transcript snippet from `examples/bt_playground.rkt`.
- Add a short “How to read BT terms” pointer near first-query examples.
- Add a paper/reference section at top level if this repo is linked from publications.
