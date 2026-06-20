// Éditeur custom des recherches sauvegardées (réglages) : libellé + requête + sélecteur
// de couleur à pastilles (palette Catppuccin). Persiste via le PluginSettings parent
// (findSettings → saveValue/loadValue), comme les *Setting natifs de DMS.
import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: editor

    property string settingKey: "savedSearches"
    // Palette Catppuccin Mocha (accents) proposée pour les pastilles.
    readonly property var palette: ["#cba6f7", "#b4befe", "#89b4fa", "#94e2d5", "#a6e3a1", "#f9e2af", "#fab387", "#f38ba8"]
    property var items: []
    property bool loading: false

    width: parent.width
    spacing: Theme.spacingM

    Component.onCompleted: load()

    function findSettings() {
        let it = parent;
        while (it) {
            if (it.saveValue !== undefined && it.loadValue !== undefined)
                return it;
            it = it.parent;
        }
        return null;
    }
    function load() {
        const s = findSettings();
        if (s) {
            loading = true;
            items = s.loadValue(settingKey, []);
            loading = false;
        }
    }
    function persist() {
        const s = findSettings();
        if (s)
            s.saveValue(settingKey, items);
    }
    function addItem(obj) {
        items = items.concat([obj]);
        persist();
    }
    function removeAt(i) {
        let a = items.slice();
        a.splice(i, 1);
        items = a;
        persist();
    }
    function setColorAt(i, c) {
        let a = items.slice();
        a[i] = Object.assign({}, a[i], {
            "color": c
        });
        items = a;
        persist();
    }

    StyledText {
        text: "Recherches sauvegardées"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }
    StyledText {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Tes smart folders : libellé + requête notmuch + couleur. Vide = défaut Inbox/Flaggés/Spam."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    // Lignes existantes.
    Repeater {
        model: editor.items

        Row {
            id: itemRow

            required property var modelData
            required property int index

            width: parent.width
            spacing: Theme.spacingS

            StyledText {
                width: 110
                anchors.verticalCenter: parent.verticalCenter
                text: itemRow.modelData.label
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                elide: Text.ElideRight
            }
            StyledText {
                width: 160
                anchors.verticalCenter: parent.verticalCenter
                text: itemRow.modelData.query
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                elide: Text.ElideRight
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: editor.palette

                    Rectangle {
                        id: swatch
                        required property string modelData
                        width: 18
                        height: 18
                        radius: 9
                        color: swatch.modelData
                        border.width: itemRow.modelData.color === swatch.modelData ? 2 : 0
                        border.color: Theme.surfaceText

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: editor.setColorAt(itemRow.index, swatch.modelData)
                        }
                    }
                }
            }

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "delete"
                size: Theme.fontSizeMedium
                color: delArea.containsMouse ? Theme.error : Theme.surfaceVariantText

                MouseArea {
                    id: delArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: editor.removeAt(itemRow.index)
                }
            }
        }
    }

    // Ligne d'ajout.
    Row {
        width: parent.width
        spacing: Theme.spacingS

        DankTextField {
            id: labelField
            width: 110
            placeholderText: "Libellé"
        }
        DankTextField {
            id: queryField
            width: 160
            placeholderText: "tag:boulot"
        }
        DankButton {
            text: "Add"
            onClicked: {
                const l = labelField.text.trim();
                const q = queryField.text.trim();
                if (l === "" || q === "")
                    return;
                editor.addItem({
                    "key": l.toLowerCase().replace(/\s+/g, "-"),
                    "label": l,
                    "query": q,
                    "color": editor.palette[editor.items.length % editor.palette.length]
                });
                labelField.text = "";
                queryField.text = "";
            }
        }
    }
}
