# DESIGN.md — astropath

> Ce document définit l'esprit, la structure et les **invariants** d'astropath.
> Avant d'ajouter quoi que ce soit, vérifie que ça s'inscrit ici. Si ce n'est pas
> le cas, la réponse est non.

---

## Ce qu'est astropath

astropath est un **widget de visu rapide des mails** pour la barre de bureau
**Quickshell / DankMaterialShell** (Material 3, thème Catppuccin Mocha). Une icône
dans la barre affiche un **badge de non-lus** ; au clic, un **popup** ancré sous
l'icône liste les fils non-lus, permet de chercher, de retaguer et d'ouvrir un fil.

La source de vérité est la **base notmuch** (index Xapian sur un Maildir). astropath
ne parle qu'à `notmuch` : il lit (`notmuch search`/`count`/`show --format=json`) et
mute des tags (`notmuch tag`). Tout raisonne par **fil (thread)** et par **tag**,
jamais par dossier. astropath **n'indexe jamais** (pas de `notmuch new`) : l'indexation
des nouveaux mails est le travail de la machinerie de synchro externe (offlineimap /
imapnotify). Le rafraîchissement se fait par **polling** (re-query périodique).

astropath est une **surface de triage** au-dessus de notmuch. Comment un fil s'ouvre
ensuite (client de lecture, commande lancée) est de la **configuration**, pas du design :
ce document n'en parle pas.

Ce n'est **pas** :

- Un client IMAP/SMTP. astropath ne parle pas au réseau : la synchro est le travail
  d'**offlineimap** (fetch) et d'**imapnotify** (push/notification). astropath observe
  leur état, il ne les pilote pas au-delà d'un refresh manuel.
- Un gestionnaire de dossiers. Le modèle est **tag-only**. « Archiver » = retirer
  `tag:inbox`, pas déplacer un fichier.

Aujourd'hui un seul compte est configuré, mais rien dans le
modèle ne le suppose : voir l'invariant *agnostique au compte* ci-dessous.

---

## Le pipeline — trois étages

astropath est une transformation à trois étages. Chaque étage a un contrat clair et
est **indépendamment testable**. Rien ne traverse un étage qui ne devrait pas : la
sortie brute de notmuch n'entre pas dans la vue, le QML n'appelle jamais `notmuch`
directement.

```
  base notmuch                                          popup Quickshell
      │                                                        ▲
      ▼                                                        │
  ┌────────┐        ┌─────────────┐        ┌──────────────────┐
  │ query  │  ───▶  │ model       │  ───▶  │ view             │
  │ (CLI)  │        │ (threads)   │        │ (QML / Material) │
  └────────┘        └─────────────┘        └──────────────────┘
```

### 1. `query` — exécution notmuch

La seule couche qui lance `notmuch`. Construit des requêtes, exécute
`notmuch search`/`count`/`show` en `--format=json`, et applique les mutations
`notmuch tag`. Sortie : du **JSON brut notmuch**, déterministe pour une base donnée.
Cet étage ne connaît rien à la présentation.

### 2. `model` — modèle de domaine

Transforme le JSON notmuch en **modèle de fils** : expéditeur, sujet, snippet, heure,
nombre de messages, tags, états (`unread`, `flagged`, `vip`). Tient l'état applicatif :
`unreadThreads`, `searchQuery`/`searchResults`, `selectedSavedSearch`, `savedSearches`
(tags + compteurs), `syncStatus`, `focusedThreadId`, `lastSyncAt`. **Pur et testable** :
mêmes entrées notmuch → même modèle (cf. golden tests, PROCEDURE_PLANS.md).

### 3. `view` — rendu Quickshell

QML / Qt Quick. Consomme le modèle, n'appelle jamais `notmuch` en direct. Porte le
système visuel ci-dessous au pixel près, en réutilisant les composants Material 3 de
DankMaterialShell.

### Implémentation

astropath est un **plugin DankMaterialShell** (`plugin.json` à la racine + `src/`),
installé dans `~/.config/DankMaterialShell/plugins/Astropath/`. Il hérite du thème
(Catppuccin Mocha) et des composants Material 3 de DMS.

- `query` → `src/query/queries.js` : builders d'argv notmuch (search/count/show/tag),
  fonctions pures. Exécutés par `src/view/Notmuch.qml` (`Process` quickshell + `StdioCollector`).
- `model` → `src/model/threads.js` (`parseSearch`, `parseCount`, `savedSearches` à
  définitions injectées = config, `parseShow`) + `format.js` (`relativeTime`). Pur, testé
  par goldens/unitaires (`tests/`, `just test` / `just bless`).
- `view` → `src/view/` : `AstropathWidget` (barre + badge), `Cockpit` (popout : en-tête
  sync, rail recherches, recherche live, liste, actions inline, navigation clavier),
  `Settings` (config : client de lecture, intervalle, smart folders). Thème = DMS.

---

## Invariants du domaine

1. **notmuch fait foi ; lecture + tags seulement.** Toute donnée affichée vient de notmuch
   (pas de cache parallèle). astropath query (lecture) et `notmuch tag` (mutation), rien
   d'autre — **jamais `notmuch new`** : il n'indexe pas, c'est le rôle de la synchro externe.
2. **Tag-only.** Aucune notion de dossier. Les actions sont des mutations de tags :
   lu = `-unread`, archiver = `-inbox`, flag = `+flagged`, spam = `+spam`, etc.
