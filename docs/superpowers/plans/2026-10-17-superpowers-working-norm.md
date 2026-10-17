# Superpowers Working Norm — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> For *this* plan the execution method is already decided: **native** (see the spec,
> "Execution method: inline by default"). Use `superpowers:executing-plans`.

**Goal:** Make superpowers the process of record for astropath — adopt its document
tree, delegate git to the agent, and strip `PROCEDURE_PLANS.md` down to what
superpowers cannot know.

**Architecture:** Documentation-only change plus one `.gitignore` rule and four
out-of-repo memory files. The repository ends up with exactly one active process
description (superpowers, pointed at from `CLAUDE.md`) and one project-specifics
document (`PROCEDURE_PLANS.md`). The eight `.claude/plans/v0.x/` directories stay
untouched as a frozen archive, declared historical by a single line.

**Tech Stack:** Markdown, git, `.gitignore`, the Nix dev shell (`nix develop --command
just ci`), Claude Code memory files under
`~/.claude/projects/-home-kuri-Apps-github-gfriloux-astropath/memory/`.

**Spec:** `docs/superpowers/specs/2026-10-17-superpowers-working-norm-design.md`

## Global Constraints

- Repository docs, code comments and commit messages in **English**. UI copy in
  `src/view/` stays in **French** and is not touched.
- Memory files stay in **French** (they are not in the repository).
- Non-interactive commands run as `nix develop --command …`.
- Commits are signed as `guillaume@friloux.me` — never `guillaume+code@friloux.me`.
- `just ci` is the single definition of the gates and is not duplicated.
- No file under `src/`, `tests/`, `nix/` or `scripts/` is modified. No new file lands
  under `.claude/plans/`. The eight archived plan directories are not rewritten.
- The user's machine configuration is out of scope: `~/.gnupg/gpg-agent.conf` keeps its
  default cache TTL, and `git merge` / `git push` are **not** added to
  `.claude/settings.local.json`'s allowlist — the permission prompt is the announce
  step.
- Merge form: `git merge --no-ff`.
- Branch: `docs/superpowers-working-norm`, off an up-to-date `main`.

## Review Focus

Failure modes the spec implies that no task's deliverable exercises on its own. Each
one has a verification step in the task that owns it.

1. **The spec and this plan are untracked in the main working tree.** A worktree
   created from `main` does not carry them, and merging back into a main worktree that
   still holds untracked copies at those paths makes `git merge` abort with "untracked
   working tree files would be overwritten". They must be **moved**, not copied, into
   the worktree. → Task 1, Step 2 and Task 5, Step 2.
2. **`.superpowers/` unignored in a fresh worktree.** The current cover is
   `.superpowers/sdd/.gitignore` containing `*`, itself untracked, so it does not exist
   in a new worktree — the exact case the new norm generalises. → Task 1, Step 5.
3. **`MEMORY.md` index pointing at a deleted memory.** `ask-before-commit.md` is
   retired by name; a stale index line would make a future session read a broken
   pointer, or worse, trust the stale description. → Task 4, Step 5.
4. **A dangling wikilink carried into the new memory.** The retired memory links
   `[[astropath-git-policy]]`, which does not exist in the memory directory. Copying
   the body forward would carry the dead link. → Task 4, Step 2.
5. **`README.md` still advertising the hybrid policy.** Its *Contributing* section says
   "merge/push/tag reserved for the maintainer" and "no code without an approved plan,
   read PROCEDURE_PLANS.md" — a contributor-facing second norm. → Task 3, Step 4.

---

### Task 1: The new document tree exists, and its scratch is ignored

**Files:**
- Move into the worktree: `docs/superpowers/specs/2026-10-17-superpowers-working-norm-design.md`, `docs/superpowers/plans/2026-10-17-superpowers-working-norm.md`
- Modify: `.gitignore`

**Interfaces:**
- Produces: the two committed document paths every later task refers to, and the root
  ignore rule `.superpowers/` that later worktrees depend on.

- [ ] **Step 1: Phase 0 — record the baseline**

