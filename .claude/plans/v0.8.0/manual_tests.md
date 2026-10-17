# Manual tests — v0.8.0 (testable service logic)

Run at closing, in a real DMS instance (`just run` + `just reload`, or `just dev-bar`).
Covers what `just ci` cannot: live QML, live settings, real notmuch timing.

Most of this version is non-regression: outside the three fixed bugs, nothing visible
should change.

## Settings — overrides (Task 1, non-regression)

- [ ] Rename a tag (label override) → the rail shows the new label, the filter stays
      `tag:<x>`.
- [ ] Clear that label back to empty → the rail falls back to the raw tag, and the entry
      is gone from `tagOverrides` in the plugin settings file.
- [ ] Recolor a tag → the rail entry and the thread chips both follow.
- [ ] Hide a tag, then unhide it → it leaves and comes back in the rail.
- [ ] Restart DMS → every override above survived.

## Settings — colliding custom search (Task 2, #5)

- [ ] Note an existing tag in the rail, say `boulot`. Add a composed search with that
      exact label (`Boulot`) and a different query (`tag:boulot and tag:unread`).
- [ ] The rail now shows **two distinct entries** with **distinct counts** — the tag's
      count and the composed one's. Neither displays the other's number.
- [ ] Add a second composed search with the same label again → a third entry, again with
      its own count.
- [ ] Clicking each of the three filters the list on its own query.
- [ ] The labels displayed are exactly what was typed (the uniqueness suffix is internal
      and never shown).

## Sync status (Task 3, #4)

- [ ] Normal use for a few polling cycles (20 s): the cockpit header never sticks on
      « erreur de synchro » while the thread list is correctly refreshing.
- [ ] Force a real failure — point `NOTMUCH_CONFIG` at a config whose database path does
      not exist, so `notmuch search` runs and **exits non-zero** — and confirm the header
      does show the error state. (Do *not* use "rename the binary out of `PATH`" for this:
      a process that fails to start emits no exit code, so the status stays on
      « synchro… » instead. Pre-existing, unrelated to this version.)
- [ ] Back to normal: the next poll clears the error.

## Lazy snippets (Task 4, #7)

- [ ] Open the cockpit on a list of 10+ threads. Hold `j` to run down the list quickly,
      then stop. The snippet displayed under the selected row belongs to **that** row
      (compare with its subject/sender).
- [ ] Same going back up with `k`.
- [ ] Navigate away from a thread before its snippet appears, then come back to it: the
      snippet eventually shows up and is the right one.
- [ ] A thread whose `notmuch show` fails (large/corrupt thread, if one is reachable)
      leaves the rest of the list working — no stuck selection, no snippet from a
      neighbor.
- [ ] Recovery: make `notmuch` unreachable from the DMS environment, navigate a few rows
      (no snippet appears), restore it, then navigate again — snippets come back without
      restarting the shell. Before v0.8.0's fix pass this wedged the queue for the rest of
      the session.

## General

- [ ] Badge counter in the bar still matches `notmuch count tag:inbox and tag:unread`.
- [ ] Tag actions (read, archive, flag, trash) and opening a thread in the reader still
      work.
- [ ] No new warning in the DMS log (`journalctl --user -u dms.service`) beyond the
      pre-existing ones.
