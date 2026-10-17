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
