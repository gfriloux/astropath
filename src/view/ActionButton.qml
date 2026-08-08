// Small action button (icon) for a thread's inline action row.
// Built on StateLayer (DMS): ripple + hover/press state layer + tooltip, all of which
// already honor AnimationSpeed.None and the enableRippleEffects setting.
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
