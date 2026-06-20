// Popout cockpit. Phase 3 : squelette (en-tête télémétrie + refresh + pied). La liste de
// fils, le rail, la recherche et les actions arrivent aux phases suivantes.
// Reçoit le service Notmuch en propriété (data → view, le QML n'appelle pas notmuch direct).
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PopoutComponent {
    id: cockpit

    property var notmuch: null

    headerText: "ASTROPATH"
    detailsText: notmuch ? (notmuch.status === "querying" ? "synchro…" : notmuch.status === "error" ? "erreur de synchro" : "à jour") : ""
    showCloseButton: true

    Column {
        width: parent.width
        spacing: Theme.spacingM

        // Barre d'outils : refresh manuel (= re-query, jamais notmuch new).
        StyledRect {
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

        // Zone liste (Phase 4).
        StyledText {
            text: "Liste des fils — à venir (Phase 4)"
            color: Theme.surfaceTextMedium
            font.pixelSize: Theme.fontSizeMedium
        }

        // Pied : raccourcis clavier (enrichi en Phase 9).
        StyledText {
            text: "j/k · ⏎ · e · #"
            color: Theme.surfaceTextMedium
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
