// Notmuch service: runs notmuch through Process, parses with the data layer (threads.js),
// exposes the model + a status. Periodic polling (no notmuch new: we only read).
import QtQuick
import Quickshell
import Quickshell.Io
import "../query/queries.js" as Queries
import "../model/threads.js" as Model

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

    // Sets command imperatively (no lazy binding) then starts: guarantees the query that
    // runs is the current one, even right after a change.
    function runSearch() {
        root.status = "querying";
        searchProc.command = ["notmuch"].concat(Queries.search(root.currentQuery));
        searchProc.running = true;
    }

    function refresh() {
        runSearch();
        unreadProc.running = true;
        discoverTags();
        refreshCounts();
    }

    // Smart folder counters: one sequence at a time (non-reentrant). If asked again while
    // one is running, we restart afterwards, with the up-to-date definitions.
    property bool _counting: false
    property bool _countPending: false
    property var _countCb: null

    function refreshCounts() {
        if (root._counting) {
            root._countPending = true;
            return;
        }
        _startCounts();
    }
    function _startCounts() {
        var defs = (definitions || []).slice(); // consistent snapshot
        if (defs.length === 0) {
            root.counts = {};
            root._counting = false;
            return;
        }
        root._counting = true;
        root._countPending = false;
        var acc = {};
        var i = 0;
        function step() {
            if (i >= defs.length) {
                root.counts = acc;
                root._counting = false;
                if (root._countPending)
                    root._startCounts();
                return;
            }
            var def = defs[i];
            root._countCb = function (text) {
                acc[def.key] = Model.parseCount(text);
                i++;
                step();
            };
            countProc.command = ["notmuch"].concat(Queries.count(def.query));
            countProc.running = true;
        }
        step();
    }
    property Process countProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: if (root._countCb)
                root._countCb(text)
        }
    }

    function setQuery(q) {
        root.currentQuery = q;
        runSearch();
    }

    // Free-text search: empty text → back to the default unread query.
    function searchText(t) {
        setQuery(t && t.length > 0 ? t : Queries.UNREAD_QUERY);
    }

    // Tag mutations (tag-only). On success → refresh the list.
    function tag(threadId, ops) {
        tagProc.command = ["notmuch"].concat(Queries.tagThread(threadId, ops));
        tagProc.running = true;
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
    property string _snippetId: ""
    function fetchSnippet(id) {
        if (!id || root.snippets[id] !== undefined)
            return;
        root._snippetId = id;
        showProc.command = ["notmuch"].concat(Queries.showThread(id));
        showProc.running = true;
    }
    property Process showProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var detail = Model.parseShow(JSON.parse(text));
                    var m = Object.assign({}, root.snippets);
                    m[root._snippetId] = detail.snippet;
                    root.snippets = m;
                } catch (e) {
                    console.warn("astropath: show parse failed:", e);
                }
            }
        }
    }

    // List: search for the current query.
    property Process searchProc: Process {
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.threads = Model.parseSearch(JSON.parse(text));
                    root.status = "idle";
                    root.lastSyncAt = Date.now();
                } catch (e) {
                    root.status = "error";
                    console.warn("astropath: search parse failed:", e);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    root.status = "error";
                    console.warn("astropath notmuch:", text.trim());
                }
            }
        }

        onExited: code => {
            if (code !== 0)
                root.status = "error";
        }
    }

    // Tag mutation: notmuch tag … -- thread:id.
    property Process tagProc: Process {
        running: false

        onExited: code => {
            if (code === 0)
                root.refresh();
            else
                root.status = "error";
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
