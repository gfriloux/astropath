# astropath

Widget mail pour **Quickshell / DankMaterialShell**. Un badge de non-lus dans la barre,
un popup pour scanner les fils, chercher, retaguer et ouvrir un mail. Les données viennent
de **notmuch** (Maildir indexé) ; tout raisonne par **fil** et par **tag**.

> Le warp est calme. L'astropathicus veille.

## Pile

- **Vue** : QML / Qt Quick via [Quickshell](https://quickshell.outfoxxed.me/), Material 3,
  thème Catppuccin Mocha.
- **Données** : `notmuch` (lecture + mutation de tags). Synchro assurée par `offlineimap`
  + `imapnotify`. L'ouverture d'un fil délègue à un client mail externe configurable
  (`alot` actuellement) ; astropath est une surface de **triage**, pas un client complet.

Architecture, invariants et système visuel : [`DESIGN.md`](./DESIGN.md).

## Développement

Le projet utilise un dev shell Nix (Quickshell, notmuch, qmllint/qmlformat, just) :

```bash
nix develop
just            # liste les cibles
just ci         # format + lint + test
just run        # lance le widget pour essai manuel
```

Hooks pre-commit : `pre-commit install`.

## Contribution

On ne code pas sans plan validé. Lire [`DESIGN.md`](./DESIGN.md) puis
[`PROCEDURE_PLANS.md`](./PROCEDURE_PLANS.md) avant tout changement. Politique git
**hybride** : travail sur branche dédiée, commits atomiques (Conventional Commits),
merge/push/tag réservés au mainteneur.

## Roadmap outillage

Démarrage **lean** : `flake.nix`, `Justfile`, pre-commit, CI minimale. À ajouter au
**premier tag** (`v0.1.0`) :

- `renovate.json` — MAJ de dépendances groupées.
- `cliff.toml` + workflow release — changelog auto depuis les Conventional Commits.
- `nix/hm-module.nix` — module home-manager pour installer le widget.

## Licence

Voir [`LICENSE`](./LICENSE).
