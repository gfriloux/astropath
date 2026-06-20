# Plan : v0.4.0 — enrichissement fonctionnel

**Type :** fonctionnel (étages `model` + `view`)
**Statut :** en attente de validation

## Contexte

Le cockpit (v0.2.0) et sa finition (v0.3.0) sont en place. v0.4.0 comble les manques
fonctionnels reportés : compteurs, chips colorés, VIP, snippet, retag.

## Objectif

Rendre le cockpit complet : informations riches (compteurs, snippet, VIP) et action retag.

## Périmètre

**In scope :** compteurs par recherche dans le rail, chips de tags **colorés** (config),
expéditeurs **VIP** (config), **snippet** (notmuch show, paresseux), **retag** (UI).

**Out of scope :** release/tag ; nouvelles vues.

## Décisions techniques

1. **Compteurs séquentiels** : un `Process` count réutilisé, enchaîné par définition
   (`onExited` → résultat + count suivant). Pas de stdin, pas de `sh -c`. `savedSearches`
   gagne ses counts ; le rail les affiche.
2. **Couleurs de tags = config** : map `tag → couleur` dérivée des définitions
   (`tag:X` → couleur de la définition). Helper JS pur `tagColors(definitions)`, testé.
   ThreadRow colore les chips (`rgba(couleur, .16)` + texte couleur), repli neutre.
3. **VIP** : liste d'expéditeurs en config (réglages). Helper pur `isVip(authors, vips)`,
   testé. ThreadRow : nom en mauve + étoile si VIP.
4. **Snippet paresseux** : `notmuch show` (via `parseShow`, déjà là) déclenché pour
   l'élément **courant/survolé** uniquement (1 process à la fois, pas N). Affiché sous le sujet.
5. **Retag** : bouton `sell` → petit éditeur (champ « +tag »/« -tag » ou liste) →
   `notmuch.tag(id, {add, remove})` (déjà là) → refresh.

## Phases (chacune = commit(s) atomique(s) ; vérif manuelle sauf JS pur)

1. **Compteurs rail** — count séquentiel par définition dans le service ; rail affiche
   `label (N)`. *Vérif : compteurs réels, mis à jour au polling.*
2. **Chips colorés** — `tagColors(definitions)` (testé) ; chips colorés dans ThreadRow.
   *Vérif : chips aux couleurs config.*
3. **VIP** — réglage liste VIP ; `isVip` (testé) ; ThreadRow marque VIP (mauve + `star`).
   *Vérif : expéditeurs VIP mis en avant.*
4. **Snippet** — show paresseux sur l'élément courant ; affichage sous le sujet.
   *Vérif : snippet du fil sélectionné.*
5. **Retag + clôture** — éditeur de retag via bouton `sell` ; sync doc ; `just ci`.
   *Vérif : ajout/retrait de tags effectif.*

## Fichiers (prévisionnel)

- `src/model/threads.js` (counts) + `src/model/format.js` (`tagColors`, `isVip`) + tests
- `src/view/Notmuch.qml` (count séquentiel, show paresseux, expose vips/tagColors)
- `src/view/SavedSearchRail.qml` (compteur), `ThreadRow.qml` (chips colorés, VIP, snippet),
  `Settings.qml` (liste VIP), nouveau `RetagEditor.qml`
- `DESIGN.md` / `README.md` si besoin

## Portes de qualité (clôture)

- [ ] `just ci` passe (helpers JS purs testés)
- [ ] Rendu validé dans DMS (`manual_tests.md`)
- [ ] Commits atomiques sur `feat/functional`, signés `+code`
- [ ] Branche mergée sur `main` à la clôture
