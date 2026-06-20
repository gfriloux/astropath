# Plan : v0.2.0 — cockpit (plugin DankMaterialShell)

**Type :** vue + glue I/O (étage `view` + exécution notmuch réelle)
**Statut :** Terminé (2026-06-20)

## Contexte

v0.1.0 a livré la couche données pure (`src/query`, `src/model`), testée par goldens.
v0.2.0 construit la **vue cockpit** et la **branche sur du vrai notmuch**, sous forme
d'un **plugin DankMaterialShell** (décision : intégré à DMS, pas autonome).

## Objectif

Un cockpit fonctionnel dans la barre DMS : badge de non-lus + popout (en-tête télémétrie,
rail des recherches sauvegardées, liste de fils, recherche, actions inline, pied), câblé
sur la vraie base notmuch, rafraîchi par un timer de polling.

## Périmètre

**In scope :** plugin DMS complet (manifest + widget barre + popout cockpit), service
Notmuch (Process), polling, mutations de tags, settings (taxonomie + intervalle + VIP +
commande de lecture), packaging home-manager.

**Out of scope :** surveillance live d'imapnotify/offlineimap (sync = polling seul) ;
multi-compte (reste agnostique mais pas d'UI dédiée) ; thème (hérité de DMS).

## Architecture (décisions techniques)

1. **Plugin DMS de type `widget`.** Le repo *est* le plugin : `plugin.json` à la racine,
   QML dans `src/view/`, JS data-layer dans `src/query`/`src/model`. Découvert depuis
   `~/.config/DankMaterialShell/plugins/Astropath/` (symlink via home-manager).
2. **PluginComponent** (`qs.Modules.Plugins`) : `horizontalBarPill` (icône `mail` + badge
   non-lus), `popoutContent` (`PopoutComponent`, `popoutWidth: 582`, hauteur variable).
3. **Thème & composants hérités de DMS** : `qs.Common` (`Theme.*` — Catppuccin Mocha déjà
   configuré) + `qs.Widgets` (`StyledText`, `StyledRect`, `DankGridView`…). **Aucun styling
   embarqué.** La palette de DESIGN.md sert de référence ; à l'implémentation on mappe sur
   les tokens `Theme.*`.
4. **Service Notmuch** (`src/view/Notmuch.qml`) : `Quickshell.Io.Process` +
   `StdioCollector`. `command: ["notmuch"].concat(Queries.<fn>(...))`. stdout → `JSON.parse`
   → transform `threads.js` → propriétés/signaux exposés (unreadThreads, counts, results).
5. **Polling, pas d'indexation.** Un `Timer` (~20 s) + ouverture du popout re-déclenchent
   les requêtes. Bouton refresh = re-query. **Jamais `notmuch new`** : astropath lit (query)
   et mute des tags (`notmuch tag`), il n'indexe pas (invariant à ajouter à DESIGN.md).
6. **Sync status basique** : état dérivé du polling (`idle | querying | error`) +
   « à jour · il y a N min ». Pas de watcher externe.
7. **Settings** (`src/view/Settings.qml` + `pluginService.savePluginData`) : **définitions
   des smart folders** (label/requête/couleur — la taxonomie perso vit ICI, pas dans le
   repo), intervalle de polling, expéditeurs VIP, commande du client de lecture.
8. **Tests** : la couche données reste golden-testée (inchangée). Tout nouveau JS pur
   (ex. temps relatif, détection VIP) → golden/unitaire. La **vue n'est pas golden-testable**
   (rendu QML, Wayland) → `manual_tests.md` + `qmllint` (avec `-I` vers la source DMS).

## Workflow dev/test (nouveau, dû au couplage DMS)

- **Lancer** : symlink le repo dans `~/.config/DankMaterialShell/plugins/Astropath`,
  activer le plugin dans DMS (PluginsTab). DMS recharge le plugin. `just run` orchestrera
  ce lien + un rappel de reload.
- **Lint vue** : `qmllint -I <source-DMS>/quickshell src/view/*.qml` (résoudre `qs.*`).
- **Imports DMS de référence** (lecture seule) : `qs.Common`, `qs.Widgets`,
  `qs.Modules.Plugins`, `Quickshell.Io`.

## Phases (chacune = commit(s) atomique(s), vérif = manuel sauf JS pur)

1. **Manifest + badge barre** — `plugin.json` + `AstropathWidget.qml` (PluginComponent,
   `horizontalBarPill` icône `mail` + badge ; compteur factice). Popout vide.
   *Vérif : le plugin charge dans DMS, l'icône apparaît.*
2. **Service Notmuch + vrai compteur** — `Notmuch.qml` (Process + StdioCollector,
   `parseSearch`/`parseCount`) + `Timer` polling. Badge câblé sur `count('tag:inbox and tag:unread')`.
   *Vérif : le badge affiche le vrai nombre.*
3. **Squelette popout** — `PopoutComponent` 582px : en-tête (wordmark, état sync, refresh)
   + pied. *Vérif : clic icône → popout s'ouvre.*
4. **Liste de fils** — rend `unreadThreads` (expéditeur, sujet, snippet via `parseShow`,
   chips tags, états lu/non-lu/flaggé, temps relatif). *Vérif : vrais fils listés.*
5. **Rail recherches sauvegardées** — lit les définitions (settings/config), affiche
   label+compteur+couleur, sélection → re-query. *Vérif : rail fonctionnel.*
6. **Barre de recherche** — requête notmuch live (debounce ~120 ms) → résultats.
   *Vérif : recherche live.*
7. **Actions inline** — par fil : lu/archiver/flag/retag/supprimer (mutations `notmuch tag`)
   + ouvrir (client externe configuré). *Vérif : tags mutés, fil rafraîchi.*
8. **Settings** — `Settings.qml` : définitions smart folders, intervalle, VIP, commande
   lecture ; persistance `pluginService`. *Vérif : réglages pris en compte.*
9. **Sync status + pied raccourcis** — état polling + « à jour il y a N min » + chips
   raccourcis clavier (`j/k`, `⏎`, `e`, `#`). *Vérif : navigation clavier + état.*
10. **Packaging + clôture** — module home-manager (symlink plugin dans le dossier DMS),
    sync `DESIGN.md`/`README.md` (invariant « pas de notmuch new », layout plugin), `just ci`.

## Fichiers (prévisionnel)

- `plugin.json`
- `src/view/AstropathWidget.qml`, `Notmuch.qml`, `Cockpit.qml`, `ThreadRow.qml`,
  `SavedSearchRail.qml`, `SearchBar.qml`, `ThreadActions.qml`, `Settings.qml`
- `src/model/format.js` (temps relatif, VIP… si JS pur) + tests golden/unitaires
- `Justfile` (cible `run` adaptée, `lint` vue avec `-I` DMS)
- `nix/hm-module.nix` (installation du plugin)
- `DESIGN.md` / `README.md`

## Portes de qualité (clôture)

- [x] `just ci` passe (golden data-layer + JS pur ajouté : `relativeTime`)
- [x] `qmllint` : la vue ne peut pas être validée statiquement contre les types DMS
  (résolution runtime `qs.*`) → filet anti-syntaxe seulement, validation = DMS réel
- [x] `manual_tests.md` exécuté (cockpit réel dans DMS, validé pas à pas)
- [x] Doc synchronisée ; invariant « pas de notmuch new » dans DESIGN.md
- [x] Commits atomiques sur `feat/cockpit`, signés `+code`
- [ ] Branche mergée sur `main` à la clôture (par l'utilisateur)

## Bilan

Cockpit livré comme **plugin DankMaterialShell** : widget barre + badge, popout
(en-tête sync « il y a N min », rail recherches sauvegardées, recherche live, liste de
fils, actions inline, navigation clavier), réglages (client de lecture, intervalle,
éditeur de smart folders avec pastilles couleur). Service Notmuch (Process + polling,
jamais `notmuch new`). Module home-manager pour l'installation.

**Reportés (finition / v0.3.0)** : compteurs par recherche dans le rail, snippet via
`notmuch show`, chips de tags colorés depuis la config, VIP, retag, passe de finition
graphique fidèle au proto, focus clavier auto à l'ouverture (limite Wayland/DMS).
