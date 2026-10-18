# Making the implicit contracts explicit

Design for the quality pass covering issues #10, #8 and #6.

Date: 2026-10-18 — Status: approved

## Intent

Nothing here is hurting daily use. This is a deliberate quality pass over the open
issues, and the investigation that preceded it reframed two of the three.

astropath relies on two contracts it never writes down. The **internal** one is how the
widget dispatches `notmuch` processes: five `Process` objects, each re-armed by hand,
each with its own idea of what happens when a request arrives while one is already
running. The **external** one is what astropath needs from its DankMaterialShell host:
the widget is a plugin dropped into an arbitrary DMS installation and declares nothing
about which DMS it requires, while the one dependency it *does* declare — notmuch — is
written in a manifest field the host does not read.

Both contracts work today by luck and by the author's memory. The job is to write them
down where something enforces them.

## What the investigation found

### #8 has no exposure, and the durable fix is a declared contract

The issue supposes that mail-derived strings reach `StyledText` with Qt's default
`Text.AutoText`, letting a hostile `Subject` render interpreted markup. Measured:

- DMS's `StyledText` sets `textFormat: Text.PlainText` explicitly, and has done since
  **v0.0.1** (2025-07-23) — unbroken across 76 tags and fifteen months of history.
  Verified in the upstream git history and in all four copies present in the Nix store
  (`dms-shell 1.5.3`, `DankCommon`, two further `quickshell/Widgets`).
- astropath renders every mail-derived string through `StyledText`: twenty instances,
  no bare `Text`, and no `textFormat` anywhere in `src/`.

The described path does not exist. #8 closes with this evidence, no code change.

Two fixes were considered and rejected, and the reasons matter more than the verdict:

**Sanitising in `threads.js` is the wrong layer.** This is a rendering-mode concern, not
a data concern. A subject that legitimately contains `<b>` must be *displayed* as `<b>`;
escaping at the model would render `&lt;b&gt;` under `PlainText`, and the golden would
freeze that fidelity loss permanently. The best-tested layer in the project is the wrong
place to put this.

**A local `MailText.qml` wrapper plus a CI rule forbidding direct `StyledText` for mail
text was rejected by the project owner, correctly.** It buys defence against a
low-probability upstream regression at the price of a permanent maintenance layer
between astropath and DMS — and a gate that would actively block adopting a
better-suited DMS widget later. astropath should not impede its own adoption of upstream
evolutions out of caution.

What replaces both: declare the host requirement in `plugin.json`, where DMS enforces it.

### The manifest is where the host contract belongs, and ours is partly inert

- **`requires_dms` is a first-class field.** Published schema
  (`PLUGINS/plugin-schema.json`, since DMS v0.1.15), semver-range pattern
  `^(>=?|<=?|=|>|<)\d+\.\d+\.\d+$`, and genuinely enforced since **v1.2.0** by
  `PluginService.checkPluginCompatibility()`: a warning banner in the Plugins tab and
  install gating in the plugin browser. astropath declares nothing.
- **`"requires": ["notmuch"]` in our manifest is inert.** DMS's schema classes it as a
  deprecated alias of `dependencies`; `PluginService.qml` reads neither; the plugin
  browser displays `dependencies` only. Our hard runtime dependency on notmuch is
  declared nowhere that has any effect.
- **The mechanism that works is `startupCheck`** (DMS ≥ v1.5.0): a path to a non-visual
  `QtObject` exposing `check(done)`. `done(null)` allows activation; `done({title,
  details})` blocks it with a message the user actually sees.

Against the published schema, the current `plugin.json` is otherwise valid: all required
fields present, `type` and `permissions` within their enums, no unknown keys.

### #10 is wider than written

The issue reports `searchProc`. Reading `Notmuch.qml`, the same no-op re-arm affects
five processes with three different severities:

| Process | Exposure |
|---|---|
| `searchProc` | As the issue describes. A rail click or free-text search landing while a poll-triggered search is in flight is silently dropped; the list keeps showing the previous query's results until the next poll. |
| `tagProc` | **The worst of the three, and unreported.** `tag()` sets `command` then `running = true` with no guard at all. Two keyboard actions in quick succession — archiving several threads in a row — and the second mutation is silently lost. The user believes they archived; nothing happened. This is the only case that loses a side effect rather than a read. |
| `countProc` | `_startCounts()` re-arms from `onStreamFinished` without waiting for `onExited`. `service.js` already documents that the firing order of those two signals is not guaranteed. When the stream finishes first, the re-arm is a no-op, the counting sequence stops mid-way and `_counting` stays `true` **for the rest of the session** — every later `refreshCounts()` just sets `_countPending`, and no rail counter ever updates again. |
| `unreadProc`, `tagsProc` | Benign. Static command, so the no-op merely skips a redundant identical run and the next poll recovers. |
| `showProc` | Already fixed in v0.8.0. |

