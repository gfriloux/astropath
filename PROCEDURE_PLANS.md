# PROCEDURE_PLANS.md — astropath planning procedure

> This document defines the process to follow **systematically** before any work on
> the code. Every change is broken down into atomic steps, each testable and
> committable on its own.
>
> **Core rule: no code without an approved plan.**
> And: read [`DESIGN.md`](DESIGN.md) before any change. If an idea does not fit the
> invariants, the answer is no.

---

## 1. Write the plan first

As soon as a version or a feature comes up, create:

```
.claude/plans/v{X.Y.Z}/
  plan.md           ← context, scope, phases, decisions, files touched
  manual_tests.md   ← manual tests (grown during dev, run at validation)
  phase0_results.md ← real state of the tree before coding (see §2)
```

Plans live **in `.claude/plans/`**, never at the root. An obsolete plan is **deleted**,
not duplicated as `_v2`/`_v3`.

### Minimal content of `plan.md`

- **Context**: where we start from, why.
- **Goal**: what we want to reach.
- **Scope**: explicit in scope / out of scope.
- **Stage(s) involved**: `query` | `model` | `view` | `nix` | `doc`.
- **Working tree state**: what is already there, what must go away.
- **Ordered atomic phases / steps**: each with its verification + commit message.
- **Technical decisions**: choices and rationale.

---

## 2. Phase 0 — Mandatory audit

**Before touching the code**, check the real state — never assume the tree is clean:

```bash
nix develop --command just ci
```

Record the result in `.claude/plans/v{X.Y.Z}/phase0_results.md`.

---

## 3. Git policy — hybrid

- Claude works on a **dedicated branch** (`feat/…`, `fix/…`, `chore/…`,
  `refactor/…`, `docs/…`), never directly on `main`.
- Claude **commits atomically**: one logical change = one commit, in
  [Conventional Commits](#commit-convention) form. Each commit passes the gates on its own.
- Claude **never** runs `merge`, `push` or `tag`. The user reviews, merges into
  `main` and pushes.
- **A plan always ends with a merge into `main`.** At closing time (gates green), the
  user merges the plan branch into `main` and pushes, **before** starting the next plan.
  A finished plan branch is never left unmerged: every plan starts from an up-to-date
  `main`.

### Commit convention

```
type(scope): short imperative message
```

- **type**: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `ci`.
- **scope**: `query`, `model`, `view`, `nix`, `notmuch`, `ui`, or the module touched.
- **language**: English (commit messages and changelog entries).

Docs are updated **in the same commit** as the code they describe. A structural change
committed without updating `DESIGN.md`/`README.md` leaves the docs stale — that is a defect.

---

## 4. Test discipline — goldens on the data layer

The `query` + `model` layer is deterministic: a notmuch fixture (frozen JSON) produces an
exact model. That expected model is stored as a **reference file**:

```
tests/fixtures/<case>/         ← frozen notmuch output (search/show --format=json)
tests/golden/<case>.json       ← expected domain model
```

- A behavior change shows up in the **golden diff**.
- A golden that changes by accident = **hard stop**.
- To regenerate a golden on purpose: `just bless`, then **review the diff**.

**We automate**: notmuch parsing → model, tag/counter/state logic, query construction.
**We do not automate**: pixel-perfect QML rendering, actually opening the external client,
real offlineimap/imapnotify syncing, launching Quickshell on Wayland. Those go into
`manual_tests.md`.

---

## 5. Change types & recipes

| Type | Stage | Steps (each = 1 commit) |
|---|---|---|
| New query / smart folder | `query` `model` | 1. fixture+golden (`test(model): …`) → 2. impl (`feat(query): …`) → 3. docs |
| New thread state / tag mutation | `model` | 1. fixture+golden → 2. impl (`feat(model): …`) → 3. DESIGN docs if an invariant is touched |
| View / component change | `view` | 1. QML impl (`feat(view): …`) → 2. `manual_tests.md` updated → visual review |
| Bug fix | affected stage | 1. failing regression test (`test: reproduce …`) → 2. fix (`fix(scope): …`) |
| Refactor | affected stage | 1. refactor without changing a golden (`refactor(scope): …`). If a golden moves, it was not a refactor. |
| Docs only | — | `docs: …` |

---

## 6. Plan template

```markdown
## Plan: [Title]

**Type:** [query | state/tag | view | bug | refactor | doc]
**Goal:** ...
**Why:** ...
**Stage(s):** [query | model | view | nix | doc]

### Files touched
- [ ] `src/...`
- [ ] `tests/fixtures/...` / `tests/golden/...`
- [ ] `DESIGN.md` / `README.md`

### Atomic steps
#### Step 1: [Title]
**Description:** ...
**Verification:** `just ci` (or the relevant target)
**Commit:** `type(scope): message`

### Quality gates
- [ ] `just ci` passes
- [ ] Goldens up to date and intentional
- [ ] Docs in sync (same commit)
- [ ] Atomic commits on a dedicated branch
```

---

## 7. Quality gates

Every change passes these gates before being considered done. **One single
definition**: the `Justfile`. pre-commit and CI both call it.

```bash
just fmt-check   # qmlformat — no unformatted file
just lint        # qmllint — no warning tolerated
just test        # notmuch goldens + Qt Quick Test
just ci          # all three in a row
```

---

## 8. What does not change between versions

- **DESIGN.md is authoritative.** Outside the invariants → no.
- **Tag-only, notmuch as source of truth, account-agnostic**: hard invariants
  (see DESIGN.md). Delegating reading to an external client (`alot` today) is a
  **revisable** scope decision. Changing it = an explicit DESIGN decision, not an
  implementation PLAN.
- **Hybrid git**: branch + atomic commits by Claude; merge/push/tag by the user.
- **Nix**: always `nix develop --command …` for non-interactive commands.
- **`tmp/`**: uncommitted scratch (design handoffs, notes, working output).
- **Release tooling** (`renovate`, `git-cliff`, release workflow): added at the **first
  tag**, not before (see README.md).

---

**Last updated:** 2026-08-08
**Status:** Active
