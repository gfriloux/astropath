# Plan : outillage de release + tag v0.4.0

**Type :** outillage (CI/CD, pas de code applicatif)
**Statut :** Terminé (2026-06-20) — reste le tag par l'utilisateur

## Contexte

Démarrage « lean » : renovate/cliff/release reportés au premier tag. Le cockpit est
complet et la CI verte → on met en place l'outillage de release, puis on tague v0.4.0.

## Objectif

Publier astropath : MAJ de dépendances automatisées, changelog auto depuis les
Conventional Commits, release GitHub sur tag.

## Périmètre

**In scope :** `renovate.json`, `cliff.toml` + `CHANGELOG.md`, workflow release GitHub,
git-cliff dans le dev shell, tag v0.4.0.

**Out of scope :** publication sur le registre de plugins DMS (plugins.danklinux.com) ;
artefact binaire (le plugin = source, pas de build).

## Décisions techniques

1. **Renovate** : managers `nix` (MAJ `flake.lock`) + `github-actions`, groupés,
   `commitMessagePrefix: "chore(deps):"` (cohérent avec le skip cliff), `schedule` week-end,
   label `dependencies`. Calqué sur pgpilot.
2. **git-cliff** : `cliff.toml` (Conventional Commits → sections Features/Bug Fixes/…,
   `chore`/`ci`/`build` skippés), URL `github.com/gfriloux/astropath`. `CHANGELOG.md` généré
   sur tout l'historique. `git-cliff` ajouté au dev shell + cible `just changelog`.
3. **Release** : `.github/workflows/release.yml` sur tag `v*` → `git-cliff --latest` pour les
   notes → release GitHub (`gh release create` / action). **Pas de build** : la release est
   une **release source** (GitHub attache le tarball ; l'installation se fait via le flake
   épinglé au tag).

## Phases (chacune = commit(s) atomique(s))

1. **Renovate** — `renovate.json` (nix + github-actions, groupé, hebdo). *Vérif : JSON valide.*
2. **Changelog** — `cliff.toml` + `git-cliff` au dev shell + `just changelog` + `CHANGELOG.md`
   généré. *Vérif : `just changelog` produit un CHANGELOG cohérent.*
3. **Workflow release** — `.github/workflows/release.yml` (tag `v*` → notes cliff → release).
   *Vérif : YAML valide ; `nix flake check`.*
4. **Clôture + tag** — sync doc (README : retirer renovate/cliff de la roadmap « à venir »),
   `just ci`, merge sur `main`, puis **tag `v0.4.0`** (par l'utilisateur) → release auto.

## Fichiers (prévisionnel)

- `renovate.json`
- `cliff.toml`, `CHANGELOG.md`
- `flake.nix` (git-cliff au dev shell), `Justfile` (`changelog`)
- `.github/workflows/release.yml`
- `README.md` (roadmap)

## Portes de qualité (clôture)

- [x] `renovate.json` valide ; `nix flake check` passe
- [x] `just changelog` génère un CHANGELOG cohérent (tag v0.4.0)
- [x] `just ci` vert
- [x] Commits atomiques sur `feat/release`, signés `+code`
- [ ] Branche mergée sur `main`, puis tag `v0.4.0` poussé (release auto à vérifier)

## Bilan

`renovate.json` (nix + github-actions, groupé), `cliff.toml` + `git-cliff` (dev shell +
`just changelog`) + `CHANGELOG.md`, workflow `release.yml` (notes git-cliff sur tag `v*`).
README mis à jour. Reste : merge + **tag `v0.4.0`** (par l'utilisateur) → 1re release.
