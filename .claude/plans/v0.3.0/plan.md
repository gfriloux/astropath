# Plan : v0.3.0 — finition graphique (fidélité au proto cockpit)

**Type :** finition graphique (étage `view`)
**Statut :** Terminé (2026-06-20)

## Contexte

v0.2.0 a livré le cockpit fonctionnel (plugin DMS). v0.3.0 le rapproche visuellement du
prototype « direction C » du handoff : avatars, densité, typographie, animations.

## Objectif

Un cockpit plus léché, fidèle au proto — sans rien changer au fonctionnel.

## Périmètre

**In scope :** avatars/monogrammes, typographie (mono pour heures/compteurs/requête),
animations (badge pulse, apparition des fils en stagger, point « live »), densité &
espacements ajustés, wordmark.

**Out of scope :** tout nouveau fonctionnel (compteurs rail, snippet, chips colorés, VIP,
retag restent du backlog v0.4.0) ; release/tag.

## Décisions techniques

1. **On reste dans le thème DMS.** Couleurs via `Theme.*`, polices via `Theme.fontFamily`
   (Inter, = proto) et `Theme.monoFontFamily` (Fira Code). **Pas de hex ni de font en dur** :
   la fidélité porte sur la *mise en page / densité / animations*, pas sur une reskinnisation.
2. **Avatar = monogramme** : `StyledRect` rond + initiales de l'expéditeur, teinte de fond
   déterministe (hash du nom → palette Catppuccin). Pas de bitmap.
3. **Animations** : utiliser `Theme.shortDuration`/`mediumDuration` et **respecter**
   `Theme.currentAnimationSpeed === AnimationSpeed.None` (désactivées si l'utilisateur coupe
   les animations DMS), via `Behavior`/`NumberAnimation`/`enabled:`.

## Phases (chacune = commit(s) atomique(s) ; vérif = visuelle dans DMS)

1. **Avatars + typographie mono** — monogramme par fil (initiales + teinte) ; `monoFontFamily`
   pour heure relative, compteur `(N)`, et la requête dans la barre de recherche.
   *Vérif : avatars colorés, chiffres/heures en mono.*
2. **Animations** — badge qui pulse quand non-lus ; apparition des fils en **stagger**
   (fadeUp, delay = index × ~40 ms) ; point « live » sur l'état sync. Respect du réglage None.
   *Vérif : pulse + apparition échelonnée + point live.*
3. **Densité & wordmark + clôture** — espacements/rayons/hauteur de ligne ajustés au proto ;
   wordmark `ASTROPATH` soigné ; sync doc si besoin ; `just ci`.
   *Vérif : densité proche du proto.*

## Fichiers (prévisionnel)

- `src/view/ThreadRow.qml` (avatar, mono, stagger, densité)
- `src/view/AstropathWidget.qml` (badge pulse)
- `src/view/Cockpit.qml` (live dot, wordmark, espacements)
- `src/view/SearchBar.qml` (mono requête) ; éventuel `Avatar.qml`
- `src/model/format.js` (initiales/teinte si JS pur) + tests

## Portes de qualité (clôture)

- [x] `just ci` passe (data layer inchangé ; helpers `initials`/`colorIndex` testés)
- [x] Rendu validé dans DMS (`manual_tests.md`)
- [x] Animations désactivées si `AnimationSpeed.None`
- [x] Commits atomiques sur `feat/polish`, signés `+code`
- [ ] Branche mergée sur `main` à la clôture (par l'utilisateur)

## Bilan

Avatars monogrammes (teinte par expéditeur, dérivée du thème) ; heure/compteur/requête en
mono ; badge qui pulse + apparition des fils en fondu (respectant `AnimationSpeed.None`).
Sur retour visuel : **actions révélées sous le fil** (plus de chevauchement à droite),
sélection = fond teinté seul (barre gauche retirée), **tags d'état filtrés** (inbox/unread
ne s'affichent plus comme chips).

**Reportés (v0.4.0 fonctionnel)** : compteurs par recherche, snippet (`notmuch show`),
chips de tags colorés depuis la config, VIP, retag. Wordmark figé par le `PopoutComponent`
de DMS (peu de marge). Densité fine laissée telle quelle (jugée correcte).
