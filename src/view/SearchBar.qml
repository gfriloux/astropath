// Barre de recherche : saisie d'une requête notmuch brute → met à jour la liste (debounce).
// Vide → revient aux non-lus. Indépendante du rail (taper outrepasse la sélection).
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
