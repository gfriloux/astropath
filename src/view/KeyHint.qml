// Indice de raccourci clavier : une touche (keycap) + son action, pour le pied du cockpit.
import QtQuick
import qs.Common
import qs.Widgets

Row {
    id: hint

    property string keyName: ""
    property string action: ""

    spacing: Theme.spacingXS

    StyledRect {
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.cornerRadius / 2
        color: Theme.surfaceContainerHigh
        implicitWidth: keycap.implicitWidth + Theme.spacingS
        implicitHeight: keycap.implicitHeight + 2

        StyledText {
            id: keycap
            anchors.centerIn: parent
            text: hint.keyName
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
        }
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: hint.action
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceTextMedium
    }
}
