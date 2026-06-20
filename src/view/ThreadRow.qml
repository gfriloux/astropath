// Une ligne de fil dans la liste cockpit. Délégué de DankListView : `modelData` = un objet
// Thread (sortie de parseSearch). Distinction lu/non-lu, chips de tags (neutres pour
// l'instant — couleurs depuis la config en Phase 8), flag, heure relative, compteur.
// Au survol : rangée d'actions sur fond opaque (HoverHandler → pas de clignotement).
import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: row

    required property var modelData
    required property int index
    readonly property var thread: modelData
    property var notmuch: null

    width: ListView.view ? ListView.view.width : implicitWidth
    implicitHeight: body.implicitHeight + Theme.spacingM * 2
    radius: Theme.cornerRadius
    color: row.ListView.isCurrentItem ? Theme.primarySelected : (rowHover.hovered ? Theme.surfaceContainerHigh : "transparent")

    // Survol passif : reste vrai même au-dessus des boutons d'action enfants.
    HoverHandler {
        id: rowHover
    }

    // Clic sur un fil : sélectionne et donne le focus clavier à la liste (j/k/⏎/e/#).
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            const v = row.ListView.view;
            if (v) {
                v.currentIndex = row.index;
                v.forceActiveFocus();
            }
        }
    }

    // Bord-gauche mauve sur l'élément sous le curseur clavier.
    Rectangle {
        visible: row.ListView.isCurrentItem
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - Theme.spacingS
        radius: 1.5
        color: Theme.primary
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

    // Rangée d'actions révélée au survol, sur fond opaque (ne masque pas le texte par
    // superposition). Ouvrir/retag arrivent en Phase 8.
    StyledRect {
        id: actionsBg
        visible: rowHover.hovered
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: actions.implicitWidth + Theme.spacingM * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHighest

        Row {
            id: actions
            anchors.centerIn: parent
            spacing: Theme.spacingXS

            ActionButton {
                visible: row.thread.unread
                icon: "mark_email_read"
                hoverColor: Theme.success
                onTriggered: if (row.notmuch)
                    row.notmuch.markRead(row.thread.id)
            }
            ActionButton {
                icon: "archive"
                hoverColor: Theme.info
                onTriggered: if (row.notmuch)
                    row.notmuch.archive(row.thread.id)
            }
            ActionButton {
                icon: "flag"
                hoverColor: Theme.warning
                onTriggered: if (row.notmuch)
                    row.notmuch.toggleFlag(row.thread.id, row.thread.flagged)
            }
            ActionButton {
                icon: "delete"
                hoverColor: Theme.error
                onTriggered: if (row.notmuch)
                    row.notmuch.trash(row.thread.id)
            }
            ActionButton {
                icon: "open_in_new"
                hoverColor: Theme.primary
                onTriggered: if (row.notmuch)
                    row.notmuch.open(row.thread.id)
            }
        }
    }
}
