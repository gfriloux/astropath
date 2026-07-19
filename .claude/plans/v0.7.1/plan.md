## Plan : Rail des catégories défilable

**Type :** bug (vue)
**Objectif :** rendre le rail gauche (recherches sauvegardées / catégories) défilable
quand les tags dépassent la hauteur disponible, comme l'est déjà la liste de mails.
**Pourquoi :** avec beaucoup de tags, le rail dépasse `footer.top` et les items du bas
sont inaccessibles — aucun moyen de scroller. La liste de mails, elle, utilise
`DankListView` et défile. Régression d'usage introduite par l'auto-découverte des tags
(v0.7.0) qui peut peupler le rail bien au-delà de la hauteur du popout.
**Étage(s) :** `view` uniquement (aucune donnée `query`/`model` touchée → pas de golden).

### Contexte / état du working tree

`src/view/SavedSearchRail.qml` est un `Column` + `Repeater` sans conteneur défilable ni
`clip`. Dans `Cockpit.qml` il est ancré `top → footer.top` sur une hauteur fixe : le
`Column` déborde silencieusement, les items hors zone sont perdus. `DankListView`
(`qs.Widgets`, déjà utilisée pour la liste de mails) est une `ListView` complète :
scrollbar, molette, momentum, `boundsBehavior: StopAtBounds`. La convertir donne le
défilement gratuitement et aligne le rail sur le pattern existant.

### Décision technique

Convertir `SavedSearchRail` de `Column`+`Repeater` en `DankListView`+`delegate` :

- `model` inchangé : `notmuch.savedSearches`.
- Le contenu du délégué (StyledRect + label + compteur + MouseArea) est repris tel quel ;
  seul le binding de largeur passe de `rail.width` à `ListView.view.width`, et l'accès au
  service via `rail` reste valide (le délégué référence l'`id` du composant racine).
- `clip: true`, `spacing: Theme.spacingXS` (identique à l'actuel), `boundsBehavior`
  hérité de `DankListView`.
- Aucun changement dans `Cockpit.qml` : le composant garde la même API (`notmuch`,
  ancrage `top → footer.top`, `width: 172`). La hauteur bornée par les ancres suffit à
  activer le défilement.

Alternative écartée : envelopper le `Column` dans un `Flickable`/`ScrollView`. Plus de
code, pas de scrollbar stylée DMS, diverge du pattern de la liste de mails. `DankListView`
est le choix cohérent.

### Fichiers touchés

- [ ] `src/view/SavedSearchRail.qml` — `Column`/`Repeater` → `DankListView`/`delegate`
- [ ] `.claude/plans/v0.7.1/manual_tests.md` — scénario « rail plein → défile »
- [ ] `.claude/plans/v0.7.1/phase0_results.md` — audit avant code

### Étapes atomiques

#### Phase 0 : audit
**Description :** `nix develop --command just ci` sur `main` propre, consigner le résultat.
**Vérification :** portes vertes avant de coder.
**Commit :** — (pas de commit, juste `phase0_results.md`).

#### Étape 1 : rail défilable (view)
**Description :** réécrire `SavedSearchRail.qml` en `DankListView` (model =
`notmuch.savedSearches`, délégué = l'item actuel, `clip: true`, `spacing: Theme.spacingXS`,
largeur du délégué = `ListView.view.width`). API du composant inchangée.
**Vérification :** `just ci` (fmt-check + lint + test) + essai manuel dans Quickshell :
rail avec assez de tags pour dépasser, vérifier molette + scrollbar + bornes.
**Commit :** `fix(view): rendre le rail des catégories défilable`

#### Étape 2 : tests manuels (doc)
**Description :** ajouter à `manual_tests.md` le scénario de défilement du rail (molette,
scrollbar, item du bas atteignable, pas de débordement visuel).
**Vérification :** relecture ; scénario exécuté en clôture.
**Commit :** inclus dans le commit de l'étape 1 (doc dans le même commit que le code).

### Portes de qualité

- [ ] `just ci` passe
- [ ] Aucun golden touché (changement purement vue)
- [ ] `manual_tests.md` : défilement du rail vérifié dans Quickshell
- [ ] Commit atomique unique sur `fix/rail-scroll`
- [ ] Purger `~/.cache/quickshell/qmlcache` avant l'essai manuel (sinon modif invisible)
