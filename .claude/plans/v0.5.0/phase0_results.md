# Phase 0 — Audit v0.5.0

**Date :** 2026-06-21
**Commande :** `nix develop --command just ci`

## Résultat : VERT ✅

- `fmt-check` : OK (aucun fichier non formaté).
- `lint` (qmllint) : OK (aucun warning).
- `test` : **20 passed, 0 failed, 0 skipped** (golden + model + queries).

La base part propre. v0.4.0 est clôturé. Aucun nettoyage préalable nécessaire.

## Périmètre de la base au démarrage

- v0.5.0 ne touche que l'étage **`view`** → pas de fixture/golden (cf. PROCEDURE_PLANS §5,
  recette « changement de vue »). Vérification = relecture visuelle + `manual_tests.md`.
- Garde-fou animations déjà respecté dans le code existant (`AstropathWidget` pulse,
  `ThreadRow` apparition) : toute nouvelle animation doit se neutraliser sur
  `Theme.currentAnimationSpeed === SettingsData.AnimationSpeed.None`.
