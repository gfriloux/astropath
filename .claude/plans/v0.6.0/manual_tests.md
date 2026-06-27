# Tests manuels — v0.6.0 (catégories auto-découvertes)

À exécuter en clôture (ce que les goldens ne couvrent pas : rendu QML, réglages live).

## Rail auto-peuplé
- [ ] Ouvrir le cockpit : le rail liste les universels (Inbox/Flaggés/Spam) **puis** une
      entrée par tag notmuch non-machine, triées alpha, avec compteur.
- [ ] Les tags machine (`unread`, `attachment`, `signed`, `replied`, …) **n'apparaissent
      pas**.
- [ ] Chaque catégorie a une couleur stable (relancer le widget → même couleur).
- [ ] Cliquer une catégorie filtre la liste sur `tag:<x>`.

## Réglages — amender
- [ ] La section liste les tags découverts.
- [ ] Masquer un tag → il disparaît du rail après refresh.
- [ ] Renommer un tag (override label) → le rail affiche le nouveau libellé, le filtre
      reste `tag:<x>`.
- [ ] Changer la couleur d'un tag → chip et rail reflètent la teinte choisie.
- [ ] Ajouter une recherche custom composée (`tag:boulot and tag:unread`) → apparaît en
      bas du rail avec son compteur.

## Dégradé / robustesse
- [ ] Base sans tag custom : seuls les universels s'affichent (pas de plantage).
- [ ] notmuch indisponible : le widget ne plante pas (statut error), rail vide toléré.
