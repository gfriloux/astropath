.pragma library

// Decisions for the notmuch service, kept out of the Process wiring in Notmuch.qml so
// they can be unit-tested. Pure: plain data in, plain data out.

// --- search status ---------------------------------------------------------
// A search run is observed through three independent signals (stdout finished, stderr
// finished, process exited) whose firing order Quickshell does not guarantee. Each
// handler records a FACT about the run; the status is recomputed from the facts, so
// whichever handler fires last reaches the same answer.

function newSearchRun() {
    return {
        exited: false,
        exitCode: 0,
        stdoutDone: false,
        parseOk: false
    };
}

// The fact a finished stdout stream contributes. Built here rather than spelled out at
// the call site so the failure case cannot omit parseOk: facts are merged onto the run,
// and an omitted field would leave a previous run's success standing.
function searchStdoutFact(parseOk) {
    return {
        stdoutDone: true,
        parseOk: !!parseOk
    };
}

// The exit code is the only authority on failure. stderr is deliberately not an input:
// notmuch writes benign warnings there on perfectly successful runs.
function decideSearchStatus(run) {
    if (!run.exited)
        return "querying";
    if (run.exitCode !== 0)
        return "error";
    if (!run.stdoutDone)
        return "querying";
    return run.parseOk ? "idle" : "error";
}

// --- lazy snippet requests -------------------------------------------------
// Keyboard navigation asks for a snippet per row it lands on, faster than notmuch show
// answers. One request runs at a time and its id is frozen for the whole run: a result is
// attributed to the thread that asked for it, never to whichever row is current when the
// process happens to finish. At most one request waits, always the newest.

function newSnippetQueue() {
    return {
        inflight: "",
        pending: "",
        textReady: false,
        exited: false
    };
}

// → { queue, dispatch }: dispatch is the id to actually run now, "" if nothing starts.
// inflightAlive tells us whether the process we believe is running actually is: one that
// died without completing (notmuch failing to start emits no completion signal) would
// otherwise hold the queue forever, killing snippets for the rest of the session. The old
// code re-armed the process on every request and healed by itself; this keeps that.
function requestSnippet(queue, id, isCached, inflightAlive) {
    var q = (queue.inflight && !inflightAlive) ? newSnippetQueue() : queue;
    if (!id || isCached || id === q.inflight)
        return {
            queue: q,
            dispatch: ""
        };
    if (!q.inflight)
        return {
            queue: Object.assign({}, q, {
                inflight: id,
                textReady: false,
                exited: false
            }),
            dispatch: id
        };
    return {
        queue: Object.assign({}, q, {
            pending: id
        }),
        dispatch: ""
    };
}

// One of the running process' two completion signals: ev = "stream" | "exit". The run is
// over only once both have landed — their order is not guaranteed.
// → { queue, completedId, dispatch }: completedId is the id the collected output belongs
// to ("" while the run is not over), dispatch the id whose turn it now is.
function snippetEvent(queue, ev) {
    var q = Object.assign({}, queue, ev === "stream" ? {
        textReady: true
    } : {
        exited: true
    });
    if (!q.textReady || !q.exited)
        return {
            queue: q,
            completedId: "",
            dispatch: ""
        };
    var completedId = q.inflight;
    var next = q.pending;
    return {
        queue: {
            inflight: next,
            pending: "",
            textReady: false,
            exited: false
        },
        completedId: completedId,
        dispatch: next
    };
}
