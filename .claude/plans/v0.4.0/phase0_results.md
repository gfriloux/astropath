# Phase 0 — audit baseline (v0.4.0)

**Date :** 2026-06-20
**Commande :** `nix develop --command just ci`
**Exit :** 0
**Branche :** `feat/functional` (depuis `main` = 0342656, v0.3.0 mergée)

## Résultat

- `just ci` vert : 18 tests. Base v0.2.0 + v0.3.0 saine.

## Décision technique (compteurs)

`Process` quickshell : pas d'usage d'écriture stdin confirmé dans DMS → on évite
`notmuch count --batch` (stdin) et tout `sh -c` (injection). Compteurs calculés en
**séquentiel** : un `Process` count réutilisé, enchaîné par définition (liste courte,
count rapide). Chaque requête reste un argv unique.

## Conclusion

Base saine. v0.4.0 = enrichissement fonctionnel par-dessus le cockpit existant.
