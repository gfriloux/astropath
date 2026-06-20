# Phase 0 — audit baseline (v0.1.0)

**Date :** 2026-06-20
**Commande :** `nix develop --command just ci`
**Exit :** 0

## Résultat

- **Dev shell** : se construit et fonctionne. `quickshell 0.3.0` et `notmuch 0.40`
  récupérés depuis `cache.nixos.org` (pas de build local long).
- **`just fmt-check`** : no-op (aucun `.qml` dans `src/`).
- **`just lint`** : no-op (aucun `.qml`).
- **`just test`** : affiche le TODO golden (aucun test encore).

## État du working tree

- Pas de `src/`, pas de `tests/`. Base vierge — on part de zéro.
- Fondations en place (flake, Justfile, pre-commit, CI, DESIGN/CLAUDE/PROCEDURE).

## Conclusion

Base propre, rien de cassé, rien à supprimer. On peut démarrer l'implémentation.
