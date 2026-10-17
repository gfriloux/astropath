# Plan v0.8.0 — Testable service logic

> **For agentic workers:** REQUIRED SUB-SKILL: use `superpowers:subagent-driven-development`
> (recommended) or `superpowers:executing-plans` to implement this plan task by task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Type:** refactor + bug (model + view + doc)
**Goal:** move the algorithmic logic still trapped in `src/view/*.qml` into pure `.js`
modules covered by `just ci`, and fix the three races/collisions that gap allowed to live
(GitHub #9, #5, #4, #7).
**Why:** `qmltestrunner -input tests` only ever reaches `src/model/` and `src/query/`.
Logic written inside `Process`/`PluginSettings` wiring has 0 % coverage, and all three
bugs in this plan are symptoms of that, not independent accidents.
**Stage(s):** `model` · `view` · `doc`

**Issues closed:** #9 (untested `CategorySettings` logic), #5 (custom key collision
overwrites counts), #4 (search status stdout/stderr race), #7 (stale snippet attribution).

**Spec:** this document (approved in chat, 2026-10-17). `DESIGN.md` stays authoritative
on invariants; nothing here touches them.

---

## Global constraints

- Enter the Nix shell for every command: `nix develop --command just ci`.
- Branch `refactor/v0.8.0-testable-logic`, off an up-to-date `main`. Claude never runs
  `merge`/`push`/`tag`.
- Docs are updated **in the same commit** as the code they describe
  (`DESIGN.md:85-90`, `README.md:71-74` describe the module map).
- **Every commit passes `just ci` on its own.** Consequence: a task writes its test and
  its implementation in the *same* commit. TDD still applies inside the task — run the
  test and watch it fail before implementing — it just does not get its own commit
  (`PROCEDURE_PLANS.md` §5's two-commit recipe cannot satisfy §3's green-per-commit rule).
- New modules are `.pragma library`, pure: same input → same output, no QML types, no
  `Date.now()`, no I/O. Objects in, new objects out — **never mutate an argument**
  (QML passes bindings by reference).
- UI copy stays French (`CLAUDE.md`). Code, comments, docs and commit messages: English.
- No new notmuch query, no new `Process`, no change to the on-disk settings schema
  (`tagOverrides`, `customSearches` keep their shape).
- The four existing goldens must not move. If one does, the change was not what this plan
  says it is — stop.

## Review focus

Input classes this plan's behavior depends on, each pinned by a test in the task that owns
the code:

1. `patchOverride` must not mutate the array it is handed — QML holds the same reference
   in `editor.overrides` (Task 1).
2. A derived key colliding twice (`boulot`, `boulot-2` both taken) must land on
   `boulot-3`, not loop or overwrite (Task 2).
3. A collision against a *hidden* discovered tag must still be avoided — hiding is
   reversible, so the collision would resurface on unhide. This one is a wiring choice,
   not a pure function: it is pinned by Task 2 Step 5 (which set of taken keys is passed)
   and by `manual_tests.md`, not by a unit test.
