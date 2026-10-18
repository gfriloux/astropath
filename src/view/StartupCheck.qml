// Activation gate (DMS startupCheck, needs DMS >= 1.5.0). DMS instantiates this before
// loading the widget and calls check(done): done(null) allows activation, done({title,
// details}) blocks it with a message the user actually sees.
//
// astropath is useless without a working notmuch, and the manifest cannot say so in a
// way the loader acts on — "dependencies" is displayed, never enforced. Without this
// gate a missing or unreadable database surfaced later as an empty list and a status
// stuck on "error", with nothing saying why.
//
// The probe is a cheap thread count over the whole database: it proves notmuch is on
// PATH, runnable, and able to open its Xapian index.
import QtQuick
import Quickshell.Io
import "../query/queries.js" as Queries

QtObject {
    id: root

    property int timeoutMs: 5000
    property var _done: null
    property string _stderr: ""

    // Every path out of here goes through this: the probe must answer exactly once.
    // A gate that fires twice confuses DMS; one that never fires hangs activation, which
    // is worse than having no gate at all.
    function _answer(error) {
        if (!root._done)
            return;
        var cb = root._done;
        root._done = null;
        timeout.running = false;
        cb(error);
    }

    function check(done) {
        root._done = done;
        root._stderr = "";
        timeout.running = true;
        probe.running = true;
    }

    property Timer timeout: Timer {
        id: timeout
        interval: root.timeoutMs
        repeat: false
        onTriggered: root._answer({
            "title": "notmuch ne répond pas",
            "details": "La commande notmuch n'a pas répondu en " + (root.timeoutMs / 1000) + " s. La base est peut-être en cours de réindexation."
        })
    }

    property Process probe: Process {
        id: probe
        command: ["notmuch"].concat(Queries.count("*", "threads"))
        running: false

        stderr: StdioCollector {
            onStreamFinished: root._stderr = text.trim()
        }

        // A notmuch that cannot start never reaches this handler; the timer covers that.
        onExited: code => {
            if (code === 0) {
                root._answer(null);
                return;
            }
            root._answer({
                "title": "La base notmuch est illisible",
                "details": root._stderr.length > 0 ? root._stderr : "notmuch s'est terminé avec le code " + code + "."
            });
        }
    }
}
