# Plan : v0.5.0 — polish visuel du cockpit

**Type :** vue (étage `view` uniquement)
**Statut :** Implémenté — en attente de relecture visuelle + merge (2026-06-21)
**Branche :** `feat/visual-polish`

## Contexte

Le cockpit est complet fonctionnellement (v0.2.0 → v0.4.0). Visuellement, il n'est pas
encore au niveau du mockup de référence (`tmp/design_handoff_astropath/`). Deux écarts
ressortent à l'usage :

1. **Hiérarchie absente** dans `ThreadRow` : émetteur, sujet et snippet partagent quasi
   le même style (émetteur et sujet sont en `fontSizeMedium` 14, mêmes règles de couleur ;
   sur un fil lu ils sont identiques). Le snippet n'est différencié que par la taille,
   pas par la couleur → bouillie grise.
2. **Pas de séparateurs** entre fils (uniquement de l'espacement) ; le rendu est plat.

Écart annexe détecté : le **bord-gauche mauve du fil actif** prescrit par DESIGN.md
(« le fil sous le curseur clavier a un bord-gauche Mauve ») **n'existe pas** dans
`ThreadRow` — seul le fond change (`Theme.primarySelected`). À corriger ici.

## Objectif

Amener le cockpit au niveau de finition du mockup : hiérarchie typographique nette,
séparateurs fins, et micro-interactions tactiles — sans toucher aux invariants (100 % `view`).

## Périmètre

**In scope :**
- Hiérarchie émetteur / sujet / snippet (graisse + couleur + taille).
- Séparateurs **en dégradé** (fondu aux bords) entre les fils, s'effaçant autour de la
  carte active.
- Bord-gauche mauve animé sur le fil actif (alignement DESIGN.md).
- Transitions douces hover ↔ sélection (fond + bord).
- Révélation **animée** de la barre d'actions (au lieu du snap actuel).
- Ripple + infobulles sur les boutons d'action (via `StateLayer` de DMS).

**Out of scope :** avatar scale au hover, pulse du point non-lu, translate Y à
l'apparition, easings expressifs M3 (réservés à un éventuel cran « expressif » ultérieur) ;
toute modif `query`/`model` ; nouvelles fonctionnalités ; release/tag.

## Décisions de design (validées avec l'utilisateur 2026-06-21)

1. **Hiérarchie = équilibrée (3 leviers).** Différenciation par graisse + couleur + taille,
   sans ligne dominante :
   - **Émetteur** : 14 (`fontSizeMedium`), DemiBold si non-lu / Medium si lu,
     couleur `surfaceText` (non-lu) / `surfaceTextMedium` (lu). Ancre forte.
   - **Sujet** : 14, Normal, couleur `surfaceText` (non-lu) / `surfaceTextMedium` (lu).
     Distingué de l'émetteur par la **graisse**.
   - **Snippet** : 12 (`fontSizeSmall`), Normal, couleur **intermédiaire ~50 %**
     (`Theme.withAlpha(Theme.surfaceText, 0.5)`) — il manque un gris entre
     `surfaceTextMedium` (0.7) et `surfaceTextLight` (0.06). Clairement tertiaire.
   - Valeurs exactes ajustables dans la boucle de relecture visuelle (autorisé §5).
2. **Séparateurs = filet en dégradé.** Hairline 1px, `Gradient` horizontal
   `transparent → Theme.outlineMedium → transparent` (fondu aux deux bords). Placé dans
   l'inter-rangée, **masqué/estompé** autour de la carte active ou survolée.
3. **Animations = équilibré.** Transitions `Behavior` (fond, bord, hauteur, opacité) +
   ripple + tooltips. **Pas** d'avatar scale / dot pulse / translate Y.
4. **Garde-fou animations.** Chaque `Behavior`/animation ajouté est neutralisé sur
   `AnimationSpeed.None` (via `enabled:` ou garde explicite), comme l'existant.
   `StateLayer`/`DankRipple` gèrent déjà `None` + le réglage `enableRippleEffects`.
5. **Réutilisation DMS.** On s'appuie sur `StateLayer` (ripple + état + tooltip en un),
   `Theme.outline*`, tokens de durée/easing. Aucune valeur hex en dur (invariant thème).

## Fichiers touchés (prévisionnel)

- [ ] `src/view/ThreadRow.qml` (hiérarchie, bord mauve, transitions, barre d'actions animée,
      hôte du séparateur)
- [ ] `src/view/GradientSeparator.qml` (**nouveau** : filet 1px en dégradé)
- [ ] `src/view/ActionButton.qml` (réécrit sur `StateLayer` : ripple + tooltip)
- [ ] `src/view/Cockpit.qml` (ajustement éventuel de `spacing` de la liste pour le filet)
- [ ] `src/view/SavedSearchRail.qml` (optionnel : `StateLayer` pour cohérence tactile)
- [ ] `DESIGN.md` (note « séparateurs en dégradé » dans le système visuel, même commit)
- [ ] `.claude/plans/v0.5.0/manual_tests.md` (mis à jour au fil)

## Phases (chacune = commit(s) atomique(s) ; vérif = relecture visuelle DMS)

### Phase 1 — Hiérarchie typographique
**Description :** dans `ThreadRow`, appliquer les 3 leviers (décision 1) à émetteur / sujet /
snippet. Ajuster l'espacement vertical du `Column` texte si besoin pour aérer.
**Vérification :** `just fmt-check && just lint` ; relecture visuelle (les 3 lignes se
distinguent au premier coup d'œil, lu comme non-lu).
**Commit :** `feat(view): hiérarchiser émetteur/sujet/snippet dans ThreadRow`

### Phase 2 — Séparateurs en dégradé
**Description :** créer `GradientSeparator.qml` (1px, gradient horizontal fondu aux bords,
couleur `Theme.outlineMedium`). L'instancier en pied de `ThreadRow`, masqué quand la rangée
est active ou survolée (fondu via `Behavior on opacity`, neutralisé si `None`). Ajuster
`spacing` de la `DankListView` dans `Cockpit.qml` pour que le filet vive dans l'inter-rangée.
Note dans `DESIGN.md` (même commit).
**Vérification :** `just fmt-check && just lint` ; relecture (filets fins visibles entre
fils, jamais en travers de la carte active).
**Commit :** `feat(view): séparateurs en dégradé entre les fils`

### Phase 3 — Bord d'accent + transitions hover/sélection
**Description :** ajouter le bord-gauche mauve (`Theme.primary`) sur le fil actif
(rectangle fin à gauche, `radius` cohérent), animé en largeur/opacité à la sélection.
Ajouter `Behavior on color` sur le fond de rangée (hover ↔ sélection ↔ transparent).
Tout sous garde `AnimationSpeed.None`.
**Vérification :** `just fmt-check && just lint` ; relecture (bord mauve aligné DESIGN ;
transitions fluides ; instantané si animations = None).
**Commit :** `feat(view): bord d'accent mauve et transitions hover/sélection`

### Phase 4 — Barre d'actions animée
**Description :** remplacer le toggle brut `visible/implicitHeight 0↔N` par une révélation
animée (hauteur + opacité, `Behavior`/`NumberAnimation`), dans l'esprit
`DankCollapsibleSection`. Garde `None` (apparition immédiate).
**Vérification :** `just fmt-check && just lint` ; relecture (la barre se déploie en douceur
au focus/hover, se replie proprement).
**Commit :** `feat(view): révélation animée de la barre d'actions`

### Phase 5 — Tactile : ripple + infobulles
**Description :** réécrire `ActionButton` sur `StateLayer` (ripple + couche d'état +
`tooltipText`), avec un libellé d'infobulle par action (lu / archiver / flag / retag /
supprimer / ouvrir). Optionnel : `StateLayer` sur les items du rail pour cohérence.
**Vérification :** `just fmt-check && just lint` ; relecture (ripple au clic, tooltip après
survol ; rien ne casse si `enableRippleEffects`/animations off).
**Commit :** `feat(view): ripple et infobulles sur les boutons d'action`

### Phase 6 — Clôture
**Description :** passe `just ci` complète ; `manual_tests.md` à jour et exécuté ; bilan.
**Vérification :** `nix develop --command just ci` vert.
**Commit :** (rien de neuf, ou `docs:` résiduel si besoin) — puis l'utilisateur merge.

## Portes de qualité (clôture)

- [x] `just ci` passe (fmt + lint + test, 20 passed) — aucun golden ne bouge (étage `view`).
- [x] Rendu validé dans DMS (relecture visuelle utilisateur, 2026-06-21).
- [x] Aucune valeur hex en dur (tout via `Theme.*`).
- [x] Chaque animation neutralisée sur `AnimationSpeed.None` (Behaviors gardés ; ripple/tooltip via StateLayer).
- [x] Doc (`DESIGN.md`) synchronisée dans le même commit que le code.
- [x] Commits atomiques sur `feat/visual-polish` (email `guillaume@friloux.me`, signés GPG).
- [ ] Branche mergée sur `main` à la clôture (par l'utilisateur).

## Bilan

**Statut : validé visuellement, prêt à merger (2026-06-21).** `just ci` vert.

Commits du plan (étage `view`) :

1. `feat(view): hiérarchiser émetteur/sujet/snippet dans ThreadRow`
2. `feat(view): séparateurs en dégradé entre les fils` (+ `GradientSeparator.qml`, DESIGN.md)
3. `feat(view): bord d'accent mauve et transitions hover/sélection`
4. `feat(view): révélation animée de la barre d'actions`
5. `feat(view): ripple et infobulles sur les boutons d'action` (ActionButton sur StateLayer)

### Ajustements post-relecture visuelle

- **Hiérarchie renforcée** (`feat(view): renforcer la hiérarchie…`) : la version initiale
  était trop discrète à l'usage → émetteur DemiBold plein, sujet Normal éteint (0.55),
  snippet plus pâle (0.42).
- **Bord mauve retiré** (`feat(view): retirer le bord mauve…`) : jugé non concluant
  visuellement ; la sélection repose désormais sur la **carte tintée seule**. DESIGN.md
  mis à jour (l'écart « bord-gauche Mauve » de la Phase 3 est donc annulé, pas conservé).
- **Popup agrandi** (`feat(view): agrandir le popup… (680x680)`) : 582×520 trop à l'étroit.
  DESIGN.md note de largeur passée à ~680px.

### Hors périmètre `view`, traités en passant

- **`build:` purge du qmlcache dans `just reload`** : un `systemctl restart` seul
  reservait l'ancien bytecode QML compilé → modifs invisibles. Cause de la confusion de
  relecture initiale (cf. [[dms-plugin-reload-qmlcache]]).
- **Email des commits corrigé** : la branche a été réécrite en `guillaume@friloux.me`
  (auteur + committer, re-signés GPG) ; `guillaume+code@friloux.me` cassait la vérif
  (cf. [[commit-email-gpg]]).

**Reste à faire :** merge `feat/visual-polish` → `main` + push + tag `v0.5.0` (utilisateur).
