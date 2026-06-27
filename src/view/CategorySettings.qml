// Réglages des catégories (PluginSettings de DMS) : AMENDE l'auto-découverte, ne crée plus.
// Les catégories du rail dérivent des tags notmuch (cf. DESIGN inv. 3). Ici on liste les
// tags de la base (hors tags d'état) avec masquer/renommer/recolorer → persiste dans
// pluginData.tagOverrides ; et les recherches COMPOSÉES (multi-tags) → pluginData.customSearches.
import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import "../query/queries.js" as Queries
import "../model/threads.js" as Model

Column {
    id: editor

    // Palette Catppuccin Mocha (accents) proposée pour les pastilles.
    readonly property var palette: ["#cba6f7", "#b4befe", "#89b4fa", "#94e2d5", "#a6e3a1", "#f9e2af", "#fab387", "#f38ba8"]
    property var discoveredTags: []
    property var overrides: [] // [{tag, label?, color?, hidden?}]
    property var customs: []    // [{key, label, query, color}]

    width: parent.width
    spacing: Theme.spacingM

    Component.onCompleted: {
        load();
        tagsProc.running = true;
    }

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
        if (!s)
            return;
        overrides = s.loadValue("tagOverrides", []);
        customs = s.loadValue("customSearches", []);
    }
    function overrideFor(tag) {
        for (var i = 0; i < overrides.length; i++)
            if (overrides[i].tag === tag)
                return overrides[i];
        return null;
    }
    // Fusionne un amendement sur un tag. On nettoie les champs vides ; une entrée réduite
    // à { tag } (plus aucun amendement) est retirée pour ne pas polluer la config.
    function patchOverride(tag, patch) {
        let a = overrides.slice();
        let idx = -1;
        for (var i = 0; i < a.length; i++)
            if (a[i].tag === tag) {
                idx = i;
                break;
            }
        let merged = Object.assign({}, idx >= 0 ? a[idx] : {
            "tag": tag
        }, patch);
        if (!merged.label)
            delete merged.label;
        if (!merged.color)
            delete merged.color;
        if (!merged.hidden)
            delete merged.hidden;
        let bare = Object.keys(merged).length === 1; // ne reste que { tag }
        if (idx >= 0)
            bare ? a.splice(idx, 1) : a[idx] = merged;
        else if (!bare)
            a.push(merged);
        overrides = a;
        const s = findSettings();
        if (s)
            s.saveValue("tagOverrides", a);
    }
    function addCustom(obj) {
        customs = customs.concat([obj]);
        const s = findSettings();
        if (s)
            s.saveValue("customSearches", customs);
    }
    function removeCustomAt(i) {
        let a = customs.slice();
        a.splice(i, 1);
        customs = a;
        const s = findSettings();
        if (s)
            s.saveValue("customSearches", customs);
    }

    Process {
        id: tagsProc
        command: ["notmuch"].concat(Queries.tags())
        running: false
        stdout: StdioCollector {
            onStreamFinished: editor.discoveredTags = Model.parseTags(text).filter(function (t) {
                return Model.DEFAULT_TAG_BLOCKLIST.indexOf(t) === -1;
            })
        }
    }

    // --- Catégories auto-découvertes -----------------------------------------
    StyledText {
        text: "Catégories"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }
    StyledText {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Auto-découvertes depuis tes tags notmuch. Tu peux masquer, renommer ou recolorer. Les tags d'état (unread, attachment…) sont exclus."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    Repeater {
        model: editor.discoveredTags

        Row {
            id: tagRow

            required property string modelData
            required property int index
            readonly property var ov: editor.overrideFor(modelData)
            readonly property bool hidden: ov ? ov.hidden === true : false
            readonly property string effColor: (ov && ov.color) ? ov.color : Model.colorForTag(modelData)

            width: parent.width
            spacing: Theme.spacingS
            opacity: hidden ? 0.45 : 1

            Rectangle {
                width: 14
                height: 14
                radius: 7
                anchors.verticalCenter: parent.verticalCenter
                color: tagRow.effColor
            }
            StyledText {
                width: 90
                anchors.verticalCenter: parent.verticalCenter
                text: tagRow.modelData
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                elide: Text.ElideRight
            }
            DankTextField {
                width: 120
                anchors.verticalCenter: parent.verticalCenter
                text: (tagRow.ov && tagRow.ov.label) ? tagRow.ov.label : ""
                placeholderText: tagRow.modelData
                onEditingFinished: editor.patchOverride(tagRow.modelData, {
                    "label": text.trim()
                })
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: editor.palette

                    Rectangle {
                        id: swatch
                        required property string modelData
                        width: 16
                        height: 16
                        radius: 8
                        color: swatch.modelData
                        border.width: tagRow.effColor === swatch.modelData ? 2 : 0
                        border.color: Theme.surfaceText

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: editor.patchOverride(tagRow.modelData, {
                                "color": swatch.modelData
                            })
                        }
                    }
                }
            }

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: tagRow.hidden ? "visibility_off" : "visibility"
                size: Theme.fontSizeMedium
                color: hideArea.containsMouse ? Theme.primary : Theme.surfaceVariantText

                MouseArea {
                    id: hideArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: editor.patchOverride(tagRow.modelData, {
                        "hidden": !tagRow.hidden
                    })
                }
            }
        }
    }

    // --- Recherches composées ------------------------------------------------
    StyledText {
        text: "Recherches composées"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }
    StyledText {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Requêtes notmuch multi-tags (ex. « tag:boulot and tag:unread ») que l'auto-découverte ne génère pas."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    Repeater {
        model: editor.customs

        Row {
            id: customRow

            required property var modelData
            required property int index

            width: parent.width
            spacing: Theme.spacingS

            StyledText {
                width: 110
                anchors.verticalCenter: parent.verticalCenter
                text: customRow.modelData.label
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                elide: Text.ElideRight
            }
            StyledText {
                width: 180
                anchors.verticalCenter: parent.verticalCenter
                text: customRow.modelData.query
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                elide: Text.ElideRight
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
                    onClicked: editor.removeCustomAt(customRow.index)
                }
            }
        }
    }

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
            width: 180
            placeholderText: "tag:a and tag:b"
        }
        DankButton {
            text: "Add"
            onClicked: {
                const l = labelField.text.trim();
                const q = queryField.text.trim();
                if (l === "" || q === "")
                    return;
                editor.addCustom({
                    "key": l.toLowerCase().replace(/\s+/g, "-"),
                    "label": l,
                    "query": q,
                    "color": editor.palette[editor.customs.length % editor.palette.length]
                });
                labelField.text = "";
                queryField.text = "";
            }
        }
    }
}
