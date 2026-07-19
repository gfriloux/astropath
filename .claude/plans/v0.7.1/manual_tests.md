# Tests manuels — v0.7.1

> Non automatisables (rendu QML / Quickshell sur Wayland). Purger
> `~/.cache/quickshell/qmlcache` avant l'essai si une modif QML semble invisible.

## MT-1 — Défilement du rail des catégories

**Pré-requis :** une base notmuch avec assez de tags pour que le rail dépasse la hauteur
du popout (rail ancré `top → footer.top`).

1. Ouvrir le popout cockpit.
2. Constater que le rail gauche liste les catégories et que la dernière dépasse la zone.
3. Molette de la souris sur le rail → le contenu défile.
4. La scrollbar DMS apparaît pendant le défilement.
5. La dernière catégorie du bas est atteignable et cliquable.
6. Le défilement s'arrête aux bornes (pas de sur-défilement infini).
7. Aucun item ne déborde visuellement sous le pied / hors de la zone du rail (`clip`).

**Attendu :** le rail défile comme la liste de mails ; tous les items sont accessibles.

## MT-2 — Non-régression rail court

1. Base avec peu de tags (rail tient dans la hauteur).
2. Ouvrir le popout.

**Attendu :** rail affiché normalement, pas de scrollbar parasite, sélection/hover/clic
et compteurs inchangés.