Run: `nix develop --command just ci` on an up-to-date `main`.
Expected: all three gates pass. Record the one-line result in this plan's
`## Manual validation` section as the baseline. A red baseline is a stop: it is not
this plan's job to fix it.

- [ ] **Step 2: Create the worktree and move the two documents into it**

Create the worktree via `superpowers:using-git-worktrees` on branch
`docs/superpowers-working-norm` off `main`. Then **`git mv`-style move** (not copy) the
untracked `docs/superpowers/` tree from the main working tree into the worktree, so the
main working tree is left with no untracked file at those paths (Review Focus 1).

- [ ] **Step 3: Add `.superpowers/` to the root `.gitignore`**

In the Claude Code section of `.gitignore`, next to the existing `.claude/worktrees/`
line, add a rule ignoring `.superpowers/` with a comment saying it is agent scratch.
Adjust the existing comment "les plans, eux, sont versionnés" so it reads as the frozen
archive it now is. The `.claude/` rules themselves do not change.

- [ ] **Step 4: Commit**

```bash
git add .gitignore docs/superpowers/
git commit -m "docs: adopt the superpowers document tree and ignore agent scratch"
```

- [ ] **Step 5: Verify the ignore rule holds where it leaked**

Run, from a **freshly created** throwaway worktree of this branch:
`git check-ignore -v .superpowers/sdd/x`
Expected: the match is reported against the **root** `.gitignore`, not
`.superpowers/sdd/.gitignore`. Remove the throwaway worktree afterwards.

---

### Task 2: `PROCEDURE_PLANS.md` holds only the project's specifics

**Files:**
- Modify: `PROCEDURE_PLANS.md` (full rewrite, 174 lines today)

**Interfaces:**
- Consumes: the ignore rule and document paths from Task 1.
- Produces: the file `CLAUDE.md` and `README.md` point at in Task 3. Its title and
  purpose line must say "project specifics", not "planning procedure".

- [ ] **Step 1: Write the verification first (project rule for non-automatable work)**

State here, before rewriting, what a correct result looks like, so Step 3 is checked
against something written in advance:

- the file contains **no** plan template, no phase list, no plan-directory convention,
  no instruction about how to write or approve a plan;
- it contains, one short section each: the gates and the `Justfile` as their single
  definition; the golden discipline on `query`/`model` plus `just bless`; what is not
  automatable and therefore lands as manual verification in a plan; Nix as the entry
  point; the language rule (English docs, French UI); the signing identity and the
  announce-before-a-series rule; `DESIGN.md`'s precedence over any skill; the
  `--no-ff` merge form; the TDD scope rule including the approved `view` derogation;
  one line declaring `.claude/plans/` a frozen archive of v0.1.0 … v0.8.0;
- it states the four working-norm facts superpowers cannot know: the agent stops for
  **decisions**, not for steps, while superpowers' own gates (design approval, plan
  review, execution-method choice) are kept; subagents are dispatched without asking;
  **native execution is this repository's default** because the announce-a-series rule
  needs commits from one context; a plan executes in an isolated worktree, where
  `just dev-bar` works from any root but only **one dev bar at a time** (its state root
  `~/.local/state/astropath-dev` is single);
- it points at superpowers for everything else, **naming the skills**:
  `superpowers:brainstorming`, `superpowers:writing-plans`,
  `superpowers:executing-plans`, `superpowers:test-driven-development`,
  `superpowers:requesting-code-review`, `superpowers:using-git-worktrees`,
  `superpowers:finishing-a-development-branch`.

- [ ] **Step 2: Confirm the current file is the thing being replaced**

Run: `grep -nE '^## ' PROCEDURE_PLANS.md`
Expected: the eight headings of the house process (plan first, phase 0, git policy,
test discipline, recipes, plan template, quality gates, what does not change). These
are what Step 3 removes or folds.

- [ ] **Step 3: Rewrite the file**

Wording and section order are the implementer's; the content list in Step 1 is not.
Keep the document short — it is a delta over superpowers, not a manual. Keep the
`**Last updated:**` / `**Status:**` footer convention, dated 2026-10-17.

