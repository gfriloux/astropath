// Petit bouton d'action (icône) pour la rangée d'actions inline d'un fil.
import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: btn

    property string icon: ""
    property color hoverColor: Theme.surfaceText

    signal triggered

    width: 28
    height: 28
    radius: Theme.cornerRadius
    color: area.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

    DankIcon {
        anchors.centerIn: parent
        name: btn.icon
        size: Theme.fontSizeMedium
        color: area.containsMouse ? btn.hoverColor : Theme.surfaceText
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.triggered()
    }
}
