## Plan : Catégories auto-découvertes (opt-out)

**Type :** requête + état/tag + vue + doc
**Objectif :** chaque tag notmuch devient une catégorie d'office (rail). La config ne
*crée* plus les catégories, elle les *amende* (renommer / recolorer / masquer). La saisie
manuelle survit pour les requêtes **composées**.
**Pourquoi :** la taxonomie vit déjà dans notmuch (inv. 1 *notmuch fait foi*, inv. 2
*tag-only*). Retaper chaque `tag:X` à la main est une redite. L'auto-découverte est plus
alignée avec les invariants que l'allowlist manuelle actuelle.
**Étages :** `query` · `model` · `view` · `doc`

### Contexte / état du working tree

Flux actuel : `AstropathWidget.cfgDefinitions` (allowlist lue de
`pluginData.savedSearches`, repli sur 3 universels) → `Notmuch.definitions` →
`Model.savedSearches/tagColors` → `SavedSearchRail`. La création se fait dans
`SavedSearchEditor` (libellé + requête + couleur). On inverse en **opt-out**.

### Principe (couche données, pure & testable)

1. **Découverte** : `notmuch search --output=tags '*'` → liste de tags (texte, 1/ligne).
2. **Blocklist machine** (constante `model`, *états, pas catégories*) :
   `unread, inbox, flagged, spam, attachment, signed, encrypted, replied, sent, draft,
   passed, new, deleted`. Les universels `inbox/flagged/spam` restent épinglés en tête
   (couleur fixe DESIGN) → exclus de l'auto pour éviter le doublon.
3. **Couleur stable** : `colorForTag(tag)` = hash déterministe → palette catégories
   Catppuccin (Lavender, Green, Teal, Peach, Yellow, Mauve). Déterministe ⇒ goldenable.
4. **Assemblage** `buildDefinitions(tags, cfg)` →
   `universels ⊕ découverts(triés, hors blocklist & hors masqués) ⊕ custom`.
   Label défaut = le tag brut.

### Config (nouvelles clés `pluginData`, pas de migration — pré-tag, aucun release)

- `tagOverrides: [{tag, label?, color?, hidden?}]` — amendements par tag.
- `customSearches: [{key, label, query, color}]` — requêtes composées
  (`tag:boulot and tag:unread`), que l'auto ne peut pas générer.

L'ancienne clé `savedSearches` est abandonnée (aucun utilisateur publié).

### Fichiers touchés

- [ ] `src/query/queries.js` — builder `tags()`
- [ ] `src/model/threads.js` — `parseTags`, `colorForTag`, `buildDefinitions`, blocklist
- [ ] `tests/tst_queries.qml` — `test_tags`
- [ ] `tests/tst_model.qml` — `test_parseTags`, `test_colorForTag`, `test_buildDefinitions`
- [ ] `tests/fixtures/discovered-searches.json` + `tests/golden/discovered-searches.json`
- [ ] `tests/cases.js` — enregistrer le cas
- [ ] `src/view/Notmuch.qml` — process de découverte + assemblage
- [ ] `src/view/AstropathWidget.qml` — passer `tagOverrides`/`customSearches`
- [ ] `src/view/SavedSearchEditor.qml` — mode amender
- [ ] `src/view/Settings.qml` — clés réglages
- [ ] `DESIGN.md` — inv. 3 + mapping couleur (auto-dérivé, blocklist = états)
- [ ] `.claude/plans/v0.7.0/manual_tests.md`

### Étapes atomiques

#### Étape 1 : découverte des tags (query + model)
**Description :** builder `tags()` → `["search","--output=tags","*"]` ; `parseTags(text)`
→ liste nettoyée (trim, lignes vides retirées). Tests unitaires.
**Vérification :** `just ci`
**Commit :** `feat(query): découverte des tags notmuch`

#### Étape 2 : catégories auto-dérivées (model + doc)
**Description :** `colorForTag`, blocklist, `buildDefinitions` ; fixture/golden
`discovered-searches` (entrée = tags + cfg → définitions attendues) ; cases.js. MAJ
DESIGN.md (inv. 3 : catégories dérivées ; mapping couleur : hash stable + override ;
blocklist = états machine, pas une taxonomie en dur).
**Vérification :** `just ci` (relire le diff du golden)
**Commit :** `feat(model): catégories auto-dérivées des tags`

#### Étape 3 : peupler le rail depuis les tags (view)
**Description :** `Notmuch.qml` découvre les tags (Process) et assemble `definitions` via
`buildDefinitions(tags, {overrides, custom})` ; `AstropathWidget` passe
`tagOverrides`/`customSearches` (repli universels si pas de tags). Compteurs inchangés.
**Vérification :** `just ci` + essai manuel (rail peuplé).
**Commit :** `feat(view): peupler le rail depuis les tags`

#### Étape 4 : réglages d'amendement (view)
**Description :** `SavedSearchEditor` → liste des tags découverts avec toggle *masquer* +
override label/couleur ; section requêtes custom (composées). `Settings.qml` : clés.
MAJ `manual_tests.md`.
**Vérification :** `just ci` + relecture visuelle des réglages.
**Commit :** `feat(view): réglages d'amendement des catégories`

### Décisions techniques

- **Blocklist en dur, justifiée** : ce sont des *états/tags opérationnels*, pas des
  catégories. Un tag masqué reste ré-affichable côté réglages → pas de perte.
- **Universels épinglés** `inbox/flagged/spam` (couleurs fixes DESIGN), exclus de l'auto.
- **Label défaut = tag brut** (déterministe, pas de capitalisation/locale).
- **Tri alphabétique** des découverts → ordre stable (goldenable).
- **Couleur** dérivée d'un hash du tag sur la palette catégories (6 teintes DESIGN).

### Portes de qualité

- [ ] `just ci` passe à chaque étape
- [ ] Golden `discovered-searches` à jour et intentionnel
- [ ] DESIGN.md synchronisé (même commit que l'étape 2)
- [ ] Commits atomiques sur `feat/auto-categories`
- [ ] `manual_tests.md` exécuté en clôture
