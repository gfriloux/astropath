// Notmuch service: runs notmuch through Process, parses with the data layer (threads.js),
// exposes the model + a status. Periodic polling (no notmuch new: we only read).
import QtQuick
import Quickshell
import Quickshell.Io
import "../query/queries.js" as Queries
import "../model/threads.js" as Model
import "../model/service.js" as Svc

QtObject {
    id: root

    property int intervalMs: 20000

    // Query shown in the list (by default: the inbox's unread threads).
    property string currentQuery: Queries.UNREAD_QUERY
    property var threads: []

    // Badge counter: always the unread ones, independent of the current query.
    property int unreadCount: 0

    property string status: "idle" // idle | querying | error
    property double lastSyncAt: 0

    // Rail categories = auto-discovered from the database's tags, amended by the config
    // (see DESIGN inv. 3). The widget injects the pinned universals + the overrides and
    // custom searches read from the settings.
    property var universals: []
    property var tagOverrides: []
    property var customSearches: []
    property var discoveredTags: []

    readonly property var definitions: Model.buildDefinitions(discoveredTags, {
        "universals": universals,
        "overrides": tagOverrides,
        "custom": customSearches
    })
    property var counts: ({})
    readonly property var savedSearches: Model.savedSearches(definitions, counts)
    // Map tag → color (assembled definitions), to color the chips.
    readonly property var tagColors: Model.tagColors(definitions)

    onDefinitionsChanged: refreshCounts()

    // Tag discovery: notmuch search --output=tags '*' → discoveredTags, which rebuilds
    // definitions (hence refreshCounts through onDefinitionsChanged).
    //
    // Deliberately NOT routed through the coalescing flight, unlike the search and the
    // counts: the command is a static binding, so a re-arm that no-ops merely skips a run
    // identical to the one already in flight, and the next poll picks it up anyway. A
    // flight here would add state for no change in behaviour. Same reasoning for
    // unreadProc below.
    function discoverTags() {
        tagsProc.running = true;
    }
    property Process tagsProc: Process {
        command: ["notmuch"].concat(Queries.tags())
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.discoveredTags = Model.parseTags(text)
        }
    }

    // Reading client command (config) — used to open a thread.
    property string readerCommand: ""

    // Searches go through the coalescing flight. Re-arming a Process that is already
    // running is a QML no-op, so a rail click or a free-text search landing while the
    // 20 s poll's own search is still running used to be dropped in silence: the list
    // kept showing the previous query's results until the next poll happened to pick the
    // new currentQuery up.
    property var _searchRun: Svc.newSearchRun()
    property var _searchFlight: Svc.newFlight()

    function runSearch() {
        var r = Svc.requestFlight(root._searchFlight, root.currentQuery, false, searchProc.running);
        root._searchFlight = r.flight;
        if (r.dispatch)
            _dispatchSearch(r.dispatch);
    }
    // Sets command imperatively (no lazy binding) then starts: guarantees the query that
    // runs is the one the flight just dispatched, not whatever currentQuery became since.
    function _dispatchSearch(query) {
        root._searchRun = Svc.newSearchRun();
        root.status = Svc.decideSearchStatus(root._searchRun);
        searchProc.command = ["notmuch"].concat(Queries.search(query));
        searchProc.running = true; // safe: only ever called on an exited process
    }
    // Both completion signals land here; whatever the flight hands back is the query whose
    // turn it now is.
    function _advanceSearch(ev) {
        var r = Svc.flightEvent(root._searchFlight, ev);
        root._searchFlight = r.flight;
        if (r.dispatch)
            _dispatchSearch(r.dispatch);
    }
    // Records one observed fact about the running search, then recomputes the status from
    // all the facts gathered so far (the three handlers fire in no guaranteed order).
    function _noteSearch(fact) {
        root._searchRun = Object.assign({}, root._searchRun, fact);
        root.status = Svc.decideSearchStatus(root._searchRun);
    }

    function refresh() {
        runSearch();
        unreadProc.running = true;
        discoverTags();
        refreshCounts();
    }

    // Smart folder counters: one notmuch count per definition, walked in order. Two
    // concerns, kept apart (see service.js): the sequencer says WHAT runs next, the
    // flight says WHEN a run is over. One sequence at a time — asked again while one
    // runs, we restart afterwards with the up-to-date definitions.
    property var _countSeq: Svc.newCountSeq()
    property var _countFlight: Svc.newFlight()
    property string _countText: ""

    function refreshCounts() {
        var r = Svc.startCounts(root._countSeq, root.definitions);
        root._countSeq = r.seq;
        if (r.dispatch)
            _dispatchCount(r.dispatch);
        else if (!root._countSeq.running)
            root.counts = {};
    }
    function _dispatchCount(query) {
        var r = Svc.requestFlight(root._countFlight, query, false, countProc.running);
        root._countFlight = r.flight;
        if (!r.dispatch)
            return;
        root._countText = "";
        countProc.command = ["notmuch"].concat(Queries.count(r.dispatch));
        countProc.running = true; // safe: only ever called on an exited process
    }
    // Both signals must land before a run counts as over. Re-arming on the stream alone
    // is what used to stop the sequence dead and leave it flagged running for the rest
    // of the session, freezing every rail counter.
    function _advanceCount(ev) {
        var f = Svc.flightEvent(root._countFlight, ev);
        root._countFlight = f.flight;
        if (!f.completedKey)
            return;
        var r = Svc.countCompleted(root._countSeq, Model.parseCount(root._countText));
        root._countSeq = r.seq;
        if (r.counts)
            root.counts = r.counts;
        if (r.dispatch)
            _dispatchCount(r.dispatch);
        else if (r.restartNeeded)
            refreshCounts();
    }
    property Process countProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root._countText = text;
                root._advanceCount("stream");
            }
        }
        onExited: root._advanceCount("exit")
    }

    function setQuery(q) {
        root.currentQuery = q;
        runSearch();
    }

    // Free-text search: empty text → back to the default unread query.
    function searchText(t) {
        setQuery(t && t.length > 0 ? t : Queries.UNREAD_QUERY);
    }

    // Tag mutations (tag-only). Queued, never coalesced: archiving several threads in a
    // row is several distinct side effects, and the old code — command then running=true
    // on a Process that might already be running — silently lost every one after the
    // first. The user saw the action accepted and nothing happened.
    property var _tagQueue: Svc.newTagQueue()

    function tag(threadId, ops) {
        var r = Svc.requestTag(root._tagQueue, {
            "id": threadId,
            "ops": ops
        }, tagProc.running);
        root._tagQueue = r.queue;
        if (r.dispatch)
            _dispatchTag(r.dispatch);
    }
    function _dispatchTag(op) {
        tagProc.command = ["notmuch"].concat(Queries.tagThread(op.id, op.ops));
        tagProc.running = true; // safe: only ever called on an exited process
    }
    function markRead(id) {
        tag(id, {
            "remove": ["unread"]
        });
    }
    function archive(id) {
        tag(id, {
            "remove": ["inbox"]
        });
    }
    function toggleFlag(id, flagged) {
        tag(id, flagged ? {
            "remove": ["flagged"]
        } : {
            "add": ["flagged"]
        });
    }
    function trash(id) {
        tag(id, {
            "add": ["deleted"],
            "remove": ["inbox", "unread"]
        });
    }

    // Opens a thread in the configured reading client (the thread:<id> query is appended).
    function open(id) {
        if (root.readerCommand && root.readerCommand.length > 0)
            Quickshell.execDetached(["sh", "-c", root.readerCommand + " thread:" + id]);
        else
            console.warn("astropath: no reader command configured (settings)");
    }

    // Lazy snippets: fetched through notmuch show for the current item only
    // (one process at a time, cached by thread id).
    property var snippets: ({})
    property var _snippetFlight: Svc.newFlight()
    property string _snippetText: ""

    function fetchSnippet(id) {
        // showProc.running is how we tell a run that is still coming from one that died
        // without ever completing (notmuch failing to start emits no completion signal).
        var r = Svc.requestFlight(root._snippetFlight, id, root.snippets[id] !== undefined, showProc.running);
        root._snippetFlight = r.flight;
        if (r.dispatch)
            _dispatchSnippet(r.dispatch);
    }
    function _dispatchSnippet(id) {
        root._snippetText = "";
        showProc.command = ["notmuch"].concat(Queries.showThread(id));
        showProc.running = true; // safe: only ever called on an exited process
    }
    // Both completion signals land here; the collected output is only attributed once the
    // run is over, under the id that actually asked for it.
    function _advanceSnippet(ev) {
        var r = Svc.flightEvent(root._snippetFlight, ev);
        root._snippetFlight = r.flight;
        if (r.completedKey) {
            try {
                var detail = Model.parseShow(JSON.parse(root._snippetText));
                var m = Object.assign({}, root.snippets);
                m[r.completedKey] = detail.snippet;
                root.snippets = m;
            } catch (e) {
                console.warn("astropath: show parse failed:", e);
            }
        }
        if (r.dispatch)
            _dispatchSnippet(r.dispatch);
    }
    property Process showProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root._snippetText = text;
                root._advanceSnippet("stream");
            }
        }
        onExited: root._advanceSnippet("exit")
    }

    // List: search for the current query.
    property Process searchProc: Process {
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.threads = Model.parseSearch(JSON.parse(text));
                    root.lastSyncAt = Date.now();
                    root._noteSearch(Svc.searchStdoutFact(true));
                } catch (e) {
                    root._noteSearch(Svc.searchStdoutFact(false));
                    console.warn("astropath: search parse failed:", e);
                }
                root._advanceSearch("stream");
            }
        }

        // notmuch warns here on runs that are otherwise fine (duplicate Message-Id,
        // Xapian notices): we log, we do not judge. The exit code judges.
        stderr: StdioCollector {
            onStreamFinished: if (text.trim())
                console.warn("astropath notmuch:", text.trim())
        }

        onExited: code => {
            root._noteSearch({
                "exited": true,
                "exitCode": code
            });
            root._advanceSearch("exit");
        }
    }

    // Tag mutation: notmuch tag … -- thread:id.
    property Process tagProc: Process {
        running: false

        // A failure is reported but does NOT stop the drain: one bad op must not strand
        // the mutations queued behind it. The refresh waits for the queue to empty, so a
        // burst of archives costs one refresh rather than one per thread.
        onExited: code => {
            if (code !== 0)
                root.status = "error";
            var r = Svc.tagEvent(root._tagQueue);
            root._tagQueue = r.queue;
            if (r.dispatch)
                root._dispatchTag(r.dispatch);
            else
                root.refresh();
        }

        stderr: StdioCollector {
            onStreamFinished: if (text.trim())
                console.warn("astropath tag:", text.trim())
        }
    }

    // Badge counter: count of unread threads.
    property Process unreadProc: Process {
        command: ["notmuch"].concat(Queries.count(Queries.UNREAD_QUERY))
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.unreadCount = Model.parseCount(text)
        }
    }

    // Polling: re-query periodically (picks up whatever the external machinery indexed).
    property Timer poll: Timer {
        interval: root.intervalMs
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
