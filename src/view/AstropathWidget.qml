// astropath bar widget (DankMaterialShell plugin). Mail icon + unread badge, backed by the
// Notmuch service; clicking opens the cockpit popout. Theme and components inherited from DMS.
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // Unread thread counter, fed by the Notmuch service (polling).
    readonly property int unreadCount: notmuchSvc.unreadCount

    // Universals pinned at the top of the rail (fixed DESIGN colors). The rest of the
    // categories is auto-discovered from the database's tags; config only amends.
    readonly property var universals: [
        {
            "key": "inbox",
            "label": "Inbox",
            "query": "tag:inbox",
            "color": "#89b4fa"
        },
        {
            "key": "flagged",
            "label": "Flaggés",
            "query": "tag:flagged",
            "color": "#fab387"
        },
        {
            "key": "spam",
            "label": "Spam",
            "query": "tag:spam",
            "color": "#f38ba8"
        }
    ]

    // Amendments read from the settings (pluginData): per-tag overrides + composed searches.
    readonly property var cfgOverrides: (pluginData && pluginData.tagOverrides) ? pluginData.tagOverrides : []
    readonly property var cfgCustom: (pluginData && pluginData.customSearches) ? pluginData.customSearches : []
    readonly property int cfgIntervalMs: (pluginData && pluginData.pollSeconds > 0) ? pluginData.pollSeconds * 1000 : 20000
    readonly property string cfgReader: (pluginData && pluginData.readerCommand) ? pluginData.readerCommand : ""

    Notmuch {
        id: notmuchSvc
        universals: root.universals
        tagOverrides: root.cfgOverrides
        customSearches: root.cfgCustom
        intervalMs: root.cfgIntervalMs
        readerCommand: root.cfgReader
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: mailIcon.implicitWidth + Theme.spacingXS
            implicitHeight: mailIcon.implicitHeight

            DankIcon {
                id: mailIcon
                anchors.centerIn: parent
                name: "mail"
                size: Theme.fontSizeLarge
                filled: root.unreadCount > 0
                color: root.unreadCount > 0 ? Theme.primary : Theme.surfaceTextMedium
            }

            // Ring pulsing while there are unread threads (disabled when animations = None).
            Rectangle {
                id: pulseRing
                anchors.centerIn: badge
                width: badge.width
                height: badge.height
                radius: height / 2
                color: Theme.error
                z: -1
                visible: root.unreadCount > 0 && Theme.currentAnimationSpeed !== SettingsData.AnimationSpeed.None

                ParallelAnimation {
                    running: pulseRing.visible
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: pulseRing
                        property: "scale"
                        from: 1
                        to: 2.4
                        duration: 1600
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: pulseRing
                        property: "opacity"
                        from: 0.5
                        to: 0
                        duration: 1600
                        easing.type: Easing.OutQuad
                    }
                }
            }

            // Unread badge, anchored at the icon's top-right.
            StyledRect {
                id: badge
                visible: root.unreadCount > 0
                anchors.horizontalCenter: mailIcon.right
                anchors.verticalCenter: mailIcon.top
                width: Math.max(badgeText.implicitWidth + Theme.spacingXS, height)
                height: badgeText.implicitHeight + 2
                radius: height / 2
                color: Theme.error

                StyledText {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.unreadCount > 99 ? "99+" : String(root.unreadCount)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.background
                }
            }
        }
    }

    // Cockpit popout, opened by clicking the icon.
    popoutContent: Component {
        Cockpit {
            notmuch: notmuchSvc
            viewHeight: root.popoutHeight
        }
    }
    popoutWidth: 680
    popoutHeight: 680
}
