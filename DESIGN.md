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
jamais par dossier.

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

---

## Invariants du domaine

1. **notmuch fait foi.** Toute donnée affichée vient de notmuch. Pas de cache parallèle
   qui pourrait diverger de la base.
2. **Tag-only.** Aucune notion de dossier. Les actions sont des mutations de tags :
   lu = `-unread`, archiver = `-inbox`, flag = `+flagged`, spam = `+spam`, etc.
3. **Les smart folders sont des tags.** `Inbox`, `Job`, `Achats`, `Humanité`,
   `Mailing lists`, `EGIT`, `Flaggés`, `Spam` = des requêtes `tag:…` avec compteur,
   pas des entités stockées.
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

| Tag | notmuch | Couleur |
|---|---|---|
| inbox | `tag:inbox` | `#89b4fa` |
| job | `tag:job` | `#b4befe` |
| achats | `tag:achats` | `#a6e3a1` |
| humanité | `tag:humanite` | `#94e2d5` |
| ml | `tag:ml` | `#fab387` |
| EGIT | `tag:EGIT` | `#f9e2af` |
| Flaggés | `tag:flagged` | `#fab387` |
| Spam | `tag:spam` | `#f38ba8` |

### Formes & profondeur

- Rayon principal **12px** (cartes, popup) ; 6–10px pour chips/petits boutons ; 14px barre.
- Profondeur par **empilement de surfaces**, pas d'ombres dures. Seule ombre :
  `0 16px 48px rgba(0,0,0,.5)` sous le popup. Blur de fond : `blur(18px)`.
- Typo : **Inter** (UI), **JetBrains Mono** (requêtes/heures/compteurs),
  **Material Symbols Rounded** (icônes, fill 0).

### Direction visuelle

Trois directions ont été prototypées (A compacte / B cartes / C cockpit). **Le choix de
la direction est une décision DESIGN à acter avant le premier PLAN d'UI** — pas un détail
d'implémentation. Tant qu'elle n'est pas tranchée ici, on ne code pas la vue.

---

## Clin d'œil Adeptus Mechanicus

Subtil, jamais kitsch. Vocabulaire « warp / astropathicus », un seul cog dans l'en-tête,
état vide « Le warp est calme. ». C'est un assaisonnement, pas un thème.
