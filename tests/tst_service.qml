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

    function test_requestFlight_dispatchesWhenIdle() {
        var r = Svc.requestFlight(Svc.newFlight(), "A", false, false);
        compare(r.dispatch, "A");
        compare(r.flight.inflight, "A");
    }

    function test_requestFlight_cachedOrEmptyIsNoop() {
        compare(Svc.requestFlight(Svc.newFlight(), "A", true, false).dispatch, "");
        compare(Svc.requestFlight(Svc.newFlight(), "", false, false).dispatch, "");
    }

    function test_requestFlight_queuesNewestWhileInflight() {
        var q = Svc.requestFlight(Svc.newFlight(), "A", false, false).flight;
        var b = Svc.requestFlight(q, "B", false, true);
        compare(b.dispatch, "");          // A is still running: nothing is started
        compare(b.flight.inflight, "A");   // and A is NOT overwritten
        var c = Svc.requestFlight(b.flight, "C", false, true);
        compare(c.flight.pending, "C");    // newest pending wins
    }

    function test_requestFlight_sameIdInflightIsNoop() {
        var q = Svc.requestFlight(Svc.newFlight(), "A", false, false).flight;
        compare(Svc.requestFlight(q, "A", false, true).dispatch, "");
    }

    // A process that died without ever completing (notmuch failed to start) leaves an
    // inflight id no signal will ever clear. The next navigation must retry, not wedge.
    function test_requestFlight_deadInflightIsAbandoned() {
        var q = Svc.requestFlight(Svc.newFlight(), "A", false, false).flight;
        var r = Svc.requestFlight(q, "B", false, false);
        compare(r.dispatch, "B");
        compare(r.flight.inflight, "B");
        compare(r.flight.pending, "");
    }

    function test_requestFlight_deadInflightRetriesTheSameId() {
        var q = Svc.requestFlight(Svc.newFlight(), "A", false, false).flight;
        compare(Svc.requestFlight(q, "A", false, false).dispatch, "A");
    }

    // A fresh inflight never inherits the previous run's completion flags.
    function test_requestFlight_startsWithCleanFlags() {
        var q = Svc.requestFlight(Svc.newFlight(), "A", false, false).flight;
        q = Svc.flightEvent(q, "stream").flight; // streamDone set, run not over
        var r = Svc.requestFlight(q, "B", false, false);
        compare(r.flight.inflight, "B");
        compare(r.flight.streamDone, false);
        compare(r.flight.exited, false);
    }

    // The two signals of one process arrive in no guaranteed order: completion must be
    // the same either way, or a result lands under the wrong thread again.
    function test_flightEvent_completesOnEitherSignalOrder() {
        var orders = [["stream", "exit"], ["exit", "stream"]];
        for (var i = 0; i < orders.length; i++) {
            var q = Svc.requestFlight(Svc.newFlight(), "A", false, false).flight;
            var first = Svc.flightEvent(q, orders[i][0]);
            compare(first.completedKey, ""); // one signal is not enough
            var second = Svc.flightEvent(first.flight, orders[i][1]);
            compare(second.completedKey, "A");
            compare(second.flight.inflight, "");
        }
    }

    function test_flightEvent_dispatchesPendingOnCompletion() {
        var q = Svc.requestFlight(Svc.newFlight(), "A", false, false).flight;
        q = Svc.requestFlight(q, "B", false, true).flight; // A still running → B pends
        var done = Svc.flightEvent(Svc.flightEvent(q, "stream").flight, "exit");
        compare(done.completedKey, "A");
        compare(done.dispatch, "B");
        compare(done.flight.inflight, "B");
        compare(done.flight.pending, "");
        compare(done.flight.streamDone, false); // flags reset for the new run
    }
}
