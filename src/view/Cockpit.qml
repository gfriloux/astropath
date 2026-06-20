// Popout cockpit. Phase 6 : en-tête + rail + barre de recherche + liste + refresh + pied.
// Actions inline et settings arrivent ensuite.
// Reçoit le service Notmuch en propriété (data → view, le QML n'appelle pas notmuch direct).
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "../model/format.js" as Format

PopoutComponent {
    id: cockpit

    property var notmuch: null
    property int viewHeight: 520
    // Horloge pour rafraîchir l'affichage « il y a N min ».
    property double now: Date.now()

    headerText: "ASTROPATH"
    detailsText: {
        if (!notmuch)
            return "";
        if (notmuch.status === "querying")
            return "synchro…";
        if (notmuch.status === "error")
            return "erreur de synchro";
        var rel = Format.relativeTime(notmuch.lastSyncAt, cockpit.now);
        return rel ? "à jour · " + rel : "à jour";
    }
    showCloseButton: true

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: cockpit.now = Date.now()
    }

    Item {
        width: parent.width
        height: cockpit.viewHeight - cockpit.headerHeight - cockpit.detailsHeight - Theme.spacingXL

        // Rail gauche : recherches sauvegardées (pleine hauteur).
        SavedSearchRail {
            id: rail
            anchors.top: parent.top
            anchors.bottom: footer.top
            anchors.left: parent.left
            anchors.bottomMargin: Theme.spacingS
            width: 172
            notmuch: cockpit.notmuch
        }

        // Barre du haut (zone principale) : recherche + refresh.
        Item {
            id: topbar
            anchors.top: parent.top
            anchors.left: rail.right
            anchors.right: parent.right
            anchors.leftMargin: Theme.spacingM
            height: 36

            StyledRect {
                id: refresh
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                radius: Theme.cornerRadius
                color: refreshArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                DankIcon {
                    anchors.centerIn: parent
                    name: "refresh"
                    size: Theme.fontSizeLarge
                    color: Theme.surfaceText
                }

                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (cockpit.notmuch)
                        cockpit.notmuch.refresh()
                }
            }

            SearchBar {
                anchors.left: parent.left
                anchors.right: refresh.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Theme.spacingS
                notmuch: cockpit.notmuch
            }
        }

        // Liste des fils de la requête courante. Navigation clavier j/k/⏎/e/#.
        DankListView {
            id: list
            anchors.top: topbar.bottom
            anchors.bottom: footer.top
            anchors.left: rail.right
            anchors.right: parent.right
            anchors.leftMargin: Theme.spacingM
            anchors.topMargin: Theme.spacingS
            anchors.bottomMargin: Theme.spacingS
            clip: true
            spacing: Theme.spacingXS
            focus: true
            model: cockpit.notmuch ? cockpit.notmuch.threads : []
            delegate: ThreadRow {
                notmuch: cockpit.notmuch
            }

            // La liste prend le focus clavier à l'ouverture du popout.
            Component.onCompleted: list.forceActiveFocus()

            Keys.onPressed: event => {
                if (list.count === 0 || !cockpit.notmuch)
                    return;
                const i = list.currentIndex;
                const t = cockpit.notmuch.threads[i];
                const k = event.text;
                if (k === "j") {
                    list.currentIndex = Math.min(list.count - 1, i + 1);
                    event.accepted = true;
                } else if (k === "k") {
                    list.currentIndex = Math.max(0, i - 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (t)
                        cockpit.notmuch.open(t.id);
                    event.accepted = true;
                } else if (k === "e") {
                    if (t)
                        cockpit.notmuch.archive(t.id);
                    event.accepted = true;
                } else if (k === "#") {
                    if (t)
                        cockpit.notmuch.trash(t.id);
                    event.accepted = true;
                }
            }
        }

        // Pied : raccourcis clavier (la navigation effective arrive en Phase 9b).
        Row {
            id: footer
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            spacing: Theme.spacingM

            KeyHint {
                keyName: "j/k"
                action: "parcourir"
            }
            KeyHint {
                keyName: "⏎"
                action: "ouvrir"
            }
            KeyHint {
                keyName: "e"
                action: "archiver"
            }
            KeyHint {
                keyName: "#"
                action: "supprimer"
            }
        }
    }
}
