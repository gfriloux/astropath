# CLAUDE.md

Guidage pour Claude Code (claude.ai/code) dans ce dépôt.

> **Avant tout travail sur le code, lire [`DESIGN.md`](./DESIGN.md) puis
> [`PROCEDURE_PLANS.md`](./PROCEDURE_PLANS.md). On ne code pas sans plan validé.**

## Ce qu'est astropath

Widget mail pour **Quickshell / DankMaterialShell** : badge de non-lus dans la barre +
popup. Données via **notmuch** (Maildir indexé), raisonnement **par fil et par tag**
(agnostique au compte). Synchro **offlineimap** + **imapnotify**. L'ouverture d'un fil
délègue à un client externe configurable (`alot` actuellement). Détails et invariants :
`DESIGN.md`.

## Pile & structure

- **Vue** : QML / Qt Quick (Quickshell), Material 3, Catppuccin Mocha.
- **Données** : couche `query` (lance notmuch) → `model` (modèle de fils, pur/testable) →
  `view` (QML). Le QML n'appelle **jamais** `notmuch` en direct.

```
src/            ← QML Quickshell + couches query/model
tests/          ← fixtures notmuch (JSON figé) + goldens (modèle attendu)
.claude/plans/  ← plans de version (plan.md, manual_tests.md, phase0_results.md)
tmp/            ← scratch non commité (handoff design, notes)
```

## Dev environment

Toujours entrer le dev shell Nix avant de builder/tester :

```bash
nix develop
```

Pour les commandes non interactives : `nix develop --command just ci`.

## Commandes

```bash
just ci          # porte complète : fmt-check + lint + test
just fmt         # qmlformat -i (formate en place)
just fmt-check   # vérifie le format, échoue si non conforme
just lint        # qmllint, aucun warning toléré
just test        # golden notmuch + Qt Quick Test
just run         # lance le widget dans Quickshell (essai manuel)
just bless       # régénère les goldens (relire le diff)
```

Le `Justfile` est la **seule** définition des gates ; pre-commit et la CI l'appellent.

## Garde-fous (ce qui ne change pas)

- **DESIGN.md fait foi.** Hors invariants → non. Tag-only, notmuch source de vérité,
  **agnostique au compte** (un compte = une facette de requête, donc multi-compte par
  construction) : invariants durs. Le client de lecture (`alot` aujourd'hui) est une
  décision de périmètre **révisable**, pas un invariant.
- **Git : hybride.** Claude travaille sur une **branche dédiée**, commite **atomiquement**
  (Conventional Commits, cf. PROCEDURE_PLANS.md §3), et ne fait **jamais** `merge`/`push`/`tag`.
  L'utilisateur relit, merge sur `main`, push.
- **Doc dans le même commit** que le code qu'elle décrit.
- **`tmp/`** : jamais commité.
- **Couche données déterministe** : tout changement de `query`/`model` passe par une
  fixture + un golden (cf. PROCEDURE_PLANS.md §4).
- **Outillage release** (renovate, git-cliff, workflow release) : ajouté au **premier tag**,
  pas avant.
