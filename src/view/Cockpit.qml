// Popout cockpit. Phase 5 : en-tête + refresh + rail recherches sauvegardées + liste de
// fils (requête courante) + pied. Recherche, actions et settings arrivent ensuite.
// Reçoit le service Notmuch en propriété (data → view, le QML n'appelle pas notmuch direct).
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PopoutComponent {
    id: cockpit

    property var notmuch: null
    property int viewHeight: 520

    headerText: "ASTROPATH"
    detailsText: notmuch ? (notmuch.status === "querying" ? "synchro…" : notmuch.status === "error" ? "erreur de synchro" : "à jour") : ""
    showCloseButton: true

    Item {
        width: parent.width
        height: cockpit.viewHeight - cockpit.headerHeight - cockpit.detailsHeight - Theme.spacingXL

        // Barre d'outils : refresh manuel (= re-query, jamais notmuch new).
        StyledRect {
            id: toolbar
            anchors.top: parent.top
            anchors.right: parent.right
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

        // Pied : raccourcis clavier (enrichi en Phase 9).
        StyledText {
            id: footer
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            text: "j/k · ⏎ · e · #"
            color: Theme.surfaceTextMedium
            font.pixelSize: Theme.fontSizeSmall
        }

        // Rail gauche : recherches sauvegardées.
        SavedSearchRail {
            id: rail
            anchors.top: toolbar.bottom
            anchors.bottom: footer.top
            anchors.left: parent.left
            anchors.topMargin: Theme.spacingS
            anchors.bottomMargin: Theme.spacingS
            width: 172
            notmuch: cockpit.notmuch
        }

        // Liste des fils de la requête courante.
        DankListView {
            anchors.top: toolbar.bottom
            anchors.bottom: footer.top
            anchors.left: rail.right
            anchors.right: parent.right
            anchors.leftMargin: Theme.spacingM
            anchors.topMargin: Theme.spacingS
            anchors.bottomMargin: Theme.spacingS
            clip: true
            spacing: Theme.spacingXS
            model: cockpit.notmuch ? cockpit.notmuch.threads : []
            delegate: ThreadRow {}
        }
    }
}
