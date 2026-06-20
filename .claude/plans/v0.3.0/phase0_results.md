# Phase 0 — audit baseline (v0.3.0)

**Date :** 2026-06-20
**Commande :** `nix develop --command just ci`
**Exit :** 0
**Branche :** `feat/polish` (depuis `main` = 1f52fde, v0.2.0 mergée)

## Résultat

- `just ci` vert : 16 tests (data layer + relativeTime). Base v0.2.0 saine.
- Cockpit fonctionnel en place (plugin DMS).

## Briques DMS confirmées (pour la finition)

- Pas de composant avatar → monogramme via `StyledRect` + initiales.
- `Theme.monoFontFamily` (Fira Code) pour heures/compteurs/requête ;
  `Theme.fontFamily` = Inter Variable (déjà la police du proto).
- Tokens d'animation : `Theme.shortDuration`/`mediumDuration`… + `Theme.currentAnimationSpeed`
  (respecter `AnimationSpeed.None` → animations désactivables).

## Conclusion

Base saine. Tout le travail v0.3.0 est visuel (vue QML), validé manuellement dans DMS.
