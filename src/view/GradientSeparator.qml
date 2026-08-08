// Thin (1px) separator hairline with a horizontal gradient, fading out at both ends. Placed
// between threads in the cockpit list. Color derived from the DMS theme (no hardcoded hex).
import QtQuick
import qs.Common

Item {
    id: sep

    implicitHeight: 1

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 1

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 0.5
                color: Theme.outlineMedium
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }
}
