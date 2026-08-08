# DESIGN.md — astropath

> This document defines the spirit, the structure and the **invariants** of astropath.
> Before adding anything, check that it fits in here. If it does not, the answer
> is no.
>
> Docs and code comments are in English; the **UI copy is in French**. Quoted strings
> in this document are the literal UI text.

---

## What astropath is

astropath is a **mail-at-a-glance widget** for the **Quickshell / DankMaterialShell**
desktop bar (Material 3, Catppuccin Mocha theme). An icon in the bar shows an
**unread badge**; on click, a **popup** anchored under the icon lists unread threads,
and lets you search, retag and open a thread.

The source of truth is the **notmuch database** (Xapian index over a Maildir). astropath
only talks to `notmuch`: it reads (`notmuch search`/`count`/`show --format=json`) and
mutates tags (`notmuch tag`). Everything is reasoned about by **thread** and by **tag**,
never by folder. astropath **never indexes** (no `notmuch new`): indexing new mail is the
job of the external sync machinery (offlineimap / imapnotify). Refreshing happens by
**polling** (periodic re-query).

astropath is a **triage surface** on top of notmuch. How a thread is opened afterwards
(reading client, command launched) is **configuration**, not design: this document does
not cover it.

It is **not**:

- An IMAP/SMTP client. astropath does not talk to the network: syncing is the job of
  **offlineimap** (fetch) and **imapnotify** (push/notification). astropath observes
  their state, it does not drive them beyond a manual refresh.
- A folder manager. The model is **tag-only**. "Archiving" = removing
  `tag:inbox`, not moving a file.

Today a single account is configured, but nothing in the model assumes that: see the
*account-agnostic* invariant below.

---

## The pipeline — three stages

astropath is a three-stage transformation. Each stage has a clear contract and is
**independently testable**. Nothing crosses a stage that should not: raw notmuch output
does not enter the view, and the QML never calls `notmuch` directly.

```
  notmuch database                                      Quickshell popup
      │                                                        ▲
      ▼                                                        │
  ┌────────┐        ┌─────────────┐        ┌──────────────────┐
  │ query  │  ───▶  │ model       │  ───▶  │ view             │
  │ (CLI)  │        │ (threads)   │        │ (QML / Material) │
  └────────┘        └─────────────┘        └──────────────────┘
```

### 1. `query` — notmuch execution

The only layer that runs `notmuch`. Builds queries, runs
`notmuch search`/`count`/`show` in `--format=json`, and applies `notmuch tag`
mutations. Output: **raw notmuch JSON**, deterministic for a given database.
This stage knows nothing about presentation.

### 2. `model` — domain model

Turns notmuch JSON into a **thread model**: sender, subject, snippet, time, message
count, tags, states (`unread`, `flagged`, `vip`). Holds the application state:
`unreadThreads`, `searchQuery`/`searchResults`, `selectedSavedSearch`, `savedSearches`
(tags + counters), `syncStatus`, `focusedThreadId`, `lastSyncAt`. **Pure and testable**:
same notmuch input → same model (see golden tests, PROCEDURE_PLANS.md).

### 3. `view` — Quickshell rendering

QML / Qt Quick. Consumes the model, never calls `notmuch` directly. Carries the visual
system below down to the pixel, reusing DankMaterialShell's Material 3 components.

### Implementation

astropath is a **DankMaterialShell plugin** (`plugin.json` at the root + `src/`),
installed into `~/.config/DankMaterialShell/plugins/Astropath/`. It inherits DMS's theme
(Catppuccin Mocha) and Material 3 components.

- `query` → `src/query/queries.js`: notmuch argv builders (search/count/show/tag),
  pure functions. Executed by `src/view/Notmuch.qml` (quickshell `Process` + `StdioCollector`).
- `model` → `src/model/threads.js` (`parseSearch`, `parseCount`, `savedSearches` with
  injected definitions = config, `parseShow`) + `format.js` (`relativeTime`). Pure, tested
  by goldens/unit tests (`tests/`, `just test` / `just bless`).
- `view` → `src/view/`: `AstropathWidget` (bar + badge), `Cockpit` (popout: sync header,
  saved-search rail, live search, list, inline actions, keyboard navigation),
  `Settings` (config: reading client, interval, smart folders). Theme = DMS.

---

## Domain invariants

1. **notmuch is the source of truth; reads + tags only.** Every displayed piece of data
   comes from notmuch (no parallel cache). astropath queries (read) and runs `notmuch tag`
   (mutation), nothing else — **never `notmuch new`**: it does not index, that is the job
   of the external sync.
2. **Tag-only.** No notion of folders. Actions are tag mutations: read = `-unread`,
   archive = `-inbox`, flag = `+flagged`, spam = `+spam`, and so on.
