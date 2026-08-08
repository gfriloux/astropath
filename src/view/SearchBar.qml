// Search bar: typing a raw notmuch query updates the list (debounced).
// Empty → back to the unread query. Independent from the rail (typing overrides the selection).
import QtQuick
import qs.Common
import qs.Widgets

DankTextField {
    id: field

    property var notmuch: null

    placeholderText: "Recherche notmuch…"
    leftIconName: "search"
    showClearButton: true
    font.family: Theme.monoFontFamily

    onTextChanged: debounce.restart()

    Timer {
        id: debounce
        interval: 120
        repeat: false
        onTriggered: if (field.notmuch)
            field.notmuch.searchText(field.text.trim())
    }
}
