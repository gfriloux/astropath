# Tests manuels — outillage de release

| Action | Attendu | OK |
|---|---|---|
| `just changelog` dans le dev shell | `CHANGELOG.md` généré, sections Features/Bug Fixes… cohérentes | ☐ |
| `nix flake check` | passe (workflow/flake valides) | ☐ |
| Pousser le tag `v0.4.0` | le workflow release se déclenche, crée la release GitHub avec les notes git-cliff | ☐ |
| Renovate (après activation sur le repo) | ouvre des PR groupées `chore(deps):` pour flake.lock / github-actions | ☐ |
