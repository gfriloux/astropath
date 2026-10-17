# PROCEDURE_PLANS.md — astropath project specifics

> **The process is superpowers** (the agent skill set; `superpowers:<skill>` below).
> This document holds only what superpowers cannot know about this repository: its
> gates, its test discipline, its toolchain, its language rules, its git identity.
>
> Read [`DESIGN.md`](DESIGN.md) first. **It outranks every skill.** If an idea does not
> fit its invariants, the answer is no — that is not a process question.

---

## 1. Where the process lives

| Step | Skill | Artifact |
|---|---|---|
| Work out what we want | `superpowers:brainstorming` | `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` |
| Turn it into tasks | `superpowers:writing-plans` | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md` |
| Isolate the workspace | `superpowers:using-git-worktrees` | a worktree on a dedicated branch |
| Implement | `superpowers:executing-plans` | atomic commits + a ledger |
| Prove each change | `superpowers:test-driven-development` | a test watched failing, then passing |
| Independent review | `superpowers:requesting-code-review` | findings, re-graded by effect |
| Integrate | `superpowers:finishing-a-development-branch` | a `--no-ff` merge into `main` |

Both document directories are committed. Nothing new lands under `.claude/plans/`
(see §8).

**Execution method: native by default.** `superpowers:writing-plans` offers
subagent-driven or native execution; this repository defaults to **native** because the
commit-series rule in §3 needs commits arriving from one context. A plan whose tasks are
genuinely independent can opt into subagent-driven execution — that is a decision taken
at the plan review, with the extra signing prompts named out loud.

## 2. When the agent stops

The agent runs a plan end to end without asking permission per step. It stops when
there is something to **decide**: a design choice that changes what gets built, an
ambiguity in the spec, friction against a `DESIGN.md` invariant, a surprise that
invalidates the plan.

Superpowers' own gates are kept, because each is a decision and not a step approval:
the brainstorming gate (nothing is built before the design is approved), the plan
review, and the choice of execution method.

Subagents — independent review, builder check, research, parallel exploration — are
dispatched without asking.

## 3. Git

- Dedicated branch (`feat/`, `fix/`, `chore/`, `refactor/`, `docs/`), never directly
  on `main`.
- Atomic commits: one logical change, one commit, each passing the gates on its own.
- **Commits and tags are signed as `guillaume@friloux.me`** — never
  `guillaume+code@friloux.me`, which breaks GPG verification.
- The agent **announces a commit series before running it**, so the passphrase is typed
  once (`gpg-agent` caches it a few minutes) and the burst goes through.
- The agent may `merge`, `push` and `tag`. **Merge form: `git merge --no-ff`** — always
  a merge commit, so a plan's branch stays legible and its closure is one point in the
  log. The signed merge commit asks for the passphrase; that prompt is the stop.
- A finished branch is never left unmerged: every plan starts from an up-to-date `main`.

### Commit convention

```
type(scope): short imperative message
```

- **type**: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `ci`.
- **scope**: `query`, `model`, `view`, `nix`, `notmuch`, `ui`, or the module touched.

Docs are updated **in the same commit** as the code they describe. A structural change
committed without updating `DESIGN.md`/`README.md` leaves the docs stale — that is a
defect, not a follow-up.

## 4. Quality gates

**One single definition: the `Justfile`.** pre-commit and CI both call it, and no other
document **redefines** the gates — a list elsewhere (here, `CLAUDE.md`, `README.md`) is
a convenience copy of the `Justfile`, never a second source.

```bash
just fmt-check   # qmlformat — no unformatted file
just lint        # qmllint — no warning tolerated
just test        # notmuch goldens + Qt Quick Test
just ci          # all three in a row
```

Every plan opens by running `just ci` on an up-to-date `main` and recording the result:
never assume the tree is clean.

## 5. Determinism — goldens on the data layer

The `query` + `model` layer is deterministic: a notmuch fixture (frozen JSON) produces
an exact model, stored as a reference file.

```
tests/fixtures/<case>/         ← frozen notmuch output (search/show --format=json)
tests/golden/<case>.json       ← expected domain model
```

- A behavior change shows up in the **golden diff**.
- A golden that changes by accident = **hard stop**.
- To regenerate one on purpose: `just bless`, then **review the diff**.
- Test data is synthetic. No real address, no personal tag taxonomy, ever.

| Change | Stage | Order |
|---|---|---|
| New query / smart folder | `query` `model` | fixture+golden → impl → docs |
| New thread state / tag mutation | `model` | fixture+golden → impl → `DESIGN.md` if an invariant moves |
| View / component change | `view` | impl → manual verification → visual review |
| Bug fix | affected | failing regression test → fix |
| Refactor | affected | no golden moves. If a golden moves, it was not a refactor. |

## 6. Test-driven development, and the `view` exception

`superpowers:test-driven-development` applies wherever a test can express the change:

- **`query` / `model` — fully.** Fixture + golden first (RED), then implementation
  (GREEN). This is §5, and it already satisfies TDD.
- **`view` (QML) — partially.** Logic extracted out of QML is testable and gets its test
  first. Rendering, live settings and a real DMS instance are not. There, the "failing
  test" step is replaced by a **manual verification step written before the
  implementation**: the plan states what to look at and what the right outcome is,
  before the code exists. The intent of TDD is kept — the expected result is decided
  before the implementation — only the automation is unavailable.

This exception is narrow and decided (2026-10-17). It is not a licence to skip tests
anywhere a test could have been written.

## 7. What is not automatable

Pixel-perfect QML rendering, actually opening the external client, real
offlineimap/imapnotify syncing, launching Quickshell on Wayland, live settings, real
notmuch timing.

These become **verification steps inside the plan**, attached to the task they validate,
in superpowers' step style: the command to run, the result that means it passed, a
`- [ ]` checkbox. The closing run gets a `## Manual validation` section at the end of
the plan: the date, which boxes were exercised, and which were not and why.

**Worktrees and the dev bar.** A plan executes in an isolated worktree.
`just dev-bar` takes the repository root as an argument and symlinks `src/` live, so it
works from any worktree — but its isolated state root
(`~/.local/state/astropath-dev`) is single, so **one dev bar at a time**. `just reload`
purges the qmlcache; toggling the plugin alone is not enough.

## 8. Toolchain, language, scratch

- **Nix.** Always `nix develop`, or `nix develop --command …` for non-interactive
  commands.
- **Language.** Repository docs, code comments and commit messages in **English**. The
  **UI copy stays in French** (`src/view/` labels, settings descriptions). Never
  translate user-facing strings as a side effect of another change.
- **`.claude/plans/` is a frozen archive** of the v0.1.0 … v0.8.0 plans. It records the
  house process that was in force then; none of it binds anything now, and nothing new
  is added to it.
- **Scratch, never committed.** `tmp/` (design handoffs, notes, working output) and
  `.superpowers/` (agent ledgers, briefs, review packages).

---

**Last updated:** 2026-10-17
**Status:** Active
