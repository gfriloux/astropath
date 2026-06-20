// Réglages du plugin (PluginsTab de DMS). Déclaratif : chaque *Setting auto-persiste dans
// pluginData via son settingKey. Le widget lit pluginData (readerCommand, pollSeconds,
// savedSearches). La taxonomie perso vit ICI (config locale), jamais dans le repo.
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "astropath"

    StyledText {
        width: parent.width
        text: "Réglages Astropath"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "readerCommand"
        label: "Client de lecture"
        description: "Commande lancée pour ouvrir un fil (la requête « thread:<id> » est ajoutée). Ex. « foot -e alot search »."
        placeholder: "foot -e alot search"
        defaultValue: ""
    }

    SliderSetting {
        settingKey: "pollSeconds"
        label: "Intervalle de rafraîchissement"
        description: "Fréquence de re-interrogation de notmuch (secondes). Pas de notmuch new : lecture seule."
        defaultValue: 20
        minimum: 5
        maximum: 120
        unit: "s"
        leftIcon: "schedule"
    }

    SavedSearchEditor {
        settingKey: "savedSearches"
    }
}
