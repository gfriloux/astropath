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
}
