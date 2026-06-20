// Une ligne de fil dans la liste cockpit. Délégué de DankListView : `modelData` = un objet
// Thread (parseSearch). Avatar monogramme, distinction lu/non-lu, chips de tags (catégories),
// flag, heure/compteur en mono, surlignage clavier, barre d'actions révélée EN DESSOUS.
import QtQuick
import qs.Common
import qs.Widgets
import "../model/format.js" as Format

StyledRect {
    id: row

    required property var modelData
    required property int index
    readonly property var thread: modelData
    property var notmuch: null

    // Tags d'état masqués (déjà indiqués autrement) : on n'affiche que les catégories.
    readonly property var noiseTags: ["unread", "inbox", "flagged", "attachment", "replied", "sent", "draft", "signed", "encrypted", "new"]
    readonly property var displayTags: (thread.tags || []).filter(t => row.noiseTags.indexOf(t) === -1)

    // Palette d'avatar dérivée du thème DMS (pas de hex en dur) ; teinte par expéditeur.
    readonly property var avatarPalette: [Theme.primary, Theme.info, Theme.success, Theme.warning, Theme.error, Theme.secondary]
    readonly property color avatarColor: avatarPalette[Format.colorIndex(thread.authors, avatarPalette.length)]

    readonly property bool active: row.ListView.isCurrentItem

    width: ListView.view ? ListView.view.width : implicitWidth
    implicitHeight: layout.implicitHeight + Theme.spacingM * 2
    radius: Theme.cornerRadius
    color: active ? Theme.primarySelected : (rowHover.hovered ? Theme.surfaceContainerHigh : "transparent")

    // Apparition en fondu échelonné (désactivée si animations = None).
    opacity: 0
    Component.onCompleted: {
        if (Theme.currentAnimationSpeed === SettingsData.AnimationSpeed.None) {
            opacity = 1;
            return;
        }
        appear.start();
    }
    SequentialAnimation {
        id: appear
        PauseAnimation {
            duration: Math.min(row.index, 10) * 25
        }
        NumberAnimation {
            target: row
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.shortDuration
            easing.type: Easing.OutQuad
        }
    }

    HoverHandler {
        id: rowHover
    }

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

    Column {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        // Contenu : avatar + texte.
        Row {
            id: body
            width: parent.width
            spacing: Theme.spacingS

            Item {
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                StyledRect {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.withAlpha(row.avatarColor, 0.2)

                    StyledText {
                        anchors.centerIn: parent
                        text: Format.initials(row.thread.authors)
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: row.avatarColor
                    }
                }

                Rectangle {
                    visible: row.thread.unread
                    width: 10
                    height: 10
                    radius: 5
                    anchors.right: parent.right
                    anchors.top: parent.top
                    color: Theme.primary
                    border.width: 2
                    border.color: Theme.surface
                }
            }

            Column {
                width: parent.width - 32 - Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Item {
                    width: parent.width
                    implicitHeight: sender.implicitHeight

                    StyledText {
                        id: sender
                        anchors.left: parent.left
                        width: parent.width - meta.width - Theme.spacingM
                        text: row.thread.authors
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: row.thread.unread ? Font.DemiBold : Font.Normal
                        color: row.thread.unread ? Theme.surfaceText : Theme.surfaceTextMedium
                        elide: Text.ElideRight
                    }

                    Row {
                        id: meta
                        anchors.right: parent.right
                        spacing: Theme.spacingXS

                        StyledText {
                            visible: row.thread.total > 1
                            anchors.verticalCenter: parent.verticalCenter
                            text: "(" + row.thread.total + ")"
                            font.family: Theme.monoFontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.thread.dateRelative
                            font.family: Theme.monoFontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }
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
                        model: row.displayTags

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

        // Barre d'actions révélée EN DESSOUS au survol / sur l'élément courant (invisible →
        // exclue du Column, la ligne reste compacte).
        Item {
            id: actionBar
            width: parent.width
            visible: rowHover.hovered || row.active
            implicitHeight: visible ? actions.implicitHeight : 0

            Row {
                id: actions
                anchors.right: parent.right
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
}