- [ ] **Step 4: Verify against Step 1**

Run: `grep -nE 'plan\.md|manual_tests\.md|phase0_results\.md|\.claude/plans/v|never.*(merge|push|tag)' PROCEDURE_PLANS.md`
Expected: the only surviving hits are inside the line that declares `.claude/plans/` a
frozen archive. Any other hit means a piece of the old process stayed behind.

Then re-read the file against Step 1's content list and confirm each item is present
and each exclusion absent.

- [ ] **Step 5: Commit**

```bash
git add PROCEDURE_PLANS.md
git commit -m "docs: reduce PROCEDURE_PLANS.md to this project's specifics"
```

---

### Task 3: `CLAUDE.md` and `README.md` point at the new norm

**Files:**
- Modify: `CLAUDE.md` (header blockquote, *Guardrails* section)
- Modify: `README.md` (*Contributing* section; *Code structure* list)

**Interfaces:**
- Consumes: `PROCEDURE_PLANS.md` as rewritten in Task 2 — these two files must not
  restate its content, only point at it.

- [ ] **Step 1: Rewrite the `CLAUDE.md` header blockquote**

Today: "Before any work on the code, read `DESIGN.md` then `PROCEDURE_PLANS.md`. No
code without an approved plan." It becomes: read `DESIGN.md`, follow superpowers for
the process, and read `PROCEDURE_PLANS.md` for this project's specifics. Keep "no code
without an approved plan" — superpowers' brainstorming gate says the same thing.

- [ ] **Step 2: Update the `CLAUDE.md` *Guardrails* section**

Replace the "**Git: hybrid.**" bullet, which currently says the agent never runs
`merge`/`push`/`tag`, with the delegated policy: dedicated branch, atomic signed
commits, a commit series announced before it runs, `--no-ff` merge performed by the
agent under `superpowers:finishing-a-development-branch`. Leave every other guardrail
bullet as it is.

- [ ] **Step 3: Update `README.md`**

*Contributing*: the pointer goes to `DESIGN.md` + superpowers + `PROCEDURE_PLANS.md`,
and the "merge/push/tag reserved for the maintainer" clause goes away. *Code
structure*: add a line for `docs/superpowers/` (specs and plans) next to the existing
entries.

- [ ] **Step 4: Verify no second active norm remains in the repository**

