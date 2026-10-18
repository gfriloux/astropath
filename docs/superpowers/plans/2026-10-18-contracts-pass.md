# Contracts Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route every `notmuch` process through one tested dispatch discipline, and declare astropath's requirements on its DMS host where DMS enforces them.

**Architecture:** One mechanism in `src/model/service.js`, two policies. Coalescing (newest wins, older deliberately discarded) for the read processes; FIFO queueing (every mutation runs, in order) for tag mutations. `Notmuch.qml` keeps only the `Process` wiring. Separately, `plugin.json` gains `requires_dms` and a `startupCheck`, and a `jq` gate in `just ci` keeps the manifest conformant with DMS's published schema.

**Tech Stack:** QML / Qt Quick (Quickshell), plain JS in `src/model/` (`.pragma library`), QtTest via `qmltestrunner`, `jq`, Nix dev shell, `just`.

**Spec:** [`docs/superpowers/specs/2026-10-18-contracts-pass-design.md`](../specs/2026-10-18-contracts-pass-design.md)

## Global Constraints

- `requires_dms` value is exactly `">=1.5.0"`.
- Target release v0.9.0; `plugin.json`'s `version` field moves with it.
- UI copy is **French**; docs, comments and commit messages are **English**.
- `src/model/` stays pure: plain data in, plain data out, no `Process`, no parsing of notmuch output beyond what callers pass in.
- No sanitising, escaping or stripping of mail-derived data anywhere.
- No wrapper component over a DMS widget; no gate forbidding direct use of DMS components.
- `just ci` must stay hermetic — no network at test time. The manifest gate uses `jq`, already in the dev shell; no new dependency is added.
- Every commit passes `just ci` on its own. Docs ship in the commit with the code they describe.
- Branch `chore/contracts-pass`, off an up-to-date `main`. Baseline recorded 2026-10-18: `just ci` green, 57 tests passing.

## Review Focus

Failure modes the spec implies that no task's happy path exercises. Each has its test pinned to the task that owns the code.

1. **A tag mutation that fails must not strand the ones queued behind it.** `tagProc.onExited` with a non-zero code must still advance the queue — the user's remaining archives have to run. (Task 3)
2. **A `notmuch` that never answers must not hang activation.** If the probe process emits no completion signal, `StartupCheck` must still call `done()` — a gate that fails open, or never closes, is worse than no gate. (Task 7)
3. **A counts completion arriving after its sequence was abandoned must be ignored,** or stale per-definition counts leak into the current sequence's accumulator. (Task 4)
4. **A pending request identical to the one in flight must neither double-dispatch nor be lost.** Clicking rail category A, then B, then A again while A runs. (Task 2)
5. **Degenerate inputs:** an empty definitions list for the counts sequence, and an empty/absent tag op. Neither may dispatch nor wedge. (Tasks 3, 4)

---

## File Structure

| File | Responsibility |
|---|---|
| `src/model/service.js` (modify) | The two policies, pure and testable. Gains the flight machine, the tag queue, the counts sequencer. |
| `tests/tst_service.qml` (modify) | Unit tests for all three. |
| `src/view/Notmuch.qml` (modify) | `Process` wiring only; every re-arm goes through `service.js`. |
| `src/view/StartupCheck.qml` (create) | Non-visual probe: is notmuch runnable and its database readable. |
| `src/view/ThreadRow.qml` (modify) | Attachment icon. |
| `plugin.json` (modify) | `requires_dms`, `dependencies`, `startupCheck`, version. |
| `tests/vendor/dms-plugin-schema-v1.5.3.json` (create) | DMS's published schema, vendored; version in the filename records provenance. |
| `scripts/check-manifest` (create) | The gate: manifest vs vendored schema, plus the assertions the schema cannot express. |
| `Justfile` (modify) | Wires the manifest check into `lint`. |
| `README.md` (modify) | States the DMS floor for humans. |

---

### Task 1: Generalise the snippet queue into a coalescing flight machine

Pure refactor. The v0.8.0 snippet queue already *is* the coalescing policy; it is renamed to say so and the snippet-specific names disappear. Behaviour must not change: the twelve existing snippet tests pass unmodified apart from the renames.

