# CLAUDE.md

Guidance for Claude Code (claude.ai/code) in this repository.

> **Before any work on the code, read [`DESIGN.md`](./DESIGN.md) — it outranks every
> skill.** The process is **superpowers**: brainstorm → design → plan → execute →
> review → integrate. **Then read [`PROCEDURE_PLANS.md`](./PROCEDURE_PLANS.md)** — it
> holds this project's specifics (gates, goldens, toolchain, git identity), and nothing
> else.
> **No code without an approved plan.**

## What astropath is

A mail widget for **Quickshell / DankMaterialShell**: an unread badge in the bar +
a popup. Data via **notmuch** (indexed Maildir), reasoning **by thread and by tag**
(account-agnostic). Syncing by **offlineimap** + **imapnotify**. Opening a thread
delegates to a configurable external client (`alot` today). Details and invariants:
`DESIGN.md`.

## Stack & structure

- **View**: QML / Qt Quick (Quickshell), Material 3, Catppuccin Mocha.
- **Data**: `query` layer (runs notmuch) → `model` (thread model, pure/testable) →
  `view` (QML). The QML **never** calls `notmuch` directly.

```
src/                     ← Quickshell QML + query/model layers
tests/                   ← notmuch fixtures (frozen JSON) + goldens (expected model)
docs/superpowers/specs/  ← designs (brainstorming output)
docs/superpowers/plans/  ← plans, verification included (writing-plans output)
.claude/plans/           ← frozen archive of the v0.1.0 … v0.8.0 plans
tmp/, .superpowers/      ← uncommitted scratch (notes; agent ledgers and briefs)
```

## Language

Docs, code comments and commit messages are in **English**. The **UI copy stays in
French** (labels in `src/view/`, settings descriptions). Do not translate user-facing
strings as a side effect of another change.

## Dev environment

Always enter the Nix dev shell before building/testing:

```bash
nix develop
```

For non-interactive commands: `nix develop --command just ci`.

## Commands

```bash
just ci          # full gate: fmt-check + lint + test
just fmt         # qmlformat -i (formats in place)
just fmt-check   # checks formatting, fails if non-conforming
just lint        # qmllint, no warning tolerated
just test        # notmuch goldens + Qt Quick Test
just run         # runs the widget in Quickshell (manual testing)
just bless       # regenerates the goldens (review the diff)
```

The `Justfile` is the **only** definition of the gates; pre-commit and CI call it.

## Guardrails (what does not change)

- **DESIGN.md is authoritative.** Outside the invariants → no. Tag-only, notmuch as
  source of truth, **account-agnostic** (an account is just a query facet, so
  multi-account comes for free): hard invariants. The reading client (`alot` today) is a
  **revisable** scope decision, not an invariant.
- **Git: delegated.** Claude works on a **dedicated branch**, commits **atomically**
  (Conventional Commits, see PROCEDURE_PLANS.md §3), **announces a commit series before
  running it** — the commits are signed, so one passphrase covers the burst — and may
  run `merge`/`push`/`tag`. Integration is a `--no-ff` merge into `main` under
  `superpowers:finishing-a-development-branch`. Claude stops for **decisions**, not for
  steps.
- **Docs in the same commit** as the code they describe.
- **`tmp/` and `.superpowers/`**: never committed.
- **Deterministic data layer**: any change to `query`/`model` goes through a fixture +
  a golden (see PROCEDURE_PLANS.md §5).