4. `notmuch search` exits 0, prints valid JSON **and** writes to stderr → `idle`
   (this is the whole of #4), while exit 0 + unparsable stdout → `error` (Task 3).
5. The `exited` and `streamFinished` signals arrive in **either** order; neither snippet
   attribution nor queue advancement may depend on which came first (Task 4).

---

## File structure

| File | Responsibility |
|---|---|
| `src/model/overrides.js` *(new)* | Settings algebra: tag-override lookup, merge/prune, custom-key derivation + uniqueness. Plain data in, plain data out. |
| `src/model/service.js` *(new)* | Notmuch service decisions: search status from observed facts, lazy-snippet request ordering. State machines as pure functions. |
| `src/model/threads.js` | Defensive key de-duplication in `buildDefinitions`. |
| `src/view/CategorySettings.qml` | Keeps only `Process`/`PluginSettings` glue; calls `overrides.js`. |
| `src/view/Notmuch.qml` | Keeps only `Process` wiring; calls `service.js`. |
| `tests/tst_overrides.qml` *(new)* | Unit tests for `overrides.js`. |
| `tests/tst_service.qml` *(new)* | Unit tests for `service.js`. |
| `tests/tst_model.qml` | One added case for `buildDefinitions` de-duplication. |
| `DESIGN.md` / `README.md` | Module map kept in sync. |

No golden/fixture is added: these transforms take hand-written plain data, not frozen
notmuch output. The golden harness stays reserved for notmuch-shaped input
(`PROCEDURE_PLANS.md` §4).

---

## Task 1 — Extract the category-override algebra (#9)

**Files:**
- Create: `src/model/overrides.js`
- Create: `tests/tst_overrides.qml`
- Modify: `src/view/CategorySettings.qml:45-93` (`overrideFor`, `patchOverride`)
- Modify: `DESIGN.md:87-89`, `README.md:72-73` (module map)

**Interfaces — produces:**

```js
overrideFor(overrides, tag)          // → the entry with that tag, or null
patchOverride(overrides, tag, patch) // → a NEW array; merge, strip falsy
                                     //   label/color/hidden, drop an entry reduced to {tag}
deriveKey(label)                     // → label.toLowerCase() with whitespace runs → "-"
```

`deriveKey` is used by Task 2; nothing else consumes this module.

- [ ] **Step 1: Write the failing tests** in `tests/tst_overrides.qml` (`TestCase`,
      `name: "overrides"`, importing `"../src/model/overrides.js" as Ov`):

```qml
function test_overrideFor() {
    var ovs = [{"tag": "boulot", "color": "#cba6f7"}, {"tag": "perso"}];
    compare(Ov.overrideFor(ovs, "boulot").color, "#cba6f7");
    compare(Ov.overrideFor(ovs, "absent"), null);
    compare(Ov.overrideFor([], "boulot"), null);
}

function test_patchOverride_addsEntry() {
    var a = Ov.patchOverride([], "boulot", {"label": "Taf"});
    compare(a.length, 1);
    compare(a[0].tag, "boulot");
    compare(a[0].label, "Taf");
}

function test_patchOverride_mergesKeepingOtherFields() {
    var a = Ov.patchOverride([{"tag": "boulot", "label": "Taf"}], "boulot", {"color": "#a6e3a1"});
    compare(a[0].label, "Taf");
    compare(a[0].color, "#a6e3a1");
}

function test_patchOverride_clearingLabelDropsTheField() {
    var a = Ov.patchOverride([{"tag": "boulot", "label": "Taf", "color": "#a6e3a1"}], "boulot", {"label": ""});
    verify(a[0].label === undefined);
    compare(a[0].color, "#a6e3a1");
}

function test_patchOverride_pruneToBareRemovesEntry() {
    var a = Ov.patchOverride([{"tag": "boulot", "label": "Taf"}], "boulot", {"label": ""});
    compare(a.length, 0);
}

function test_patchOverride_hideThenUnhide() {
    var hidden = Ov.patchOverride([], "boulot", {"hidden": true});
    compare(hidden[0].hidden, true);
    compare(Ov.patchOverride(hidden, "boulot", {"hidden": false}).length, 0);
}

// Review focus 1: editor.overrides is handed over by reference.
function test_patchOverride_doesNotMutateInput() {
    var input = [{"tag": "boulot", "label": "Taf"}];
    Ov.patchOverride(input, "boulot", {"label": ""});
    compare(input.length, 1);
    compare(input[0].label, "Taf");
}

function test_deriveKey() {
    compare(Ov.deriveKey("Boulot"), "boulot");
    compare(Ov.deriveKey("  Urgent   client "), "-urgent-client-");
    compare(Ov.deriveKey("À trier"), "à-trier");
}
```

> `deriveKey` is the *existing* `l.toLowerCase().replace(/\s+/g, "-")` behavior, applied to
> an already-trimmed label (the Add button trims). The middle assertion documents what it
> does to untrimmed input rather than silently changing it.

- [ ] **Step 2: Run the tests and watch them fail**

Run: `nix develop --command just test`
Expected: FAIL — `overrides.js` does not exist.

- [ ] **Step 3: Implement `src/model/overrides.js`**

`.pragma library`, header comment stating the module is pure and mirrors
`threads.js`'s role for settings data. The merge/prune algorithm is the one currently in
`CategorySettings.qml:53-79`, minus the `findSettings()/saveValue` I/O: copy the array,
merge onto `{tag}` or the existing entry, `delete` falsy `label`/`color`/`hidden`, and
treat `Object.keys(merged).length === 1` as "nothing left to amend" → remove (or never
add) the entry.

- [ ] **Step 4: Rewire `CategorySettings.qml`**

Import the module (`import "../model/overrides.js" as Ov`, next to the existing
`threads.js` import). `overrideFor(tag)` and `patchOverride(tag, patch)` keep their current signatures and
call sites (`tagRow.ov`, the three `patchOverride` handlers) — they become one-liners
delegating to `Ov.*` and, for `patchOverride`, assigning the result and persisting it via
`findSettings().saveValue("tagOverrides", …)`. Behavior is identical; this is the
refactor half of the task.

- [ ] **Step 5: Update the module map**

`DESIGN.md:87-89` and `README.md:72-73` list the `model` modules — add `overrides.js`
(settings algebra, pure, unit-tested) alongside `threads.js`/`format.js`.

- [ ] **Step 6: Verify**

Run: `nix develop --command just ci`
Expected: PASS, test total 24 → 32, **no golden moved**.

- [ ] **Step 7: Commit**

```bash
git add src/model/overrides.js tests/tst_overrides.qml src/view/CategorySettings.qml DESIGN.md README.md
git commit -m "refactor(model): extract the category override algebra into a pure module"
```

---

## Task 2 — Keep saved-search keys unique (#5)

**Files:**
- Modify: `src/model/overrides.js` (add `uniqueKey`)
- Modify: `src/model/threads.js:120` (`buildDefinitions` return)
- Modify: `tests/tst_overrides.qml`, `tests/tst_model.qml`
- Modify: `src/view/CategorySettings.qml:283-299` (Add button)

**Interfaces — consumes:** `deriveKey` (Task 1). **Produces:**

```js
uniqueKey(label, takenKeys)  // → deriveKey(label), suffixed "-2", "-3", … until free
```

- [ ] **Step 1: Write the failing tests**

In `tests/tst_overrides.qml`:

```qml
function test_uniqueKey_freeKeyIsUnchanged() {
    compare(Ov.uniqueKey("Boulot", ["perso", "factures"]), "boulot");
    compare(Ov.uniqueKey("Boulot", []), "boulot");
}

function test_uniqueKey_collidingKeyIsSuffixed() {
    compare(Ov.uniqueKey("Boulot", ["boulot"]), "boulot-2");
}

// Review focus 2.
function test_uniqueKey_repeatedCollisionWalksUp() {
    compare(Ov.uniqueKey("Boulot", ["boulot", "boulot-2"]), "boulot-3");
}
```

In `tests/tst_model.qml`:

```qml
function test_buildDefinitions_dedupesByKey() {
    // A custom search keyed like a discovered tag must not yield two rail entries
    // sharing one count slot: the first occurrence wins.
    var defs = Model.buildDefinitions(["boulot"], {
        "custom": [{"key": "boulot", "label": "Boulot urgent", "query": "tag:boulot and tag:unread", "color": "#f38ba8"}]
    });
    compare(defs.length, 1);
    compare(defs[0].query, "tag:boulot");
}
```

- [ ] **Step 2: Run the tests and watch them fail**

Run: `nix develop --command just test`
Expected: FAIL — `uniqueKey` undefined; `buildDefinitions` returns 2 entries.

- [ ] **Step 3: Implement `uniqueKey(label, takenKeys)` in `src/model/overrides.js`**

Start from `deriveKey(label)`; while the candidate is in `takenKeys`, try
`base + "-" + n` with `n` from 2 upward. `takenKeys` may be undefined → treat as empty.

- [ ] **Step 4: De-duplicate in `buildDefinitions`**

`src/model/threads.js:120` currently returns `universals.concat(discovered).concat(custom)`.
Filter that concatenation to the first occurrence of each `key`, so a future caller cannot
reintroduce the collision. Document in the comment above the function that de-duplication
is defensive — uniqueness is enforced at entry, in the settings.

- [ ] **Step 5: Use `uniqueKey` in the Add button**

`CategorySettings.qml:290-295` builds `{key: l.toLowerCase().replace(/\s+/g, "-"), …}`.
Replace with `Ov.uniqueKey(l, taken)` where `taken` = `editor.discoveredTags` concatenated
with the existing `editor.customs` keys. Use `editor.discoveredTags` as it stands — it is
the full discovered list minus `DEFAULT_TAG_BLOCKLIST`, so it includes tags currently
hidden by an override (review focus 3: hiding is reversible, the key must stay reserved).
The user-typed `label` is stored untouched; only the internal key is suffixed.

- [ ] **Step 6: Verify**

Run: `nix develop --command just ci`
Expected: PASS. The `discovered-searches` golden has no colliding key, so it **must not
move** — if it does, the de-duplication is wrong.

- [ ] **Step 7: Commit**

```bash
git add src/model/overrides.js src/model/threads.js tests/tst_overrides.qml tests/tst_model.qml src/view/CategorySettings.qml
git commit -m "fix(model): keep saved-search keys unique so counts cannot collide"
```

---

## Task 3 — The exit code decides the search status (#4)

**Files:**
- Create: `src/model/service.js`
- Create: `tests/tst_service.qml`
- Modify: `src/view/Notmuch.qml:62-66` (`runSearch`), `:201-230` (`searchProc`)
- Modify: `DESIGN.md:85-90`, `README.md:72-73` (module map)

**Interfaces — produces:**

```js
newSearchRun()           // → {exited: false, exitCode: 0, stdoutDone: false, parseOk: false}
decideSearchStatus(run)  // → "querying" | "idle" | "error"
```

`decideSearchStatus` rules, in order: not `exited` → `"querying"`; `exitCode !== 0` →
`"error"`; not `stdoutDone` → `"querying"`; `parseOk` → `"idle"`; else `"error"`.
**stderr is never an input** — the caller logs it, it does not decide anything.

This shape is what makes the fix order-independent: the two `StdioCollector` handlers and
`onExited` each record a *fact* about the run, and the status is recomputed from the facts
every time one lands. Whoever fires last reaches the same answer.

- [ ] **Step 1: Write the failing tests** in `tests/tst_service.qml` (`TestCase`,
      `name: "service"`, importing `"../src/model/service.js" as Svc`):

```qml
function test_decideSearchStatus_pendingWhileRunning() {
    var run = Svc.newSearchRun();
    compare(Svc.decideSearchStatus(run), "querying");
    run.stdoutDone = true;
    run.parseOk = true;
    compare(Svc.decideSearchStatus(run), "querying"); // parsed, but not exited yet
}

// Review focus 4 / the issue itself: benign stderr must not mask a good run.
function test_decideSearchStatus_idleOnCleanExitWhateverStderr() {
    compare(Svc.decideSearchStatus({"exited": true, "exitCode": 0, "stdoutDone": true, "parseOk": true}), "idle");
}

function test_decideSearchStatus_errorOnNonZeroExit() {
    compare(Svc.decideSearchStatus({"exited": true, "exitCode": 1, "stdoutDone": true, "parseOk": true}), "error");
}

function test_decideSearchStatus_errorOnUnparsableStdout() {
    compare(Svc.decideSearchStatus({"exited": true, "exitCode": 0, "stdoutDone": true, "parseOk": false}), "error");
}

function test_decideSearchStatus_waitsForStdout() {
    compare(Svc.decideSearchStatus({"exited": true, "exitCode": 0, "stdoutDone": false, "parseOk": false}), "querying");
}
```

- [ ] **Step 2: Run the tests and watch them fail**

Run: `nix develop --command just test`
Expected: FAIL — `service.js` does not exist.

- [ ] **Step 3: Implement `src/model/service.js`**

`.pragma library`, header comment: pure decisions for the notmuch service, so the
`Process` wiring in `Notmuch.qml` holds glue only. Implement the two functions above.

- [ ] **Step 4: Rewire `searchProc` in `Notmuch.qml`**

Import the module (`import "../model/service.js" as Svc`) and add
`property var _searchRun: Svc.newSearchRun()`. `runSearch()` resets it before
starting (`root._searchRun = Svc.newSearchRun()`) and sets `status = "querying"`.
Each of the three handlers records its fact into a copy of `_searchRun`, reassigns it,
then sets `root.status = Svc.decideSearchStatus(root._searchRun)`:

- stdout `onStreamFinished`: `stdoutDone = true`; on successful parse also
  `parseOk = true` and assign `root.threads` / `root.lastSyncAt` as today; on exception,
  `parseOk` stays false and the existing `console.warn` is kept.
- stderr `onStreamFinished`: keeps `console.warn("astropath notmuch:", text.trim())` for
  non-empty text and **nothing else** — no status assignment.
- `onExited`: `exited = true`, `exitCode = code`.

`lastSyncAt` keeps being stamped on a successful parse (it is a timestamp of data, not of
status).

- [ ] **Step 5: Update the module map**

Add `service.js` next to `overrides.js` in `DESIGN.md:87-89` and `README.md:72-73`, and
note at `DESIGN.md:85-86` that `Notmuch.qml` executes but no longer decides.

- [ ] **Step 6: Verify**

Run: `nix develop --command just ci`
Expected: PASS, no golden moved.

- [ ] **Step 7: Commit**

```bash
git add src/model/service.js tests/tst_service.qml src/view/Notmuch.qml DESIGN.md README.md
git commit -m "fix(view): decide the search status from the exit code only"
```

---

## Task 4 — Serialise the lazy snippet fetches (#7)

**Files:**
- Modify: `src/model/service.js`, `tests/tst_service.qml`
- Modify: `src/view/Notmuch.qml:173-198` (`fetchSnippet`, `showProc`)

**Interfaces — consumes:** nothing from Task 3 beyond the module. **Produces:**

```js
newSnippetQueue()                  // → {inflight: "", pending: "", textReady: false, exited: false}
requestSnippet(queue, id, isCached)// → {queue: <new>, dispatch: "<id to run>" | ""}
snippetEvent(queue, ev)            // ev: "stream" | "exit"
                                   // → {queue: <new>, completedId: "<id to attribute>" | "", dispatch: "" | "<id>"}
```

Semantics — one request in flight, at most one pending (always the newest):

- `requestSnippet`: empty `id`, `isCached`, or `id === queue.inflight` → no change,
  `dispatch: ""`. Nothing in flight → `inflight = id`, `dispatch = id`. Something in
  flight → `pending = id` (overwriting any previous pending), `dispatch: ""`.
- `snippetEvent`: records the signal (`textReady` or `exited`). While both are not in,
  `completedId: ""`, `dispatch: ""`. Once both are in: `completedId` = the id that was in
  flight, then the queue advances — `pending` becomes `inflight` (flags reset) and is
  returned as `dispatch`, or the queue goes idle.

A request superseded while pending is dropped on purpose (its row is no longer the current
one; re-selecting it fires `onActiveChanged` → `fetchSnippet` again). The newest request
always wins, and **no result can ever be attributed to a thread that did not ask for it.**

- [ ] **Step 1: Write the failing tests** in `tests/tst_service.qml`:

```qml
function test_requestSnippet_dispatchesWhenIdle() {
    var r = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false);
    compare(r.dispatch, "A");
    compare(r.queue.inflight, "A");
}

function test_requestSnippet_cachedOrEmptyIsNoop() {
    compare(Svc.requestSnippet(Svc.newSnippetQueue(), "A", true).dispatch, "");
    compare(Svc.requestSnippet(Svc.newSnippetQueue(), "", false).dispatch, "");
}

function test_requestSnippet_queuesNewestWhileInflight() {
    var q = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false).queue;
    var b = Svc.requestSnippet(q, "B", false);
    compare(b.dispatch, "");          // A is still running: nothing is started
    compare(b.queue.inflight, "A");   // and A is NOT overwritten
    var c = Svc.requestSnippet(b.queue, "C", false);
    compare(c.queue.pending, "C");    // newest pending wins
}

function test_requestSnippet_sameIdInflightIsNoop() {
    var q = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false).queue;
    compare(Svc.requestSnippet(q, "A", false).dispatch, "");
}

// Review focus 5: both signal orders must complete identically.
function test_snippetEvent_completesOnEitherSignalOrder() {
    var orders = [["stream", "exit"], ["exit", "stream"]];
    for (var i = 0; i < orders.length; i++) {
        var q = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false).queue;
        var first = Svc.snippetEvent(q, orders[i][0]);
        compare(first.completedId, "");  // one signal is not enough
        var second = Svc.snippetEvent(first.queue, orders[i][1]);
        compare(second.completedId, "A");
        compare(second.queue.inflight, "");
    }
}

function test_snippetEvent_dispatchesPendingOnCompletion() {
    var q = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false).queue;
    q = Svc.requestSnippet(q, "B", false).queue;
    var done = Svc.snippetEvent(Svc.snippetEvent(q, "stream").queue, "exit");
    compare(done.completedId, "A");
    compare(done.dispatch, "B");
    compare(done.queue.inflight, "B");
    compare(done.queue.pending, "");
    compare(done.queue.textReady, false); // flags reset for the new run
}
```

- [ ] **Step 2: Run the tests and watch them fail**

Run: `nix develop --command just test`
Expected: FAIL — `newSnippetQueue` undefined.

- [ ] **Step 3: Implement the three functions in `src/model/service.js`**

- [ ] **Step 4: Rewire the snippet fetch in `Notmuch.qml`**

Replace `property string _snippetId` with `property var _snippetQueue: Svc.newSnippetQueue()`
and `property string _snippetText: ""`.

- `fetchSnippet(id)` → `var r = Svc.requestSnippet(root._snippetQueue, id, root.snippets[id] !== undefined); root._snippetQueue = r.queue; if (r.dispatch) _dispatchSnippet(r.dispatch);`
- `_dispatchSnippet(id)` → `root._snippetText = ""`, set `showProc.command` from
  `Queries.showThread(id)`, `showProc.running = true`.
- stdout `onStreamFinished` → store `root._snippetText = text`, then `_advanceSnippet("stream")`.
  **No parsing here**: the id to attribute is only known once the run is complete.
- `onExited` → `_advanceSnippet("exit")`.
- `_advanceSnippet(ev)` → call `Svc.snippetEvent`, reassign `root._snippetQueue`; if
  `completedId` is non-empty, parse `root._snippetText` with `Model.parseShow(JSON.parse(…))`
  inside the existing `try/catch` (keeping `console.warn("astropath: show parse failed:", e)`)
  and store the snippet under `completedId` in a copied `root.snippets`; then, if
  `dispatch` is non-empty, `_dispatchSnippet(dispatch)`.

Setting `running = true` now only ever happens on a process that has exited, which is
what the no-op bug in the issue was about.

- [ ] **Step 5: Verify**

Run: `nix develop --command just ci`
Expected: PASS, no golden moved.

- [ ] **Step 6: Commit**

```bash
git add src/model/service.js tests/tst_service.qml src/view/Notmuch.qml
git commit -m "fix(view): serialise lazy snippet fetches so results cannot be misattributed"
```

---

## Task 5 — Close the version

**Files:**
- Modify: `plugin.json:5`
- Modify: `.claude/plans/v0.8.0/manual_tests.md` (checked off during the run)

- [ ] **Step 1: Run the manual tests** in `manual_tests.md` (`just run` / `just dev-bar`,
      then `just reload` — purge `qmlcache`, the rendering sticks otherwise).
- [ ] **Step 2: Bump `plugin.json` version to `0.8.0`.**
- [ ] **Step 3: Verify** — `nix develop --command just ci`: PASS.
- [ ] **Step 4: Commit**

```bash
git add plugin.json .claude/plans/v0.8.0
git commit -m "chore: bump module version to 0.8.0"
```

---

## Technical decisions

- **Two modules, not one.** `overrides.js` is settings algebra, `service.js` is service
  orchestration; they have no shared type and no call between them. Keeping them apart
  keeps each file small enough to hold in one head (and in one review).
- **Facts, then a decision** (#4) rather than "whoever fires last wins". Deciding from
  recorded observations removes the signal-ordering dependency instead of betting on a
  particular order, which Quickshell does not guarantee for two streams of one process.
- **`status` stays `"querying"` until exit.** Today the UI flips to `idle` as soon as
  stdout parses. Waiting for the exit code is the point of the fix; the extra delay is a
  process teardown, invisible in practice.
- **Auto-suffixed keys** (#5), decided in chat: the typed label is kept intact and nothing
  is silently lost, where refusing the add would require inventing an error affordance
  that `CategorySettings.qml` does not have.
- **De-duplication in `buildDefinitions` is defensive, not the fix.** Uniqueness is
  enforced where keys are born (the Add button). The model-layer filter exists so a future
  caller cannot reintroduce the bug.
- **No new golden.** These functions take hand-written plain data; goldens are for
  notmuch-shaped fixtures (`PROCEDURE_PLANS.md` §4). Unit tests in `tests/tst_*.qml` are
  the right instrument.
- **Test-first inside a task, one commit out.** See Global constraints.

## Out of scope

- #6 (attachment indicator) and #8 (`textFormat`) — view-only, separate plan. Note for #8:
  DMS's `StyledText` already pins `textFormat: Text.PlainText`, so today's exposure is nil.
- **Adjacent, deliberately untouched:** `runSearch()` reassigns `searchProc.command` and
  sets `running = true` without checking whether a search is already in flight — the same
  QML no-op class as #7, on a different process. Task 3 does not change that behavior.
  Tracked as **#10**, to be fixed on top of this version's `service.js`.
- Any `DESIGN.md` invariant, the settings schema, the reading client, release tooling.

## Quality gates

- [ ] `nix develop --command just ci` green at every commit
- [ ] The four goldens unchanged (`git diff --stat tests/golden/` empty)
- [ ] Test total: 24 → ~47, including `tst_overrides` and `tst_service`
- [ ] `DESIGN.md` / `README.md` module map updated in the same commit as each new module
- [ ] Atomic commits on `refactor/v0.8.0-testable-logic`
- [ ] `manual_tests.md` run at closing
- [ ] Issues #9, #5, #4, #7 closed by the merge