**Files:**
- Modify: `src/model/service.js` — the `--- lazy snippet requests ---` section
- Modify: `tests/tst_service.qml`
- Modify: `src/view/Notmuch.qml` — `fetchSnippet`, `_advanceSnippet`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `newFlight()` → `{inflight: "", pending: "", streamDone: false, exited: false}`
  - `requestFlight(flight, key, skip, inflightAlive)` → `{flight, dispatch}` — `dispatch` is the key to run now, `""` for nothing. `skip` short-circuits (snippets pass "already cached"). `inflightAlive` false while `flight.inflight` is set means the process died without completing: the flight resets and the request proceeds.
  - `flightEvent(flight, ev)` → `{flight, completedKey, dispatch}` — `ev` is `"stream"` or `"exit"`; the run is over only once both have landed.

- [ ] **Step 1: Rename in `src/model/service.js`**

`newSnippetQueue`→`newFlight`, `requestSnippet`→`requestFlight`, `snippetEvent`→`flightEvent`, field `textReady`→`streamDone`, parameter `id`→`key`, `isCached`→`skip`, result field `completedId`→`completedKey`. Rewrite the section comment to state the policy generically: one run in flight, at most one pending, always the newest; superseded requests are discarded because running them would produce results the newest immediately overwrites.

- [ ] **Step 2: Rename at the two call sites in `src/view/Notmuch.qml`**

