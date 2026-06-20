# Plan : v0.1.0 — couche données (query + model)

**Type :** requête + modèle (étages `query` et `model`)
**Statut :** en attente de validation

## Contexte

Premier PLAN d'astropath. Les fondations sont posées (DESIGN/PROCEDURE/flake/CI).
On construit la **couche données déterministe** avant toute vue : c'est l'invariant
« déterminisme de la couche données » qui rend les golden tests possibles, et la vue
cockpit (v0.2.0) consommera ce modèle.

## Objectif

Transformer la sortie `notmuch --format=json` en un **modèle de fils** pur, testé par
goldens. Aucune UI.

## Périmètre

**In scope :**
- Construction des commandes notmuch (argv) — pur JS, testable.
- Transform `notmuch search` → liste de fils (`Thread[]`).
- Transform `notmuch count` + recherches sauvegardées (tag → label/compteur/couleur).
- Transform `notmuch show` → snippet / détail d'un fil.
- Harnais de golden tests + `just bless` opérationnels.

**Out of scope :**
- Toute vue QML (cockpit) → v0.2.0.
- Exécution réelle de notmuch au runtime (`Process`/`Notmuch.qml`) → v0.2.0 (le glue I/O
  n'est pas golden-testable ; on le câblera quand la vue l'exercera). Validé ici
  uniquement par un essai manuel optionnel contre la vraie base.
- Mutations de tags appliquées (le builder `tagThread` est écrit + testé, mais non
  exécuté faute de runtime/UI).

## Architecture (décisions techniques)

1. **Modules ES purs.** `src/query/queries.js` et `src/model/threads.js` n'importent
   ni Qt ni QML : fonctions sur objets simples. Importables par la future vue ET par les
   tests.
2. **Schéma notmuch** (documenté, stable) :
   - `search --format=json` → `[{thread, timestamp, date_relative, matched, total,
     authors, subject, query, tags:[…]}]`
   - `count 'query'` → entier.
   - `show --format=json` → arbre fil/messages avec `headers`, `body`, `tags`.
   À confirmer contre la vraie base en tests manuels (cf. `manual_tests.md`).
3. **Modèle `Thread`** (sortie de `parseSearch`) :
   `{ id, authors, subject, dateRelative, total, tags, unread, flagged, vip, snippet? }`
   - `unread`/`flagged` = `tags` contient `unread`/`flagged`.
   - `vip` = expéditeur dans une liste configurable (config, pas notmuch).
   - `snippet` optionnel, rempli par `parseShow` (le résumé `search` n'a pas de corps).
4. **Tests = goldens via `qmltestrunner`.** `tests/tst_model.qml` lit fixture + golden
   (JSON) par `XMLHttpRequest` synchrone (`file://`), compare en deep-equal.
   `just bless` régénère les goldens via un petit script quickshell (`Quickshell.Io.FileView`).
   *Repli si l'I/O fichier sous qmltestrunner est trop fragile : ajouter `nodejs` comme
   runner de test dev-only — décision à prendre seulement si blocage.*
5. **Couleurs de tags** : recopiées de DESIGN.md (mapping tag → couleur) dans `threads.js`
   (`savedSearches`).

## Phases (chacune = commit(s) atomique(s))

### Phase 1 — Harnais golden + bless
Mettre `just test` et `just bless` réellement opérationnels sur une fixture triviale.
- `tests/tst_model.qml` (lecture fixture/golden + deep-equal).
- script bless quickshell.
- ajuster `Justfile` (`test`, `bless`).
- **Vérif :** `just test` passe sur un cas bidon ; `just bless` régénère.
- **Commits :** `test: golden harness via qmltestrunner`, `build: wire just bless`

### Phase 2 — Query builders
`src/query/queries.js` : `searchUnread()`, `search(raw)`, `count(query)`,
`showThread(id)`, `tagThread(id, {add, remove})` → argv notmuch.
- **Vérif :** tests d'argv exacts.
- **Commits :** `test(query): cover argv builders`, `feat(query): notmuch argv builders`

### Phase 3 — Search → threads
`src/model/threads.js : parseSearch(json)` + fixtures/goldens (fils lus/non-lus,
flaggés, multi-tags, multi-messages).
- **Commits :** `test(model): fixtures+golden for search`, `feat(model): parse search into threads`

### Phase 4 — Counts + recherches sauvegardées
`parseCount`, `savedSearches(tags, counts)` (label + compteur + couleur depuis DESIGN).
- **Commits :** `test(model): golden for saved searches`, `feat(model): counts and saved searches`

### Phase 5 — Show → snippet/détail
`parseShow(json)` → snippet + en-têtes du fil ; enrichit `Thread.snippet`.
- **Commits :** `test(model): golden for show`, `feat(model): parse show into snippet`

### Phase 6 — Synchro doc + clôture
- `DESIGN.md`/`README.md` : noter les modules `src/query` / `src/model`.
- `manual_tests.md` : essai contre la vraie base notmuch.
- **Vérif finale :** `just ci` vert.
- **Commit :** `docs: document data layer modules`

## Fichiers touchés

- `src/query/queries.js`
- `src/model/threads.js`
- `tests/tst_model.qml`
- `tests/fixtures/*.json`
- `tests/golden/*.json`
- `scripts/bless.qml` (ou équivalent quickshell)
- `Justfile` (cibles `test`/`bless`)
- `DESIGN.md` / `README.md`

## Portes de qualité (clôture)

- [ ] `just ci` passe (fmt-check + lint + test goldens)
- [ ] Goldens à jour et intentionnels
- [ ] Doc synchronisée (mêmes commits que le code structurel)
- [ ] Commits atomiques sur `feat/data-layer`, signés `+code`
