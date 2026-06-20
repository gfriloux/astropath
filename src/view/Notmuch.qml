// Service Notmuch : lance notmuch via Process, parse avec la couche données (threads.js),
// expose le modèle + un statut. Polling périodique (pas de notmuch new : on lit seulement).
import QtQuick
import Quickshell
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

    // Définitions des smart folders : injectées depuis la config (settings du plugin).
    // Le widget fournit un défaut universel si la config est vide.
    property var definitions: []
    readonly property var savedSearches: Model.savedSearches(definitions, ({}))

    // Commande du client de lecture (config) — pour ouvrir un fil.
    property string readerCommand: ""

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

    // Mutations de tags (tag-only). Après succès → refresh de la liste.
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

    // Ouvre un fil dans le client de lecture configuré (la requête thread:<id> est ajoutée).
    function open(id) {
        if (root.readerCommand && root.readerCommand.length > 0)
            Quickshell.execDetached(["sh", "-c", root.readerCommand + " thread:" + id]);
        else
            console.warn("astropath: commande de lecture non configurée (réglages)");
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

    // Mutation de tags : notmuch tag … -- thread:id.
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
