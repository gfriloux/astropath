// Widget de barre astropath (plugin DankMaterialShell).
// Phase 1 : icône mail + badge de non-lus (compteur factice). Le service Notmuch et le
// popout cockpit arrivent aux phases suivantes. Thème et composants hérités de DMS.
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // Compteur de fils non-lus, alimenté par le service Notmuch (polling).
    readonly property int unreadCount: notmuchSvc.unreadCount

    // Universels épinglés en tête du rail (couleurs fixes DESIGN). Le reste des catégories
    // est auto-découvert depuis les tags de la base ; la config ne fait qu'amender.
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

    // Amendements lus des réglages (pluginData) : overrides par tag + recherches composées.
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

            // Anneau qui pulse tant qu'il y a des non-lus (désactivé si animations = None).
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

            // Badge de non-lus, ancré en haut-droite de l'icône.
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

    // Popout cockpit ouvert au clic sur l'icône.
    popoutContent: Component {
        Cockpit {
            notmuch: notmuchSvc
            viewHeight: root.popoutHeight
        }
    }
    popoutWidth: 680
    popoutHeight: 680
}
