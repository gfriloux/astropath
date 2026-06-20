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

            StyledText {
                id: countText
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingM
                anchors.verticalCenter: parent.verticalCenter
                visible: item.modelData.count > 0
                text: item.modelData.count
                font.family: Theme.monoFontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: item.selected ? Theme.primary : Theme.surfaceTextMedium
            }

            StyledText {
                id: label
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingM
                anchors.right: countText.visible ? countText.left : parent.right
                anchors.rightMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData.label
                elide: Text.ElideRight
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
