import QtQuick
import QtTest
import "../src/model/service.js" as Svc

TestCase {
    name: "service"

    function test_decideSearchStatus_pendingWhileRunning() {
        var run = Svc.newSearchRun();
        compare(Svc.decideSearchStatus(run), "querying");
        run.stdoutDone = true;
        run.parseOk = true;
        compare(Svc.decideSearchStatus(run), "querying"); // parsed, but not exited yet
    }

    // The point of the fix: notmuch can warn on stderr (duplicate Message-Id, Xapian
    // notices) on an otherwise perfect run. stderr is not an input here at all.
    function test_decideSearchStatus_idleOnCleanExitWhateverStderr() {
        compare(Svc.decideSearchStatus({
            "exited": true,
            "exitCode": 0,
            "stdoutDone": true,
            "parseOk": true
        }), "idle");
    }

    function test_decideSearchStatus_errorOnNonZeroExit() {
        compare(Svc.decideSearchStatus({
            "exited": true,
            "exitCode": 1,
            "stdoutDone": true,
            "parseOk": true
        }), "error");
    }

    function test_decideSearchStatus_errorOnUnparsableStdout() {
        compare(Svc.decideSearchStatus({
            "exited": true,
            "exitCode": 0,
            "stdoutDone": true,
            "parseOk": false
        }), "error");
    }

    function test_decideSearchStatus_waitsForStdout() {
        compare(Svc.decideSearchStatus({
            "exited": true,
            "exitCode": 0,
            "stdoutDone": false,
            "parseOk": false
        }), "querying");
    }

    function test_searchStdoutFact_carriesTheParseOutcome() {
        // The failure fact must state parseOk:false, not omit it — facts are merged onto
        // the run, so an omitted field would leave a previous success standing.
        compare(Svc.searchStdoutFact(true).stdoutDone, true);
        compare(Svc.searchStdoutFact(true).parseOk, true);
        compare(Svc.searchStdoutFact(false).parseOk, false);
    }

    function test_requestSnippet_dispatchesWhenIdle() {
        var r = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false, false);
        compare(r.dispatch, "A");
        compare(r.queue.inflight, "A");
    }

    function test_requestSnippet_cachedOrEmptyIsNoop() {
        compare(Svc.requestSnippet(Svc.newSnippetQueue(), "A", true, false).dispatch, "");
        compare(Svc.requestSnippet(Svc.newSnippetQueue(), "", false, false).dispatch, "");
    }

    function test_requestSnippet_queuesNewestWhileInflight() {
        var q = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false, false).queue;
        var b = Svc.requestSnippet(q, "B", false, true);
        compare(b.dispatch, "");          // A is still running: nothing is started
        compare(b.queue.inflight, "A");   // and A is NOT overwritten
        var c = Svc.requestSnippet(b.queue, "C", false, true);
        compare(c.queue.pending, "C");    // newest pending wins
    }

    function test_requestSnippet_sameIdInflightIsNoop() {
        var q = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false, false).queue;
        compare(Svc.requestSnippet(q, "A", false, true).dispatch, "");
    }

    // A process that died without ever completing (notmuch failed to start) leaves an
    // inflight id no signal will ever clear. The next navigation must retry, not wedge.
    function test_requestSnippet_deadInflightIsAbandoned() {
        var q = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false, false).queue;
        var r = Svc.requestSnippet(q, "B", false, false);
        compare(r.dispatch, "B");
        compare(r.queue.inflight, "B");
        compare(r.queue.pending, "");
    }

    function test_requestSnippet_deadInflightRetriesTheSameId() {
        var q = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false, false).queue;
        compare(Svc.requestSnippet(q, "A", false, false).dispatch, "A");
    }

    // A fresh inflight never inherits the previous run's completion flags.
    function test_requestSnippet_startsWithCleanFlags() {
        var q = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false, false).queue;
        q = Svc.snippetEvent(q, "stream").queue; // textReady set, run not over
        var r = Svc.requestSnippet(q, "B", false, false);
        compare(r.queue.inflight, "B");
        compare(r.queue.textReady, false);
        compare(r.queue.exited, false);
    }

    // The two signals of one process arrive in no guaranteed order: completion must be
    // the same either way, or a result lands under the wrong thread again.
    function test_snippetEvent_completesOnEitherSignalOrder() {
        var orders = [["stream", "exit"], ["exit", "stream"]];
        for (var i = 0; i < orders.length; i++) {
            var q = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false, false).queue;
            var first = Svc.snippetEvent(q, orders[i][0]);
            compare(first.completedId, ""); // one signal is not enough
            var second = Svc.snippetEvent(first.queue, orders[i][1]);
            compare(second.completedId, "A");
            compare(second.queue.inflight, "");
        }
    }

    function test_snippetEvent_dispatchesPendingOnCompletion() {
        var q = Svc.requestSnippet(Svc.newSnippetQueue(), "A", false, false).queue;
        q = Svc.requestSnippet(q, "B", false, true).queue; // A still running → B pends
        var done = Svc.snippetEvent(Svc.snippetEvent(q, "stream").queue, "exit");
        compare(done.completedId, "A");
        compare(done.dispatch, "B");
        compare(done.queue.inflight, "B");
        compare(done.queue.pending, "");
        compare(done.queue.textReady, false); // flags reset for the new run
    }
}