Run: `grep -rnE 'reserved for the maintainer|never.*(merge|push|tag)|hybrid' --include='*.md' . | grep -v '^./.claude/plans/' | grep -v '^./CHANGELOG.md'`
Expected: no hit. Hits under `.claude/plans/` and in `CHANGELOG.md` are history and are
exempt by construction (Review Focus 5).

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md README.md
git commit -m "docs: point CLAUDE.md and README.md at the superpowers norm"
```

---

### Task 4: The stored memories stop teaching the old norm

**Files** (outside the repository, under
`~/.claude/projects/-home-kuri-Apps-github-gfriloux-astropath/memory/`):
- Delete: `ask-before-commit.md`
- Create: `git-delegated-announce-series.md`
- Modify: `merge-at-end-of-plan.md`, `release-commands-handoff.md`, `MEMORY.md`

**Interfaces:**
- Consumes: the git policy as written in Task 3, Step 2 — the memory must not contradict
  it.
- Produces: no memory under a name or description that tells a future session to ask at
  every plan task or to refrain from merging.

- [ ] **Step 1: Write the verification first**

A correct result is: `grep -rl 'à chaque tâche' memory/` returns nothing; no file named
`ask-before-commit.md`; every `MEMORY.md` line resolves to an existing file; no
`[[astropath-git-policy]]` link anywhere.

- [ ] **Step 2: Create `git-delegated-announce-series.md`**

`type: feedback`, French body, with the `**Why:**` / `**How to apply:**` lines the
memory format requires. Content: git is delegated including `merge`/`push`/`tag`; a
commit series is announced before it runs so the passphrase is typed once (`gpg-agent`
caches it a few minutes); the agent stops for decisions, not for steps; native
execution is the default so commits arrive from one context. Link
`[[commit-email-gpg]]`, `[[merge-at-end-of-plan]]`, `[[release-commands-handoff]]`. Do
**not** carry over `[[astropath-git-policy]]` (Review Focus 4).

- [ ] **Step 3: Delete `ask-before-commit.md`**

- [ ] **Step 4: Edit the two surviving memories in place**

`merge-at-end-of-plan.md`: replace the "**Forme du merge — à reconfirmer avec lui**"
paragraph with the answer — `--no-ff`, decided 2026-10-17 — and say the agent performs
the merge. `release-commands-handoff.md`: keep the whole verified command sequence, and
fix only its two contradictions with the new policy (the "par défaut Claude ne fait pas
merge/push/tag" rationale, and the `[[ask-before-commit]]` link at the end, which now
points at the new memory).

- [ ] **Step 5: Update `MEMORY.md` and verify the index**

Replace the `ask-before-commit.md` line with one for the new memory, keeping the
one-line `- [Title](file.md) — hook` form. Then run, from the memory directory:
`for f in $(grep -oP '\]\(\K[^)]+' MEMORY.md); do test -f "$f" || echo "MISSING: $f"; done`
Expected: no output. Then `grep -rn 'à chaque tâche\|astropath-git-policy' .`
Expected: no output.

- [ ] **Step 6: No commit**

These files are outside the repository and are not committed. Say so explicitly when
reporting the task, so the absence of a commit does not read as an omission.

---

### Task 5: Gates, manual validation record, and integration

**Files:**
- Modify: `docs/superpowers/plans/2026-10-17-superpowers-working-norm.md` (the
  `## Manual validation` section of this plan)

**Interfaces:**
- Consumes: every preceding task's deliverable.

- [ ] **Step 1: Run the gates and the diff scope check**

Run: `nix develop --command just ci`
Expected: pass, same as the Task 1 baseline.

Run: `git diff --stat main...HEAD`
Expected: changes confined to `CLAUDE.md`, `PROCEDURE_PLANS.md`, `README.md`,
`.gitignore`, `docs/superpowers/`. Any `src/`, `tests/`, `nix/` or `scripts/` path is a
defect — the goldens cannot have moved.

- [ ] **Step 2: Fill in `## Manual validation` and commit**

Record the date, the baseline from Task 1, the `git check-ignore` output from Task 1
Step 5, and which boxes were actually exercised versus skipped and why. Confirm the
main working tree holds no untracked `docs/superpowers/` copy (Review Focus 1), so the
merge cannot abort.

```bash
git add docs/superpowers/plans/2026-10-17-superpowers-working-norm.md
git commit -m "docs: record the superpowers norm migration validation"
```

- [ ] **Step 3: Independent review**

Dispatch `superpowers:requesting-code-review` on the whole branch. Feedback comes back
through `superpowers:receiving-code-review` — verify each point rather than implementing
it on sight.

- [ ] **Step 4: Integrate**

Follow `superpowers:finishing-a-development-branch`. Announce the integration, then:

```bash
git merge --no-ff docs/superpowers-working-norm
git push origin main
```

The signed merge commit asks for the passphrase; that prompt is the stop. No tag — this
ships no version.

---

## Manual validation

_Filled in at Task 5. Baseline from Task 1, Step 1 goes here._

- [ ] `nix develop --command just ci` green before starting (baseline, date + result)
- [ ] `git check-ignore -v .superpowers/sdd/x` from a fresh worktree matches the root
      `.gitignore`
- [ ] `nix develop --command just ci` green at closing
- [ ] `git diff --stat main...HEAD` touches only docs, `README.md`, `CLAUDE.md`,
      `PROCEDURE_PLANS.md`, `.gitignore`
- [ ] `MEMORY.md` index fully resolves; no memory teaches the old norm
- [ ] No untracked `docs/superpowers/` left in the main working tree before the merge
