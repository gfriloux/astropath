// One thread row in the cockpit list. DankListView delegate: `modelData` = a Thread object
// (parseSearch). Monogram avatar, read/unread distinction, tag chips (categories), flag,
// time/counter in mono, keyboard highlight, action bar revealed BELOW.
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

    // State tags hidden (already conveyed otherwise): only categories are displayed.
    readonly property var noiseTags: ["unread", "inbox", "flagged", "attachment", "replied", "sent", "draft", "signed", "encrypted", "new"]
    readonly property var displayTags: (thread.tags || []).filter(t => row.noiseTags.indexOf(t) === -1)

    // Avatar palette derived from the DMS theme (no hardcoded hex); hue per sender.
    readonly property var avatarPalette: [Theme.primary, Theme.info, Theme.success, Theme.warning, Theme.error, Theme.secondary]
    readonly property color avatarColor: avatarPalette[Format.colorIndex(thread.authors, avatarPalette.length)]

    readonly property bool active: row.ListView.isCurrentItem
    readonly property string snippet: (notmuch && notmuch.snippets[thread.id]) ? notmuch.snippets[thread.id] : ""
    property bool retagging: false

    // Fetches the snippet (lazy notmuch show) when the thread becomes the current one.
    onActiveChanged: if (active && notmuch)
        notmuch.fetchSnippet(thread.id)
    onRetaggingChanged: if (retagging)
        retagField.forceActiveFocus()

    width: ListView.view ? ListView.view.width : implicitWidth
    implicitHeight: layout.implicitHeight + Theme.spacingM * 2
    radius: Theme.cornerRadius
    color: active ? Theme.primarySelected : (rowHover.hovered ? Theme.surfaceContainerHigh : "transparent")

    // Smooth background transition between rest / hover / selection (neutralized when None).
    Behavior on color {
        enabled: Theme.currentAnimationSpeed !== SettingsData.AnimationSpeed.None
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }
    }

    // Staggered fade-in (disabled when animations = None).
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

        // Content: avatar + text.
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
                        font.weight: Font.DemiBold
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
                    font.weight: Font.Normal
                    color: row.thread.unread ? Theme.surfaceTextMedium : Theme.withAlpha(Theme.surfaceText, 0.55)
                    elide: Text.ElideRight
                }

                // Snippet (notmuch show), shown on the current item.
                StyledText {
                    width: parent.width
                    visible: row.active && row.snippet.length > 0
                    text: row.snippet
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.withAlpha(Theme.surfaceText, 0.42)
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

        // Action bar revealed BELOW on hover / on the current item (invisible →
        // excluded from the Column, so the row stays compact).
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
                        tooltip: "Marquer lu"
                        onTriggered: if (row.notmuch)
                            row.notmuch.markRead(row.thread.id)
                    }
                    ActionButton {
                        icon: "archive"
                        hoverColor: Theme.info
                        tooltip: "Archiver"
                        onTriggered: if (row.notmuch)
                            row.notmuch.archive(row.thread.id)
                    }
                    ActionButton {
                        icon: "flag"
                        hoverColor: Theme.warning
                        tooltip: row.thread.flagged ? "Retirer le flag" : "Flag"
                        onTriggered: if (row.notmuch)
                            row.notmuch.toggleFlag(row.thread.id, row.thread.flagged)
                    }
                    ActionButton {
                        icon: "sell"
                        hoverColor: Theme.primary
                        tooltip: "Retag"
                        onTriggered: row.retagging = !row.retagging
                    }
                    ActionButton {
                        icon: "delete"
                        hoverColor: Theme.error
                        tooltip: "Supprimer"
                        onTriggered: if (row.notmuch)
                            row.notmuch.trash(row.thread.id)
                    }
                    ActionButton {
                        icon: "open_in_new"
                        hoverColor: Theme.primary
                        tooltip: "Ouvrir"
                        onTriggered: if (row.notmuch)
                            row.notmuch.open(row.thread.id)
                    }
                }

                // Inline retag editor: « +tag -tag » then Enter.
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

    // Separator hairline at the row's foot, fading at both ends. Faded out around the
    // active/hovered card and under the last thread, so it never cuts through a card.
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
