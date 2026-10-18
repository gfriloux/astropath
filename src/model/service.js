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

// --- counts sequencer ------------------------------------------------------
// The rail counters are one notmuch count per definition, run in order. This decides
// WHAT runs next; the flight below decides WHEN one run is over. Keeping them apart is
// what fixes the old latch: _startCounts() re-armed countProc from onStreamFinished
// alone, and when the stream finished before the exit that re-arm was a no-op — the
// sequence stopped mid-way and its "running" flag was never cleared, so no rail counter
// updated again for the rest of the session.

function newCountSeq() {
    return {
        keys: [],
        queries: [],
        index: 0,
        acc: {},
        running: false,
        restart: false
    };
}

// → { seq, dispatch }: dispatch is the query to count now, "" if nothing starts.
// Asked again while a sequence runs, the request is remembered rather than interleaved:
// the definitions may have changed, and two sequences sharing one Process would scramble
// each other's accumulator.
function startCounts(seq, defs) {
    if (seq.running)
        return {
            seq: Object.assign({}, seq, {
                restart: true
            }),
            dispatch: ""
        };
    var list = defs || [];
    if (list.length === 0)
        return {
            seq: newCountSeq(),
            dispatch: ""
        };
    return {
        seq: {
            keys: list.map(function (d) {
                return d.key;
            }),
            queries: list.map(function (d) {
                return d.query;
            }),
            index: 0,
            acc: {},
            running: true,
            restart: false
        },
        dispatch: list[0].query
    };
}

// → { seq, dispatch, counts, restartNeeded }: counts is the finished accumulator, null
// while the sequence is still walking. A completion arriving when no sequence is running
// belongs to one that was abandoned and is dropped, or its count would leak into the
// accumulator of the sequence running now.
function countCompleted(seq, count) {
    if (!seq.running)
        return {
            seq: seq,
            dispatch: "",
            counts: null,
            restartNeeded: false
        };
    var acc = Object.assign({}, seq.acc);
    acc[seq.keys[seq.index]] = count;
    var next = seq.index + 1;
    if (next < seq.keys.length)
        return {
            seq: Object.assign({}, seq, {
                index: next,
                acc: acc
            }),
            dispatch: seq.queries[next],
            counts: null,
            restartNeeded: false
        };
    return {
        seq: Object.assign({}, newCountSeq(), {
            acc: acc
        }),
        dispatch: "",
        counts: acc,
        restartNeeded: !!seq.restart
    };
}

// --- tag mutations: one run at a time, but NOTHING is discarded -------------
// The flight below coalesces because a superseded READ produces results the newest one
// would overwrite anyway. A mutation is the opposite: archiving thread A and then thread
// B are two distinct side effects on the database, so "newest wins" here is data loss.
// Every op runs, in the order it was asked for.
//
// Ops are opaque: the caller puts in whatever it needs to build its command, and gets the
// same value back to dispatch.

function newTagQueue() {
    return {
        inflight: null,
        pending: []
    };
}

// → { queue, dispatch }: dispatch is the op to run now, null if one is already running.
// inflightAlive has the same job as in requestFlight: a process that died without ever
// emitting its exit (notmuch failing to start) would otherwise hold the queue forever.
function requestTag(queue, op, inflightAlive) {
    var q = (queue.inflight && !inflightAlive) ? newTagQueue() : queue;
    if (!op)
        return {
            queue: q,
            dispatch: null
        };
    if (!q.inflight)
        return {
            queue: Object.assign({}, q, {
                inflight: op
            }),
            dispatch: op
        };
    return {
        queue: Object.assign({}, q, {
            pending: q.pending.concat([op])
        }),
        dispatch: null
    };
}

// A mutation produces nothing we read, so its single exit signal ends it. The exit CODE
// is deliberately not an input: a failed mutation still advances the queue, or one bad
// op would strand every op behind it.
// → { queue, completed, dispatch }: completed is the op that just finished, dispatch the
// next one, null once the queue has drained.
function tagEvent(queue) {
    var completed = queue.inflight;
    var rest = queue.pending.slice();
    var next = rest.length > 0 ? rest.shift() : null;
    return {
        queue: {
            inflight: next,
            pending: rest
        },
        completed: completed,
        dispatch: next
    };
}

// --- coalescing single flight ----------------------------------------------
// The dispatch discipline for every READ we make of notmuch: searches, snippets, the
// per-definition counts. One run at a time, and its key is frozen for the whole run, so a
// result is attributed to whatever asked for it rather than to whatever happens to be
// current when the process finishes.
//
// At most one request waits, always the newest. Superseded requests are DISCARDED on
// purpose, not forgotten: running them would produce results the newest one would
// overwrite a moment later. Mutations do not get this policy — see the tag queue below,
// where dropping a request would drop a side effect.
//
// Re-arming a Process that is already running is a QML no-op: the new command is ignored
// and the request vanishes. Nothing here may re-arm without going through this machine.

function newFlight() {
    return {
        inflight: "",
        pending: "",
        streamDone: false,
        exited: false
    };
}

// → { flight, dispatch }: dispatch is the key to actually run now, "" if nothing starts.
// inflightAlive tells us whether the process we believe is running actually is: one that
// died without completing (notmuch failing to start emits no completion signal) would
// otherwise hold the flight forever, killing the feature for the rest of the session. The
// old code re-armed the process on every request and healed by itself; this keeps that.
// skip is the caller's "nothing to do" predicate (snippets pass "already cached").
function requestFlight(flight, key, skip, inflightAlive) {
    var f = (flight.inflight && !inflightAlive) ? newFlight() : flight;
    if (!key || skip)
        return {
            flight: f,
            dispatch: ""
        };
    // Asking again for the key already in flight: that run will deliver exactly what is
    // wanted, so nothing is started. But anything pending was requested BEFORE this and is
    // now stale — leaving it would end the sequence on a query the user has moved off.
    if (key === f.inflight)
        return {
            flight: Object.assign({}, f, {
                pending: ""
            }),
            dispatch: ""
        };
    if (!f.inflight)
        return {
            flight: Object.assign({}, f, {
                inflight: key,
                streamDone: false,
                exited: false
            }),
            dispatch: key
        };
    return {
        flight: Object.assign({}, f, {
            pending: key
        }),
        dispatch: ""
    };
}

// One of the running process' two completion signals: ev = "stream" | "exit". The run is
// over only once both have landed — their order is not guaranteed.
// → { flight, completedKey, dispatch }: completedKey is the key the collected output
// belongs to ("" while the run is not over), dispatch the key whose turn it now is.
function flightEvent(flight, ev) {
    var f = Object.assign({}, flight, ev === "stream" ? {
        streamDone: true
    } : {
        exited: true
    });
    if (!f.streamDone || !f.exited)
        return {
            flight: f,
            completedKey: "",
            dispatch: ""
        };
    var completedKey = f.inflight;
    var next = f.pending;
    return {
        flight: {
            inflight: next,
            pending: "",
            streamDone: false,
            exited: false
        },
        completedKey: completedKey,
        dispatch: next
    };
}