3. **Les smart folders sont des tags.** Les vues universelles (`Inbox`, `Flaggés`,
   `Spam`…) et les **catégories définies en config utilisateur** = des requêtes `tag:…`
   avec compteur, pas des entités stockées. astropath n'embarque aucune taxonomie en dur.
4. **Agnostique au compte.** astropath ne modélise pas les comptes : un compte n'est
   qu'une facette de requête notmuch (chemin ou tag). Mono ou multi-compte se modélisent
   via les recherches sauvegardées, sans traitement spécial — conséquence directe du
   raisonnement tag-only. Des vues par compte plus riches (badges séparés, bascule) seront
   des PLANs si le besoin émerge.
5. **Best-effort sur la synchro.** L'état de synchro (`live | idle | syncing | error`)
   est *observé* (imapnotify / offlineimap / `notmuch new`). Une synchro indisponible
   dégrade l'affichage, ne fait jamais planter le widget.
6. **Déterminisme de la couche données.** `query` + `model` sont déterministes pour une
   base notmuch figée — c'est ce qui rend les golden tests possibles.

---

## Système visuel (impératif)

Hi-fi : couleurs, typo, espacements et rayons sont définitifs. Le prototype HTML
d'origine (3 directions A/B/C + états annexes) vit dans `tmp/design_handoff_astropath/`
(non commité) ; les valeurs durables sont recopiées ici pour survivre.

### Palette — Catppuccin Mocha

| Rôle | Hex |
|---|---|
| Fond / base | `#1e1e2e` |
| Mantle | `#181825` |
| Crust | `#11111b` |
| Conteneur surélevé | `#313244` |
| Conteneur le plus haut | `#45475a` |
| Outline / séparateurs | `#6c7086` |
| Texte | `#cdd6f4` |
| Texte secondaire | `#a6adc8` |
| **Accent primaire — Mauve** | `#cba6f7` |
| Accent secondaire — Lavender | `#b4befe` |
| Non-lu / urgent / erreur — Red | `#f38ba8` |
| Flag / warning — Peach | `#fab387` |
| Succès / live — Green | `#a6e3a1` |
| Info — Blue | `#89b4fa` |
| Accent froid — Teal | `#94e2d5` |

Mauve **avec parcimonie** : focus, sélection, badge actif, bouton Composer. Jamais en
aplat massif.

### Mapping couleur des tags

Chip = `background: rgba(couleur, 0.16)` + `color: couleur`.

Tags universels (couleur fixe) :

| Tag | notmuch | Couleur |
|---|---|---|
| inbox | `tag:inbox` | `#89b4fa` |
| flaggé | `tag:flagged` | `#fab387` |
| spam | `tag:spam` | `#f38ba8` |

Les **tags de catégorie** (les smart folders perso de l'utilisateur) reçoivent chacun
une couleur de la palette Catppuccin, assignée en **config utilisateur** — astropath ne
code aucune taxonomie en dur (cf. invariant *agnostique au compte*). Palette disponible
pour l'assignation : Lavender `#b4befe`, Green `#a6e3a1`, Teal `#94e2d5`, Peach `#fab387`,
Yellow `#f9e2af`, Mauve `#cba6f7`.

### Formes & profondeur

- Rayon principal **12px** (cartes, popup) ; 6–10px pour chips/petits boutons ; 14px barre.
- Profondeur par **empilement de surfaces**, pas d'ombres dures. Seule ombre :
  `0 16px 48px rgba(0,0,0,.5)` sous le popup. Blur de fond : `blur(18px)`.
- **Séparateurs de liste** : filet 1px en **dégradé** (fondu aux deux bords), teinte
  `outline`. Posé entre les fils ; s'efface (en fondu) autour de la carte active/survolée
  pour ne jamais la trancher.
- Typo : **Inter** (UI), **JetBrains Mono** (requêtes/heures/compteurs),
  **Material Symbols Rounded** (icônes, fill 0).

### Direction visuelle — C (cockpit)

La direction retenue est **C — cockpit** : un mini-client dense, orienté power-user clavier.
Layout de référence (le prototype HTML détaille le pixel-perfect) :

- **Largeur ~582px** — au-delà de la cible 380–420px des autres directions, assumé : le
  cockpit privilégie la densité d'information à la compacité.
- **En-tête télémétrie** pleine largeur : wordmark, état `SYNC LIVE` + barres de signal
  animées, refresh, bouton **Composer**.
- **Rail gauche (~172px)** : liste verticale des recherches sauvegardées (icône + label +
  compteur), sélection marquée par un bord-gauche Mauve.
- **Zone principale** : barre de recherche + liste de fils en densité moyenne (avatar 32px).
  Le fil sous le curseur clavier a un **fond tinté** (mauve translucide) et révèle la
  **rangée d'actions inline** (lu / archiver / flag / retag / supprimer / ouvrir).
- **Pied** : chips de raccourcis clavier (`j`/`k`, `⏎`, `e`, `#`).

Ouvrir un fil (`⏎`) et **Composer** délèguent au client externe configurable : astropath
déclenche, il n'affiche ni ne compose lui-même (cf. *surface de triage* ci-dessus).

---

## Clin d'œil Adeptus Mechanicus

Subtil, jamais kitsch. Vocabulaire « warp / astropathicus », un seul cog dans l'en-tête,
état vide « Le warp est calme. ». C'est un assaisonnement, pas un thème.
