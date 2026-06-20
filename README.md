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

Hooks pre-commit : `pre-commit install`. `just run` lie le plugin dans le dossier DMS,
`just reload` recharge DMS (le toggle plugin ne relit pas le QML).

## Installation

astropath est un **plugin DankMaterialShell**. Via le module home-manager :

```nix
inputs.astropath.url = "github:gfriloux/astropath";

# config home-manager :
imports = [ inputs.astropath.homeModules.default ];
programs.astropath.enable = true;
```

Le module installe le plugin dans `~/.config/DankMaterialShell/plugins/Astropath/` ;
il reste à l'**activer dans DMS** (Settings → Plugins → Astropath) et à configurer le
client de lecture + les smart folders dans ses réglages.

## Structure du code

- `plugin.json` — manifest du plugin DMS (type widget, permissions, icône).
- `src/query/` — construction des commandes notmuch (argv), JS pur.
- `src/model/` — transforms `notmuch` JSON → modèle (`parseSearch`/`parseCount`/
  `savedSearches`/`parseShow`) + `format.js`, JS pur testé par goldens.
- `src/view/` — plugin QML : widget barre, cockpit (popout), réglages. Thème hérité de DMS.
- `tests/` — fixtures notmuch + goldens. `just test` (qmltestrunner), `just bless`
  (régénère). Données de test synthétiques.
- `nix/hm-module.nix` — module home-manager (installe le plugin).

## Contribution

On ne code pas sans plan validé. Lire [`DESIGN.md`](./DESIGN.md) puis
[`PROCEDURE_PLANS.md`](./PROCEDURE_PLANS.md) avant tout changement. Politique git
**hybride** : travail sur branche dédiée, commits atomiques (Conventional Commits),
merge/push/tag réservés au mainteneur.

## Roadmap outillage

Démarrage **lean** : `flake.nix`, `Justfile`, pre-commit, CI minimale, module
home-manager. À ajouter au **premier tag** :

- `renovate.json` — MAJ de dépendances groupées.
- `cliff.toml` + workflow release — changelog auto depuis les Conventional Commits.

## Licence

Voir [`LICENSE`](./LICENSE).