### #6 is exactly as written

A view-layer addition using `Thread.tags`, already flowing. No model or query change.

## Goals

1. No notmuch request is silently dropped, for any process, under one discipline that is
   pure and unit-tested.
2. astropath's requirement on its host is declared in the manifest in the form DMS
   enforces.
3. A missing or unusable notmuch is reported when the plugin activates, with a message,
   instead of surfacing later as obscure breakage.
4. A manifest that drifts out of conformance with DMS's published schema fails `just ci`.
5. Threads carrying an attachment show it.
6. #8 closes with its evidence recorded.

## Non-goals

- Sanitising, escaping or stripping mail-derived data anywhere.
- Any local wrapper over a DMS widget, and any CI rule forbidding the direct use of DMS
  components.
- Migrating to the `components` multi-surface manifest. *(My call.)* astropath has one
  surface; `component` is a supported fallback path in `_resolveComponentPaths` with no
  deprecation warning anywhere in the loader. The migration would be churn.
- Any change to the notmuch query vocabulary or the model's tag semantics. `attachment`
  stays in `DEFAULT_TAG_BLOCKLIST`, per #6's own acceptance criteria.
- The UI language. Copy stays French, per CLAUDE.md; the i18n question is its own future
  plan.

## Anti-goals

These would mean failure even if every test passed:

- **A change that makes astropath harder to keep current with DMS.** This is the one that
  killed the wrapper. Any mechanism added here must track upstream, not fence it off.
- **A `requires_dms` floor higher than astropath genuinely needs.** It would lock out
  users for nothing.
- **Trading a silent drop for a silent queue-up.** A superseded request must be
  *deliberately* discarded, visible as such in the state machine — not quietly forgotten
  by a different mechanism.
- **A startup gate that fails open**, reporting nothing when notmuch is broken.

## Constraints

- `DESIGN.md` invariants hold: tag-only, notmuch as source of truth, account-agnostic.
- Changes to `query`/`model` go through a fixture and a golden (PROCEDURE_PLANS.md §5).
- The `Justfile` stays the only definition of the gates.
- Docs ship in the same commit as the code they describe.
- The dispatch logic must be a pure, unit-tested function in `src/model/service.js`, not
  new `Process` wiring — #10's own acceptance criterion, and consistent with how #7 was
  fixed. `tests/tst_service.qml` already exists for it.
- `just ci` must stay hermetic: no network at test time.

## The version floor

What astropath consumes from DMS, and when each landed upstream:

| Used by astropath | First DMS tag |
|---|---|
| `StyledText`, `DankIcon`, `DankTextField` | v0.0.1 |
| `DankListView` | v0.0.3 |
| `DankButton`, `PluginComponent`, `PluginSettings` | v0.0.28 |
| `plugin-schema.json` published | v0.1.15 |
| `requires_dms` enforced | v1.2.0 |
| `startupCheck` | **v1.5.0** |
| `components` multi-surface | v1.5.0 |

The current code's true floor is v0.0.28. Adopting `startupCheck` raises it to v1.5.0.

**Decision: `requires_dms: ">=1.5.0"`.** The owner runs 1.5.3, upstream is at 1.6.3, and
the owner's stated position is to adopt DMS's evolutions rather than hold back out of
caution. The cost is users below v1.5.0 (June 2026), which is acceptable. Note that
`requires_dms` is only *enforced* from v1.2.0; older DMS ignores the field, so declaring
it is safe at any floor.

## What is decided

### One mechanism, two policies

All four live processes route through a single-flight discipline in `service.js`: one run
in flight, requests arriving during it handled by an explicit policy. The mechanism is
shared; **the policy is not, and this is the crux of the design.**

- **Coalescing** — `searchProc`, `countProc`, `showProc`, `unreadProc`. Keep only the
  newest request; older ones are deliberately discarded, because running them would
  produce stale results the newest would immediately overwrite. This is what
  `requestSnippet`/`snippetEvent` already do for snippets.
