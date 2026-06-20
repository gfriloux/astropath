// Une ligne de fil dans la liste cockpit. Délégué de DankListView : `modelData` = un objet
// Thread (sortie de parseSearch). Distinction lu/non-lu, chips de tags (neutres pour
// l'instant — couleurs depuis la config en Phase 8), flag, heure relative, compteur.
import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: row

    required property var modelData
    readonly property var thread: modelData

    width: ListView.view ? ListView.view.width : implicitWidth
    implicitHeight: body.implicitHeight + Theme.spacingM * 2
    radius: Theme.cornerRadius
    color: hover.containsMouse ? Theme.surfaceContainerHigh : "transparent"

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }

    Row {
        id: body
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        Rectangle {
            width: 8
            height: 8
            radius: 4
            anchors.top: parent.top
            anchors.topMargin: Theme.spacingXS
            color: row.thread.unread ? Theme.primary : "transparent"
        }

        Column {
            width: parent.width - 8 - Theme.spacingS
            spacing: 2

            Item {
                width: parent.width
                implicitHeight: sender.implicitHeight

                StyledText {
                    id: sender
                    anchors.left: parent.left
                    width: parent.width - time.width - Theme.spacingM
                    text: row.thread.authors + (row.thread.total > 1 ? "  (" + row.thread.total + ")" : "")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: row.thread.unread ? Font.DemiBold : Font.Normal
                    color: row.thread.unread ? Theme.surfaceText : Theme.surfaceTextMedium
                    elide: Text.ElideRight
                }

                StyledText {
                    id: time
                    anchors.right: parent.right
                    text: row.thread.dateRelative
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceTextMedium
                }
            }

            StyledText {
                width: parent.width
                text: row.thread.subject
                font.pixelSize: Theme.fontSizeMedium
                color: row.thread.unread ? Theme.surfaceText : Theme.surfaceTextMedium
                elide: Text.ElideRight
            }

            Row {
                spacing: Theme.spacingXS

                Repeater {
                    model: row.thread.tags

                    StyledRect {
                        required property string modelData
                        radius: Theme.cornerRadius / 2
                        color: Theme.surfaceContainerHigh
                        implicitWidth: chipText.implicitWidth + Theme.spacingS
                        implicitHeight: chipText.implicitHeight + 2

                        StyledText {
                            id: chipText
                            anchors.centerIn: parent
                            text: parent.modelData
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }
                    }
                }

                DankIcon {
                    visible: row.thread.flagged
                    name: "flag"
                    size: Theme.fontSizeMedium
                    color: Theme.warning
                }
            }
        }
    }
}
