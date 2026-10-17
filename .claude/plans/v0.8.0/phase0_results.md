# Phase 0 — Audit v0.8.0

**Date:** 2026-10-17
**Starting branch:** `main` at `714f08f` (clean tree; only `.claude/plans/v0.8.0/` untracked).

## `nix develop --command just ci`

Exit code 0.

- `fmt-check`: OK (gate passed, `just ci` continued).
- `lint`: OK.
- `test`: **24 passed, 0 failed, 0 skipped** (golden + model + queries).

## Coverage state this plan starts from

`qmltestrunner -input tests` exercises `tst_golden.qml`, `tst_model.qml` and
`tst_queries.qml` only — i.e. `src/model/threads.js`, `src/model/format.js` and
`src/query/queries.js`. **Nothing under `src/view/` is touched by CI.** That is the gap
this plan closes for the logic concerned by issues #9, #5, #4 and #7.

Healthy base before coding. The four existing goldens (`search-unread`,
`saved-searches`, `show-thread`, `discovered-searches`) **must not move**: every change
here is either a pure extraction or a fix on an input shape no fixture contains (no
fixture has colliding keys).