3. **Smart folders are tags.** Universal views (`Inbox`, `Flagged`, `Spam`…) and
   **categories** are `tag:…` queries with a counter, not stored entities. astropath ships
   no hardcoded taxonomy: categories are **auto-discovered** from the database's tags
   (`notmuch search --output=tags`, a direct consequence of *notmuch is the source of
   truth*). Excluded from auto-discovery are **machine tags** (states: `unread`,
   `attachment`, `signed`, `replied`… — a list of *operational* tags, not a personal
   taxonomy). User config only **amends**: hide a tag, rename its label, change its color,
   or add a **composed** search (which auto-discovery, limited to a plain `tag:X`, cannot
   generate).
4. **Account-agnostic.** astropath does not model accounts: an account is just a facet of
   a notmuch query (path or tag). Single- or multi-account setups are modelled through
   saved searches, with no special handling — a direct consequence of tag-only reasoning.
   Richer per-account views (separate badges, switching) will be PLANs if the need shows up.
5. **Best-effort on sync.** Sync state (`live | idle | syncing | error`) is *observed*
   (imapnotify / offlineimap / `notmuch new`). An unavailable sync degrades the display,
   it never crashes the widget.
6. **Deterministic data layer.** `query` + `model` are deterministic for a frozen notmuch
   database — that is what makes golden tests possible.

---

## Visual system (mandatory)

Hi-fi: colors, typography, spacing and radii are final. The original HTML prototype
(3 directions A/B/C + secondary states) lives in `tmp/design_handoff_astropath/`
(not committed); the lasting values are copied here so they survive.

### Palette — Catppuccin Mocha

| Role | Hex |
|---|---|
| Background / base | `#1e1e2e` |
| Mantle | `#181825` |
| Crust | `#11111b` |
| Raised container | `#313244` |
| Highest container | `#45475a` |
| Outline / separators | `#6c7086` |
| Text | `#cdd6f4` |
| Secondary text | `#a6adc8` |
| **Primary accent — Mauve** | `#cba6f7` |
| Secondary accent — Lavender | `#b4befe` |
| Unread / urgent / error — Red | `#f38ba8` |
| Flag / warning — Peach | `#fab387` |
| Success / live — Green | `#a6e3a1` |
| Info — Blue | `#89b4fa` |
| Cool accent — Teal | `#94e2d5` |

Mauve **sparingly**: focus, selection, active badge, Compose button. Never as a massive
flat fill.

### Tag color mapping

Chip = `background: rgba(color, 0.16)` + `color: color`.

Universal tags (fixed color):

| Tag | notmuch | Color |
|---|---|---|
| inbox | `tag:inbox` | `#89b4fa` |
| flagged | `tag:flagged` | `#fab387` |
| spam | `tag:spam` | `#f38ba8` |

**Category tags** (auto-discovered) each get a color **derived by deterministic hash**
of the tag name over the category palette — same tag → same color, with no config (and
goldenable). The user can **override** the color of a given tag. astropath hardcodes no
taxonomy (see the *account-agnostic* invariant). Category palette: Lavender `#b4befe`,
Green `#a6e3a1`, Teal `#94e2d5`, Peach `#fab387`, Yellow `#f9e2af`, Mauve `#cba6f7`.

### Shapes & depth

- Main radius **12px** (cards, popup); 6–10px for chips/small buttons; 14px for the bar.
- Depth by **stacking surfaces**, no hard shadows. The only shadow:
  `0 16px 48px rgba(0,0,0,.5)` under the popup. Background blur: `blur(18px)`.
- **List separators**: a 1px **gradient** hairline (fading out at both ends), `outline`
  tint. Placed between threads; it fades away around the active/hovered card so it never
  cuts through it.
- Typography: **Inter** (UI), **JetBrains Mono** (queries/times/counters),
  **Material Symbols Rounded** (icons, fill 0).

### Visual direction — C (cockpit)

The chosen direction is **C — cockpit**: a dense mini-client, aimed at keyboard
power-users. Reference layout (the HTML prototype has the pixel-perfect detail):

- **Width ~680px** (popup ~680×680) — well beyond the 380–420px target of the other
  directions, and deliberately so: the cockpit favors information density and readability
  over compactness.
- **Full-width telemetry header**: wordmark, `SYNC LIVE` state + animated signal bars,
  refresh, **Compose** button.
- **Left rail (~172px)**: vertical list of saved searches (icon + label + counter),
  selection marked by a **tinted background** (translucent mauve) with label and counter
  in Mauve — no left border.
- **Main area**: search bar + thread list at medium density (32px avatar). The thread
  under the keyboard cursor gets a **tinted background** (translucent mauve) and reveals
  the **inline action row** (read / archive / flag / retag / delete / open).
- **Footer**: keyboard shortcut chips (`j`/`k`, `⏎`, `e`, `#`).

Opening a thread (`⏎`) and **Compose** delegate to the configurable external client:
astropath triggers, it neither displays nor composes itself (see *triage surface* above).

---

## Adeptus Mechanicus nod

Subtle, never kitsch. "Warp / astropathicus" vocabulary, a single cog in the header,
an empty state reading « Le warp est calme. ». It is seasoning, not a theme.
