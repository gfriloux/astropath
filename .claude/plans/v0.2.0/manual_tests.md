# Tests manuels — v0.2.0 (cockpit, plugin DMS)

> Enrichi après chaque phase. Exécuté en validation finale, dans une vraie session DMS
> avec le plugin lié dans `~/.config/DankMaterialShell/plugins/Astropath` et activé.

## Prérequis

| Action | Attendu | OK |
|---|---|---|
| Plugin lié + activé dans DMS (PluginsTab) | astropath apparaît dans la liste, activable | ☐ |
| `notmuch` disponible, base non vide | `notmuch count tag:unread` > 0 | ☐ |

## Barre + badge (Phases 1-2)

| Action | Attendu | OK |
|---|---|---|
| Icône `mail` dans la barre DMS | présente, style Catppuccin (Theme hérité) | ☐ |
| Mails non-lus présents | badge rouge avec le **vrai** compteur | ☐ |
| Tout lu | pas de badge, icône atténuée | ☐ |
| Attendre le polling / forcer refresh | compteur se met à jour sans `notmuch new` | ☐ |

## Popout cockpit (Phases 3-6)

| Action | Attendu | OK |
|---|---|---|
| Clic sur l'icône | popout ~582px s'ouvre (en-tête, rail, liste, pied) | ☐ |
| Liste de fils | expéditeur, sujet, snippet, chips tags, temps relatif, état lu/non-lu | ☐ |
| Rail recherches sauvegardées | labels + compteurs ; sélection filtre la liste | ☐ |
| Recherche notmuch live | résultats mis à jour (debounce), requête brute affichée | ☐ |

## Actions + settings + sync (Phases 7-9)

| Action | Attendu | OK |
|---|---|---|
| Marquer lu / archiver / flag / retag / supprimer | tag muté (`notmuch tag`), fil rafraîchi | ☐ |
| Ouvrir un fil | client de lecture configuré lancé | ☐ |
| Réglages (smart folders, intervalle, VIP, commande lecture) | persistés, pris en compte | ☐ |
| Indicateur sync | « à jour · il y a N min », état idle/querying/error | ☐ |
| Navigation clavier `j/k`, `⏎`, `e`, `#` | parcourt / ouvre / archive / supprime | ☐ |