`_snippetQueue` keeps its name (it is the snippet's flight); only the `Svc.` calls change.

- [ ] **Step 3: Rename in `tests/tst_service.qml`**

Rename the twelve `test_requestSnippet_*` / `test_snippetEvent_*` functions to `test_requestFlight_*` / `test_flightEvent_*` and update the calls. Assertions are unchanged — that is the point.

- [ ] **Step 4: Run the gate**

Run: `nix develop --command just ci`
Expected: PASS, still 57 tests. A behaviour change here means the rename was not a rename.

- [ ] **Step 5: Commit**

```bash
git add src/model/service.js src/view/Notmuch.qml tests/tst_service.qml
git commit -m "refactor(model): generalise the snippet queue into a coalescing flight machine"
```

---

### Task 2: Route `searchProc` through the flight machine

Fixes the bug #10 reports.

**Files:**
- Modify: `src/view/Notmuch.qml` — `runSearch`, `refresh`, `searchProc`
- Modify: `tests/tst_service.qml`

**Interfaces:**
- Consumes: `newFlight`, `requestFlight`, `flightEvent` (Task 1).
- Produces: nothing new in `service.js`. `Notmuch.qml` gains `_searchFlight` and `_dispatchSearch(query)`.

- [ ] **Step 1: Write the failing tests**

Covers Review Focus #4 — the key is the query string, so a pending request equal to the inflight one is a real case here in a way it was not for snippets.

```qml
function test_requestFlight_pendingEqualToInflightIsNotLost() {
    var f = Svc.requestFlight(Svc.newFlight(), "tag:inbox", false, false).flight;
    var b = Svc.requestFlight(f, "tag:unread", false, true);
    compare(b.dispatch, "");
    var a = Svc.requestFlight(b.flight, "tag:inbox", false, true);
    compare(a.dispatch, "");                 // still nothing starts
    compare(a.flight.pending, "tag:inbox");  // newest wins, even back to the inflight key
    var done = Svc.flightEvent(Svc.flightEvent(a.flight, "stream").flight, "exit");
    compare(done.completedKey, "tag:inbox");
    compare(done.dispatch, "tag:inbox");     // the superseding request still runs
}

function test_requestFlight_samePollQueryRunsAgainWhenIdle() {
    var f = Svc.requestFlight(Svc.newFlight(), "tag:unread", false, false).flight;
    var done = Svc.flightEvent(Svc.flightEvent(f, "stream").flight, "exit");
    compare(Svc.requestFlight(done.flight, "tag:unread", false, false).dispatch, "tag:unread");
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `nix develop --command just test`
Expected: FAIL — `pendingEqualToInflightIsNotLost` is the one that can fail; if both pass as written, Task 1's machine already covers them and the tests stand as regression cover.

- [ ] **Step 3: Rewire `searchProc` in `src/view/Notmuch.qml`**

Add `property var _searchFlight: Svc.newFlight()`. `runSearch()` becomes a *request*: `Svc.requestFlight(_searchFlight, root.currentQuery, false, searchProc.running)`, storing the flight and calling `_dispatchSearch(dispatch)` when non-empty. `_dispatchSearch(query)` is where the existing body moves — reset `_searchRun`, recompute `status`, set `command` from `Queries.search(query)`, set `running = true`. Both completion signals (`stdout.onStreamFinished`, `onExited`) additionally call `Svc.flightEvent`, dispatching whatever it returns. `_noteSearch` keeps its current job: the status facts are independent of the dispatch.

- [ ] **Step 4: Document why `unreadProc` and `tagsProc` stay as they are**

A comment on each: the command is a static binding, so a no-op re-arm merely skips a redundant identical run and the next poll recovers. Routing them would add state for no behaviour.

- [ ] **Step 5: Run the gate**

Run: `nix develop --command just ci`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/view/Notmuch.qml tests/tst_service.qml
git commit -m "fix(view): never drop a search when one is already in flight

Closes #10 for searchProc; tagProc and countProc follow."
```

---

### Task 3: FIFO queue for tag mutations

The data-loss case. Not reported in any issue.

**Files:**
- Modify: `src/model/service.js`
- Modify: `tests/tst_service.qml`
- Modify: `src/view/Notmuch.qml` — `tag`, `tagProc`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `newTagQueue()` → `{inflight: null, pending: []}`
  - `requestTag(queue, op, inflightAlive)` → `{queue, dispatch}` — `op` is opaque to `service.js` (`Notmuch.qml` passes `{id, ops}`); `dispatch` is the op to run now or `null`. A falsy `op` is a no-op. A dead inflight (`inflight` set, `inflightAlive` false) is abandoned and the queue proceeds, as in `requestFlight`.
  - `tagEvent(queue)` → `{queue, completed, dispatch}` — one signal (exit) ends a mutation; `completed` is the op that finished, `dispatch` the next or `null`.

- [ ] **Step 1: Write the failing tests**

```qml
function test_requestTag_queuesEveryMutationInOrder() {
    var q = Svc.requestTag(Svc.newTagQueue(), {"id": "A"}, false);
    compare(q.dispatch.id, "A");
    var b = Svc.requestTag(q.queue, {"id": "B"}, true);
    compare(b.dispatch, null);               // A is running
    var c = Svc.requestTag(b.queue, {"id": "C"}, true);
    compare(c.queue.pending.length, 2);      // B and C both kept — newest does NOT win
    var afterA = Svc.tagEvent(c.queue);
    compare(afterA.completed.id, "A");
    compare(afterA.dispatch.id, "B");        // FIFO
    compare(Svc.tagEvent(afterA.queue).dispatch.id, "C");
}

function test_tagEvent_drainsToEmpty() {
    var q = Svc.requestTag(Svc.newTagQueue(), {"id": "A"}, false).queue;
    var done = Svc.tagEvent(q);
    compare(done.dispatch, null);
    compare(done.queue.inflight, null);
}

// Review Focus 1: the exit code is deliberately not an input here. A failed mutation
// still advances the queue, so the archives behind it are not stranded.
function test_tagEvent_advancesWhateverTheOutcome() {
    var q = Svc.requestTag(Svc.newTagQueue(), {"id": "A"}, false).queue;
    q = Svc.requestTag(q, {"id": "B"}, true).queue;
    compare(Svc.tagEvent(q).dispatch.id, "B");
}

function test_requestTag_emptyOpIsNoop() {          // Review Focus 5
    compare(Svc.requestTag(Svc.newTagQueue(), null, false).dispatch, null);
}

function test_requestTag_deadInflightIsAbandoned() {
    var q = Svc.requestTag(Svc.newTagQueue(), {"id": "A"}, false).queue;
    compare(Svc.requestTag(q, {"id": "B"}, false).dispatch.id, "B");
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `nix develop --command just test`
Expected: FAIL with `newTagQueue is not a function`.

- [ ] **Step 3: Implement the three functions in `src/model/service.js`**

New section, `--- tag mutations ---`, with a comment stating why the policy differs from the flight machine: each mutation is a distinct side effect on the database, so "newest wins" here would be data loss.

- [ ] **Step 4: Run to verify they pass**

Run: `nix develop --command just test`
Expected: PASS.

- [ ] **Step 5: Rewire `tagProc` in `src/view/Notmuch.qml`**

`tag(threadId, ops)` requests `{id: threadId, ops: ops}`; `_dispatchTag(op)` builds the command via `Queries.tagThread(op.id, op.ops)` and starts the process. `tagProc.onExited` advances the queue **whatever the exit code** — Review Focus #1 — setting `status = "error"` on a non-zero code without stopping the drain. `refresh()` is called once, when `tagEvent` returns `dispatch === null`: the queue has drained and one refresh covers every mutation in it.

- [ ] **Step 6: Run the gate**

Run: `nix develop --command just ci`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/model/service.js src/view/Notmuch.qml tests/tst_service.qml
git commit -m "fix(view): queue tag mutations instead of dropping all but the first

Archiving several threads in quick succession silently lost every mutation
after the first: tag() re-armed a running Process, which is a no-op."
```

---

### Task 4: Counts sequencer, and two-signal completion for `countProc`

Fixes the permanent latch: `_startCounts` re-arms from `onStreamFinished` alone, and `service.js` already documents that the stream/exit order is not guaranteed.

**Files:**
- Modify: `src/model/service.js`
- Modify: `tests/tst_service.qml`
- Modify: `src/view/Notmuch.qml` — `refreshCounts`, `_startCounts`, `countProc`

**Interfaces:**
- Consumes: `newFlight`, `flightEvent` (Task 1) to gate one run's completion.
- Produces:
  - `newCountSeq()` → `{keys: [], queries: [], index: 0, acc: {}, running: false, restart: false}`
  - `startCounts(seq, defs)` → `{seq, dispatch}` — `defs` is the definitions array (each with `key` and `query`). While `seq.running`, records `restart` and dispatches `""`. An empty `defs` dispatches `""` and is not running.
  - `countCompleted(seq, count)` → `{seq, dispatch, counts, restartNeeded}` — records `count` under the current key and advances. `counts` is the finished accumulator or `null` while the sequence runs. A completion arriving when `!seq.running` is ignored entirely (Review Focus #3).

- [ ] **Step 1: Write the failing tests**

```qml
function test_startCounts_walksEveryDefinitionInOrder() {
    var defs = [{"key": "inbox", "query": "tag:inbox"}, {"key": "flagged", "query": "tag:flagged"}];
    var s = Svc.startCounts(Svc.newCountSeq(), defs);
    compare(s.dispatch, "tag:inbox");
    var first = Svc.countCompleted(s.seq, 12);
    compare(first.dispatch, "tag:flagged");
    compare(first.counts, null);
    var second = Svc.countCompleted(first.seq, 3);
    compare(second.dispatch, "");
    compare(second.counts.inbox, 12);
    compare(second.counts.flagged, 3);
}

function test_startCounts_emptyDefsIsNoop() {       // Review Focus 5
    var s = Svc.startCounts(Svc.newCountSeq(), []);
    compare(s.dispatch, "");
    compare(s.seq.running, false);
}

function test_startCounts_restartsAfterTheRunningSequence() {
    var defs = [{"key": "inbox", "query": "tag:inbox"}];
    var s = Svc.startCounts(Svc.newCountSeq(), defs);
    var again = Svc.startCounts(s.seq, defs);
    compare(again.dispatch, "");                     // nothing starts mid-sequence
    compare(Svc.countCompleted(again.seq, 1).restartNeeded, true);
}

function test_countCompleted_afterAbandonIsIgnored() {   // Review Focus 3
    var done = Svc.countCompleted(Svc.newCountSeq(), 99);
    compare(done.counts, null);
    compare(done.dispatch, "");
    compare(Object.keys(done.seq.acc).length, 0);
}
```

- [ ] **Step 2: Run to verify they fail**

Run: `nix develop --command just test`
Expected: FAIL with `newCountSeq is not a function`.

- [ ] **Step 3: Implement the three functions in `src/model/service.js`**

- [ ] **Step 4: Run to verify they pass**

Run: `nix develop --command just test`
Expected: PASS.

- [ ] **Step 5: Rewire `countProc` in `src/view/Notmuch.qml`**

The closure-based `step()` and the `_counting` / `_countPending` / `_countCb` booleans go away, replaced by `_countSeq` plus a `_countFlight`. `countProc` gains an `onExited` handler; both signals feed `Svc.flightEvent`, and only a completed flight calls `Svc.countCompleted(_countSeq, Model.parseCount(text))`. The collected stdout is held in a property the way `_snippetText` already is, since the stream may land before the exit. `counts` is assigned when `countCompleted` returns a non-null accumulator; `restartNeeded` triggers `startCounts` again with the current `definitions`.

- [ ] **Step 6: Run the gate**

Run: `nix develop --command just ci`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/model/service.js src/view/Notmuch.qml tests/tst_service.qml
git commit -m "fix(view): stop the counts sequence latching for the session

countProc re-armed on onStreamFinished alone. When the stream finished before
the exit, the re-arm was a no-op, the sequence stopped and _counting stayed
true forever: no rail counter updated again."
```

---

### Task 5: Attachment indicator

Issue #6, exactly as specified. View-only; per PROCEDURE_PLANS.md §6 the expected outcome is written here, before the code.

**Files:**
- Modify: `src/view/ThreadRow.qml` — the `Row` holding the chips and the flag `DankIcon`, around line 216

**Interfaces:**
- Consumes: nothing. Uses `row.thread.tags`, already flowing.
- Produces: nothing.

- [ ] **Step 1: Write the manual verification, before the code**

Add to the plan's manual list below: a thread tagged `attachment` shows a paperclip beside the chips, distinct from and not replacing the flag icon; a thread without the tag shows no icon and the surrounding chips do not shift.

- [ ] **Step 2: Add the icon**

A second `DankIcon` in the same `Row` as the flag one, same `size` and pattern, `name: "attach_file"`, `color: Theme.surfaceTextMedium`, `visible: row.thread.tags && row.thread.tags.indexOf("attachment") !== -1`. No change to `src/model/threads.js` or `src/query/queries.js`: `attachment` stays in `DEFAULT_TAG_BLOCKLIST`.

- [ ] **Step 3: Run the gate**

Run: `nix develop --command just ci`
Expected: PASS, and no golden moves — this touches no model.

- [ ] **Step 4: Commit**

```bash
git add src/view/ThreadRow.qml docs/superpowers/plans/2026-10-18-contracts-pass.md
git commit -m "feat(view): show an attachment indicator on thread rows

Closes #6."
```

---

### Task 6: The manifest gate

Written before the manifest it checks, so it starts RED against today's `plugin.json`.

**Files:**
- Create: `tests/vendor/dms-plugin-schema-v1.5.3.json`
- Create: `scripts/check-manifest`
- Modify: `Justfile` — the `lint` recipe

**Interfaces:**
- Consumes: nothing.
- Produces: `scripts/check-manifest`, exit 0 on a conformant manifest, non-zero with one message per violation.

- [ ] **Step 1: Vendor DMS's schema**

Copy `PLUGINS/plugin-schema.json` from DMS v1.5.3 verbatim. The version in the filename is the provenance record; do not edit the contents.

- [ ] **Step 2: Write `scripts/check-manifest`**

Bash plus `jq` — both already in the dev shell, so the gate stays hermetic and gains no dependency. Reads `plugin.json` and the vendored schema and asserts, driving the first three from the schema so the check tracks upstream rather than restating it:

1. every field in `schema.required` is present;
2. every key in the manifest appears in `schema.properties`;
3. `type` is within its enum, and every entry of `permissions` is within its items enum;
4. the deprecated `requires` key is absent;
5. `requires_dms` is present and matches the schema's own `pattern`;
6. the relative paths in `component`, `settings` and `startupCheck` exist on disk.

- [ ] **Step 3: Wire it into the gate**

Append to the `lint` recipe in `Justfile`, after `qmllint`. `lint` becomes a multi-line recipe in the same style as `fmt-check`.

- [ ] **Step 4: Run it to verify it fails**

Run: `nix develop --command just lint`
Expected: FAIL on two counts — deprecated `requires` present, `requires_dms` missing.

- [ ] **Step 5: Commit**

Committing a red gate is deliberate: Task 7 is what turns it green, and splitting them is what makes the gate demonstrably able to fail. The two tasks land together on the branch; neither is pushed alone.

```bash
git add tests/vendor/dms-plugin-schema-v1.5.3.json scripts/check-manifest Justfile
git commit -m "test(nix): check plugin.json against DMS's published plugin schema"
```

---

### Task 7: Declare the host contract

**Files:**
- Create: `src/view/StartupCheck.qml`
- Modify: `plugin.json`
- Modify: `README.md`

**Interfaces:**
- Consumes: `scripts/check-manifest` (Task 6).
- Produces: `src/view/StartupCheck.qml`, a `QtObject` exposing `check(done)` — `done(null)` allows activation, `done({title, details})` blocks it.

- [ ] **Step 1: Write the manual verification, before the code**

Added to the manual list below: with `notmuch` removed from `PATH`, enabling the plugin in DMS shows the blocking message rather than loading a broken widget; with notmuch present, activation is unchanged.

- [ ] **Step 2: Write `src/view/StartupCheck.qml`**

A `QtObject` with a `Process` running `notmuch count --output=threads '*'`. Exit 0 → `done(null)`. Non-zero or failure to start → `done({title, details})`. Covering Review Focus #2, a `Timer` of 5000 ms calls `done()` with a timeout message if neither signal has landed, and `done` is guarded so it fires exactly once whichever path gets there first — a probe that never answers must not leave activation hanging.

French copy, per the language rule. Title: `"notmuch est introuvable"` when the process cannot start, `"La base notmuch est illisible"` on a non-zero exit, `"notmuch ne répond pas"` on timeout. Details carry the exit code or the stderr line when there is one.

- [ ] **Step 3: Update `plugin.json`**

Add `"requires_dms": ">=1.5.0"` and `"startupCheck": "./src/view/StartupCheck.qml"`. Replace `"requires": ["notmuch"]` with `"dependencies": ["notmuch"]` — the non-deprecated spelling, and the one the plugin browser displays. Set `"version": "0.9.0"`.

- [ ] **Step 4: Run the gate to verify it now passes**

Run: `nix develop --command just ci`
Expected: PASS, including the manifest check that failed in Task 6.

- [ ] **Step 5: State the floor in `README.md`**

One line in the install section: astropath requires DankMaterialShell ≥ 1.5.0, and why — `startupCheck` is the mechanism that reports a broken notmuch, and it landed in DMS 1.5.0.

- [ ] **Step 6: Commit**

```bash
git add plugin.json src/view/StartupCheck.qml README.md
git commit -m "feat(nix): declare the DMS floor and gate activation on notmuch

requires_dms is enforced by DMS since 1.2.0; startupCheck, which reports an
unusable notmuch at activation, needs 1.5.0. The former \"requires\" key was a
deprecated alias the loader never read."
```

---

### Task 8: Close out

**Files:**
- Modify: `docs/superpowers/plans/2026-10-18-contracts-pass.md` — the manual validation section

- [ ] **Step 1: Run the manual list**

Below. Record the date, which boxes were exercised and which were not, and why.

- [ ] **Step 2: Independent review**

`superpowers:requesting-code-review` over the whole branch.

- [ ] **Step 3: Close #8 with its evidence**

A comment recording the measurement — DMS's `StyledText` has pinned `textFormat: Text.PlainText` since v0.0.1, unbroken across 76 tags; astropath routes every mail-derived string through it; `requires_dms: ">=1.5.0"` now declares the floor — then close as not planned. No code change.

- [ ] **Step 4: Integrate**

`superpowers:finishing-a-development-branch`: `git merge --no-ff` into `main`, then `git-cliff --tag v0.9.0`, a signed tag, and push.

---

## Manual validation

Run at the close of the plan; `just dev-bar` from the worktree, one dev bar at a time, `just reload` after each change.

- [ ] Clicking a rail category while a poll-triggered search is in flight ends with the list showing the newest query's results, not the previous one's.
- [ ] Typing a free-text search during a poll behaves the same.
- [ ] Archiving three threads in rapid succession removes all three from the inbox.
- [ ] A tag mutation that fails does not prevent the ones queued behind it from running.
- [ ] Rail counters still update after a long session with heavy navigation (the latch is gone).
- [ ] With `notmuch` removed from `PATH`, enabling the plugin shows the blocking message; with it present, activation is unchanged.
- [ ] A thread tagged `attachment` shows a paperclip beside the chips, distinct from the flag icon.
- [ ] A thread without the tag shows no icon, and the surrounding chips do not shift.
