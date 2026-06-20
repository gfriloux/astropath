# Phase 0 — audit baseline (v0.2.0)

**Date :** 2026-06-20
**Commande :** `nix develop --command just ci`
**Exit :** 0
**Branche :** `feat/cockpit` (depuis `main` = 9586164, v0.1.0 mergée)

## Résultat

- `just ci` vert : **15 tests** golden/unitaires passent (couche données v0.1.0).
- Working tree propre.

## Base de départ

```
src/query/queries.js   builders argv notmuch (search/count/show/tag)
src/model/threads.js   parseSearch, parseCount, savedSearches, parseShow
tests/                 harnais golden + fixtures/goldens (données synthétiques)
```

Aucune **vue** ni **glue I/O réel** (`Notmuch.qml`) — c'est tout l'objet de v0.2.0.

## Conclusion

Base propre et testée. Prêt à construire la vue cockpit + le câblage notmuch.
