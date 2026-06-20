// Service Notmuch : lance notmuch via Process, parse avec la couche données (threads.js),
// expose le modèle + un statut. Polling périodique (pas de notmuch new : on lit seulement).
import QtQuick
import Quickshell.Io
import "../query/queries.js" as Queries
import "../model/threads.js" as Model

QtObject {
    id: root

    property int intervalMs: 20000
    property var unreadThreads: []
    readonly property int unreadCount: unreadThreads.length
    property string status: "idle" // idle | querying | error
    property double lastSyncAt: 0

    function refresh() {
        root.status = "querying";
        searchProc.running = true;
    }

    // Fils non-lus : notmuch search --format=json 'tag:inbox and tag:unread'
    property Process searchProc: Process {
        command: ["notmuch"].concat(Queries.searchUnread())
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.unreadThreads = Model.parseSearch(JSON.parse(text));
                    root.status = "idle";
                    root.lastSyncAt = Date.now();
                } catch (e) {
                    root.status = "error";
                    console.warn("astropath: parse search échoué:", e);
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

    // Polling : re-query périodiquement (récupère ce que la machinerie externe a indexé).
    property Timer poll: Timer {
        interval: root.intervalMs
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
