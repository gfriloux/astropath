# Phase 0 — audit baseline (release)

**Date :** 2026-06-20
**Commande :** `nix develop --command just ci`
**Exit :** 0
**Branche :** `feat/release` (depuis `main` = 80e9dbf — v0.4.0 + fix CI)

## Résultat

- `just ci` vert ; CI GitHub Actions désormais verte (fix `QML2_IMPORT_PATH`).
- Cockpit fonctionnellement complet (v0.1.0 → v0.4.0).

## Conclusion

Le projet est prêt à être publié. Reste l'outillage de release (déféré depuis le départ
en mode « lean ») : MAJ de dépendances, changelog auto, workflow de release, puis tag.
