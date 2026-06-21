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
    readonly property string snippet: (notmuch && notmuch.snippets[thread.id]) ? notmuch.snippets[thread.id] : ""
    property bool retagging: false

    // Récupère le snippet (notmuch show paresseux) quand le fil devient courant.
    onActiveChanged: if (active && notmuch)
        notmuch.fetchSnippet(thread.id)
    onRetaggingChanged: if (retagging)
        retagField.forceActiveFocus()

    width: ListView.view ? ListView.view.width : implicitWidth
    implicitHeight: layout.implicitHeight + Theme.spacingM * 2
    radius: Theme.cornerRadius
    color: active ? Theme.primarySelected : (rowHover.hovered ? Theme.surfaceContainerHigh : "transparent")

    // Transition douce du fond entre repos / survol / sélection (neutralisée si None).
    Behavior on color {
        enabled: Theme.currentAnimationSpeed !== SettingsData.AnimationSpeed.None
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }
    }

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

    // Bord-gauche d'accent mauve sur le fil actif (cf. DESIGN.md). Glisse en largeur
    // à la sélection (neutralisé si animations = None).
    Rectangle {
        id: accent
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.spacingXS
        anchors.bottomMargin: Theme.spacingXS
        width: row.active ? 3 : 0
        radius: width / 2
        color: Theme.primary

        Behavior on width {
            enabled: Theme.currentAnimationSpeed !== SettingsData.AnimationSpeed.None
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
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
                        font.weight: row.thread.unread ? Font.DemiBold : Font.Medium
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

                // Snippet (notmuch show), affiché sur l'élément courant.
                StyledText {
                    width: parent.width
                    visible: row.active && row.snippet.length > 0
                    text: row.snippet
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.withAlpha(Theme.surfaceText, 0.5)
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Row {
                    spacing: Theme.spacingXS

                    Repeater {
                        model: row.displayTags

                        StyledRect {
                            id: chip
                            required property string modelData
                            readonly property var tc: row.notmuch ? row.notmuch.tagColors : ({})
                            readonly property bool hasColor: tc[modelData] !== undefined
                            radius: Theme.cornerRadius / 2
                            color: hasColor ? Theme.withAlpha(tc[modelData], 0.16) : Theme.surfaceContainerHigh
                            implicitWidth: chipText.implicitWidth + Theme.spacingS
                            implicitHeight: chipText.implicitHeight + 2

                            StyledText {
                                id: chipText
                                anchors.centerIn: parent
                                text: chip.modelData
                                font.pixelSize: Theme.fontSizeSmall
                                color: chip.hasColor ? chip.tc[chip.modelData] : Theme.surfaceTextMedium
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
            clip: true

            readonly property bool shown: rowHover.hovered || row.active
            visible: implicitHeight > 0
            implicitHeight: shown ? abCol.implicitHeight : 0
            opacity: shown ? 1 : 0

            Behavior on implicitHeight {
                enabled: Theme.currentAnimationSpeed !== SettingsData.AnimationSpeed.None
                NumberAnimation {
                    duration: Theme.shortDuration
                    easing.type: Theme.standardEasing
                }
            }
            Behavior on opacity {
                enabled: Theme.currentAnimationSpeed !== SettingsData.AnimationSpeed.None
                NumberAnimation {
                    duration: Theme.shortDuration
                    easing.type: Theme.standardEasing
                }
            }

            Column {
                id: abCol
                width: parent.width
                spacing: Theme.spacingXS

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
                        icon: "sell"
                        hoverColor: Theme.primary
                        onTriggered: row.retagging = !row.retagging
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

                // Éditeur de retag inline : « +tag -tag » puis Entrée.
                DankTextField {
                    id: retagField
                    visible: row.retagging
                    width: parent.width
                    placeholderText: "+tag -tag puis Entrée"
                    font.family: Theme.monoFontFamily

                    Keys.onReturnPressed: {
                        if (row.notmuch)
                            row.notmuch.tag(row.thread.id, Format.parseRetag(text));
                        row.retagging = false;
                        text = "";
                    }
                    Keys.onEscapePressed: {
                        row.retagging = false;
                        text = "";
                    }
                }
            }
        }
    }

    // Filet séparateur en pied de rangée, fondu aux bords. Masqué (en fondu) autour de
    // la carte active/survolée et sous le dernier fil, pour ne jamais trancher une carte.
    GradientSeparator {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM

        readonly property bool last: row.ListView.view ? row.index === row.ListView.view.count - 1 : false
        opacity: (row.active || rowHover.hovered || last) ? 0 : 1

        Behavior on opacity {
            enabled: Theme.currentAnimationSpeed !== SettingsData.AnimationSpeed.None
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }
        }
    }
}
