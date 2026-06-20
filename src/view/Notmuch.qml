// Service Notmuch : lance notmuch via Process, parse avec la couche données (threads.js),
// expose le modèle + un statut. Polling périodique (pas de notmuch new : on lit seulement).
import QtQuick
import Quickshell.Io
import "../query/queries.js" as Queries
import "../model/threads.js" as Model

QtObject {
    id: root

    property int intervalMs: 20000

    // Requête affichée dans la liste (par défaut : les non-lus de la boîte).
    property string currentQuery: Queries.UNREAD_QUERY
    property var threads: []

    // Compteur du badge : toujours les non-lus, indépendant de la requête courante.
    property int unreadCount: 0

    property string status: "idle" // idle | querying | error
    property double lastSyncAt: 0

    // Définitions des smart folders (CONFIG ; défaut universel, aucune taxonomie perso —
    // les catégories perso seront ajoutées via les réglages, Phase 8).
    property var definitions: [
        {
            "key": "inbox",
            "label": "Inbox",
            "query": "tag:inbox",
            "color": ""
        },
        {
            "key": "flagged",
            "label": "Flaggés",
            "query": "tag:flagged",
            "color": ""
        },
        {
            "key": "spam",
            "label": "Spam",
            "query": "tag:spam",
            "color": ""
        }
    ]
    readonly property var savedSearches: Model.savedSearches(definitions, ({}))

    // Pose le command impérativement (pas de binding lazy) puis lance : garantit que la
    // requête lancée est bien la requête courante, même juste après un changement.
    function runSearch() {
        root.status = "querying";
        searchProc.command = ["notmuch"].concat(Queries.search(root.currentQuery));
        searchProc.running = true;
    }

    function refresh() {
        runSearch();
        unreadProc.running = true;
    }

    function setQuery(q) {
        root.currentQuery = q;
        runSearch();
    }

    // Recherche libre : texte vide → revient aux non-lus par défaut.
    function searchText(t) {
        setQuery(t && t.length > 0 ? t : Queries.UNREAD_QUERY);
    }

    // Liste : search de la requête courante.
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

    // Compteur badge : count des non-lus.
    property Process unreadProc: Process {
        command: ["notmuch"].concat(Queries.count(Queries.UNREAD_QUERY))
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.unreadCount = Model.parseCount(text)
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
