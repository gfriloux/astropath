# Design — astropath's working norm moves to superpowers

**Date:** 2026-10-17
**Status:** approved by the user, 2026-10-17

## Intent and why

astropath has been built under a house process written for this repository alone:
`PROCEDURE_PLANS.md` (plan first, phase-0 audit, atomic commits, goldens) plus a git
policy that forbade the agent from running `merge`, `push` or `tag`, and asked it to
stop for the user's approval at every task of a plan.

That process did its job across eight shipped versions. Two things changed. The agent
is more capable than when the rules were written, so per-task approval stops now cost
more than they catch. And the project would rather conform to a **shared, published
standard** — the superpowers skill set — than keep maintaining a bespoke one. The bar
goes up, and it goes up by adopting someone else's bar rather than by inventing more
local rules.

So: superpowers becomes the process. `PROCEDURE_PLANS.md` stops describing a process
and starts describing only what superpowers cannot know — this project's gates, its
data-layer test discipline, its Nix entry point, its language rules.

## Goals

1. **Superpowers is the process of record.** Brainstorm → written design → plan →
   execution → review → integration, with its skills invoked as they prescribe, and
   its document layout adopted as-is.
2. **Autonomy by default, the user as arbiter.** The agent runs a plan end to end
   without asking permission per step. It stops when there is something to *decide*:
   a design choice that changes what gets built, an ambiguity in the spec, a friction
   against a `DESIGN.md` invariant, a surprise that invalidates the plan.

   Superpowers' own mandatory human waits are kept, because each one is a decision and
   not a step approval: the brainstorming gate (nothing is built before the design is
   approved), the plan review at the end of `writing-plans`, and the choice of
   execution method. What goes away is the old per-task approval stop.
3. **Git is delegated.** The agent may run every git command, including `merge`,
   `push` and `tag`. One constraint: commits and tags are GPG-signed and the user must
   type a passphrase, which `gpg-agent` caches for a few minutes. So the agent
   announces a commit series before starting it, the user unlocks once, and the burst
   goes through.
4. **Subagents are free.** Independent code review, the brainstorming builder check,
   parallel execution: the agent dispatches these without asking.
5. **One document per piece of work.** The plan carries the verification, including
   the manual verification that `just ci` cannot cover.
6. **The project's invariants keep the last word.** `DESIGN.md` outranks any skill.

## Non-goals

- Rewriting or renaming the eight existing `.claude/plans/v0.x/` directories. They
  describe shipped versions; they are frozen as an archive, read-only history. Several
  of them restate the superseded process (`v0.8.0/plan.md` still says "Claude never
  runs merge/push/tag"); that text stays as it is, and `PROCEDURE_PLANS.md` carries
  the one line that declares the directory historical.
- Changing the user's machine configuration. `gpg-agent`'s cache TTL is left at its
  default, and `git merge` / `git push` are deliberately **not** added to
  `.claude/settings.local.json`'s allowlist — the permission prompt is the announce
  step, so suppressing it would remove the one place the user sees an integration
  coming.
- Changing `DESIGN.md`'s invariants, the `Justfile` gates, the golden discipline, the
  Nix workflow, or the Conventional Commits convention.
- Translating the UI. It stays in French, and no change here touches `src/view/`
  user-facing strings.
- Adding release tooling. `git-cliff`, `renovate` and the release workflow already
  exist and are untouched.

## Anti-goals

What would make this a failure even if every file lands correctly:

- **Two parallel process documents.** If `PROCEDURE_PLANS.md` still describes a
  planning workflow after this change, the repository has two norms and the agent will
  follow whichever it read last. `PROCEDURE_PLANS.md` must end up strictly
  complementary to superpowers, never overlapping it.
- **Two parallel document trees.** Nothing new lands under `.claude/plans/`.
- **Autonomy read as "do not consult".** Fewer stops is not fewer questions. An
  unasked question that turns into a wrong guess is the exact failure this change must
  not buy.
- **Stale memories steering the agent.** Three stored memories encode the old rules
  (never commit autonomously, ask at every plan task, merge form to be reconfirmed).
  If they survive, the agent will keep applying the old norm in a future session.

## Constraints

- **Language.** Repository docs, code comments and commit messages in English. UI copy
  in French.
- **Nix.** Non-interactive commands run as `nix develop --command …`.
- **Gates.** `just ci` (`fmt-check` + `lint` + `test`) is the single definition, called
  by pre-commit and CI. It is not duplicated anywhere.
- **Signing.** Every commit and tag is signed as `guillaume@friloux.me` (never
  `guillaume+code@friloux.me`, which breaks GPG verification). The passphrase is the
  user's to type.
- **Live testing.** QML rendering, Wayland, a real DMS instance, real notmuch timing
  and offlineimap syncing cannot be automated. `just dev-bar` starts an isolated DMS
  instance and accepts any repository root (it takes `justfile_directory()` and
  symlinks `src/` live), so it works from a git worktree. Its isolated state root
  `~/.local/state/astropath-dev` is single: **one dev bar at a time** across worktrees.
- **Determinism.** Any change to `query`/`model` goes through a notmuch fixture and a
  golden. A golden that moves by accident is a hard stop.

## The decisions taken

### Document layout

Canonical superpowers paths, committed:

```
docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md    ← designs (brainstorming output)
docs/superpowers/plans/YYYY-MM-DD-<feature>.md         ← plans (writing-plans output)
.claude/plans/                                         ← frozen archive, v0.1.0 … v0.8.0
.superpowers/                                          ← agent scratch, git-ignored (fixed below)
tmp/                                                   ← scratch, git-ignored
```

Plan and spec filenames are dated, per superpowers. The version a plan ships
(`v0.9.0`, …) belongs in the plan's **Goal** line, not in its filename — releases are
a property of the work, not of the document tree.

### `manual_tests.md` and `phase0_results.md` disappear as files

Both are folded into the plan document, which is where superpowers puts verification:

- **Phase-0 audit** becomes the plan's first step: run `nix develop --command just ci`
  on an up-to-date `main`, record the result on one line in the plan. Its purpose —
  never assume the tree is clean — is preserved; its separate file is not.
- **Manual tests** become verification steps inside the task they validate, in
  superpowers' own step style (the command to run, the result that means it passed, a
  `- [ ]` checkbox). This is already how `.claude/plans/v0.8.0/manual_tests.md` was
  written — it referenced "Task 1", "Task 2" — so nothing is lost by attaching each
  check to its task.
