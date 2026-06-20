# Tests manuels — v0.4.0 (enrichissement fonctionnel)

> Validation dans DMS (plugin lié + activé). `just reload` après chaque phase.

| Phase | Action | Attendu | OK |
|---|---|---|---|
| 1 | Ouvrir le popout | chaque entrée du rail affiche son **compteur** `label (N)` ; MAJ au polling | ☐ |
| 2 | Fil avec tags de catégorie | **chips colorés** selon la config (couleur du smart folder) | ☐ |
| 3 | Sélectionner un fil | **snippet** (1-2 lignes) affiché sous le sujet | ☐ |
| 4 | Bouton retag (`sell`) sur un fil | éditeur ; ajouter/retirer un tag → appliqué (`notmuch tag`) + refresh | ☐ |
