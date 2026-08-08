// Plugin settings (DMS's PluginsTab). Declarative: each *Setting auto-persists into
// pluginData through its settingKey. The widget reads pluginData (readerCommand,
// pollSeconds, tagOverrides, customSearches). The taxonomy is auto-discovered from notmuch;
// config only carries the AMENDMENTS (hide/rename/recolor + composed searches).
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

    CategorySettings {}
}
