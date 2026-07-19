# Phase 0 — Audit v0.7.1

**Date :** 2026-07-19
**Branche de départ :** `main` (propre, seul `.claude/plans/v0.7.1/` non suivi).

## `nix develop --command just ci`

- `fmt-check` : OK (porte franchie, `just ci` a poursuivi jusqu'aux tests).
- `lint` : OK.
- `test` : **24 passed, 0 failed, 0 skipped** (golden + model + queries).

Base saine avant de coder. Aucun golden ne doit bouger (changement purement vue).
