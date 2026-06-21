// Petit bouton d'action (icône) pour la rangée d'actions inline d'un fil.
// Bâti sur StateLayer (DMS) : ripple + couche d'état hover/press + infobulle, le tout
// respectant déjà AnimationSpeed.None et le réglage enableRippleEffects.
import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: btn

    property string icon: ""
    property color hoverColor: Theme.surfaceText
    property string tooltip: ""

    signal triggered

    width: 28
    height: 28
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHigh

    DankIcon {
        anchors.centerIn: parent
        name: btn.icon
        size: Theme.fontSizeMedium
        color: state.containsMouse ? btn.hoverColor : Theme.surfaceText
    }

    StateLayer {
        id: state
        stateColor: btn.hoverColor
        cornerRadius: btn.radius
        tooltipText: btn.tooltip
        onClicked: btn.triggered()
    }
}