- **The closing run** gets a final `## Manual validation` section in the plan: the
  date it was run, which boxes were actually exercised, and which were not and why.
  v0.8.0 recorded exactly this, and that record is worth keeping.

### Git policy

Replaces `PROCEDURE_PLANS.md` §3's "Claude never runs merge/push/tag".

- Work happens on a dedicated branch (`feat/`, `fix/`, `chore/`, `refactor/`, `docs/`),
  never directly on `main`.
- Atomic commits, Conventional Commits form, each passing the gates on its own, docs in
  the same commit as the code they describe.
- The agent announces a commit series before running it ("I'm about to commit steps
  1–6"), so the user unlocks `gpg-agent` once.
- The agent may `merge`, `push` and `tag`. Integration at the end of a branch follows
  `superpowers:finishing-a-development-branch`: the agent names the integration it is
  about to perform and performs it. The signed merge commit asks for the passphrase,
  which is the natural stop — the user sees every integration arrive without the agent
  having to hold a menu open.
- **Merge form: `git merge --no-ff`** (user's decision, 2026-10-17). Always a merge
  commit, signed, so a plan's branch stays legible in the history and its closure is a
  single point in the log. This matches the existing history
  (`Merge branch 'refactor/v0.8.0-testable-logic'`) and settles the question
  `merge-at-end-of-plan.md` had reserved.
- A finished branch is never left unmerged: every plan starts from an up-to-date
  `main`.

### Execution method: inline by default

`writing-plans` offers subagent-driven or native execution. For this repository the
default is **native** (the session implements the plan itself), because the
announce-a-series-then-one-passphrase rule depends on commits arriving from one
context in one burst; under subagent-driven development they arrive from several
contexts at unpredictable times, and every one of them stops on a passphrase prompt.
Subagents stay free for what does not commit: independent code review, the
brainstorming builder check, research and parallel exploration. A plan whose tasks are
genuinely independent can still opt into subagent-driven execution — that is a
decision taken at the plan review, with the passphrase cost named.

This is **my call as the author of this design**, derived from the signing constraint.

### Worktrees

A plan executes in an isolated worktree, per `superpowers:using-git-worktrees`. This is
compatible with live testing: `just dev-bar` loads whichever worktree it is invoked
from. The one-dev-bar-at-a-time limit is accepted as-is — no change to
`scripts/astropath-dev`.

### Test-driven development, and the view layer

`superpowers:test-driven-development` applies wherever a test can express the change:

- `query` / `model` — fully. Fixture + golden first (RED), then implementation (GREEN).
  This is the existing discipline and it already satisfies TDD.
- `view` (QML) — partially. Logic extracted out of QML is testable and gets a test
  first. Rendering, live settings and a real DMS instance are not. There, the "failing
  test" step is replaced by a **manual verification step written before the
  implementation**: the plan states what to look at and what the right outcome looks
  like, before the code exists. The intent of TDD — the expected result is decided
  before the implementation — is kept; the automation is not available.

It is the one place where superpowers' letter cannot be met. Raised as an open question
and **approved by the user on 2026-10-17**: it goes into `PROCEDURE_PLANS.md` as a
decided, narrowly-scoped project rule, not as a general licence to skip tests.

### `PROCEDURE_PLANS.md` after the change

The file stays — `CLAUDE.md` points at it and the pointer is worth keeping — but it is
rewritten to hold only what superpowers does not know:

- the gates and the `Justfile` as their single definition;
- the golden discipline on `query`/`model`, and `just bless`;
- what is not automatable and therefore lands as manual verification;
- Nix as the entry point for every command;
- the language rule (English docs, French UI);
- the signing identity and the announce-before-a-series rule;
- `DESIGN.md`'s precedence over any skill;
- one line declaring `.claude/plans/` a frozen archive of v0.1.0 … v0.8.0, whose
  contents describe the process that was in force then and no longer binds anything;
- a pointer to superpowers for everything else, naming the skills by name.

Everything it currently says about writing plans, phases, plan templates and the plan
directory goes away, replaced by that pointer. `CLAUDE.md` is updated in the same
commit: its "read DESIGN.md then PROCEDURE_PLANS.md, no code without an approved plan"
header becomes "read DESIGN.md, then follow superpowers; PROCEDURE_PLANS.md holds this
project's specifics".

### Agent scratch must actually be ignored

`.superpowers/` is **not** ignored at the repository root. The only thing covering it
today is `.superpowers/sdd/.gitignore` containing `*` — a file that is itself ignored
and untracked, so it does not exist in a fresh clone or in a newly created
`git worktree`. Since the new norm makes worktree execution the default, every new
worktree would start with unignored agent scratch.

Fix: add `.superpowers/` to the root `.gitignore`, next to `tmp/`, with a comment. This
**is** a rule change, not a comment-only change — it corrects a leak the current setup
only appears to cover.

### Stored memories

Three memories encode the superseded norm and must be corrected as part of this work,
or the next session will reapply the old rules. They live outside the repository
(`~/.claude/projects/-home-kuri-Apps-github-gfriloux-astropath/memory/`) and are not in
git, so the repo diff cannot verify them — see Verification.

- `ask-before-commit.md` — "never commit autonomously, ask at every plan task". The
  **slug itself is the stale signal**, since `MEMORY.md`'s index is what a future
  session reads first. So: delete this file and its index line, and write a new memory
  under a name that states the live rule (e.g. `git-delegated-announce-series`) saying
  git is delegated, a commit series is announced so the passphrase is typed once, and
  the agent stops for decisions rather than for steps.
- `merge-at-end-of-plan.md` — edited in place: the reserved question is answered
  (`--no-ff`), and the merge is performed by the agent under
  `finishing-a-development-branch`.
- `release-commands-handoff.md` — edited in place only where it contradicts the new
  policy; it already allows delegating the release sequence.

Memory bodies **stay in French**, like every other memory in that directory. The
English-only rule covers repository docs, code comments and commit messages; these
files are not in the repository.

`commit-email-gpg.md`, `email-privacy.md`, `dms-plugin-reload-qmlcache.md`,
`subagent-transcript-not-streamed.md` and `ui-i18n-todo.md` stay as they are.

### Bootstrap: this change ships under the new norm

User's decision, 2026-10-17. This work executes the way it describes: isolated
worktree, dated plan under `docs/superpowers/plans/`, atomic signed commits announced
as a series, then the agent merges with `--no-ff` and pushes `main`. Approving this
design is what authorises that first integration.

## What is left to the builder

- The exact wording and section order of the rewritten `PROCEDURE_PLANS.md`, as long as
  it covers the list above and describes no planning process of its own.
- Whether `README.md` needs a line about the new document tree.
- The wording of `.gitignore`'s comment about `.claude/plans/` now that the directory
  is frozen (its ignore rules do not change; only `.superpowers/` is added).
- The commit split, within the rule that docs ship with what they describe.

## Verification

This change ships documentation, `.gitignore` and memory files only; no `src/` or
`tests/` file is touched, so the goldens cannot move.

- `nix develop --command just ci` stays green (it does not read these docs, but a
  green run is the proof nothing leaked into the code).
- `git diff --stat` shows changes confined to `CLAUDE.md`, `PROCEDURE_PLANS.md`,
  `.gitignore`, `docs/superpowers/`, and possibly `README.md`.
- `git check-ignore -v .superpowers/sdd/x` — run from a **freshly created worktree**,
  it must report the root `.gitignore` as the matching rule. This is the check that proves the scratch leak is closed where it actually
  leaked.
- A fresh reader of `CLAUDE.md` can reach the superpowers workflow and find no second,
  **active** process description in the repository. The frozen `.claude/plans/` archive
  is exempt by construction, and the line in `PROCEDURE_PLANS.md` declaring it
  historical is what makes a reader able to tell.
- The memory directory holds no file telling a future session to ask at every plan task
  or to refrain from merging, and `MEMORY.md`'s index lines match the files present.
