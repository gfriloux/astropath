// Filet séparateur fin (1px) en dégradé horizontal, fondu aux deux bords. Posé entre les
// fils de la liste cockpit. Couleur dérivée du thème DMS (pas de hex en dur).
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
