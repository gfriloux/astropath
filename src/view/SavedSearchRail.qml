// Rail gauche : recherches sauvegardées (smart folders). Libellés cliquables ; sélection
// change la requête courante du service. Compteurs par recherche = raffinement ultérieur.
import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: rail

    property var notmuch: null
    readonly property string selectedQuery: notmuch ? notmuch.currentQuery : ""

    spacing: Theme.spacingXS

    Repeater {
        model: rail.notmuch ? rail.notmuch.savedSearches : []

        StyledRect {
            id: item

            required property var modelData
            readonly property bool selected: rail.selectedQuery === modelData.query

            width: rail.width
            implicitHeight: label.implicitHeight + Theme.spacingS * 2
            radius: Theme.cornerRadius
            color: selected ? Theme.primarySelected : (itemArea.containsMouse ? Theme.surfaceContainerHigh : "transparent")

            Rectangle {
                visible: item.selected
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: parent.height - Theme.spacingXS
                radius: 1.5
                color: Theme.primary
            }

            StyledText {
                id: label
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingM
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData.label
                font.pixelSize: Theme.fontSizeMedium
                color: item.selected ? Theme.primary : Theme.surfaceText
            }

            MouseArea {
                id: itemArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (rail.notmuch)
                    rail.notmuch.setQuery(item.modelData.query)
            }
        }
    }
}