- **Queueing** — `tagProc`. **Every** mutation must run, in order. Archiving thread A and
  then thread B are two distinct side effects on the database; "newest wins" here is data
  loss. A builder who reuses the snippet queue verbatim for tags will silently reintroduce
  the bug this plan exists to fix.

The healing path already present in `requestSnippet` — detecting an in-flight run whose
process is not actually alive, since a `notmuch` that fails to start emits no completion
signal — must survive into the shared mechanism. Without it, one failed spawn freezes a
process for the rest of the session.

`countProc` additionally needs its completion to be the conjunction of both signals
(`onStreamFinished` *and* `onExited`), the way `showProc` already does it. Re-arming on
the stream alone is what makes the permanent latch possible.

### The manifest

- `requires_dms: ">=1.5.0"` added.
- `"requires": ["notmuch"]` removed. Replaced by `"dependencies": ["notmuch"]`, which is
  the non-deprecated spelling and is what the plugin browser displays.
- `startupCheck` added, pointing at a new non-visual QML component that verifies notmuch
  is runnable and its database readable, and blocks activation with a message when not.
- `plugin.json` validated against DMS's published schema as part of `just ci`. The schema
  is **vendored** into the repo rather than fetched, to keep the gate hermetic; the
  vendored copy records the DMS version it came from. *(My call — the alternative, a
  network fetch at test time, breaks the Nix CI.)*

### The rest

- #6 implemented as its issue specifies: an `attachment` `DankIcon` beside the existing
  flag icon, same `Row`, same pattern, driven by `thread.tags`.
- #8 closed with the evidence above and no code change.

### Settled details

Small calls a builder would otherwise have to stop and ask about. Each is mine, and each
is overridable.

- **Target release: v0.9.0.** One branch, one `--no-ff` merge, one tag. `plugin.json`'s
  own `version` field moves with it.
- **The startup-check component lives in `src/view/`, beside `Notmuch.qml`.** It is
  non-visual, but `src/view/` is already where this project keeps its `Process` wiring,
  and `src/model/` is reserved for pure logic. It is under `src/`, so `fmt-check` and
  `lint` cover it like everything else.
- **The counts sequencer folds into the shared mechanism.** `refreshCounts()` /
  `_startCounts()` already hand-rolls exactly the coalescing policy — `_counting` plus
  `_countPending`, newest definitions win. It should express that through the shared
  state machine instead of its own booleans. Note the shape: counting is a *sequence* of
  runs, one per definition, so what sits on top of the mechanism is a sequencer, not a
  plain single-flight. This is the fiddliest part of the work.
- **Refreshes triggered by tag completions coalesce.** `tagProc.onExited` calls
  `refresh()` on success. Once tag mutations queue instead of dropping, archiving three
  threads fires three refreshes; the search, count and unread runs they kick off must
  collapse to one pass, which the coalescing policy gives for free as long as `refresh()`
  is not made to wait on them.
- **The README states the DMS floor too.** `requires_dms` is for the host; a human
  installing the plugin reads the README. Same commit.

## Left to the builder

- **The shape of the single-flight state machine.** Either generalise
  `requestSnippet`/`snippetEvent` into a policy-parameterised pair, or introduce a new
  trio and re-express the snippet queue in terms of it. Both are fine; what matters is one
  discipline rather than four hand-rolled guards, pure and unit-tested in
  `tests/tst_service.qml`.
- **The startup probe itself** — which notmuch invocation establishes "usable" (a cheap
  `notmuch count` against the database is the obvious candidate), and the French copy for
  the blocking message.
- **How the manifest check is implemented.** Adding `python3Packages.jsonschema` to the
  dev shell is acceptable if that is the cleanest route; so is a narrow hand-written check
  against the vendored schema. The requirement is that a drifted manifest fails `just ci`.
- **Whether `unreadProc` and `tagsProc` are worth routing through the mechanism.** Their
  exposure is benign. Including them for uniformity is reasonable; so is leaving them and
  saying why in a comment.

## Verification

Unit tests in `tests/tst_service.qml` covering both policies: a coalescing run where the
middle request is dropped and the newest wins, a queueing run where three mutations all
execute in order, and the dead-in-flight healing path. No golden changes — `service.js` is
pure logic with no fixture surface.

Manual checks, for the plan's manual test list: clicking a rail category while a poll
search is in flight; archiving three threads in rapid succession and confirming all three
left the inbox; rail counters still updating after a long session; plugin activation with
`notmuch` removed from `PATH`; the attachment icon appearing without shifting the
surrounding chips.
