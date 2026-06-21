# Tests manuels — v0.5.0 (polish visuel)

> Étage `view` : pas de golden. Validation = relecture visuelle dans DMS
> (`just run`), animations ON puis OFF.

## Hiérarchie (Phase 1)

- [ ] Émetteur, sujet et snippet se distinguent **au premier coup d'œil** sur un fil non-lu.
- [ ] Sur un fil **lu**, émetteur (Medium) et sujet (Normal) restent distincts (graisse).
- [ ] Snippet nettement plus éteint (~50 %) et plus petit que le sujet.
- [ ] Élision correcte (pas de débordement) sur sujets/émetteurs longs.

## Séparateurs (Phase 2)

- [ ] Filet fin visible **entre** les fils, fondu aux deux bords.
- [ ] Aucun filet ne traverse la carte active ni la carte survolée.
- [ ] Rythme visuel cohérent (espacement liste OK).

## Bord d'accent + transitions (Phase 3)

- [ ] Le fil actif porte un **bord-gauche mauve** (conforme DESIGN.md).
- [ ] Transition de fond fluide hover ↔ sélection ↔ repos.
- [ ] `AnimationSpeed = None` → changements **instantanés**, aucun artefact.

## Barre d'actions (Phase 4)

- [ ] Déploiement en douceur au focus/hover ; repli propre.
- [ ] La rangée reste compacte quand la barre est masquée.
- [ ] `AnimationSpeed = None` → apparition immédiate.

## Ripple + infobulles (Phase 5)

- [ ] Ripple au clic sur chaque bouton d'action.
- [ ] Infobulle après ~400 ms de survol, libellé correct par action.
- [ ] `enableRippleEffects = false` ou animations `None` → pas de ripple, rien ne casse.

## Non-régression

- [ ] Navigation clavier j/k/⏎/e/# inchangée.
- [ ] Retag inline, chips colorés, compteurs rail, snippet paresseux : OK.
- [ ] Badge de barre + popout s'ouvrent normalement.
