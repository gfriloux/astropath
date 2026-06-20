// Widget de barre astropath (plugin DankMaterialShell).
// Phase 1 : icône mail + badge de non-lus (compteur factice). Le service Notmuch et le
// popout cockpit arrivent aux phases suivantes. Thème et composants hérités de DMS.
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // Phase 1 : compteur factice. Câblé sur notmuch (Process) en Phase 2.
    property int unreadCount: 3

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
}
